module gccbuild.patch;

import scriptlike, gccbuild;

void patchSources()
{
    startSectionLog("Dumping patch directories");
    foreach (entry; patchDirectories)
        writeBulletPointLog(entry.toString());
    endSectionLog();

    startSection("Patching sources");
    foreach (name, component; build.configuredComponents)
    {
        patchComponent(*component);
    }

    if (!gdcSourcePath.empty && build.gcc.wasExtracted)
    {
        writeBulletPoint("Merging GDC into GCC");
        auto oldCWD = pushCWD(Path(gdcSourcePath));
        runCollectLog("./setup-gcc.sh " ~ build.gcc.sourceFolder.toString());
        endBulletPoint();
    }
    endSection();
}

void patchComponent(MainConfig.Component component)
{
    if (!component.wasExtracted)
        writeBulletPoint(component.baseDirName.toString() ~ "... (skipped)");
    else
    {
        writeBulletPoint(component.baseDirName.toString());
        auto patches = getPatchList(component);

        auto oldCWD = pushCWD(component.sourceFolder);
        foreach (entry; patches)
            runCollectLog("patch -p1 -i " ~ entry);
        endBulletPoint();
    }
}

string[] getPatchList(MainConfig.Component component)
{
    string[string] patches;

    foreach (patchDir; patchDirectories)
    {
        patchDir = patchDir ~ component.baseDirName;
        if (!patchDir.exists)
            continue;

        foreach (entry; patchDir.dirEntries(SpanMode.shallow))
        {
            // Allow later directories to overwrite patch
            patches[entry.baseName] = entry;
        }
    }

    auto sorted = patches.values.dup;
    sorted.sort!((a, b) => a.baseName < b.baseName);

    yapFunc(sorted);
    return sorted;
}
