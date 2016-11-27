module main;
import scriptlike;
import std.file : DirEntry;

void main(string[] args)
{
    failEnforce(args.length >= 5, "Usage: install-gdmd installFolder gccVersion host name");
    scriptlikeEcho = true;

    Path installFolder = args[1];
    auto gccVersion = Path(args[2]);
    auto host = Path(args[3]);
    string name = args[4];

    DirEntry[] gdcFiles;
    DirEntry[] gdcLinks;
    foreach(file; dirEntries(installFolder ~ "bin", SpanMode.shallow))
    {
        if(file.isFile && file.name.canFind("gdc"))
        {
            if(file.isSymlink())
            {
                gdcLinks ~= file;
            }
            else
            {
                gdcFiles ~= file;
            }
        }
    }

    auto gdmdSrc = Path("/home/build/share/gdmd") ~ host ~ gccVersion ~ name;
    foreach(file; gdcFiles)
    {
        auto gdmdDst = file.replace("gdc", "gdmd");
        run(mixin(interp!"cp ${gdmdSrc} ${gdmdDst}"));
    }

    foreach(file; gdcLinks)
    {
        auto gdmdFile = file.name.replace("gdc", "gdmd");
        auto target = runCollect(mixin(interp!`readlink {$file}`)).replace("gdc", "gdmd");
        run(mixin(interp!"ln -s ${target} ${gdmdFile}"));
    }
}
