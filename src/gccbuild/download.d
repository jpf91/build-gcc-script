module gccbuild.download;

import scriptlike, gccbuild, std.digest.md;

void downloadSources()
{

    startSection("Fetching source files");

    foreach (name, component; build.configuredComponents)
    {
        downloadComponent(name, component);
    }

    if (build.glibcPorts)
        downloadComponent("glibc_ports", build.glibcPorts);

    endSection();
}

void downloadComponent(string name, Component component)
{
    auto dlPath = component.localFile;
    if (dlPath.exists && !forceDownload)
    {
        writeBulletPoint("Found " ~ component.file ~ " (cached)");
        if (verifyCachedSources)
            enforceChecksum(dlPath, component.md5);

        endBulletPoint();
    }
    else
    {
        string forced = dlPath.exists ? " (forced)" : "";
        writeBulletPoint("Downloading " ~ component.file ~ forced ~ "...");
        tryMkdirRecurse(dlPath.dirName);
        tryRemove(dlPath);

        string[] urls = map!(a => component.suburl.empty ? a ~ component.file : a ~ component
            .suburl)(mirrors[name]).array;
        if (!component.url.empty)
            urls = [component.url] ~ urls;

        foreach (url; urls)
        {
            try
            {
                runCollectLog(mixin(interp!"wget ${url} -O ${dlPath}"));
                break;
            }
            catch (Exception e)
            {
                tryRemove(dlPath);
            }
        }

        failEnforcec(dlPath.exists, "Failed to find a working mirror for ", component.file);
        enforceChecksum(dlPath, component.md5);
        endBulletPoint();
    }
}

void enforceChecksum(Path file, string sum)
{
    if (!verifyFile(file, sum))
        failc("Invalid MD5 of ", file);
}

bool verifyFile(Path file, string sum)
{
    auto md5 = File(file.toString()).byChunk(4096).md5Of().toHexString!(LetterCase.lower);
    if (sicmp(md5, sum) == 0)
    {
        yapFunc("md5(", file, ")=", md5, " == ", sum, " => OK");
        return true;
    }

    yapFunc("md5(", file, ")=", md5, " == ", sum, " => FAIL");
    return false;
}
