# deploy_to_remote.ps1
# Deploy the remote_setup folder to a remote runner and restart the service.
# Usage: .\deploy_to_remote.ps1 -RemoteHost "remote-ip" -RemotePath "C:\path\to\remote"

param(
    [Parameter(Mandatory=$true)]
    [string]$RemoteHost,

    [Parameter(Mandatory=$true)]
    [string]$RemotePath,

    [string]$ServiceName = "riko-agent",

    [string]$LocalPath = $PSScriptRoot + "\..\remote_setup",  # Deploy the remote_setup folder

    [switch]$UseSCP  # If true, use scp (requires OpenSSH); else use Copy-Item (for local network)
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying remote_setup to $RemoteHost at $RemotePath..."

if ($UseSCP) {
    # Assume scp is available
    $source = "$LocalPath\*"
    $dest = "$RemoteHost`:$RemotePath"
    scp -r $source $dest
} else {
    # For local network
    $source = "$LocalPath\*"
    $dest = "\\$RemoteHost\$RemotePath"
    Copy-Item -Path $source -Destination $dest -Recurse -Force
}

Write-Host "Files copied. Starting agent on remote..."

# Start the agent remotely (assumes PowerShell remoting)
Invoke-Command -ComputerName $RemoteHost -ScriptBlock {
    param($RemotePath)
    cd $RemotePath
    Start-Process -FilePath ".\install_remote.bat" -NoNewWindow
} -ArgumentList $RemotePath

Write-Host "Deployment complete. Remote agent should be starting."