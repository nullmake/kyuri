# Requires -Version 5.1

# 1. Check for Administrator privileges
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $currentPrincipal.IsInRole($adminRole)) {
    Write-Error "This script must be run as an Administrator."
    exit
}

# 2. Define paths
$ProjectRoot = (Get-Item $PSScriptRoot).Parent.FullName
$ScriptPath = Join-Path $ProjectRoot "source\App.ahk"
$TaskName = "Kyuri_AutoStart"

# 3. Get AutoHotkey execution path (Scoop version)
$AhkExe = Get-Command autohotkey -ErrorAction SilentlyContinue |
          Select-Object -ExpandProperty Source

if (-not $AhkExe) {
    Write-Error "AutoHotkey not found. Please ensure it is installed via Scoop."
    exit
}

# 4. Define Task Action, Trigger, and Settings
$Action = New-ScheduledTaskAction -Execute $AhkExe -Argument "`"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit (New-TimeSpan -Hours 0)

# 5. Register or Update Task
Register-ScheduledTask -TaskName $TaskName `
                       -Action $Action `
                       -Trigger $Trigger `
                       -Settings $Settings `
                       -RunLevel Highest `
                       -Force

Write-Host "--------------------------------------------------"
Write-Host "Success: Registered '$TaskName' to Task Scheduler."
Write-Host "Executable: $AhkExe"
Write-Host "Target: $ScriptPath"
Write-Host "Kyuri will start automatically at next logon."
Write-Host "--------------------------------------------------"
