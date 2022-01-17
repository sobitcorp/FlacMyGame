@echo off
setlocal disabledelayedexpansion
setlocal
rem (c) SoBiT 2019-2021
set out=fmg_out
set bkp=fmg_bkp
set decode=flac:flac.exe:--totally-silent`-dfo`@fd@`@fs@:con,ogg:oggdec.exe:-qw`@fd@`@fs@:nul,mp3:lame.exe:--decode`--quiet`@fs@`@fd@:con,wav:@copy:/y`@fs@`@fd@:nul
set encode=flac:flac.exe:@oqc@`-esfo`@fd@`@fs@:con,ogg:oggenc2.exe:@oqc@`-Qo`@fd@`@fs@:nul,mp3:lame.exe:@oqc@`@fs@`@fd@:con
set edit=wavedit.exe
set ftmp=~mmtmp.wav
set tempdir=.
set copybat=flacMyGame_install.bat
set locase=for %%n in (1 2) do if %%n==2 ( for %%# in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do set "lcres=!lcres:%%#=%%#!") else set lcres=
setlocal enableextensions enabledelayedexpansion

set cfg=
set select=
set aexts=
set bext=
set bexts=
set bdir=
set bdirs=
set bids=
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
set oqb=
set editcmd=
set ct=0
set cto=0
set ctn=0
set obits=16
if "%1"=="" goto load
set select=%1
if .%select:~0,1%==.- goto help
if .%select:~0,1%==./ goto help
if .%select:~0,4%==.help goto help
if not .%select%==. (
	set cfg=%1
	set select=%2
	if "!cfg:.csv=!"=="!cfg!" (
		set cfg=!cfg!.csv
	)
)
goto load

:help
echo Usage: flacmygame [csv config file] [name of specific single music track to create]
goto end

:load
echo flacMyGame v1.1.0 by SoBiT
setlocal disabledelayedexpansion
if "%cfg%"=="" (
	for %%i in ("*.csv") do set cfg=%%~fi
)
if "%cfg%"=="" (
	echo No configuration file found! Make sure a .csv file exists in this folder.
	goto pause
)
set cfg="%cfg:^=^^%"
set cfg=%cfg:!=^!%
endlocal & set cfg=%cfg%
if not exist "!cfg!" (
	echo Configuration file !cfg! does not exist^^!
	goto pause
)
echo Loading configuration !cfg!...
for /f "usebackq tokens=* delims=," %%i in (!cfg!) do (
	set l=%%i
	set l=!l: =`!
	if "!l:~0,1!"=="$" goto loadok
	if not "!l:~0,1!"=="#" (
		set n=0
		set op=
		for %%j in ("!l:,="^,"!") do (
			set v=%%j
			set v=!v:"=!
			if !n!==0 ( 
				set op=!v!
			) else if not .!v!==. (
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
					if !n!==4 set oq=!v:`= !
					if !n!==5 set oqb=!v:`= !
					if !n!==6 set obits=!v!
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
	goto pause
)
color 0a
set aname=!aname:`= !
set bname=!bname:`= !
set oname=!oname:`= !
if not "%alook%"=="" set alook=!alook:`= !
set aexts=!aexts:~1!
set bexts=!bexts:~1!
for %%i in (%decode%) do (
	set l=%%i
	for /f "tokens=1-4 delims=:" %%a in ("!l:`= !") do (
		set m=%%b
		set decpar%%a=%%c
		set decprn%%a=%%d
		set decct%%a=0
		if not "!m:@=!"=="%%b" (
			set decmd%%a=!m:~1!
			set decnm%%a=!m:~1!
		) else (
			set decmd%%a=
			set decnm%%a=!m!
			for %%j in (.. .) do (
				if exist %%j\%%b (
					setlocal disabledelayedexpansion
					for /f "delims=" %%f in ("%%j\%%b") do set decmd%%a="%%~ff"
					setlocal enabledelayedexpansion
				)
			)
		)
	)
)
for %%i in (%encode%) do (
	set l=%%i
	for /f "tokens=1-4 delims=:" %%a in ("!l:`= !") do (
		set m=%%b
		set encpar%%a=%%c
		set encprn%%a=%%d
		if not "!m:@=!"=="%%b" (
			set encmd%%a=!m:~1!
			set encnm%%a=!m:~1!
		) else (
			set encmd%%a=
			set encnm%%a=!m!
			for %%j in (.. .) do (
				if exist %%j\%%b (
					setlocal disabledelayedexpansion
					for /f "delims=" %%f in ("%%j\%%b") do set encmd%%a="%%~ff"
					setlocal enabledelayedexpansion
				)
			)
		)
	)
)
setlocal disabledelayedexpansion
for %%i in (.. .) do (
	if exist %%i\%edit% (
		for /f "delims=" %%f in ("%%i\%edit%") do set editcmd="%%~ff"
	)
)
for /f "delims=" %%F in ("%tempdir%") do set atdir=%%~fF
for /f "delims=" %%F in ("%out%") do set aodir=%%~fF
setlocal enabledelayedexpansion
if "!atdir:~-1!"=="\" set atdir=!atdir:~,-1!
if "!aodir:~-1!"=="\" set aodir=!aodir:~,-1!
del /q /f !atdir!\1!ftmp! >nul 2>&1
del /q /f !atdir!\2!ftmp! >nul 2>&1
del /q /f !atdir!\3!ftmp! >nul 2>&1
set m=0
set nbids=0
for /f "usebackq tokens=* delims=," %%i in (!cfg!) do (
	set l=%%i
	set l=!l: =`!
	set t=
	set op=
	if !m!==1 if not "!l:~0,1!"=="#" (
		set n=0
		if "!l:~0,1!"=="$" goto load2
		for %%j in ("!l:,="^,"!") do (
			set v=%%j
			set v=!v:"=!
			if !n! GTR 2 (
				if not "!v!"=="" set v=!v:`= !
				set t=!t!,!v!
			) else (
				if !n!==0 (
					set op=!v!
					set bids=!bids!,!v!
					set bdir!op!=
					set ct!op!=0
					set ctn!op!=0
				)
				if !n!==1 set bname!op!=!v:`= !
				if !n!==2 set bsr!op!=!v!
			)
			set /a n+=1
		)
		set bdirs!op!=!t:~1!
		set /a nbids+=1
	)
	if "!l:~0,1!"=="$" set /a m=m+1
)

:load2
set bids=!bids:~1!
set tb=
set m=0
for /f "usebackq tokens=* delims=," %%i in (!cfg!) do (
	set l=%%i
	set l=!l: =`!
	if !m!==2 if not "!l:~0,1!"=="#" (
		if "!l:~0,1!"=="$" goto ready
		set n=0
		set bn=0
		set na=-1
		set /a cto+=1
		for %%j in ("!l:,="^,"!") do (
			set v=%%j
			set v=!v:"=!
			if !na! GEQ 0 (
				if !na!==0 (
					if !v!==1 set /a na=-1
					if !v!==5 set /a na=-1
					if not !na! GEQ 0 (
						call :findtrk "" !ta!
						if .!ftres!==. ( 
							set /a ctn+=1
						) else ( 
							set /a ct+=1
							set /a decct!ftx!+=1
						)
					)
				)
				if !na! GEQ 0 set /a na+=1
				set /a na%%=4
			) else (
				if !n!==0 (
					set ta=!v!
					if not .!select!==. if /i not !select!==!v! set n=8
				)
				if !n!==1 (
					if !nbids! LEQ 1 ( 
						set tc=0
						set /a n+=1
					) else set tc=!v!
				) 
				if !n!==2 if not !tb!==!tc!!v! (
					set tb=!tc!!v!
					call :findtrk !tc! !v!
					if .!ftres!==. (
						set /a ctn!tc!+=1
					) else (
						set tc=!ftc!
						set /a ct!tc!+=1
						set /a decct!ftx!+=1
					)
				)
				if !n!==7 set /a na=0
			)
			set /a n+=1
		)
	)
	if "!l:~0,1!"=="$" set /a m=m+1
)

:ready
set cta=0
set ctna=0
for %%m in (%bids%) do (
	set /a cta=cta+!ct%%m!
	set /a ctna=ctna+!ctn%%m!
)
rem echo !ct! !ct0! !ct1! !ct2! !ct9! :: !ctn! !ctn0! !ctn1! !ctn2! !ctn9! :: !cta! !ctna! !cto! :: !decctflac! !decctogg! !decctmp3! !decctwav!
echo.
echo !title:`= !
echo !caption:`= !
echo.
if !cta!==0 (
	if not .!select!==. (
		echo [ERR] The given .csv file has no instructions for making !select!^^!
		echo.      Please check your command-line arguments.
	) else echo [ERR] !bname! ^(!bprefix!*.{!bexts!}^) not found^^!
	goto pause
)
if !ct!==0 if not !ctn!==0 echo [WARN] !aname! ^(!aprefix!*.{!aexts!}^) not found^^! Result will sound incorrect^^!
echo Using !cta! of the following !bname!:
for %%m in (%bids%) do (
	if not !ct%%m!==0 (
		set e=!bext%%m!
		for %%e in (!e!) do (
			echo.   !ct%%m! !bname%%m! in !bdir%%m:"=!\!bprefix!*.%%e with !decnm%%e!
		)
	)
)
echo.
if not !ct!==0 (
	echo Using !ct! !aname! in !bdir:"=!\!aprefix!*.!bext! with !decnm%bext%!
	echo.
)
echo Write !cto! !oname! to !aodir!\!oprefix!*.!oext! with !encnm%oext%! quality !oq!
echo.
echo Using !atdir!\ as temporary directory
echo.
for %%i in (%decode%) do (
	for /f "tokens=1-2 delims=:" %%a in ("%%i") do (
		if not !decct%%a!==0 if .!decmd%%a!==. (
			echo [ERR] Decoder %%b not found^^!
			goto download
		)
	)
)
if .!encmd%oext%!==. (
	echo [ERR] Encoder !encnm%oext%! not found^^!
	goto download
)
if .!editcmd!==. (
	echo [ERR] WAV editor !edit! not found^^!
	goto download
)
if not !ctna!==0 (
	echo [WARN] !ctna! of !cto! required !bname! not found:
	for %%m in (%bids%) do (
		if not !ctn%%m!==0 (
			echo.    Missing !ctn%%m! !bname%%m! !bname!^^!
		)
	)
)
if not !ctn!==0 (
	set /a ctx=ctn+ct
	echo [WARN] !ctn! of !ctx! required !aname! not found^^!
)
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
	echo Ready^^! Please verify the above info is correct.
	pause
)

echo.
set k=0
set m=0
set ta=
set tb=
for /f "usebackq tokens=* delims=," %%i in (!cfg!) do (
	set l=%%i
	set l=!l: =`!
	if !m!==2 if not "!l:~0,1!"=="#" (
		for %%k in (0 1) do (
			if !k!==1 (
				if not !na! GEQ 0 call :convinit
				rem !editcmd! resample "!atdir!\2!ftmp!" !sr!
				set fs="!atdir!\2!ftmp!"
				set fd="!aodir!\!oprefix!!ta:\=@!.!oext!"
				set tcmd=!encmd%oext%!
				set tpar=!encpar%oext%!
				set tprn=!encprn%oext%!
				set oqc=!oq!
				if %%k==1 set oqc=!oqb!
				call :runcmd
				for %%i in (!fd!) do (
					if %%~zi==0 del /q /f !fd! >nul 2>&1
				)
				if not exist !fd! (
					if %%k==1 echo [ERR] Error encoding !oname:~,-1! !fd!
				) else set k=0
			)
		)
		del /q /f "!atdir!\2!ftmp!" >nul 2>&1
		del /q /f "!atdir!\3!ftmp!" >nul 2>&1
		if "!l:~0,1!"=="$" goto convdone
		set n=0
		set na=-1
		set k=0
		set k2=0
		set wsrate=100
		set wamp=0
		set wstart=0
		set wlen=0
		for %%j in ("!l:,="^,"!") do (
			set v=%%j
			set v=!v:"=!
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
						call :findtrk "" !ta!
						if .!ftres!==. (
							echo [WARN] !aname:~,-1! !ta! ^(!aprefix!*.{!aexts!}^) NOT FOUND^^! Result may sound incorrect^^!
							set n=8
						) else (
							set fs=!ftres!
							set fd="!atdir!\3!ftmp!"
							set tcmd=!decmd%bext%!
							set tpar=!decpar%bext%!
							set tprn=!decprn%bext%!
							call :runcmd
							for %%i in ("!atdir!\3!ftmp!") do (
								if %%~zi==0 del /q /f "!atdir!\3!ftmp!" >nul 2>&1
							)
							if not exist "!atdir!\3!ftmp!" echo [WARN] Error decoding !aname:~,-1! !fs! ^^! Result may sound incorrect^^!
							attrib -r "!atdir!\3!ftmp!"
							!editcmd! bitdepth "!atdir!\3!ftmp!" !obits!
							!editcmd! resample "!atdir!\3!ftmp!" !sr!
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
					if not .!select!==. if /i not !select!==!v! (
						set n=8
						set k=0
					)
				)
				if !n!==1 (
					if !nbids! LEQ 1 ( 
						set tc=0
						set /a n+=1
					) else set tc=!v!
				) 
				if !n!==2 (
					set tb=!tc!!v!
					for %%c in (!tc!) do (
						set sr=!bsr%%c!
					)
					del /q /f "!atdir!\1!ftmp!" >nul 2>&1
					call :findtrk !tc! !v!
					if .!ftres!==. (
						for %%c in (!tc!) do (
							echo [ERR] Track !v! of !bname%%e! !bname! ^(!bprefix!*.{!bexts!}^) NOT FOUND^^!
						)
						set n=8
					) else (
						set tc=!ftc!
						set fs=!ftres!
						set fd="!atdir!\1!ftmp!"
						for %%c in (!tc!) do (
							for %%e in (!bext%%c!) do (
								set tcmd=!decmd%%e!
								set tpar=!decpar%%e!
								set tprn=!decprn%%e!
							)
						)
						call :runcmd
						for %%i in ("!atdir!\1!ftmp!") do (
							if %%~zi==0 del /q /f "!atdir!\1!ftmp!" >nul 2>&1
						)
						if not exist "!atdir!\1!ftmp!" (
							echo [ERR] Error decoding !bname:~,-1! !fs! ^^!
							set n=8
							set tb=
						) else set k=1
					)
				)
				if !n!==3 set wsrate=!v!
				if !n!==4 set wamp=!v!
				if !n!==5 set wstart=!v!
				if !n!==6 set wlen=!v!
				if !n!==7 call :convinit
			)
			set /a n+=1
		)
	)
	if "!l:~0,1!"=="$" set /a m=m+1
)
goto convdone
:convinit
echo Generating !oprefix!!ta!.!oext!...
attrib -r "!atdir!\1!ftmp!"
!editcmd! bitdepth "!atdir!\1!ftmp!" !obits!
!editcmd! resample "!atdir!\1!ftmp!" !sr!
del /q /f "!atdir!\2!ftmp!" >nul 2>&1
copy /y "!atdir!\1!ftmp!" "!atdir!\2!ftmp!" >nul
attrib -r "!atdir!\2!ftmp!"
!editcmd! crop "!atdir!\2!ftmp!" !wstart! !wlen!
!editcmd! amp "!atdir!\2!ftmp!" !wamp!
!editcmd! setsamp "!atdir!\2!ftmp!" -!wsrate!%%
set na=0
goto end
:runcmd
set tpar=%tpar:@=^^!%
set tpar=%tpar%
setlocal disabledelayedexpansion
set tpar=%tpar:?=!%
%tcmd% %tpar% >%tprn% 2>&1
endlocal
goto end


:convdone
del /q /f "!atdir!\1!ftmp!" >nul 2>&1
del /q /f "!atdir!\2!ftmp!" >nul 2>&1
del /q /f "!atdir!\3!ftmp!" >nul 2>&1
if not .!select!==. goto end
set j=!copybat!
set copybat=!aodir!\!copybat!
echo @echo off>!copybat!
echo setlocal enableextensions disabledelayedexpansion>>!copybat!
echo rem Moves !oname! into !name! directory after making a backup>>!copybat!
echo rem (c) SBT 2019>>!copybat!
echo set ccdir=.>>!copybat!
echo for /f "delims=" %%%%F in ("%%ccdir%%") do set ccdir=%%%%~fF>>!copybat!
echo for %%%%i in (.. ..\.. ..\..\..) do (>>!copybat!
echo if exist "%%ccdir%%\%%%%i\!updirchk!" (>>!copybat!
echo for /f "delims=" %%%%F in ("%%ccdir%%\%%%%i") do set cgdir=%%%%~fF>>!copybat!
echo ))>>!copybat!
echo if not exist "%%cgdir%%\!updirchk!" (>>!copybat!
echo echo This program must be run from a subfolder inside your !name! directory^^!>>!copybat!
echo echo ^^^^(..\!updirchk! not found^^^^)>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo set cbdir="%%cgdir%%\!bkp!">>!copybat!
echo for /f "delims=" %%%%F in (%%cbdir%%) do set cbdir=%%%%~fF>>!copybat!
echo if not exist "%%ccdir%%\!oprefix!*.!oext!" (>>!copybat!
echo echo Nothing to do.>>!copybat!
echo echo ^^^^("%%ccdir%%\!oprefix!*.!oext!" not found^^^^)>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo if exist "%%cbdir%%\!oprefix!*.!oext!" (>>!copybat!
echo echo Backup folder is not empty^^!>>!copybat!
echo echo Please make sure there's nothing important in it, empty it and try again^^!>>!copybat!
echo echo ^^^^("%%cbdir%%\!oprefix!*.!oext!" already exist^^^^)>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo setlocal enabledelayedexpansion>>!copybat!
echo echo.>>!copybat!
echo echo Ready to move !oname! into !name! directory.>>!copybat!
echo echo A backup will first be created of any files that will be replaced.>>!copybat!
echo echo.>>!copybat!
echo echo Moving from: ^^!ccdir^^!\!oprefix!*.!oext!>>!copybat!
echo echo Moving to: ^^!cgdir^^!\!aprefix!*.!oext!>>!copybat!
echo echo Backing up existing files in: ^^!cbdir^^!\>>!copybat!
echo echo.>>!copybat!
echo pause>>!copybat!
echo if not exist "^!cbdir^!\" mkdir "^!cbdir^!">>!copybat!
echo if not exist "^!cbdir^!\" (>>!copybat!
echo echo Can't create backup directory ^^!cbdir^^!>>!copybat!
echo goto end>>!copybat!
echo )>>!copybat!
echo for %%%%i in ("^!ccdir^!\!oprefix!*.!oext!") do (>>!copybat!
echo set fn=?!aprefix!%%%%~ni.!oext!>>!copybat!
echo set fn=^^!fn:?%oprefix%=^^!>>!copybat!
echo set fn=^^!fn:@=\^^!>>!copybat!
echo move /y "^!cgdir^!\^!fn^!" "^!cbdir^!\%%%%~ni.!oext!" ^>nul 2^>^&^1>>!copybat!
echo setlocal disabledelayedexpansion>>!copybat!
echo set op=move /y "%%%%~fi">>!copybat!
echo setlocal enabledelayedexpansion>>!copybat!
echo ^^!op^^! "^!cgdir^!\^!fn^!" ^>nul>>!copybat!
echo endlocal ^& endlocal>>!copybat!
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
	goto pause
)
cd !aodir!
!copybat!
goto end



:findtrk
set ftres=
set ftc=%1
set ftc=%ftc:"=%
if .%mmdebug%==.. echo FT: %1 ^| %2 ^| %3 =  !bdir%ftc%! ^| !bext%ftc%! ^| !bdirs%ftc%!

if .!bdir%ftc%!==."?" (
	if .%ftc% ==.0 goto end
	if .%ftc%==. goto end
	call :findtrk 0 %2 %1
	goto end
)
if .!bdir%ftc%!==. (
	call :finddir %ftc%
	goto findtrk
)
set e=!bext%ftc%!
set ftk=%bprefix%
if .%ftc%==. (
	set ftk=%aprefix%
)
set p=!bdir%ftc%!
set p=!p:"=!\%ftk%
if .%ftc%==.0 if not .%3==. set p=!p!*%3
setlocal disabledelayedexpansion
set n=
set /a n=%2
if not .%n%==.%2 set n=
if .%n%==. (
	if exist "%p%%2.%e%" set ftres="%p%%2.%e%"
	goto findtrke
)
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%00%n% - *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%0%n% - *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%%n% - *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%00%n%-*%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%0%n%-*%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%%n%-*%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%00%n%. *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%0%n%. *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%%n%. *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%00%n%.*%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%0%n%.*%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%%n%.*%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%00%n% *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%0%n% *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%%n% *%e%") do set ftres="%%~fi"
if .%ftc%==.0 if .%ftres%==. for %%i in ("%p%*%n%*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*00%n% - *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*0%n% - *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*%n% - *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*00%n%-*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*0%n%-*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*%n%-*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*00%n%. *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*0%n%. *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*%n%. *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*00%n%.*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*0%n%.*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*%n%.*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%* 0%n% *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*00%n% *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*0%n% *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%* %n% *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%* 0%n%*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*-0%n%*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*-%n%*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*%n% *%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%* %n%*%e%") do set ftres="%%~fi"
if .%ftres%==. for %%i in ("%p%*%n%*%e%") do set ftres="%%~fi"
:findtrke
if not .%ftres%==. (
	for %%i in (%ftres%) do set ftx=%%~xi
	set ftres=%ftres:^=^^%
	set ftres=%ftres:!=?%
)
endlocal & set ftres=%ftres%& set ftx=%ftx%
if not .%ftres%==. (
	%locase%!ftx:~1!
	set ftx=!lcres!
)
if .%mmdebug%==.. echo FTRES :: %ftres% : %ftx%
goto end

:finddir
if .%mmdebug%==.. echo FD: %1 ^| %2 ^| %3 ^| %4 ^| %5 ^| %6

set e=%bexts%
set p=%bprefix%
if .%1==. (
	set e=%aexts%
	set p=%aprefix%
)
set fdt=.
set fdr=
if not .!bdirs%1!==. set fdt="!bdirs%1:,=" "!"
for %%i in (%e%) do (
	for %%j in (!fdt!) do (
	for /f "tokens=*" %%x in ("%%j") do (
		for %%k in ("." ".." "..\.." %alook%) do (
		for /f "tokens=*" %%y in (%%k) do (
			set fdk=%%y\*%%x*
			set fdk="!fdk:"=!"
			if .%%j==.. set fdk=!fdk! %%y\.
			for /d %%l in (!fdk!) do (
 				if .%mmdebug%==.. echo SSS %%i ^| %%j ^| %%k ^| %%l  ==  !fdk!: %%l\%p%*.%%i"
				echo "%%l"|findstr /i %%x >nul && (
					setlocal disabledelayedexpansion
					if exist %%l\%p%*.%%i (
						endlocal
						set u=
						set d=%%~fl
						for %%m in (%bids%) do (
							if .!bdir%%m!==.!d! set u=1
						)
						if .!bdir!==.!d! set u=1
						if .!u!==. (
							set bext%1=%%i
							setlocal disabledelayedexpansion
							set fdr=%%~fl
							goto finddire
						)
					) else endlocal
				)
			)
		))
	))
)
setlocal disabledelayedexpansion
set fdr=?
:finddire
set fdr="%fdr:^=^^%"
set fdr=%fdr:!=^!%
endlocal & set bdir%1=%fdr%
goto end

:download
echo.      Please download the latest release - this file is included.
echo.      Visit github.com/sobitcorp/flacmygame
echo.
:pause
pause
goto end


goto end

:end