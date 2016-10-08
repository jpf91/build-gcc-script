module gccbuild.build.binutils;

import scriptlike, gccbuild;

void buildBinutils()
{
    auto comp = build.binutils;
    startSection("Building binutils");
    auto saveCWD = comp.prepareBuildDir();

    runBuildCommands(comp.cmdVariants["main"].commands,
        ["CONFIGURE" : comp.configureFile.toString()]);

    if (!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}
