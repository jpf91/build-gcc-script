module gccbuild.build.binutils;

import scriptlike, gccbuild;

void buildBinutils()
{
    auto comp = build.binutils;
    if (!comp.mainBuildCommand.matchesBuildType)
        return;

    startSection("Building binutils");
    auto saveCWD = comp.prepareBuildDir();

    runBuildCommands(comp.mainBuildCommand.commands, ["CONFIGURE" : comp.configureFile.toString()]);

    if (!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}
