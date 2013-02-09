@echo off
if NOT "%CalledFromTop%"=="TRUE" ( 
@echo ERROR: This script cannot be called directly
goto :eof )

set output_certs=Your_Certs

mkdir %output_certs%
mkdir %output_certs%\certificate_authority

:: make copy of the ca certificate
copy %cadirectory%\certs\root.pem %output_certs%\certificate_authority >NUL
	:: Check Err
	if %errorlevel% GTR 0 ( goto SetError )

:: convert ca cert from pem to der
openssl x509 ^
	-outform DER ^
	-in %cadirectory%\certs\root.pem ^
	-out %output_certs%\certificate_authority\root.der

	:: Check Err
	if %errorlevel% GTR 0 ( goto SetError )

cls

@echo.
@echo ----------------------------------------------------------------
@echo.
@echo  Optional password assignement to the CA java trustore
@echo.
@echo ----------------------------------------------------------------
@echo.

:: Set double quotes for calling java program with no password value
set truststore_password=""

:: Prompt for password otherwise
@echo  This can be done later on. Hit ENTER To skip password assignment
@echo  or input an optional password for java trustore copy of the CA now 
@echo.
set /p truststore_password=  [ Hit ENTER to skip adding password ] : 

goto :eof

:: Create java keystore CA truststore
java -cp ^"%JCA%^" ImportCert %output_certs%\certificate_authority\root.der ^
	%truststore_password% ^
	%output_certs%\certificate_authority\CATrustStore.jks >NUL


goto :eof

:ExitNoChange
@echo ERROR: This script cannot be called directly
goto :eof

:SetError
echo ERROR: Copying and converting certificates
pause >nul 
set GlobalErrorState=1
goto :eof
