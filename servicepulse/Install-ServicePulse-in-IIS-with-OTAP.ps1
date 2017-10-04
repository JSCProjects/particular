param(
 [Parameter(Mandatory=$True)]
 [ValidateSet("dev", "tst", "acc", "prd")]
 [string]
 $environment = "dev",

 [string]
 $servicepulsePath = "C:\Program Files (x86)\Particular Software\ServicePulse\ServicePulse.Host.exe",
 
 [string]
 $iisPath = "F:\Particular"
)

$environment = $environment.ToLowerInvariant();

# Stop the current ServicePulse windows service
sc stop "Particular ServicePulse";

$portNumber = 33333;
switch ($environment)
{
    "dev" { $portNumber = 33333; }
    "tst" { $portNumber = 33334; }
    "acc" { $portNumber = 33335; }
    "prd" { $portNumber = 33336; }
}
$serviceControlUri = "http://localhost:$portNumber/api/";

$servicepulseAppName = "servicepulse.$environment"

$pathToIIsServicePulse = "$iisPath\$servicepulseAppName";

# Extract the files from the installed servicepulse windows service
& $servicepulsePath --extract --outPath=$pathToIIsServicePulse

# Change the servicecontrol api url in the app.constants.js
$constantsPath = "$pathToIIsServicePulse\js\app.constants.js";
(Get-Content $constantsPath) -replace "http://localhost:33333/api/", $serviceControlUri | out-file $constantsPath

# Start IIS Configuration
Import-Module WebAdministration;
$appPath = "IIS:\Sites\Default Web Site\";

# Create IIS ApplicationPool
if((Test-Path IIS:\AppPools\$servicepulseAppName) -eq 0)
{
    New-WebAppPool -Name $servicepulseAppName -Force;
}

# Create IIS WebApplication
if((Get-WebApplication -Name $servicepulseAppName) -eq $null)
{  
    New-WebApplication -Name $servicepulseAppName -ApplicationPool $servicepulseAppName -Site "Default Web Site" -PhysicalPath $pathToIIsServicePulse;
}
else
{
    echo "$servicepulseAppName already exists";
}