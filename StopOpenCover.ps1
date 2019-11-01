param(
      [Parameter(Mandatory=$true, Position = 0, HelpMessage = 'applicationName must be set')]
      [string] $applicationName,
      [Parameter(Mandatory=$true, Position = 1, HelpMessage = 'serverName must be set')]
      [string] $serverName,
      [Parameter(Mandatory=$true, Position = 2, HelpMessage = 'userName must be set')]
      [string] $userName,
      [Parameter(Mandatory=$true, Position = 3, HelpMessage = 'password must be set')]
      [string] $password,
      [Parameter(Mandatory=$true, Position = 4, HelpMessage = 'outputFolder must be set')]
      [string] $outputFolder,
      [Parameter(Mandatory=$true, Position = 5, HelpMessage = 'buildServerFolder must be set')]
      [string] $buildServerFolder
)

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
$session = New-PSSession $serverName -Credential $credential

Invoke-Command -Session $session -ScriptBlock {
    $applicationName = $args[0]
    $outputFolder = $args[1]

    # Check if paths exists, else throw error
    if(-not ($outputFolder | Test-Path)){
        Write-Error -Message "No path found for $outputFolder" -ErrorAction Stop
    }

    # Get w3wp.exe process created by the StartOpenCover.ps1
    Write-Output "About to search for a w3wp.exe process with CommandLine ""$env:SystemRoot\System32\inetsrv\w3wp.exe"" -debug"
    $process = Get-WmiObject Win32_Process |
               Where-Object { $_.Name -eq "w3wp.exe" -and $_.CommandLine -eq """$env:SystemRoot\System32\inetsrv\w3wp.exe"" -debug" } | 
               Select-Object ProcessID

    if ($null -ne $process) {
        Write-Output "Found a w3wp process with ID:" $process.ProcessID
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

    Start-Website $applicationName
    Write-Output "IIS Website is started for $applicationName"

} -ArgumentList $applicationName, $outputFolder

Write-Output "Copy from $outputFolder to $buildServerFolder"
Copy-Item $outputFolder -Destination $buildServerFolder -FromSession $session -Recurse