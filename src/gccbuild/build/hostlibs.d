module gccbuild.build.hostlibs;

import gccbuild, scriptlike;

void buildHostLibs()
{
    startSection("Building host libraries");
    buildGMP();
    buildMPFR();
    buildMPC();
    endSection();
}

void buildGMP()
{
    buildLibrary(build.gmp, "GMP");
}

void buildMPFR()
{
    buildLibrary(build.mpfr, "MPFR");
}

void buildMPC()
{
    buildLibrary(build.mpc, "MPC");
}

private void buildLibrary(Component comp, string name)
{
    if (!comp.mainBuildCommand.matchesBuildType)
        return;

    writeBulletPoint(name ~ ": " ~ comp.baseDirName.toString());
    auto saveCWD = comp.prepareBuildDir();

    runBuildCommands(comp.mainBuildCommand.commands, ["CONFIGURE" : comp.configureFile.toString()]);

    if (!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endBulletPoint();
}
