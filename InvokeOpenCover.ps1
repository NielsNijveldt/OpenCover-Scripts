param(
    [Parameter(Mandatory=$true, Position = 0, HelpMessage = 'openCoverScriptPath must be set')]
    [string] $openCoverScriptPath,
    [Parameter(Mandatory=$true, Position = 1, HelpMessage = 'applicationName must be set')]
    [string] $applicationName,
    [Parameter(Mandatory=$true, Position = 2, HelpMessage = 'openCoverConsoleExecutablePath must be set')]
    [string] $openCoverConsoleExecutablePath,
    [Parameter(Mandatory=$true, Position = 3, HelpMessage = 'targetDir must be set')]
    [string] $targetDir,
    [Parameter(Mandatory=$true, Position = 4, HelpMessage = 'outputFileDir must be set')]
    [string] $outputFileDir,
    [Parameter(Mandatory=$true, Position = 5, HelpMessage = 'serverName must be set')]
    [string] $serverName,
    [Parameter(Mandatory=$true, Position = 6, HelpMessage = 'userName must be set')]
    [string] $userName,
    [Parameter(Mandatory=$true, Position = 7, HelpMessage = 'password must be set')]
    [string] $password,
    [Parameter(Mandatory=$true, Position = 8, HelpMessage = 'warmupRequestUrl must be set')]
    [string] $warmupRequestUrl
)

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword

Invoke-Command -ComputerName $serverName -Credential $credential -InDisconnectedSession -ScriptBlock {
    $scriptPath = $args[0]

    # Check if scriptPath exists, else throw error
    if(-not ($scriptPath | Test-Path)){
        Write-Error -Message "No path found for $scriptPath" -ErrorAction Stop
    }

    & "$scriptPath\StartOpenCover.ps1" -applicationName $args[1] -openCoverConsoleExecutablePath $args[2] -targetDir $args[3] -outputFileDir $args[4] -warmupRequestUrl $args[5]
} -ArgumentList $openCoverScriptPath, $applicationName, $openCoverConsoleExecutablePath, $targetDir, $outputFileDir, $warmupRequestUrl