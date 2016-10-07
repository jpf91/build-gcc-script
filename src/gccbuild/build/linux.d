﻿module gccbuild.build.linux;

import scriptlike, gccbuild;

void installLinuxHeaders()
{
    auto comp = build.linux;
    startSection("Installing linux headers");

    comp.buildFolder.tryRmdirRecurse();
    runCollectLog("cp -R --reflink=auto " ~ comp.sourceFolder.toString() ~ " " ~ comp.buildFolder.toString());
    auto saveCWD = comp.buildFolder.pushCWD();

    runBuildCommands(comp.cmdVariants["main"]);

    if(!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}