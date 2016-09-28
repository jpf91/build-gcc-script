module gccbuild.download;

import scriptlike, gccbuild, std.digest.md;

void downloadSources()
{

    startSection("Fetching source files");

    foreach(name, component; build.namedFields!(BuildConfig, "mpc", "mpfr", "gmp", "glibc", "linux", "w32api", "gcc"))
    {
        if (!component.isInConfig)
            continue;
            
        auto dlPath = downloadDir ~ name ~ component.file;
        if (dlPath.exists && !forceDownload)
        {
            if (verifyCachedSources)
                enforceChecksum(dlPath, component.md5);

            writeBulletPoint("Found " ~ component.file ~ " (cached)");
        }
        else
        {
            string forced = dlPath.exists ? " (forced)" : "";
            writeBulletPoint("Downloading " ~ component.file ~ forced ~ "...");
            tryMkdirRecurse(dlPath.dirName);
            tryRemove(dlPath);

            string[] urls = map!(a => component.suburl.empty
                ? a ~ component.file : a ~ component.suburl)(mirrors[name]).array;
            if(!component.url.empty)
                urls = [component.url] ~ urls;

            foreach(url; urls)
            {
                try
                {
                    auto output = runCollect(mixin(interp!"wget ${url} -O ${dlPath}"));
                    writeLogCMD(output);
                    break;
                }
                catch(Exception e)
                {
                    tryRemove(dlPath);
                }
            }

            failEnforcec(dlPath.exists, "Failed to find a working mirror for ", component.file);
            enforceChecksum(dlPath, component.md5);
        }
    }
}

void enforceChecksum(Path file, string sum)
{
    if(!verifyFile(file, sum))
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

auto namedFields(T, A...)(T instance)
{
    static string generateMixin(string[] fields)
    {
        string result = "return only(";
        foreach(i, entry; fields)
        {
            if (i != 0)
                result ~= ", ";
            result ~= "tuple!(\"name\", \"value\")(\"" ~ entry ~ "\", instance." ~ entry ~ ")";
        }
        result ~= ");";
        return result;
    }
    
    mixin(generateMixin([A]));
}