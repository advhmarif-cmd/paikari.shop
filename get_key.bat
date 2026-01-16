keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android > sha1.txt 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Failed to find keytool or keystore > sha1.txt
  echo %ERRORLEVEL% >> sha1.txt
)
