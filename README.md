# newestLixLibs
CLI Tool to help update all Haxe libraries for a project to their newest needed version

1. Build out the newestLixLibs.n
2. Copy newestLixLibs.n into your project
3. Run "neko newestLixLibs" -> this will save the newest version of everything saved in /haxe_librares.  If this is the first time you run it, it will essentially copy /haxe_libraries
4. After installing a new library ("lix install some-package"), run "neko newestLixLibs" again.  If the library you just installed reverted any previously installed library to an older version, newestLixLib will restore it from the copy it made earlier.
