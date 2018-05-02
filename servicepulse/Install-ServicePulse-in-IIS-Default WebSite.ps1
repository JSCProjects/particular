param(
 [string]
 $servicepulsePath = "C:\Program Files (x86)\Particular Software\ServicePulse\ServicePulse.Host.exe",
 
 [string]
 $iisPath = "C:\Particular"
)

# Stop the current ServicePulse windows service
sc stop "Particular ServicePulse";

$portNumber = 33333;

$servicepulseAppName = "ServicePulse"
$serviceControlUri = "/api";

$pathToIIsServicePulse = "$iisPath\$servicepulseAppName";

# Extract the files from the installed servicepulse windows service
& $servicepulsePath --extract --outPath=$pathToIIsServicePulse

# Change the servicecontrol api url in the app.constants.js
$constantsPath = "$pathToIIsServicePulse\js\app.constants.js";
(Get-Content $constantsPath) -replace "http://localhost:33333/api/", $serviceControlUri | out-file $constantsPath

Import-Module WebAdministration
Set-ItemProperty 'IIS:\Sites\Default Web Site\' -name physicalPath -value $pathToIIsServicePulse