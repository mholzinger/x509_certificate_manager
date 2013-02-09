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
::@echo -------------------------------------
::@echo DEBUG MODE INFO
::@echo -------------------------------------
::@echo JCA - %JCA%
::@echo InitialConfigPath - %InitialConfigPath%
::@echo CertHome - %CertHome%
::@echo cadirectory - %cadirectory%
::@echo RANDFILE - %RANDFILE%
::@echo OPENSSL_CONF - %OPENSSL_CONF%
::pause


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

