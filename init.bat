@echo off

set CMDER_INIT_START=%time%

:: Use /v command line arg or set to > 0 for verbose output to aid in debugging.
set verbose_output=0
set debug_output=0
set time_init=0
set fast_init=1
set max_depth=1
set "CMDER_USER_FLAGS= "

:: Find root dir
if not defined CMDER_ROOT (
    if defined ConEmuDir (
        for /f "delims=" %%i in ("%ConEmuDir%\..\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    ) else (
        for /f "delims=" %%i in ("%~dp0\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    )
)

:: Remove trailing '\' from %CMDER_ROOT%
if "%CMDER_ROOT:~-1%" == "\" SET "CMDER_ROOT=%CMDER_ROOT:~0,-1%"				
call "%cmder_root%\vendor\lib\lib_path"
call "%cmder_root%\vendor\lib\lib_profile"


:: SECCION start

:: Pick right version of clink
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
    set architecture_bits=32
) else (
    set architecture=64
    set architecture_bits=64
)

"%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\config" --scripts "%CMDER_ROOT%\vendor"


:: I do not even know, copypasted from their .bat
if not defined TERM set TERM=cygwin

setlocal enabledelayedexpansion

:: check if git is in path...
for /F "delims=" %%F in ('where git.exe 2^>nul') do (
    :: get the absolute path to the user provided git binary
    pushd %%~dpF
    :: check if there's shim - and if yes follow the path
    if exist git.shim (

        for /F "tokens=2 delims== " %%I in (git.shim) do (
            pushd %%~dpI
            set "test_dir=!CD!"
            popd
        )
    ) else (
        set "test_dir=!CD!"
    )
    popd


        :: use the user provided git if its version is greater than, or equal to the vendored git
        if !errorlevel! geq 0 if exist "!test_dir:~0,-4!\cmd\git.exe" (
            set "GIT_INSTALL_ROOT=!test_dir:~0,-4!"
            set test_dir=
        )

    )
)

::SECCION CONFIGURE_GIT
:: Add git to the path
if defined GIT_INSTALL_ROOT (
    %lib_path% enhance_path "!GIT_INSTALL_ROOT!\usr\bin" append
        
        :: Find locale.exe: From the git install root, from the path, using the git installed env, or fallback using the env from the path.
        if not defined git_locale set git_locale=env /usr/bin/locale
        for /F "delims=" %%F in ('!git_locale! -uU 2') do (
            set "LANG=%%F"
        )
    

)

endlocal & set "PATH=%PATH%" & set "LANG=%LANG%" 

:: SECCION PATH_ENHANCE
:: Drop *.bat and *.cmd files into "%CMDER_ROOT%\config\profile.d"
:: to run them at startup.
%lib_profile% run_profile_d "%CMDER_ROOT%\config\profile.d"

:: Allows user to override default aliases store using profile.d
:: scripts run above by setting the 'aliases' env variable.
::
:: Note: If overriding default aliases store file the aliases
:: must also be self executing, see '.\user_aliases.cmd.example',
:: and be in profile.d folder.
set "user_aliases=%CMDER_ROOT%\config\user_aliases.cmd"

:: Add aliases to the environment
call "%user_aliases%"

:: Set home path
if not defined HOME set "HOME=%USERPROFILE%"

set "initialConfig=%CMDER_ROOT%\config\user_profile.cmd"

set CMDER_INIT_END=%time%


:: Show time elapsed
"%cmder_root%\vendor\bin\timer.cmd" %CMDER_INIT_START% %CMDER_INIT_END%

exit /b