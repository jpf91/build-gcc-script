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
            {
                auto md5 = File(dlPath.toString()).byChunk(4096).md5Of().toHexString!(LetterCase.lower);
                failEnforcec(sicmp(md5, component.md5) == 0,"Invalid MD5 of cached ", component.file,
                    " file: is: ", md5, " expected: ", component.md5);
            }
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
                    break;
                }
                catch(Exception e)
                {
                    tryRemove(dlPath);
                }
            }

            failEnforcec(dlPath.exists, "Failed to find a working mirror for ", component.file);

            auto md5 = File(dlPath.toString()).byChunk(4096).md5Of().toHexString!(LetterCase.lower);
            if(sicmp(md5, component.md5) != 0)
            {
                tryRemove(dlPath);
                failc("Invalid MD5 of downloaded ", component.file, " file: is: ", md5, " expected: ", component.md5);
            }
        }
    }
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