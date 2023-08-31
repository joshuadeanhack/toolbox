
$NoShutdown = $False
$sysprepPath  = "C:\Windows\System32\Sysprep\Sysprep.exe"
$rootPath = "C:\Users\Administrator\Desktop"

#Make a folder on the desktop called Configure and place the Unattend inside
$answerFilePath = (Join-Path $rootPath -ChildPath "Configure\Unattend-simple-packer.xml") 

# Finally, perform sysprep.
if ($NoShutdown)
{
  Start-Process -FilePath $sysprepPath -ArgumentList ("/oobe /quit /generalize `"/unattend:{0}`" -f $answerFilePath") -Wait -NoNewWindow
}
else
{
  Start-Process -FilePath $sysprepPath -ArgumentList ("/oobe /shutdown /generalize `"/unattend:{0}`" -f $answerFilePath") -Wait -NoNewWindow
}
