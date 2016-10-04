module gccbuild.build.binutils;

import scriptlike, gccbuild;

void buildBinutils()
{
    auto comp = build.binutils;
    startSection("Building binutils");
    auto saveCWD = comp.prepareBuildDir();
        
    runBuildCommand(comp.configureFile.toString(), comp.commands["main"], "configure");
    runBuildCommand("make", comp.commands["main"], "make");
    runBuildCommand("make", comp.commands["main"], "make_install");

    if(!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}