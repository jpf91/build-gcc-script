module gccbuild.build.binutils;

import scriptlike, gccbuild;

void buildBinutils()
{
    auto comp = build.binutils;
    startSection("Building binutils");
    auto saveCWD = comp.prepareBuildDir();

    runBuildCommands(comp.mainBuildCommand.commands, ["CONFIGURE" : comp.configureFile.toString()]);

    if (!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}
