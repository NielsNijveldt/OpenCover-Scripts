param(
      [Parameter(Mandatory=$true, Position = 0, HelpMessage = 'applicationName must be set')]
      [string] $applicationName
)
# Get w3wp.exe process created by the StartOpenCover.ps1
$process = Get-WmiObject Win32_Process |
           Where-Object { $_.Name -eq "w3wp.exe" -and $_.CommandLine -eq """$env:SystemRoot\System32\inetsrv\w3wp.exe"" -debug" } | 
           Select-Object ProcessID

if ($null -ne $process) {
    Write-Output "Found " $process.ProcessID
} else {
    Write-Error -Message "No w3wp process found for opencover" -ErrorAction Stop
}

$processes = Get-Process | Where-Object { $_.Id -eq $process.ProcessID }

if ($null -eq $processes -or $null -eq $processes[0]) {
    Write-Error -Message "No w3wp process found for Id $process.ProcessID" -ErrorAction Stop
}

if ($processes.Length -gt 1) {
    Write-Error -Message "More w3wp processes found for Id $process.ProcessID then expected" -ErrorAction Stop
}

# Kill w3wp process, not the OpenCover process!
$processes[0].Kill()

# Wait for a couple of seconds for opencover to wrap up and then restart IIS site
Start-Sleep -s 30
Write-Output "OpenCover is stopped"

& "$env:SystemRoot\System32\inetsrv\appcmd.exe" start site /site.name:$applicationName
Write-Output "IIS Website is started for $applicationName"