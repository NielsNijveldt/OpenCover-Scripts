param(
    [Parameter(Mandatory=$true, Position = 0, HelpMessage = 'applicationName must be set')]
    [string] $applicationName,
    [Parameter(Mandatory=$true, Position = 1, HelpMessage = 'openCoverConsoleExecutablePath must be set')]
    [string] $openCoverConsoleExecutablePath,
    [Parameter(Mandatory=$true, Position = 2, HelpMessage = 'targetDir must be set')]
    [string] $targetDir,
    [Parameter(Mandatory=$true, Position = 3, HelpMessage = 'outputFileDir must be set')]
    [string] $outputFileDir,
    [Parameter(Mandatory=$true, Position = 4, HelpMessage = 'warmupRequestUrl must be set')]
    [string] $warmupRequestUrl
)

# Check if paths exists, else throw error
if(-not ($openCoverConsoleExecutablePath | Test-Path)){
    Write-Error -Message "No path found for $openCoverConsoleExecutablePath" -ErrorAction Stop
}
if(-not ($targetDir | Test-Path)){
    Write-Error -Message "No path found for $targetDir" -ErrorAction Stop
}
if(-not ($outputFileDir | Test-Path)){
    Write-Error -Message "No path found for $outputFileDir" -ErrorAction Stop
}

# Stop IIS for application
Stop-Website $applicationName

Start-Sleep -s 5

$sites = Get-Website | where {$_.Name -eq $applicationName}

# Wait until website is really stopped
if ($NULL -eq $sites -and $NULL -eq $sites[0])
{  
    while('Stopped' -ne $sites[0].State) {
        Start-Sleep -s 5
        $sites = Get-Website | where {$_.Name -eq $applicationName}
    }
}
Write-Output "IIS Website is stopped for $applicationName"

# When updating target arguments, don't forget to update StopOpenCover.ps1
$arguments = "-target:$env:SystemRoot\System32\inetsrv\w3wp.exe -targetargs:-debug -targetdir:$targetDir -output:$outputFileDir -filter:+[*]* -register:user"
Write-Output "Start process: $openCoverConsoleExecutablePath $arguments"

$process = New-Object System.Diagnostics.Process
$process.StartInfo.FileName = $openCoverConsoleExecutablePath
$process.StartInfo.Arguments = $arguments
$isStarted = $process.Start()

if ($isStarted) {
    Write-Output "OpenCover is starting"
} else {
    Write-Error -Message "OpenCover is not starting (correctly)" -ErrorAction Stop
}

# Invoke web requests until the application is really started
$isStarted = $false;
while(!$isStarted){
    try {
        Start-Sleep -s 20
        Write-Host "Check if application is running"
        Invoke-WebRequest -URI $warmupRequestUrl
    }
    catch {
        # Check for 401, because that's the right state when not logged in (This check can be improved in the future)
        $isStarted = $_.Exception.Message.Contains("401")
    }
}

Write-Host "The application is running"