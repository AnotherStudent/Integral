rem Delete old release
del "Integral.zip" /q

rem Create Release archive
set Zip=../7za.exe

cd App

"%Zip%" a "../Integral.zip" "Integral.exe" "MathParserDll.dll" -ssw

exit