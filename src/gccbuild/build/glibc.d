module gccbuild.build.glibc;

import scriptlike, gccbuild;

void buildGlibc()
{
    //DIR_MULTILIB, MULTILIB_ARGS
    auto comp = build.glibc;
    startSection("Building glibc");
    auto oldPath = updatePathVar(binDirStage1);

    foreach(multilib; build.multilibs)
    {
        writeBulletPoint("Multilib variant: " ~ (multilib.isDefaultLib ? "default" : multilib.args));
        auto saveCWD = comp.prepareBuildDir();

        auto mlibDir = Path("/") ~ Path(build.relativeSysrootPrefix) ~ Path("lib") ~ Path(multilib.osFolder);
        string[string] extraVars;
        extraVars["DIR_MULTILIB"] = mlibDir.toString();
        extraVars["MULTILIB_ARGS"] = multilib.args;

        /* 
         * stupid glibc messes up slibdir generation when not using a /usr prefix.
         * We could just use a /usr prefix instead, but then glibc will copy some files into /$LIBDIR and some in /usr/$LIBDIR 
         * https://sourceware.org/glibc/wiki/FAQ
         */
        Path("configparms").writeFile("slibdir=" ~ mlibDir.toString() ~ "\n");

        runBuildCommand(comp.configureFile.toString(), comp.commands["main"], "configure", extraVars);
        runBuildCommand("make", comp.commands["main"], "make", extraVars);
        runBuildCommand("make", comp.commands["main"], "make_install", extraVars);
        endBulletPoint();
    }

    writeBulletPoint("Cleaning up sysroot");
    tryRmdirRecurse(sysrootDir ~ "bin");
    tryRmdirRecurse(sysrootDir ~ "libexec");
    tryRmdirRecurse(sysrootDir ~ "sbin");
    tryRmdirRecurse(sysrootDir ~ "etc");
    tryRmdirRecurse(sysrootDir ~ "var");
    tryRmdirRecurse(sysrootDir ~ "share");
    endBulletPoint();

    restorePathVar(oldPath);

    if(!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}