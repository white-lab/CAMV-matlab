set "curpath=%cd%"
set "PROWIZ=%curpath%\ProteoWizard32"
set "TARGET=%curpath%\ProteoWizard"
set "MSI=%curpath%\pwiz-setup-3.0.9205-x86.msi"
:: Taken from http://proteowizard.sourceforge.net/downloads.shtml
set "URL=https://www.dropbox.com/s/q7wabxjlhy1uqd9/pwiz-setup-3.0.9205-x86.msi?dl=1"

del "%MSI%"
rmdir /S /Q "%PROWIZ%"
rmdir /S /Q "%TARGET%"

bitsadmin.exe /transfer "ProteoWizard" "%URL%" "%MSI%"

msiexec /a "%MSI%" /qb TARGETDIR="%PROWIZ%"

echo d | xcopy "%PROWIZ%\PFiles\ProteoWizard" "%TARGET%" /E /Y

rmdir /S /Q "%PROWIZ%"
if exist "%PROWIZ%": rmdir /S /Q "%PROWIZ%"
del "%MSI%"
