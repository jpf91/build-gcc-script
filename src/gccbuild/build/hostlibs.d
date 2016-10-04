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

private void buildLibrary(MainConfig.Component comp, string name)
{
    writeBulletPoint(name ~ ": " ~ comp.baseDirName.toString());
    auto saveCWD = comp.prepareBuildDir();
    
    runBuildCommand(comp.configureFile.toString(), comp.commands["main"], "configure");
    runBuildCommand("make", comp.commands["main"], "make");
    runBuildCommand("make", comp.commands["main"], "make_install");

    if(!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endBulletPoint();
}