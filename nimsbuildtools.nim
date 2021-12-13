import std/[macros, os, strutils, strtabs]

proc execQuote*(args: openArray[string]; workingDir: string = "") =
  let p = args.quoteShellCommand

  if workingDir.len != 0:
    withDir(workingDir):
      exec p
  else:
    exec p

proc execAndReturnQuote*(args: openArray[string]; workingDir: string = ""): tuple[output: string, exitCode: int] =
  let p = args.quoteShellCommand

  if workingDir.len != 0:
    withDir(workingDir):
      gorgeEx p
  else:
    gorgeEx p

proc download*(url, dist: string) =
  if findExe("nimgrab") != "":
    execQuote(["nimgrab", url, dist])
  elif findExe("curl") != "":
    execQuote(["curl", "--location", "--silent", "--show-error", "-o", dist, url])
  elif findExe("wget") != "":
    execQuote(["wget", url, "-O", dist])
  else:
    quit "This script requires nimgrab, curl or wget to download a file"

proc untar*(src, dist: string) =
  when hostOS == "windows":
    # "-C" option has a bug and cause error.
    execQuote(["tar", "--force-local", "--no-same-owner", "-x", "-f", src], dist)
  else:
    execQuote(["tar", "x", "-C", dist, "-f", src])

proc unzip*(src, dist: string) =
  execQuote(["unzip", src, "-d", dist])

template downloadAnd*(un: proc; url, tmp, dist: string) =
  download(url, tmp)
  un(tmp, dist)

proc checkRequiredCmds*(): bool =
  if findExe("wget") == "" and findExe("curl") == "" and findExe("nimgrab") == "":
    echo "This script needs nimgrab, curl or wget command"
    return false

  if system.findExe("tar") == "":
    quit "This script needs tar command"
    return false

  true

proc hasRequiredCmdOrQuit*(cmd: string) =
  if system.findExe(cmd) == "":
    quit "This script needs " & cmd

proc cpFileToDir*(src, dir: string) =
  let filename = src.extractFilename
  cpFile(src, dir / filename)

macro cpFilesInDirToDir*(srcDir, distDir: string; srcFiles: untyped): untyped =
  result = newStmtList()
  for i in srcFiles:
    result.add newCall("cpFile", infix(srcDir, "/", i), infix(distDir, "/", i))

type
  MSYS2Shell = distinct string

func toUnixPath*(src: string): string =
  src.replace '\\', '/'

proc getMSYS2Shell*(targetDir: string): MSYS2Shell = 
  MSYS2Shell(targetDir / "msys64/msys2_shell.cmd")

template execQuoteImpl(msys2Shell: MSYS2Shell; execProc: untyped; args: openArray[string]; workingDir: string; env: StringTableRef): untyped =
  var s = ""

  if workingDir.len != 0:
    s = "cd " & workingDir.quoteShellPosix & " && "

  if env != nil:
    for k, v in env:
      s.add(k & "=" & v.quoteShellPosix & " ")

  for i, a in args:
    if i > 0: s.add ' '
    s.add a.quoteShellPosix

  execProc([msys2Shell.string, "-mingw64", "-defterm", "-no-start", "-c", s])

proc execQuote*(msys2Shell: MSYS2Shell; args: openArray[string]; workingDir = ""; env: StringTableRef = nil) =
  let wd = workingDir.toUnixPath
  execQuoteImpl(msys2Shell, execQuote, args, wd, env)

proc execAndReturnQuote*(msys2Shell: MSYS2Shell; args: openArray[string]; workingDir = ""; env: StringTableRef = nil): tuple[output: string, exitCode: int] =
  let wd = workingDir.toUnixPath
  execQuoteImpl(msys2Shell, execAndReturnQuote, args, wd, env)

proc getHomeDir*(msys2Shell: MSYS2Shell): string =
  var r = msys2Shell.execAndReturnQuote(["printenv", "HOME"])
  if r.exitCode != 0:
    echo r
    quit "Failed to get home directory path"

  r.output.removeSuffix
  r.output

proc getWindowsPathFromMsys2Path*(msys2Shell: MSYS2Shell; msys2Path: string): string =
  var r = msys2Shell.execAndReturnQuote(["cygpath", "-w", msys2Path])
  if r.exitCode != 0:
    echo r
    quit "Failed to run cygpath -w " & msys2Path

  r.output.removeSuffix
  r.output

proc installMSYS2*(targetDir, downloadDir: string) =
  try:
    downloadAnd untar,
      "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.tar.xz",
      downloadDir / "msys2-base.tar.xz",
      targetDir
  except OSError:
    discard

  rmFile(downloadDir / "msys2-base.tar.xz")

  # https://www.msys2.org/wiki/MSYS2-installation/
  let msys2Shell = getMSYS2Shell(targetDir)
  msys2Shell.execQuote(["echo", "initializing msys2 done"])

proc installMSYS2Packages*(msys2Shell: MSYS2Shell; packages: varargs[string]) =
  # `msys2Shell` is a return value from `getMSYS2Shell`
  var tmp = @["pacman", "-S", "--noconfirm"]
  tmp.add packages
  msys2Shell.execQuote(tmp)

proc download*(msys2Shell: MSYS2Shell; url, dist: string) =
  msys2Shell.execQuote ["wget", url, "-O", dist.toUnixPath]

proc unzip*(msys2Shell: MSYS2Shell; src, dist: string) =
  msys2Shell.execQuote ["unzip", src.toUnixPath, "-d", dist.toUnixPath]
