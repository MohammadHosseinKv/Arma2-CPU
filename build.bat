@echo off
rem build.bat - synth+impl via ISE CLI (XST -> NGDBUILD -> MAP -> PAR -> BITGEN)
rem Save at repo root and run from repo root (or via VS Code task).

setlocal enabledelayedexpansion

rem === Edit these ===
set TOP=Arma2_CPU
set PART=xc6slx9-2-tqg144
set SRCDIR=src
set SIMDIR=sim
set UCF=constraints\LCL_Project1_14041_UCF.ucf
set BUILD=build
set LOGSDIR=logs

rem Xilinx install path (edit if needed)
set XILINX=E:\XISE\14.7\ISE_DS

rem ensure working dir is script folder (repo root)
pushd "%~dp0" >nul

if not exist "%BUILD%" mkdir "%BUILD%"

echo === Generating PRJ files with paths RELATIVE TO %BUILD% ===
if exist "%BUILD%\xst.prj" del /f /q "%BUILD%\xst.prj" 2>nul
if exist "%BUILD%\isim.prj" del /f /q "%BUILD%\isim.prj" 2>nul

rem We will write paths relative to the build directory (i.e. ../src\file.vhd)
rem Use non-recursive dir listing; change to /s or for /r if you need recursion.

for /f "delims=" %%F in ('dir /b "%SRCDIR%\*.vhd" 2^>nul') do (
  echo work ..\%SRCDIR%\%%F>>"%BUILD%\xst.prj"
  echo vhdl work ..\%SRCDIR%\%%F>>"%BUILD%\isim.prj"
)

rem Append sim files (testbenches) after RTL
for /f "delims=" %%F in ('dir /b "%SIMDIR%\*.vhd" 2^>nul') do (
  echo vhdl work ..\%SIMDIR%\%%F>>"%BUILD%\isim.prj"
)

echo --- build\xst.prj (XST format, relative-to-build) ---
type "%BUILD%\xst.prj" || echo (no xst.prj generated)
echo --- build\isim.prj (ISim/fuse format, relative-to-build) ---
type "%BUILD%\isim.prj" || echo (no isim.prj generated)

rem --- create XST input file referencing build\xst.prj ---
> "%BUILD%\project.xst" (
  echo run
  echo -ifn %BUILD%\xst.prj
  echo -ofn %BUILD%\project_xst
  echo -top %TOP%
  echo -p %PART%
  echo -ifmt vhdl
  echo -opt_mode Speed
  echo -opt_level 1
)

echo --- project.xst contents ---
type "%BUILD%\project.xst"
echo -------------------------

rem --- locate ISE executables ---
if defined XILINX (
  set XST_BIN=%XILINX%\ISE\bin\nt\xst.exe
  set NGDBUILD_BIN=%XILINX%\ISE\bin\nt\ngdbuild.exe
  set MAP_BIN=%XILINX%\ISE\bin\nt\map.exe
  set PAR_BIN=%XILINX%\ISE\bin\nt\par.exe
  set BITGEN_BIN=%XILINX%\ISE\bin\nt\bitgen.exe
) else (
  set XST_BIN=xst
  set NGDBUILD_BIN=ngdbuild
  set MAP_BIN=map
  set PAR_BIN=par
  set BITGEN_BIN=bitgen
)

rem --- Step 1: run XST (synthesis) ---
echo === Running XST (synthesis) ===
"%XST_BIN%" -ifn "%BUILD%\project.xst" -ofn "%LOGSDIR%\xst.log"
if errorlevel 1 (
  echo XST FAILED. See "%LOGSDIR%\xst.log" and "%BUILD%\project.xst".
  popd
  goto :ERR
)

rem --- find .ngc output produced by XST for TOP ---
echo === Locating .ngc for top: %TOP% ===
set "NGC_FOUND="
for /f "delims=" %%G in ('dir /b /s "%BUILD%\%TOP%*.ngc" 2^>nul') do (
  set "NGC_FOUND=%%~fG"
  goto :ngc_done
)
for /f "delims=" %%G in ('dir /b /s "%~dp0%TOP%*.ngc" 2^>nul') do (
  set "NGC_FOUND=%%~fG"
  goto :ngc_done
)
for /f "delims=" %%G in ('dir /b /s "%BUILD%\*.ngc" 2^>nul') do (
  set "NGC_FOUND=%%~fG"
  goto :ngc_done
)

:ngc_done
if not defined NGC_FOUND (
  echo ERROR: .ngc file for top '%TOP%' not found. Examine %LOGSDIR%\xst.log
  popd
  goto :ERR
)
echo Found NGC: %NGC_FOUND%

echo Build finished: "%BUILD%\%TOP%.bit"
popd
endlocal
goto :EOF

:ERR
echo ERROR - check logs in "%LOGSDIR%" for details
endlocal
exit /b 1

:EOF
