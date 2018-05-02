param(
 [string]
 $servicepulsePath = "C:\Program Files (x86)\Particular Software\ServicePulse\ServicePulse.Host.exe",
 
 [string]
 $iisPath = "C:\Particular"
)

$website = "IIS:\Sites\Default Web Site\";

function ConfigureReverseProxy(){
    param(
    [string]
    $subDir,

    [string]
    $port,

    [string]
    $pathToIIsServicePulse
    )

    $url = "http://localhost:$port/$subDir/";
    $constantsPath = "$pathToIIsServicePulse\js\app.constants.js";
            
    if ($subDir.equals("monitoring")) {
        $url = "http://localhost:$port/";
        # small bug monitoring url isn't set after extraction
        (Get-Content $constantsPath) -replace "monitoring_urls: \[''\]", "monitoring_urls: ['/$subDir']" | out-file $constantsPath;
    }
    else {
        (Get-Content $constantsPath) -replace $url, "/$subDir" | out-file $constantsPath;
    }
    
    md -force "$pathToIIsServicePulse\$subDir";

    $reverseProxyXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
	<system.webServer>
		<rewrite>
			<rules>
				<rule name="ReverseProxyInboundRuleFor$subDir"
                      stopProcessing="true">
					<match url="(.*)" />
					<action type="Rewrite"
                            url="$url{R:1}" />
				</rule>
			</rules>
		</rewrite>
	</system.webServer>
</configuration>
"@;

    New-Item -Path "$pathToIIsServicePulse\$subDir" -Name "web.config" -ItemType file -value $reverseProxyXml -Force;
}

function SetMimeType() {
    param(
    [string]
    $ext,

    [string]
    $mimeType
    )

    if (!(Get-WebConfigurationProperty $website -Filter system.webServer/staticContent -Name collection[fileExtension="$ext"])) 
    { 
        Add-WebConfigurationProperty $website -Filter system.webServer/staticContent -Name "." -Value @{fileExtension='$ext';mimeType='$mimeType'};
    }
}

$servicepulseAppName = "ServicePulse";

$pathToIIsServicePulse = "$iisPath\$servicepulseAppName";

# Extract the files from the installed servicepulse windows service
& $servicepulsePath --extract --outPath=$pathToIIsServicePulse;

# Change the servicecontrol api url in the app.constants.js
ConfigureReverseProxy api 33333 $pathToIIsServicePulse;

# Change the servicecontrol monitoring url in the app.constants.js
ConfigureReverseProxy monitoring 33633 $pathToIIsServicePulse;

Import-Module WebAdministration
Set-ItemProperty $website -name physicalPath -value $pathToIIsServicePulse;

SetMimeType ".eot" "application/vnd.ms-fontobject";
SetMimeType ".ttf" "application/octet-stream";
SetMimeType ".svg" "image/svg+xml";
SetMimeType ".woff" "application/font-woff";
SetMimeType ".woff2" "application/font-woff2";

iisreset;