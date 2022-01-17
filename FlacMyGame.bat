@echo off
setlocal enableextensions enabledelayedexpansion
setlocal
rem (c) SBT 2019
set out=musmod_out
set bkp=musmod_bkp
set decode=flac:flac.exe:-dsfo`@fd@`@fs@:con,ogg:oggdec.exe:-qw`@fd@`@fs@:nul,mp3:lame.exe:--decode`--quiet`@fs@`@fd@:con,wav:copy:/y`@fs@`@fd@:nul
set encode=flac:flac.exe:@oq@`-esfo`@fd@`@fs@:con,ogg:oggenc2.exe:@oq@`-Qo`@fd@`@fs@:con,mp3:lame.exe:@oq@`@fs@`@fd@:con
set edit=wavedit.exe
set ftmp=~mmtmp.wav
set tempdir=.
set copybat=musmod_install.bat

set cfg=
set select=
set aext=
set aexts=
set bext=
set bexts=
set adir=
set bdir=
set aadir=
set abdir=
set aodir=
set name=
set updirchk=
set title=
set caption=
set aname=
set aprefix=
set bname=
set bprefix=
set alook=
set oname=
set oprefix=
set oext=
set oq=
set adec=
set adecmd=
set adecpar=
set adecprn=
set bdec=
set bdecmd=
set bdecpar=
set bdecprn=
set enc=
set encmd=
set encpar=
set encprn=
set editcmd=
set cta=
set ctb=
set cto=
if "%1"=="" goto load
set select=%1
if "%select:~0,1%"=="-" goto help
if "%select:~0,4%"=="help" goto help
if not "%select:.=%"=="%select%" (
	set cfg=%1
	set select=%2
)
goto load

:help
echo Usage: musmod [csv config file] [name of specific single music track to create]
goto end

:load
echo musmod v1.0.0 by SBT
if "%cfg%"=="" (
	for %%i in ("*.csv") do set cfg=%%~fi
)
if "%cfg%"=="" (
	echo No configuration file found^^! Make sure a .csv file exists in this folder.
	goto end
)
if not exist "!cfg!" (
	echo Configuration file !cfg! does not exist^^!
	goto end
)
echo Loading configuration !cfg!...
for /f "usebackq tokens=* delims=," %%i in ("!cfg!") do (
	set l=%%i
	set l=!l: =`!
	if "!l:~0,1!"=="$" goto loadok
	if not "!l:~0,1!"=="#" (
		set /a n=0
		set op=
		for %%j in ("!l:,="^,"!") do (
			set v=%%j
			set v=!v:"=!
			if !n!==0 ( 
				set op=!v!
			) else (
				if !op!==0 (
					if !n!==1 set name=!v!
					if !n!==2 set updirchk=!v!
					if !n!==3 set title=!v!
					if !n!==4 set caption=!v!
				)
				if !op!==1 (
					if !n! GTR 2 ( set aexts=!aexts!,!v!
					) else (
						if !n!==1 set aname=!v!
						if !n!==2 set aprefix=!v!
					)
				)
				if !op!==2 (
					if !n! GTR 2 ( set bexts=!bexts!,!v!
					) else (
						if !n!==1 set bname=!v!
						if !n!==2 set bprefix=!v!
					)
				)
				if !op!==3 (
					if !n!==1 set oname=!v!
					if !n!==2 set oprefix=!v!
					if !n!==3 set oext=!v!
					if !n!==4 set oq=!v!
				)
				if !op!==4 set alook=!alook! "!v!"
			)
			set /a n+=1
		)
	)
)

:loadok
if "%title%"=="" (
	echo [ERR] Configuration file is malformed^^!
	goto end
)
set aname=!aname:`= !
set bname=!bname:`= !
set oname=!oname:`= !
set alook=!alook:`= !
set aexts=!aexts:~1!
set bexts=!bexts:~1!
for /f "delims=" %%F in ("%tempdir%") do set atdir=%%~fF
if "!atdir:~-1!"=="\" set atdir=!atdir:~,-1!
del /q /f !atdir!\1!ftmp! >nul 2>&1
del /q /f !atdir!\2!ftmp! >nul 2>&1
del /q /f !atdir!\3!ftmp! >nul 2>&1
for %%i in (. .. !alook!) do (
	set l=%%i
	set l=!l:"=!
	for %%j in (!aexts!) do (
		if "!aext!"=="" (
			if exist "!l!\!aprefix!*.%%j" (
				set adir=!l!
				set aext=%%j
			)
		)
	)
	for %%j in (!bexts!) do (
		if "!bext!"=="" (
			if exist "!l!\!bprefix!*.%%j" (
				set bdir=!l!
				set bext=%%j
			)
		)
	)
)
for %%i in (%decode%) do (
	set l=%%i
	set l=!l:`= !
	for /f "tokens=1-4 delims=:" %%A in ("!l!") do (
		if !aext!==%%A (
			set adec=%%B
			set adecpar=%%C
			set adecprn=%%D
		)
		if !bext!==%%A (
			set bdec=%%B
			set bdecpar=%%C
			set bdecprn=%%D
		)
	)
)
for %%i in (%encode%) do (
	set l=%%i
	set l=!l:`= !
	for /f "tokens=1-4 delims=:" %%A in ("!l!") do (
		if !oext!==%%A (
			set enc=%%B
			set encpar=%%C
			set encprn=%%D
		)
	)
)
set adecpar=%adecpar:@=^^!%
set bdecpar=%bdecpar:@=^^!%
set encpar=%encpar:@=^^!%
for %%i in (.. .) do (
	if exist %%i\!adec! set adecmd=%%i\!adec!
	if exist %%i\!bdec! set bdecmd=%%i\!bdec!
	if exist %%i\!enc! set encmd=%%i\!enc!
	if exist %%i\!edit! set editcmd=%%i\!edit!
)
for /f "delims=" %%F in ("%adir%") do set aadir=%%~fF
for /f "delims=" %%F in ("%bdir%") do set abdir=%%~fF
for /f "delims=" %%F in ("%out%") do set aodir=%%~fF
for /f "delims=" %%F in ("%adecmd%") do set adecmd="%%~fF"
for /f "delims=" %%F in ("%bdecmd%") do set bdecmd="%%~fF"
for /f "delims=" %%F in ("%encmd%") do set encmd="%%~fF"
for /f "delims=" %%F in ("%editcmd%") do set editcmd="%%~fF"
if "!aadir:~-1!"=="\" set aadir=!aadir:~,-1!
if "!abdir:~-1!"=="\" set abdir=!abdir:~,-1!
if "!aodir:~-1!"=="\" set aodir=!aodir:~,-1!

if "!aext!"=="" goto ready
if "!bext!"=="" goto ready
if not "!select!"=="" goto ready
set /a cta=0
set /a ctb=0
set /a ctna=0
set /a ctnb=0
set /a cto=0
set m=0
for /f "usebackq tokens=* delims=," %%i in ("!cfg!") do (
	set l=%%i
	set l=!l: =`!
rem	set xx=
	if !m!==1 (
	if not "!l:~0,1!"=="#" (
		if "!l:~0,1!"=="$" goto ready
		set /a n=0
		set /a na=-1
		set /a cto+=1
		for %%j in ("!l:,="^,"!") do (
			set v=%%j
			set v=!v:"=!
rem			set xx=!xx! [!n! = !v!]
			if !na! GEQ 0 (
				if !na!==0 (
rem echo edit !v! in [!ta!]
					if !v!==1 set /a na=-1
					if !v!==5 set /a na=-1
					if not !na! GEQ 0 (
						set /a cta+=1
						if "!fta!"=="" set /a ctna+=1
					)
				)
				if !na! GEQ 0 set /a na+=1
				set /a na%%=4
			) else (
				if !n!==0 (
					set ta=!v!
					call :findtrk a !v!
					set fta=!ftres!
				)
				if !n!==1 (
					if not !tb!==!v! (
						set /a ctb+=1
						set tb=!v!
						call :findtrk b !v!
						set ftb=!ftres!
						if "!ftb!"=="" set /a ctnb+=1
					)
				)
				if !n!==6 set /a na=0
			)
			set /a n+=1
		)
	) )
	if "!l:~0,1!"=="$" set m=1
rem	echo !xx!
)

:ready
echo.
echo !title:`= !
echo !caption:`= !
echo.
if "!aext!"=="" echo [WARN] !aname! ^(!aprefix!*.{!aexts!}^) not found^^! Result will sound incorrect^^!
if "!bext!"=="" (
	echo [ERR] !bname! ^(!bprefix!*.{!bexts!}^) not found^^!
	goto end
)
rem if "!adec!"=="" set adec=direct copy
rem if "!bdec!"=="" set bdec=direct copy
echo Using !cta! !aname! in !aadir!\!aprefix!*.!aext! with !adec!
echo.
echo Using !ctb! !bname! in !abdir!\!bprefix!*.!bext! with !bdec!
echo.
echo Write !cto! !oname! to !aodir!\!oprefix!*.!oext! with !enc! quality !oq!
echo.
echo Using !atdir!\ as temporary directory
if "!adec!"=="copy" set adecmd=copy
if "!bdec!"=="copy" set bdecmd=copy
if "!enc!"=="copy" set encmd=copy
if "!adecmd!"=="" (
	echo [ERR] Decoder !adec! not found^^!
	goto end
)
if "!bdecmd!"=="" (
	echo [ERR] Decoder !bdec! not found^^!
	goto end
)
if "!encmd!"=="" (
	echo [ERR] Encoder !enc! not found^^!
	goto end
)
if "!editcmd!"=="" (
	echo [ERR] WAV editor !edit! not found^^!
	goto end
)
if !ctna! GTR 0 echo [WARN] !ctna! of !cta! required !aname! not found^^!
if !ctnb! GTR 0 echo [WARN] !ctnb! of !ctb! required !bname! not found^^!
if not exist "!aodir!\" mkdir "!aodir!"
if not exist "!aodir!\" (
	echo [ERR] Can't create output directory !aodir!
	goto end
)
if not exist "!atdir!\" (
	echo [ERR] Temp. directory doesn't exist: !atdir!\
	goto end
)
echo.
if "!select!"=="" (
	echo Ready^^!
	pause
)


echo.
set k=0
set m=0
set ta=
set tb=
for /f "usebackq tokens=* delims=," %%i in ("!cfg!") do (
	set l=%%i
	set l=!l: =`!
	if !m!==1 (
		if !k!==1 (
			if not !na! GEQ 0 call :convinit
			set fs="!atdir!\2!ftmp!"
			set fd="!aodir!\!oprefix!!ta!.!oext!"
			set tcmd=!encmd!
			set tpar=%encpar%
			set tprn=!encprn!
			call :runcmd
			if not exist !fd! echo [ERR] Error encoding !oname:~,-1! !fd!
		)
		del /q /f "!atdir!\2!ftmp!" >nul 2>&1
		del /q /f "!atdir!\3!ftmp!" >nul 2>&1
		if "!l:~0,1!"=="$" goto convdone
		set /a n=0
		set /a na=-1
		set k=0
		set k2=0
		set wsrate=100
		set wamp=0
		set wstart=0
		set wlen=0
		for %%j in ("!l:,="^,"!") do (
			set v=%%j
			set v=!v:"=!
			if !n!==0 (
				if not "!l:~0,1!"=="#" (
				if "!select!"=="" (
					set k=1
				) )
				if "!v:#=!"=="!select!" set k=1
			)
			if !k!==1 (
				if !na! GEQ 0 (
					if !na!==0 set weop=!v!
					if !na!==1 set wesrc=!v!
					if !na!==2 set wedst=!v!
					if !na!==3 (
						set welen=!v!
						if !k2!==0 (
							if !weop!==1 set k2=1
							if !weop!==5 set k2=1
						)
						if !k2!==1 (
							set k2=2
							if "!fta!"=="" (
								echo [WARN] !aname:~,-1! !aadir!\!aprefix!*!ta!*.!aext! NOT FOUND^^! Result will sound incorrect^^!
							) else (
								set fs=!fta!
								set fd="!atdir!\3!ftmp!"
								set tcmd=!adecmd!
								set tpar=%adecpar%
								set tprn=!adecprn!
								call :runcmd
								if not exist "!atdir!\3!ftmp!" echo [WARN] Error decoding !aname:~,-1! !fta! ^^! Result will sound incorrect^^!
								attrib -r "!atdir!\3!ftmp!"
							)
						)
						if !weop!==1 !editcmd! copyext "!atdir!\2!ftmp!" "!atdir!\3!ftmp!" !wesrc! !wedst! !welen! .01
						if !weop!==3 !editcmd! copy "!atdir!\2!ftmp!" !wesrc! !wedst! !welen! .01
						if !weop!==7 !editcmd! rol "!atdir!\2!ftmp!" !wedst! !wesrc! !welen!
						if !weop!==8 !editcmd! ror "!atdir!\2!ftmp!" !wedst! !wesrc! !welen!
						if !weop!==5 (
							if !k2!==2 (
								set k2=3
								!editcmd! resamp "!atdir!\3!ftmp!" -!wsrate!%%
							)
							!editcmd! copyext "!atdir!\2!ftmp!" "!atdir!\3!ftmp!" !wesrc! !wedst! !welen! .01
						)
					)
					if !na! GEQ 0 set /a na+=1
					set /a na%%=4
				) else (
					if !n!==0 (
						set ta=!v!
						call :findtrk a !v!
						set fta=!ftres!
					)
					if !n!==1 (
						if not !tb!==!v! (
							del /q /f "!atdir!\1!ftmp!" >nul 2>&1
							call :findtrk b !v!
							set ftb=!ftres!
							if "!ftb!"=="" (
								echo [ERR] !bname:~,-1! !abdir!\!bprefix!*!v!*.!bext! NOT FOUND^^!
								set k=0
							) else (
								set fs=!ftb!
								set fd="!atdir!\1!ftmp!"
								set tcmd=!bdecmd!
								set tpar=%bdecpar%
								set tprn=!bdecprn!
								call :runcmd
								if not exist "!atdir!\1!ftmp!" (
									echo [ERR] Error decoding !bname:~,-1! !ftb! ^^!
									set k=0
								) else set tb=!v!
							)
						)
					)
					if !n!==2 set wsrate=!v!
					if !n!==3 set wamp=!v!
					if !n!==4 set wstart=!v!
					if !n!==5 set wlen=!v!
					if !n!==6 call :convinit
				)
			)
			set /a n+=1
		)
	)
	if "!l:~0,1!"=="$" set m=1
)
goto convdone
:convinit
echo Generating !aprefix!!ta!.!aext!...
del /q /f "!atdir!\2!ftmp!" >nul 2>&1
copy /y "!atdir!\1!ftmp!" "!atdir!\2!ftmp!" >nul
attrib -r "!atdir!\2!ftmp!"
!editcmd! crop "!atdir!\2!ftmp!" !wstart! !wlen!
!editcmd! amp "!atdir!\2!ftmp!" !wamp!
!editcmd! setsamp "!atdir!\2!ftmp!" -!wsrate!%%
set /a na=0
goto end
:runcmd
setlocal disabledelayedexpansion
set tpar=%tpar:?=!%
%tcmd% %tpar% >%tprn% 2>&1
endlocal
goto end


:convdone
del /q /f "!atdir!\1!ftmp!" >nul 2>&1
del /q /f "!atdir!\2!ftmp!" >nul 2>&1
del /q /f "!atdir!\3!ftmp!" >nul 2>&1
if not "!select!"=="" goto end
set j=!copybat!
set copybat=!aodir!\!copybat!
echo @echo off>!copybat!
echo setlocal enableextensions enabledelayedexpansion>>!copybat!
echo rem Moves !oname! into !name! directory after making a backup>>!copybat!
echo rem (c) SBT 2019>>!copybat!
echo set ccdir=.>>!copybat!
echo for /f "delims=" %%%%F in ("%%ccdir%%") do set ccdir=%%%%~fF>>!copybat!
echo set cgdir=^^!ccdir^^!\..>>!copybat!
echo for /f "delims=" %%%%F in ("%%cgdir%%") do set cgdir=%%%%~fF>>!copybat!
echo if not exist "^!cgdir^!\!updirchk!" (>>!copybat!
echo set cgdir=^^!ccdir^^!\..\..>>!copybat!
echo for /f "delims=" %%%%F in ("^!cgdir^!") do set cgdir=%%%%~fF>>!copybat!
echo )>>!copybat!
echo if not exist "^!cgdir^!\!updirchk!" (>>!copybat!
echo echo This program must be run from a subfolder inside your !name! directory^^^^^^^^^^!>>!copybat!
echo echo ^^^^(^^!cgdir^^!\!updirchk! not found^^^^)>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo set cbdir=^^!cgdir^^!\!bkp!>>!copybat!
echo for /f "delims=" %%%%F in ("%%cbdir%%") do set cbdir=%%%%~fF>>!copybat!
echo if not exist "^!ccdir^!\!oprefix!*.!oext!" (>>!copybat!
echo echo Nothing to do.>>!copybat!
echo echo ^^^^(^^!ccdir^^!\!oprefix!*.!oext! not found^^^^)>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo if exist "^!cbdir^!\!oprefix!*.!oext!" (>>!copybat!
echo echo Backup folder is not empty^^!>>!copybat!
echo echo Please make sure there's nothing important in it, empty it and try again^^^^^^^^^^!>>!copybat!
echo echo ^^^^(^^!cbdir^^!\!oprefix!*.!oext! already exist^^^^)>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo echo.>>!copybat!
echo echo Ready to move !oname! into !name! directory.>>!copybat!
echo echo A backup will first be created of any files that will be replaced.>>!copybat!
echo echo.>>!copybat!
echo echo Moving from: ^^!ccdir^^!\!oprefix!*.!oext!>>!copybat!
echo echo Moving to: ^^!cgdir^^!\!oprefix!*.!oext!>>!copybat!
echo echo Backing up existing files in: ^^!cbdir^^!\>>!copybat!
echo echo.>>!copybat!
echo pause>>!copybat!
echo if not exist "^!cbdir^!\" mkdir "^!cbdir^!">>!copybat!
echo if not exist "^!cbdir^!\" (>>!copybat!
echo echo Can't create backup directory ^^!cbdir^^!>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo for %%%%i in ("^!ccdir^!\!oprefix!*.!oext!") do (>>!copybat!
echo move /y "^!cgdir^!\%%%%~nxi" "^!cbdir^!\" ^>nul 2^>^&^1>>!copybat!
echo move /y "%%%%~fi" "^!cgdir^!\" ^>nul>>!copybat!
echo )>>!copybat!
echo echo.>>!copybat!
echo echo Finished^^^^^^^^^^!>>!copybat!
echo :end>>!copybat!
echo pause>>!copybat!
echo.
echo.
if not exist ..\!updirchk! (
	echo The !oname! are ready.
	echo Copy the folder !aodir!
	echo   into your !name! directory and run !j!
	echo   to activate the !oname!.
	echo.
	echo The !aname! will be backed up automatically.
	echo.
	pause
	goto end
)
cd !aodir!
!copybat!
goto end



:findtrk
set ftres=
set ftn=
set /a i=%2
if %i%==%2 set ftn=%2
set ftp=^^!a%1dir^^!\^^!%1prefix^^!
set fte=.^^!%1ext^^!
set ftp=%ftp%
set fte=%fte%
setlocal disabledelayedexpansion
if "%ftn%"=="" (
	if exist "%ftp%%2%fte%" set ftres="%ftp%%2%fte%"
	goto findtrke
)
rem if x%ftres%==x for %%i in ("%ftp%*00%ftn%*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*00%ftn%-*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*00%ftn%.*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*00%ftn% *%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*-0%ftn%*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*0%ftn%-*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*0%ftn%.*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%* 0%ftn% *%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%* 0%ftn%*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*0%ftn% *%fte%") do set ftres="%%~fi"
rem if x%ftres%==x for %%i in ("%ftp%*0%ftn%*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*-%ftn%*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*%ftn%-*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*%ftn%.*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%* %ftn% *%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%* %ftn%*%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*%ftn% *%fte%") do set ftres="%%~fi"
if x%ftres%==x for %%i in ("%ftp%*%ftn%*%fte%") do set ftres="%%~fi"
:findtrke
if not x%ftres%==x set ftres=%ftres:!=?%
endlocal & set ftres=%ftres%
rem echo [%0] [%1] [%2] = #%ftn% - %ftp% %fte% = %ftres%
goto end



goto end

:end
