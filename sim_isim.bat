@echo off
rem sim_isim.bat — run ISim with optional Tcl batch if present
setlocal enabledelayedexpansion

rem ===== Defaults - can be overridden via args =====
set XILINX=E:\XISE\14.7\ISE_DS
set TB=
set BUILD=build
set SIMDIR=sim
set LOGSDIR=logs
set DO_FUSE=1
set DO_GUI=1
set DO_TCL=1
rem If 1 -> try to launch ISim without a console window using PowerShell Start-Process
rem If 0 -> use plain start (minimized) which may still show a taskbar window briefly.
set HIDE_ISIM_CONSOLE=1

rem ==================================================

rem Ensure working dir is script folder (repo root)
pushd "%~dp0" >nul

rem Create logs dir if missing
if not exist "%LOGSDIR%" mkdir "%LOGSDIR%"

rem ---------- Argument parsing ----------
for %%A in (%*) do (
  set "arg=%%~A"
  if "!arg:~0,1!"=="/" set "arg=!arg:~1!"
  if "!arg:~0,1!"=="-" set "arg=!arg:~1!"
  echo "!arg!" | findstr "[:=]" >nul
  if errorlevel 1 (
    if not defined TB (
      set "TB=!arg!"
    )
  ) else (
    for /f "tokens=1,2 delims=:=" %%K in ("!arg!") do (
      set "key=%%K"
      set "val=%%L"
      if "!val!"=="" set "val=1"
      call :set_param "!key!" "!val!"
    )
  )
)
goto :after_parse

:set_param
set "k=%~1"
set "v=%~2"
if /I "%k%"=="tb" set "TB=%v%" & goto :eof
if /I "%k%"=="fuse" set "DO_FUSE=%v%" & goto :eof
if /I "%k%"=="gui" set "DO_GUI=%v%" & goto :eof
if /I "%k%"=="tcl" set "DO_TCL=%v%" & goto :eof
if /I "%k%"=="build" set "BUILD=%v%" & goto :eof
if /I "%k%"=="simdir" set "SIMDIR=%v%" & goto :eof
if /I "%k%"=="logdir" set "LOGSDIR=%v%" & goto :eof
if /I "%k%"=="xilinx" set "XILINX=%v%" & goto :eof
goto :eof

:after_parse
rem ---------- end parsing ----------

rem Auto-detect TB if not specified
if "%TB%"=="" (
  set FOUND=
  for /f "delims=" %%f in ('dir /b "%SIMDIR%\*_tb.vhd" 2^>nul') do (
    set "TB=%%~nf"
    set FOUND=1
    goto :tb_found
  )
  for /f "delims=" %%f in ('dir /b "%SIMDIR%\*tb*.vhd" 2^>nul') do (
    set "TB=%%~nf"
    set FOUND=1
    goto :tb_found
  )
  if not defined FOUND (
    echo No testbench detected in %SIMDIR%. Please set TB variable or pass it as first arg.
    popd
    exit /b 1
  )
)
:tb_found

echo sim_isim: TB=%TB% BUILD=%BUILD% LOGS=%LOGSDIR%

rem Ensure XILINX path and fuse binary
if defined XILINX (
  set "FUSE_BIN=%XILINX%\ISE\bin\nt\fuse.exe"
) else (
  set "FUSE_BIN=fuse"
)

rem --- FUSE step (optional) ---
if /I "%DO_FUSE%"=="1" (
  echo --- Running fuse for testbench: %TB% ---
  "%FUSE_BIN%" -prj "%BUILD%\isim.prj" work.%TB% -o "%BUILD%\%TB%_isim.exe" > "%LOGSDIR%\fuse.log" 2>&1
  if errorlevel 1 (
    echo ERROR: fuse linking failed. See %LOGSDIR%\fuse.log
    type "%LOGSDIR%\fuse.log" | more
    popd
    exit /b 1
  )
  echo Fuse finished; executable: "%BUILD%\%TB%_isim.exe"
) else (
  echo Skipping fuse (DO_FUSE=%DO_FUSE%)
)

rem Verify the executable exists now (if you expect it)
if not exist "%BUILD%\%TB%_isim.exe" (
  echo WARNING: fused executable not found: "%BUILD%\%TB%_isim.exe"
  rem If you intentionally skip fuse, the exe may be absent; decide if that is OK.
)

rem ==== Launch mode decision ====
rem Build absolute path to scripts tcl (use %~dp0 to avoid cwd issues)
set "TCL_SCRIPT=%~dp0scripts\isim_run.tcl"

if /I "%DO_GUI%"=="1" (
  echo Launching ISim GUI (DO_GUI=%DO_GUI%)
  if exist "%TCL_SCRIPT%" (
    if /I "%DO_TCL%"=="1" (
      echo Using Tcl script: "%TCL_SCRIPT%"
      rem Launch GUI non-blocking so the batch doesn't hang or re-enter
      rem --- launch helper: use PowerShell to hide console if requested
if /I "%HIDE_ISIM_CONSOLE%"=="1" (
  rem Use PowerShell Start-Process to hide the console window.
  rem Build argument list as a single string and call Start-Process.
  rem Note: double quotes inside the -Command need to be escaped for cmd.
  set "EXE_PATH=%BUILD%\%TB%_isim.exe"
  set "TCL_PATH=%~dp0scripts\isim_run.tcl"

  if exist "%TCL_PATH%" (
    rem launch hidden with tcl
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath '%EXE_PATH%' -ArgumentList '-gui','-tclbatch','%TCL_PATH%' -WindowStyle Hidden"
  ) else (
    rem launch hidden without tcl
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath '%EXE_PATH%' -ArgumentList '-gui' -WindowStyle Hidden"
  )
) else (
  rem fallback: start minimized (may still briefly show console)
  if exist "%TCL_SCRIPT%" (
    start "" /MIN "%BUILD%\%TB%_isim.exe" -gui -tclbatch "%TCL_SCRIPT%"
  ) else (
    start "" /MIN "%BUILD%\%TB%_isim.exe" -gui
  )
)

      rem If you want batch to wait until GUI closed, use start /WAIT instead:
      rem start /WAIT "" "%BUILD%\%TB%_isim.exe" -gui -tclbatch "%TCL_SCRIPT%"
      popd
      endlocal
      exit /b 0
    ) else (
      echo Tcl script present but DO_TCL=%DO_TCL% -> not running tcl
      rem --- launch helper: use PowerShell to hide console if requested
if /I "%HIDE_ISIM_CONSOLE%"=="1" (
  rem Use PowerShell Start-Process to hide the console window.
  rem Build argument list as a single string and call Start-Process.
  rem Note: double quotes inside the -Command need to be escaped for cmd.
  set "EXE_PATH=%BUILD%\%TB%_isim.exe"
  set "TCL_PATH=%~dp0scripts\isim_run.tcl"

  if exist "%TCL_PATH%" (
    rem launch hidden with tcl
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath '%EXE_PATH%' -ArgumentList '-gui','-tclbatch','%TCL_PATH%' -WindowStyle Hidden"
  ) else (
    rem launch hidden without tcl
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath '%EXE_PATH%' -ArgumentList '-gui' -WindowStyle Hidden"
  )
) else (
  rem fallback: start minimized (may still briefly show console)
  if exist "%TCL_SCRIPT%" (
    start "" /MIN "%BUILD%\%TB%_isim.exe" -gui -tclbatch "%TCL_SCRIPT%"
  ) else (
    start "" /MIN "%BUILD%\%TB%_isim.exe" -gui
  )
)

      popd
      endlocal
      exit /b 0
    )
  ) else (
    echo WARNING: Tcl script not found at "%TCL_SCRIPT%", launching GUI without Tcl script.
    rem --- launch helper: use PowerShell to hide console if requested
if /I "%HIDE_ISIM_CONSOLE%"=="1" (
  rem Use PowerShell Start-Process to hide the console window.
  rem Build argument list as a single string and call Start-Process.
  rem Note: double quotes inside the -Command need to be escaped for cmd.
  set "EXE_PATH=%BUILD%\%TB%_isim.exe"
  set "TCL_PATH=%~dp0scripts\isim_run.tcl"

  if exist "%TCL_PATH%" (
    rem launch hidden with tcl
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath '%EXE_PATH%' -ArgumentList '-gui','-tclbatch','%TCL_PATH%' -WindowStyle Hidden"
  ) else (
    rem launch hidden without tcl
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath '%EXE_PATH%' -ArgumentList '-gui' -WindowStyle Hidden"
  )
) else (
  rem fallback: start minimized (may still briefly show console)
  if exist "%TCL_SCRIPT%" (
    start "" /MIN "%BUILD%\%TB%_isim.exe" -gui -tclbatch "%TCL_SCRIPT%"
  ) else (
    start "" /MIN "%BUILD%\%TB%_isim.exe" -gui
  )
)

    popd
    endlocal
    exit /b 0
  )
) else (
  echo Running in batch mode (no GUI)
  if exist "%TCL_SCRIPT%" (
    if /I "%DO_TCL%"=="1" (
      echo Running exe with Tcl batch: "%TCL_SCRIPT%"
      "%BUILD%\%TB%_isim.exe" -tclbatch "%TCL_SCRIPT%"
      rem When running in batch this call blocks until Tcl script finishes
      popd
      endlocal
      exit /b 0
    ) else (
      echo Skipping Tcl script (DO_TCL=%DO_TCL%)
      popd
      endlocal
      exit /b 0
    )
  ) else (
    echo No Tcl script found and GUI disabled.
    popd
    endlocal
    exit /b 0
  )
)

:EOF
