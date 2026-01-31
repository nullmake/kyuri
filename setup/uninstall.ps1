# Requires -Version 5.1

# 1. Check for Administrator privileges
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $currentPrincipal.IsInRole($adminRole)) {
    Write-Error "This script must be run as an Administrator."
    exit
}

$TaskName = "Kyuri_AutoStart"

# 2. Check if the task exists and unregister it
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "--------------------------------------------------"
    Write-Host "Success: Unregistered '$TaskName' from Task Scheduler."
    Write-Host "--------------------------------------------------"
} else {
    Write-Host "Task '$TaskName' not found. Nothing to remove."
}
