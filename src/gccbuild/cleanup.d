module gccbuild.cleanup;

import scriptlike, gccbuild, painlessjson, std.json;

void cleanupToolchain(Duration totalTime)
{
    startSection("Finalizing toolchain");

    stripTargetLibraries();
    stripHostBinaries();

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
    runCollectLog("mv " ~ (logFilePath.toString() ~ ".xz") ~ " " ~ (toolchainDir ~ "build.log.xz").toString());
    endBulletPoint();

    endSection(false);
}

struct GCCInfo
{
    string target, host;
    MultilibEntry[] multilibs;
}

void stripTargetLibraries()
{
    if(skipStripLibraries)
    {
        writeBulletPoint("Stripping target libraries... (skipped)");
        return;
    }
    writeBulletPoint("Stripping target libraries...");

    auto oldPath = updatePathVar(binDir);
    foreach(multilib; build.multilibs)
    {
        auto path = toolchainDir ~ Path("lib") ~ Path(multilib.osFolder);
        auto path2 = toolchainDir ~ Path(build.target) ~ Path("lib") ~ Path(multilib.osFolder);
        auto path3 = sysrootDir ~ Path("lib") ~ Path(multilib.osFolder);
        stripPath(path, build.target ~ "-strip");
        stripPath(path2, build.target ~ "-strip");
        stripPath(path3, build.target ~ "-strip");
    }
    restorePathVar(oldPath);
    endBulletPoint();
}

void stripHostBinaries()
{
    if(skipStripBinaries)
    {
        writeBulletPoint("Stripping host binaries... (skipped)");
        return;
    }
    writeBulletPoint("Stripping host binaries...");

    auto path = toolchainDir ~ "bin";
    auto path2 = toolchainDir ~ Path(build.target) ~ "bin";

    stripPath(path, build.host ~ "-strip", true, false);
    stripPath(path2, build.host ~ "-strip", true, false);
    endBulletPoint();
}

void stripPath(Path path, string stripProgram, bool stripExes = false, bool stripLibs = true)
{
    yapFunc(stripProgram, " ", path);
    if(!path.exists || !path.isDir)
        return;

    foreach(entry; path.dirEntries(SpanMode.depth))
    {
        if(!entry.isFile)
            continue;
        if(stripLibs && (entry.extension == ".so" || entry.extension == ".dll"))
        {
            // Skip linker script files (libc.so)
            if(!runCollectLog("file -b " ~ entry).canFind("ASCII"))
            {
                tryRunCollectLog(stripProgram ~ " " ~ entry);
            }
        }
        else if(stripExes &&
            (entry.extension == ".exe" || runCollectLog("file -b " ~ entry).canFind("executable")))
        {
            tryRunCollectLog(stripProgram ~ " " ~ entry);
        }
    }
}