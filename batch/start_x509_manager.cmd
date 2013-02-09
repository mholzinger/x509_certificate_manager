@echo off & setLocal EnableDELAYedeXpansion
set GlobalErrorState=0

:: This string is set to have subordinate scripts do self checks
set CalledFromTop=TRUE

:: Startup tests, these should go unnoticed in the terminal unless we have an error
:: echoing this line will show what problem we ran into if we dont pass the tests
@echo -------- Startup Tests --------
@echo.

:TestJava
@echo Test: Calling Java CLI ...
set ERRORLEVEL=
java -version >NUL 2>NUL

IF %ERRORLEVEL% GTR 0 ( ^
@echo ERROR TestJava: ^<%errorlevel%^>
@echo Java path has not been is not configured for CLI. && ^
goto ConfirmExit )

@echo SUCCESS: Java path set

:TestOpenSSLConfig
set ERRORLEVEL=
@echo Test: Calling OpenSSL CLI ...
openssl version >NUL 2>NUL

IF %ERRORLEVEL% GTR 0 ( ^
@echo ERROR TestOpenSSLConfig: ^<%errorlevel%^>
@echo openssl is not correctly configured - exiting && ^
goto ConfirmExit)

@echo SUCCESS: OpenSSL correctly installed

:SetWorkingPaths
:: Build all of our working strings

set JCA=%CD%
set InitialConfigPath=%CD%
set CertHome=X509_Manager

:ChangePathToLocalProfile
cd %HOMEPATH%
set userhome=%CD%
set cadirectory=^"%userhome%\%CertHome%\RootCA^"
set RANDFILE=%cadirectory%\.rand
md

:: Set openssl config file path
set OPENSSL_CONF=%InitialConfigPath%\openssl.cfg

:: Set randfile location for openssl
set RANDFILE=%userhome%\%CertHome%\RootCA\.rand

:: debug mode info
@echo -------------------------------------
@echo DEBUG MODE INFO
@echo -------------------------------------
@echo JCA - %JCA%
@echo InitialConfigPath - %InitialConfigPath%
@echo CertHome - %CertHome%
@echo cadirectory - %cadirectory%
@echo RANDFILE - %RANDFILE%
@echo OPENSSL_CONF - %OPENSSL_CONF%
pause


:TestForExistingCA
@echo Test: Testing for existing CA
type %CertHome%\cm_tag.txt >NUL 2>NUL
if ERRORLEVEL 1 (goto SetupWorkingDir)

:: We have a working CA, let's do stuff
cd %CertHome%

:: Check to see our java progs are present
:: IF NOT EXIST %JCA%\ImportKey.class ( copy %JCA%\ImportKey.class %CD% )
:: IF NOT EXIST %JCA%\ImportCert.class ( copy %JCA%\ImportCert.class %CD% )

goto CATasks

:SetupWorkingDir
:: Create parent directory for openssl RootCA (called RootCA)
mkdir %CertHome%
cd %CertHome%

:: Create our CSR signing directory
mkdir to_sign

:: copy java programs over for jks conversion
:: copy %JCA%\ImportKey.class .
:: copy %JCA%\ImportCert.class .

:Start
cls
@echo.
@echo X509 Certificate Manager - Windows Utility
@echo ----------------------------------------------------------------
@echo.
@echo  Type any key to create a new Certificate Authority
pause >nul

:: This Marks the section where we begin 4 steps for the CA and certs
:: Setions are
:: STEP 1 - ASK FOR CA VALIDITY DAYS
:: STEP 2 - ASK 8 QUESTIONS TO ESTABLISH DISTINGUISHED NAME
:: STEP 3 - ASK QUESTIONS FOR KEY ACCESS CONTROL
:: STEP 4 - PROMPT FOR PASSWORDS


:: START STEP 1 - ASK FOR CA VALIDITY DAYS
:AskForValidityDays
:: Capture Max validity days, tests for lengh and chars entered
cls
set ca_expiredays=

:: Begin interactive prompt menu
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  Set the validity period for the CA (Certificate Authority)
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  Maximum value allowed is 9600 days
@echo.
:: end interactive prompt menu

set /p ca_expiredays=  Max number of days for CA to be valid for [] : 
set /a valdays=%ca_expiredays%

if %valdays% EQU %ca_expiredays% (
    IF %valdays% GTR 9600 ( echo ERROR^: Value entered ^(%valdays%^) is greater than 9600 ) ^
		& PAUSE & GOTO AskForValidityDays
    IF %valdays% EQU 0 ( echo Value of ^(%valdays%^) invalid for CA ) & echo. & goto AskForValidityDays
	IF %valdays% LEQ 9600 ( goto ConfirmValidityDays )
    REM - Other Comparison operators for numbers
    REM - LEQ - Less Than or Equal To
    REM - GEQ - Greater Than or Equal To
    REM - NEQ - Not Equal To
) ELSE (
    REM - Non-numbers and decimal numbers get kicked out here
	echo.
    echo ERROR^: Non-Integer value passed. Type any key to re-enter a valid numeric value ...
	pause >nul
	GOTO AskForValidityDays
)

:ConfirmValidityDays
:: removing comma chars (if any)
set ca_expiredays=%ca_expiredays:,=%

@echo.
set /p user_in=" Type (y) to confirm [%ca_expiredays%], or (n) to change [y/n] : "
CALL :UPCase user_in
IF %user_in% EQU N ( cls & goto AskForValidityDays )
IF %user_in% EQU Y ( cls & goto CaptureDN )
goto ConfirmValidityDays

:: START STEP 2 - ASK 8 QUESTIONS TO ESTABLISH DISTINGUISHED NAME
:CaptureDN

:: Begin interactive prompt menu
cls
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  Locality information for CA Distinguished Name 
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  What you are about to enter is what is called a Distinguished Name or a DN.
@echo  If you enter '.', the field will be left blank.
@echo.
:: end interactive prompt menu

set /p country= Country Name (2 letter code) [AU]: 
set /p state= State or Province Name (full name) : 
set /p city= City ( Locality Name ) []: 

cls

:: Begin interactive prompt menu
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  Company information for CA Distinguished Name 
@echo.
@echo ----------------------------------------------------------------
@echo.
:: end interactive prompt menu

@echo Company Name ( Organization ) [Sample Corp] 
set /p organization= []: 

@echo.
@echo Department ( Organizational Unit Name ) [Sample Corp. Security]
set /p org_unit= []: 

@echo.
@echo Company website name ( Common Name or server FQDN) [samplecompanywebsite.com]: 
set /p commonname= []: 

@echo.
set /p emailaddy= Email Address []: 

:PrintDNValues
:: Begin interactive prompt menu
cls
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  Confirm the values entered for the DN of your CA
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo Country : ^<%country%^>
@echo State : ^<%state%^>
@echo City : ^<%city%^>
@echo Company : ^<%organization%^>
@echo Organizational Unit : ^<%org_unit%^>
@echo Company Url (common name) : ^<%commonname%^>
@echo email address : ^<%emailaddy%^>
@echo.
:: end interactive prompt menu

:ConfirmDN
set /p user_in=" Type (y) to confirm these values and continue, or (n) to re-enter [y/n] : "
CALL :UPCase user_in
IF %user_in% equ N ( 
set country=
set state=
set city=
set organization=
set org_unit=
set commonname=
set akm_commonname=
set emailaddy=
set client_ou=
set client_cn=
cls
goto CaptureDN )
IF %user_in% equ Y echo ( cls & goto SetDN )
goto :PrintDNValues

:SetDN
cls

:: Create the strings for the DN value to be passed to each Certificate Signing Request
set ca_distinguished_name=^"^/C^=%country%^/ST^=%state%^/L^=%city%^/O^=%organization%^/OU^=%org_unit%^/CN^=%commonname%^/emailAddress^=%emailaddy%^"

cls
call create_ca.bat
if %GlobalErrorState% GTR 0 ( goto ConfirmExitWithError )

:: START STEP 4 - PROMPT FOR PASSWORDS
:ConvertCertsPromptPassword
:: Copy and convert all certificate pairs into a user friendly directory
call stash_ca.bat
if %GlobalErrorState% GTR 0 ( goto ConfirmExitWithError )

:CAComplete
:: grab current working directory
set newcertdir=%CD%\Your_Certs

:: write a tag file to note compltion
copy /y NUL cm_tag.txt >NUL

:CACompleteOption
:: input statement to open working directory or quit
cls
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  Certificate Authority completed successfully !
@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  New directory with certificate files : 
@echo  ^<%newcertdir%^>
@echo.

goto confirmExit

:ConfirmExitWithError
set CalledFromTop=
@echo.
@echo BEFORE QUITTING WITH AN ERROR - Take note of the error above this message^!
PAUSE
goto :eof

:ConfirmExit
set CalledFromTop=
@echo.
@echo Now exiting AKM Certificate Manager
TIMEOUT 1 >NUL 2>NUL
goto :eof


:UPCase
SET %~1=!%1:y=Y!
SET %~1=!%1:n=N!
SET %~1=!%1:q=Q!
goto :eof
