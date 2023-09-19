
$Shutdown = $True
$sysprepPath  = "C:\Windows\System32\Sysprep\Sysprep.exe"
$rootPath = "C:\Users\Administrator\Desktop"

# Packer copies the windows/scripts folder on the desktop with the Sysprep-Unattend file inside
$answerFilePath = (Join-Path $rootPath -ChildPath "scripts\Sysprep-WinServer2022.xml") 

# Finally, perform sysprep.
if ($Shutdown)
{
  Start-Process -FilePath $sysprepPath -ArgumentList ("/oobe /shutdown /generalize `"/unattend:{0}`" -f $answerFilePath") -Wait -NoNewWindow
}
else
{
  Start-Process -FilePath $sysprepPath -ArgumentList ("/oobe /quit /generalize `"/unattend:{0}`" -f $answerFilePath") -Wait -NoNewWindow
}
