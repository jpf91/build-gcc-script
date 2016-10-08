module gccbuild.extract;

import scriptlike, gccbuild;

void extractSources()
{
    startSection("Extracting files");
    extractDir.tryMkdirRecurse();
    chdir(extractDir);

    foreach (name, component; build.configuredComponents)
    {
        extractComponent(component);
    }

    if (build.glibc.isInConfig && !build.glibcPorts.file.empty)
    {
        extractComponent(&build.glibcPorts);
        runCollectLog(
            "mv " ~ build.glibcPorts.sourceFolder.toString() ~ " " ~ (
            build.glibc.sourceFolder ~ "ports").toString());
    }

    endSection();
}

void extractComponent(MainConfig.Component* component)
{
    switch (component.file.extension)
    {
    case ".gz":
    case ".bz2":
    case ".xz":
        failEnforcec(component.file.stripExt.extension == ".tar",
            "Unknown archive format: ", component.file);

        if (component.sourceFolder.exists && !forceExtract)
        {
            writeBulletPoint(component.file ~ " (cached)");
        }
        else
        {
            string forced = component.sourceFolder.exists ? " (forced)" : "";
            writeBulletPoint(component.file ~ forced ~ "...");
            component.sourceFolder.tryRmdirRecurse();
            try
                runCollectLog(mixin(interp!"tar xf ${component.localFile}"));
            catch (Exception e)
                failc("Couldn't extract ", component.file, ": ", e);
            component.wasExtracted = true;
            endBulletPoint();
        }
        break;
    default:
        failc("Unknown archive format: ", component.file);
    }
}
