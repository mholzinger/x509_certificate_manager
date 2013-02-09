@echo off
if NOT "%CalledFromTop%"=="TRUE" ( 
@echo ERROR: This script cannot be called directly
goto :eof )

:: Create self signed certificate authority
:: We're checking for errorlevel at each critical step and 
:: bailing out of the script of something is wrong
@echo off

mkdir %cadirectory%
	
	:: Check Err
	if %errorlevel% GTR 0 ( goto SetError )

copy /y NUL %cadirectory%\index.txt >NUL

cd %cadirectory%
echo 01 > serial

mkdir certs crl newcerts private 

	:: Check Err
	if %errorlevel% GTR 0 ( goto SetError )

:: Generate rand file and store in private dir
@openssl rand -out .rand 2048 >NUL

	:: Check Err
	if %errorlevel% GTR 0 ( goto SetError )

:: Create Certificate Authority private key and self-signed certificate
@openssl req -new -x509 -nodes ^
	-newkey rsa:2048 -sha256 ^
	-subj %ca_distinguished_name% ^
	-days %ca_expiredays% ^
	-keyout private\root_key.pem ^
	-out certs\root.pem >NUL
::	-verbose >NUL

	:: Check Err
	if %errorlevel% GTR 0 ( goto SetError )

:: DEBUG
@echo %CD%
@echo openssl x509 -text -in certs\root.pem -out certs\root.txt

:: Output information to text file
@openssl x509 -text -in certs\root.pem ^
	-out certs\root.txt

	:: Check Err
	if %errorlevel% GTR 0 ( goto SetError )

:: We're done - Everything works so far...
cd ..
goto :eof

:SetError
echo ERROR: Creating Certificate Authority
pause >nul 
set GlobalErrorState=1
goto :eof
