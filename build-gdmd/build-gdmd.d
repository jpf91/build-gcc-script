module main;
import scriptlike;

immutable string[] hosts = ["arm-unknown-linux-gnueabi",
    "arm-unknown-linux-gnueabihf",
    "i686-unknown-linux-gnu",
    "i686-w64-mingw32",
    "x86_64-unknown-linux-gnu",
    "x86_64-w64-mingw32"];

immutable string[] gccVersions = ["4.8", "4.9", "5", "6", "7"];

enum string[string] compilerPath = [
    "arm-unknown-linux-gnueabi": "arm-unknown-linux-gnueabihf",
    "arm-unknown-linux-gnueabihf": "arm-unknown-linux-gnueabihf",
    "i686-unknown-linux-gnu": "x86_64-unknown-linux-gnu",
    "i686-w64-mingw32": "i686-w64-mingw32",
    "x86_64-unknown-linux-gnu": "x86_64-unknown-linux-gnu",
    "x86_64-w64-mingw32": "x86_64-w64-mingw32"
];

enum string[string] compilerFlags = [
    "arm-unknown-linux-gnueabi": "-mfloat-abi=soft",
    "arm-unknown-linux-gnueabihf": "",
    "i686-unknown-linux-gnu": "-m32",
    "i686-w64-mingw32": "",
    "x86_64-unknown-linux-gnu": "",
    "x86_64-w64-mingw32": ""
];

void main(string[] args)
{
    scriptlikeEcho = true;

    foreach(host; hosts)
    {
        writefln("Compiling for host: %s", host);
        auto hostparts = findSplit(compilerPath[host], "-");
        auto xhost = hostparts[0] ~ "_host-" ~ hostparts[2];
        auto compilerPath = Path("/home/build/share/host-toolchains/") ~ Path(compilerPath[host]) ~ "xbin";
        auto strip = compilerPath ~ (xhost ~ "-strip");
        auto gdc = compilerPath ~ (xhost ~ "-gdc");

        foreach(gccVersion; gccVersions)
        {
            auto installDir = Path("/home/build/share/gdmd") ~ host ~ gccVersion;
            installDir.tryMkdirRecurse();
            auto config = "gdc" ~ gccVersion;

            compileGDMD(compilerFlags[host], gdc, strip, config, installDir, "gdmd");
            compileGDMD(compilerFlags[host] ~ " -fversion=UseSystemAR", gdc, strip, config, installDir, "gdmd_native");
        }
    }
}

void compileGDMD(string dflags, Path gdc, Path strip, string config, Path installDir, string installName)
{
    run(mixin(interp!`DFLAGS="${dflags}" dub build -f -v --compiler=${gdc} --config=${config}`));
    auto compiledGDMD = "gdmd";
    if(!compiledGDMD.exists)
        compiledGDMD = "gdmd.exe";
    run(mixin(interp!`${strip} ${compiledGDMD}`));
    run(mixin(interp!`chmod +x ${compiledGDMD}`));

    run(mixin(interp!`mv ${compiledGDMD} ${installDir ~ installName.setExtension(compiledGDMD.extension)}`));
}
