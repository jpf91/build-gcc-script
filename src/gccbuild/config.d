module gccbuild.config;

import gccbuild, scriptlike, painlessjson, std.json;

BuildMode mode = BuildMode.all;
Path buildConfig;
string buildTriplet = "x86_64-linux-gnu";
Path mirrorFile = "mirrors.json";
bool verifyCachedSources = true;
bool forceDownload = false;
bool forceExtract = false;
Path cacheDir = Path("cache");

@property Path downloadDir()
{
    return cacheDir ~ "downloads";
}

BuildConfig build;
string[][string] mirrors;

void loadMirrors()
{
    startSectionLog("Loading mirror information");
    try
        mirrors = fromJSON!(typeof(mirrors))(mirrorFile.readText().parseJSON());
    catch(Exception e)
        failc("Couldn't load mirror file ", mirrorFile, ": ", e);
}

void loadBuildConfig(Path file)
{
    startSectionLog("Loading build configuration");
    try
        build = fromJSON!BuildConfig(file.readText().parseJSON());
    catch(Exception e)
        failc("Couldn't load build configuration ", file, ": ", e);

    if (build.target == build.host)
    {
        if (build.host == buildTriplet)
            build.type = ToolchainType.native;
        else
            build.type = ToolchainType.cross_native;
    }
    else
    {
        if (build.host == buildTriplet)
            build.type = ToolchainType.cross;
        else
            build.type = ToolchainType.canadian;
    }

    startSection("Dumping configuration");
    writeBulletPoint(mixin(interp!"Type: ${build.type}"));
    writeBulletPoint(mixin(interp!"Build: ${buildTriplet}"));
    writeBulletPoint(mixin(interp!"Host: ${build.host}"));
    writeBulletPoint(mixin(interp!"Target: ${build.target}"));
}

void saveBuildConfig(string file, BuildConfig conf = build)
{
    auto val = conf.toJSON();
    std.file.write(file, std.json.toJSON(&val, true));
}

struct BuildConfig
{
    static struct Component
    {
        string file, url, md5, configure;
        // Total url is url | mirror ~ suburl | mirror ~ filename
        string suburl;
        string[string] makeEnv;

        // Whether this component is specified in config file
        @property bool isInConfig()
        {
            return !file.empty;
        }
    }
    
    @SerializeIgnore ToolchainType type;
    
    Component mpc, mpfr, gmp, glibc, linux, w32api;
    Component gcc;
    
    string target, host;
}

enum ToolchainType
{
    native,
    cross,
    cross_native,
    canadian
}

enum BuildMode
{
    all,
    download,
    extract,
    patch
}