module gccbuild.build.glibc;

import scriptlike, gccbuild;

void buildGlibc()
{
    //DIR_MULTILIB, MULTILIB_ARGS
    auto comp = build.glibc;
    startSection("Building glibc");
    auto oldPath = updatePathVar(binDirStage1);

    if(comp.cmdVariants["main"].multiCommands.empty)
    {
        foreach(multilib; build.multilibs)
        {
            writeBulletPoint("Multilib variant: " ~ (multilib.isDefaultLib ? "default" : multilib.args));
            auto saveCWD = comp.prepareBuildDir();

            auto mlibDir = Path("/") ~ Path(build.relativeSysrootPrefix) ~ Path("lib") ~ Path(multilib.osFolder);
            string[string] extraVars;
            extraVars["DIR_MULTILIB"] = mlibDir.toString();
            extraVars["MULTILIB_ARGS"] = multilib.args;

            extraVars["CONFIGURE"] = comp.configureFile.toString();
            runBuildCommands(comp.cmdVariants["main"].commands, extraVars);
            endBulletPoint();
        }
    }
    else
    {
        foreach(i, commands; comp.cmdVariants["main"].multiCommands)
        {
            writeBulletPoint("Custom multilib command run: " ~ to!string(i));
            auto saveCWD = comp.prepareBuildDir();

            runBuildCommands(commands, ["CONFIGURE": comp.configureFile.toString()]);
            endBulletPoint();
        }
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
