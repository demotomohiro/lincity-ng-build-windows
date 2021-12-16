# lincity-ng-build-windows
[Nim](https://nim-lang.org) script to build latest [lincity-ng](https://github.com/lincity-ng/lincity-ng) on windows with gcc and libraries in [MSYS2](https://www.msys2.org).

You can download lincity-ng executable for windows on [releases page](https://github.com/demotomohiro/lincity-ng-build-windows/releases).

This repository doesn't contains lincity-ng source code and related data.

This script works only on windows. It downloads MSYS2 and installs build tools and libraries used to build lincity-ng. Then it builds lincity-ng.

- Antivirus software might delete files in gcc:
https://github.com/msys2/MINGW-packages/issues/10295

## Requirement
- [Nim](https://nim-lang.org)
- tar or [7z](https://www.7-zip.org)

## How to use
```
git clone https://github.com/demotomohiro/lincity-ng-build-windows.git
nim lincity-ng-build-windows\lincity_ng_build_cmake.nims
```

In default, it downloads MSYS2 to current directory, creates lincity-ng directory in current directory and put lincity-ng.exe in it.
You can specify where lincity-ng directory is created with `--rootdir:<pathTodirectory>` option.
You can specify download directory with `--downloaddir:<pathTodirectory>` option.
