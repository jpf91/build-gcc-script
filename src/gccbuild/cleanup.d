module gccbuild.cleanup;

import scriptlike, gccbuild, painlessjson, std.json;

void cleanupToolchain(Duration totalTime)
{
    startSection("Finalizing toolchain");

    removeFolders();
    stripTargetLibraries();
    stripHostBinaries();

    if (build.cleanup.matchesBuildType && !build.cleanup.commands.empty)
    {
        writeBulletPoint("Executing custom cleanup commands");
        auto oldCWD = pushCWD(toolchainDir);
        runBuildCommands(build.cleanup.commands);
        endBulletPoint();
    }

    writeBulletPoint("Writing GCC information");
    auto info = GCCInfo(build.target, build.host, build.multilibs);
    auto json = info.toJSON();
    writeFile(toolchainDir ~ "gcc_info.json", toJSON(&json, true));
    endBulletPoint();

    endSectionLog();
    writelnLog();
    writelnLog("Total execution time: ", totalTime);
    closeLog();

    writeBulletPoint("Compressing log file");
    runCollectLog("xz -9 " ~ logFilePath.toString());
    runCollectLog(
        "mv " ~ (logFilePath.toString() ~ ".xz") ~ " " ~ (toolchainDir ~ "build.log.xz").toString());
    endBulletPoint();

    endSection(false);
}

struct GCCInfo
{
    string target, host;
    MultilibEntry[] multilibs;
}

void removeFolders()
{
    writeBulletPoint("Removing unnecessary folders");
    if ((build.cleanup.matchesBuildType && !build.cleanup.remove.empty)
            || (build.variantCleanup && !build.variantCleanup.remove.empty))
    {
        if (build.cleanup.matchesBuildType)
        {
            foreach (entry; build.cleanup.remove)
            {
                tryRmdirRecurse(toolchainDir ~ entry.substituteVars);
            }
        }
        if (build.variantCleanup)
        {
            foreach (entry; build.variantCleanup.remove)
            {
                tryRmdirRecurse(toolchainDir ~ entry.substituteVars);
            }
        }
    }
    else
    {
        tryRmdirRecurse(sysrootDirWithPrefix ~ "bin");
        tryRmdirRecurse(sysrootDirWithPrefix ~ "libexec");
        tryRmdirRecurse(sysrootDirWithPrefix ~ "sbin");
        tryRmdirRecurse(sysrootDirWithPrefix ~ "etc");
        tryRmdirRecurse(sysrootDirWithPrefix ~ "var");
        tryRmdirRecurse(sysrootDirWithPrefix ~ "share");
        tryRmdirRecurse(sysrootDir ~ "bin");
        tryRmdirRecurse(sysrootDir ~ "libexec");
        tryRmdirRecurse(sysrootDir ~ "sbin");
        tryRmdirRecurse(sysrootDir ~ "etc");
        tryRmdirRecurse(sysrootDir ~ "var");
        tryRmdirRecurse(sysrootDir ~ "share");
        tryRmdirRecurse(toolchainDir ~ "etc");
        tryRmdirRecurse(toolchainDir ~ "var");
        tryRmdirRecurse(toolchainDir ~ "share");
    }
    endBulletPoint();
}

void stripTargetLibraries()
{
    if (skipStripLibraries)
    {
        writeBulletPoint("Stripping target libraries... (skipped)");
        return;
    }
    writeBulletPoint("Stripping target libraries...");

    auto oldPath = updatePathVar(binDir);

    if ((build.cleanup.matchesBuildType && !build.cleanup.stripTarget.empty)
            || (build.variantCleanup && !build.variantCleanup.stripTarget.empty))
    {
        if (build.cleanup.matchesBuildType)
        {
            foreach (entry; build.cleanup.stripTarget)
            {
                stripPath(toolchainDir ~ entry.substituteVars, targetStrip);
            }
        }
        if (build.variantCleanup)
        {
            foreach (entry; build.variantCleanup.stripTarget)
            {
                stripPath(toolchainDir ~ entry.substituteVars, targetStrip);
            }
        }
    }
    else
    {
        foreach (multilib; build.multilibs)
        {
            auto path = sysrootDirWithPrefix ~ Path("lib") ~ Path(multilib.osFolder);
            auto path2 = toolchainDir ~ Path(build.target) ~ Path("lib") ~ Path(multilib.osFolder);
            auto path3 = toolchainDir ~ Path("lib") ~ Path(multilib.osFolder);
            auto path4 = toolchainDir ~ Path("lib");
            stripPath(path, targetStrip);
            stripPath(path2, targetStrip);
            stripPath(path3, targetStrip);
            stripPath(path4, targetStrip);
        }
    }
    restorePathVar(oldPath);
    endBulletPoint();
}

void stripHostBinaries()
{
    if (skipStripBinaries)
    {
        writeBulletPoint("Stripping host binaries... (skipped)");
        return;
    }
    writeBulletPoint("Stripping host binaries...");

    if ((build.cleanup.matchesBuildType && !build.cleanup.stripHost.empty)
            || (build.variantCleanup && !build.variantCleanup.stripHost.empty))
    {
        if (build.cleanup.matchesBuildType)
        {
            foreach (entry; build.cleanup.stripHost)
            {
                stripPath(toolchainDir ~ entry.substituteVars, hostStrip, true, false);
            }
        }
        if (build.variantCleanup)
        {
            foreach (entry; build.variantCleanup.stripHost)
            {
                stripPath(toolchainDir ~ entry.substituteVars, hostStrip, true, false);
            }
        }
    }
    else
    {
        auto path = toolchainDir ~ "bin";
        auto path2 = toolchainDir ~ Path(build.target) ~ "bin";
        auto path3 = toolchainDir ~ "libexec";
        auto path4 = toolchainDir ~ Path(build.target) ~ "libexec";
        stripPath(path, hostStrip, true, false);
        stripPath(path2, hostStrip, true, false);
        stripPath(path3, hostStrip, true, true);
        stripPath(path4, hostStrip, true, true);
    }
    endBulletPoint();
}

void stripPath(Path path, string stripProgram, bool stripExes = false, bool stripLibs = true)
{
    yapFunc(stripProgram, " ", path);
    if (!path.exists || !path.isDir)
        return;

    foreach (entry; path.dirEntries(SpanMode.depth))
    {
        if (!entry.isFile)
            continue;
        if (stripLibs && (entry.extension == ".so" || entry.extension == ".dll"
            || entry.extension == ".a" || entry.extension == ".lib"))
        {
            // Skip linker script files (libc.so)
            if (!runCollectLog("file -b " ~ entry).canFind("ASCII"))
            {
                tryRunCollectLog(stripProgram ~ " --strip-debug " ~ entry);
            }
        }
        else if (stripExes && (entry.extension == ".exe"
                || runCollectLog("file -b " ~ entry).canFind("executable")))
        {
            tryRunCollectLog(stripProgram ~ " --strip-debug " ~ entry);
        }
    }
}
