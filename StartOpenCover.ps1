param(
    [Parameter(Mandatory=$true, Position = 0, HelpMessage = 'applicationName must be set')]
    [string] $applicationName,
    [Parameter(Mandatory=$true, Position = 1, HelpMessage = 'openCoverConsoleExecutablePath must be set')]
    [string] $openCoverConsoleExecutablePath,
    [Parameter(Mandatory=$true, Position = 2, HelpMessage = 'targetDir must be set')]
    [string] $targetDir,
    [Parameter(Mandatory=$true, Position = 3, HelpMessage = 'oututFileDir must be set')]
    [string] $oututFileDir
)

& "$env:SystemRoot\System32\inetsrv\appcmd.exe" stop site /site.name:$applicationName
Write-Output "IIS Website is stopped for $applicationName"

Start-Sleep -s 5

# When updating target arguments, don't forget to update StopOpenCover.ps1
$arguments = "-target:$env:SystemRoot\System32\inetsrv\w3wp.exe -targetargs:-debug -targetdir:$targetDir -output:$oututFileDir -filter:+[*]* -register:user"
Write-Output "Start process: $openCoverConsoleExecutablePath $arguments"

$process = New-Object System.Diagnostics.Process
$process.StartInfo.FileName = $openCoverConsoleExecutablePath
$process.StartInfo.Arguments = $arguments
$isStarted = $process.Start()

if ($isStarted) {
    Write-Output "OpenCover is running"
} else {
    Write-Error -Message "OpenCover is not running (correctly)" -ErrorAction Stop
}