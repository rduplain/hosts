@ECHO OFF

REM - Build on Windows.
REM
REM   Requires:
REM
REM   * `janet` and `jpm` - https://janet-lang.org/
REM   * `git` - https://git-scm.com/


REM - In Janet v1.3.1, `jpm deps` ends in error "cannot open ./project.janet".
REM   jpm deps

set argparse=https://github.com/janet-lang/argparse.git

call janet -e "(import argparse :exit true)"

if %ERRORLEVEL% neq 0 (

  if not exist deps (
    call mkdir deps
  )
  cd deps

  if not exist argparse (
    call git clone --depth 1 %argparse%
  )
  cd argparse
  call jpm install
  cd ..

  cd ..

)

REM - Ensure that the build does not go stale.
if exist .\build\hosts.exe ( call del .\build\hosts.exe )

call jpm build
call jpm test

REM - Primary batch program exit.
if %ERRORLEVEL% equ 0 (
  echo Complete.
  exit /b 0
) else (
  echo Fail.
  exit /B 1
)
