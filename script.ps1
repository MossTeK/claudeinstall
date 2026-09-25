$installer = "C:\Users\Public\ClaudeSetup.exe"
$url = "https://downloads.claude.ai/releases/win32/x64/1.44121.2/Claude-817a7b4563855a33d4b678faefc71f87554445d8.exe"

if (!(Test-Path $installer)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile$installer -UseBasicParsing
}

$activeKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\AnthropicClaude"
if (!(Test-Path $activeKey)) {
    New-Item -Path $activeKey -Force | Out-Null
}
Set-ItemProperty -Path $activeKey -Name "StubPath" -Value "cmd.exe /c if not exist `"%LocalAppData%\Programs\Claude\Claude.exe`" `"$installer`" /S" -Force
Set-ItemProperty -Path $activeKey -Name "Version" -Value "1,44121,2" -Force
Set-ItemProperty -Path $activeKey -Name "ComponentID" -Value "Claude Desktop" -Force

$loggedUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName
if ($loggedUser) {
    $action = New-ScheduledTaskAction -Execute$installer -Argument "/S"
    Register-ScheduledTask -TaskName "InstallClaudeTemp" -Action $action -User$loggedUser -Force | Out-Null
    Start-ScheduledTask -TaskName "InstallClaudeTemp"
    Start-Sleep -Seconds 15
    Unregister-ScheduledTask -TaskName "InstallClaudeTemp" -Confirm:$false
    Write-Output "Installed for active user ($loggedUser). Configured Active Setup for all other profiles."
} else {
    Write-Output "No active user session. Active Setup configured for next user logon."
}
