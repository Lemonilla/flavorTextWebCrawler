@echo off
setlocal EnableDelayedExpansion

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: SCRIPT.........: flavor.bat
::: VERSION........: 2.0
::: DATE...........: 12/18/2014
::: AUTHOR.........: Neal Troscinski
::: REQUIRMENTS....: repl.bat; wget.exe;
::: DESCRIPTION....: Downloads the flavor text from 
:::                  Magic: The Gathering cards.
:::
:::      flavor [threads]
:::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Check to see if arg[1] is defined.
:: If so, this instance is a thread with ID = arg[2]
if not "%~2"=="" goto :run

:: Setup threads and run them.
:: Split total number of cards by the number of threads
:: and start a thread for each segment.
:: If arg[0] is not defined, assign the
:: number of threads to 250.
set "threads=%~1"
if not defined total set total=100000
if not defined threads set threads=250
set /a add=%total%/%threads%
set lower=1
set upper=%add%
set t_ID=1
:thread
	start /b "" "%~0" %lower% %upper% %t_ID%
	set /a lower+=%add%
	set /a upper+=%add%
	set /a t_ID+=1
if %lower% LSS %total% goto :thread
set /a t_ID-=1

:: Wait for all the threads to finish.
:: This is done by waiting for their ID.d
:: files to appear.
:: ALso writing current process number to
:: the screen.
:wait
	set wait=0
	cls
	for /f "tokens=1 delims=." %%G in (' dir /b *.tmc ') do echo %%G
	for /l %%A in (1,1,%t_ID%) do (	
		if not exist %%A.d set wait=1
	)
	timeout /t 1 /nobreak >nul
if "%wait%"=="1" goto :wait

:: Combine all list_ID.t files into list.txt		
for /l %%A in (1,1,%t_ID%) do type list_%t_ID%.t >>list.txt

:: Remove all temporary files and exit
del *.tmc
del *.tm
del *.t
del *.d
exit /b

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::: Start Recursion :::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Loop through input values arg[0] through arg[1]
:: Calling :pull on each number
:: When finished it will create a file with the name
:: of arg[2] which will be picked up by main's wait loop
:run
set ID=%~3
	for /l %%A in (%~1,1,%~2) do call :pull %%A
	echo. >%ID%.d
exit


:pull
	set current=%~1

	:: Set flag for error handling
	:rerun
	
	:: Download html for parsing to ####.tmc
	:: where #### is the current value of the loop in :run
	:: This requires wget.exe
	wget -O %current%.tmc "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=%current%" 1>nul 2>&1

	:: Parse out the data we need
	:: This requires repl.bat
	1>name_%ID%.tm 2>nul (
		type %current%.tmc | find "<span id=""ctl00_ctl00_ctl00_MainContent_SubContent_SubContentHeader_subtitleDisplay"">" | repl "<span id=\qctl00_ctl00_ctl00_MainContent_SubContent_SubContentHeader_subtitleDisplay\q>" "" x | repl "</span>" "" | repl "  " ""
	)
	1>flavor_%ID%.tm 2>nul (
		type %current%.tmc | find "<div class=""cardtextbox"" style=""padding-left:10px;""><i>" | repl "<div class=\qcardtextbox\q style=\qpadding-left:10px;\q><i>" "" x | repl "</i></div></div>" "" | repl "  " ""
	)

	set /p check_n=<name_%ID%.tm
	set /p check_f=<flavor_%ID%.tm

	:: Check to see if any values were gathered
	:: and write to the list file if they were both found
	if defined check_f (
		if defined check_n (
			1>>list_%ID%.t (
				echo.[%current%]
				echo.%check_n%
				type flavor_%ID%.tm
				echo.
			)
		) else (
			goto :rerun
		)
	)

	:: Cleanup
	set "check_n="
	set "check_f="
	del %current%.tmc
	del name_%ID%.tm
	del flavor_%ID%.tm


goto :eof