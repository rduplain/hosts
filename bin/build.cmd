@echo off

REM - Build on Windows, in cmd.exe or a Developer Command Prompt.
REM
REM   Requires:
REM
REM   * `git` - https://git-scm.com/
REM   * Build Tools for Visual Studio - Find "Build Tools" on
REM     https://visualstudio.microsoft.com/downloads/
REM
REM   Automatically builds prerequisites:
REM
REM   * `janet` and `jpm` - https://janet-lang.org/
REM
REM   The build first compiles a project-local Janet matching JANET_VERSION,
REM   then runs `jpm deps` on the project to install dependencies in the same
REM   project-local directory as Janet. While this build.cmd is checking PATH
REM   for `janet`, a system-installed Janet is not currently supported when
REM   `jpm deps` is required by the project.
REM
REM   This build.cmd has no project-specific details in it, and can be dropped
REM   in as-is into other Janet projects. It must be checked into version
REM   control (or otherwise downloaded before the build) in order for
REM   continuous integration (CI) to have a build entry point.
REM
REM   Configure with the "if not defined" environment variables below, each
REM   having a preset default in build.cmd. Note that Windows batch sets
REM   variables globally in the calling cmd.exe session, such that repeat calls
REM   to build.cmd will have whatever value was set on the last run of
REM   build.cmd. This is an especially important limitation to consider when
REM   changing variables or pulling a new build.cmd after a previous run.
REM
REM   When using an untagged JANET_VERSION, set JANET_VERSION_CHECK to whatever
REM   version prefix is reported by `janet --version`. For example, "v1.7.0".

REM - Support configuration with environment variables.
if not defined JANET_URL set JANET_URL=https://github.com/janet-lang/janet.git
if not defined JANET_VERSION set JANET_VERSION=v1.11.0
if not defined JANET_VERSION_CHECK set JANET_VERSION_CHECK=%JANET_VERSION%

REM - x86 or x64? Clean .\deps\ when changing this value.
if not defined ARCH set ARCH=x86

set PATH_ORIGINAL=%PATH%

if not defined VCINSTALLDIR (
  SETLOCAL ENABLEDELAYEDEXPANSION
  for %%f in (
    "Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build"
    "Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build"
    "Microsoft Visual Studio 15.0\VC"
    "Microsoft Visual Studio 14.0\VC"
    "Microsoft Visual Studio 13.0\VC"
    "Microsoft Visual Studio 12.0\VC"
  ) do (
    set vcvarsall="%PROGRAMFILES(X86)%\%%~f\vcvarsall.bat"
    if exist !vcvarsall! (
      echo Using !vcvarsall! ...
      call !vcvarsall! %ARCH%
      goto :have_visual_studio
    )
  )
  echo Unable to find Visual Studio tools.
  exit /b 1
)

:have_visual_studio

set PATH=%cd%\deps\janet\dist;%PATH%;%PATH_ORIGINAL%

set JANET_PATH=%cd%\deps\modules
set JANET_DIST=%cd%\deps\janet\dist
set JANET_HEADERPATH=%JANET_DIST%
set JANET_BINPATH=%JANET_DIST%
set JANET_LIBPATH=%JANET_DIST%

if not exist %JANET_PATH% (
  call mkdir %JANET_PATH%
)

REM - Find/Build Janet.
call echo Checking Janet on PATH ...
call :JANET_VERSION %JANET_VERSION_CHECK%
if %ERRORLEVEL% neq 0 (

  call echo Building Janet ...
  if not exist deps (
    call mkdir deps
  )
  cd deps
  if not exist janet (
    call git clone %JANET_URL%
  )
  cd janet

  call git remote update
  call git checkout %JANET_VERSION%
  call build_win
  call build_win dist

  cd ..
  cd ..

)

call :JANET_VERSION %JANET_VERSION_CHECK%
if %ERRORLEVEL% neq 0 (
  call echo Janet %JANET_VERSION% not found, checking for %JANET_VERSION_CHECK%.
  exit /b 1
)

REM - echo Janet %JANET_VERSION%
call echo | set /p =Janet
call janet -e "(print \" v\" janet/version)"

call janet .\deps\janet\dist\jpm deps

REM - Ensure that the build does not go stale.
if exist .\build\*.exe (
  echo Removing previous build: .\build\*.exe ...
  call del .\build\*.exe
)

call janet .\deps\janet\dist\jpm test

REM - Primary batch program exit.
if %ERRORLEVEL% equ 0 (
  call echo Complete.
  exit /b 0
) else (
  call echo Fail.
  exit /B 1
)

REM - Emulate a function to check the Janet version.
:JANET_VERSION
set version=%1
if "%version%" == "" (
  call echo Error. Provide version when calling :JANET_VERSION.
  exit /b 2
)
for /f %%i in ('janet -e "(print \"v\" janet/version)"') do set output=%%i
if "%output%" == "%version%" (
  exit /b 0
) else (
  exit /b 1
)
