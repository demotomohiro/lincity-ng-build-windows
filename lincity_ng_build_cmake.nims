import std/[os, parseopt, strformat, strutils, strtabs]
import nimsbuildtools

proc main(rootDir, downloadDir: string; isMakeArchive: bool) =
  mkDir downloadDir
  mkdir rootDir
  installMSYS2(rootDir, downloadDir)

  let
    msys2Shell = getMSYS2Shell(rootDir)
    msys2DownloadDir = msys2Shell.getHomeDir()
    msys2RootDir = msys2Shell.getHomeDir()
    msys2BuildDir = (msys2RootDir / "lincity-ng_build").toUnixPath

  msys2Shell.installMSYS2Packages(
    "mingw-w64-x86_64-gcc",
    "mingw-w64-x86_64-SDL2",
    "mingw-w64-x86_64-SDL2_mixer",
    "mingw-w64-x86_64-SDL2_image",
    "mingw-w64-x86_64-SDL2_ttf",
    "mingw-w64-x86_64-SDL2_gfx",
    "mingw-w64-x86_64-physfs",
    "mingw-w64-x86_64-libxml2",
    "unzip",
    "git",
    "mingw-w64-x86_64-ninja",
    "mingw-w64-x86_64-cmake"
  )

  ## msys2Shell.execQuote(["git", "clone", "--branch", "vorot93/cmake", "--depth", "1", "--shallow-submodules", "--recurse-submodules", "https://github.com/lincity-ng/lincity-ng.git"], msys2RootDir)
  msys2Shell.execQuote(["git", "clone", "--branch", "demotomohiro/msys2", "--depth", "1", "--shallow-submodules", "--recurse-submodules", "https://github.com/demotomohiro/lincity-ng.git"], msys2RootDir)

  let lincitySrcDir = (msys2RootDir / "lincity-ng").toUnixPath
  msys2Shell.execQuote(["cmake", "-S", lincitySrcDir, "-B", msys2BuildDir, "-DCMAKE_BUILD_TYPE=Release", "-DPACKAGE_NAME=Lincity-ng", "-DVERSION=0.01234"])
  msys2Shell.execQuote(["cmake", "--build", msys2BuildDir])

  let
    lincitySrcDirWin = msys2Shell.getWindowsPathFromMsys2Path(lincitySrcDir)
    lincityPackageDir = rootDir / "lincity-ng"
    lincityExe = msys2Shell.getWindowsPathFromMsys2Path(msys2BuildDir) / "lincity-ng.exe"

  mkDir lincityPackageDir
  cpFileToDir lincityExe, lincityPackageDir
  mkDir lincityPackageDir / "data"
  cpDir lincitySrcDirWin / "data", lincityPackageDir / "data"

  cpFilesInDirToDir(lincitySrcDirWin, lincityPackageDir):
    "README"
    "COPYING"
    "COPYING-data.txt"
    "COPYING-fonts.txt"

  let mingw64BinDir = rootDir / "msys64" / "mingw64" / "bin"
  cpFilesInDirToDir(mingw64BinDir, lincityPackageDir):
    "libgcc_s_seh-1.dll"
    "libstdc++-6.dll"
    "libphysfs.dll"
    "SDL2.dll"
    "libSDL2_gfx-1-0-0.dll"
    "SDL2_image.dll"
    "SDL2_mixer.dll"
    "SDL2_ttf.dll"
    "libxml2-2.dll"
    "zlib1.dll"
    "libwinpthread-1.dll"
    "libjpeg-8.dll"
    "libpng16-16.dll"
    "libtiff-5.dll"
    "libwebp-7.dll"
    "libFLAC-8.dll"
    "libmpg123-0.dll"
    "libopusfile-0.dll"
    "libvorbisfile-3.dll"
    "libfreetype-6.dll"
    "libiconv-2.dll"
    "liblzma-5.dll"
    "libdeflate.dll"
    "libjbig-0.dll"
    "libLerc.dll"
    "libzstd.dll"
    "libssp-0.dll"
    "libogg-0.dll"
    "libopus-0.dll"
    "libvorbis-0.dll"
    "libbz2-1.dll"
    "libbrotlidec.dll"
    "libharfbuzz-0.dll"
    "libbrotlicommon.dll"
    "libglib-2.0-0.dll"
    "libgraphite2.dll"
    "libintl-8.dll"
    "libpcre-1.dll"

  if isMakeArchive:
    execQuote(["7z", "a", "lincity-ng.zip", lincityPackageDir])

proc preMain =
  var
    rootDir, downloadDir = getCurrentDir()
    isMakeArchive = false

  var isFirst = true
  for kind, key, val in getopt():
    case kind:
    of cmdArgument:
      if not isFirst:
        quit "Invalid argument"
    of cmdLongOption, cmdShortOption:
      case key:
      of "rootdir": rootDir = val
      of "downloaddir": downloadDir = val
      of "archive": isMakeArchive = true
      else:
        quit "Invalid argument"
    of cmdEnd:
      discard

    isFirst = false

  #echo &"Root directory: {rootDir}"
  #echo &"Download directory: {downloadDir}"
  main(rootDir, downloadDir, isMakeArchive)

preMain()
