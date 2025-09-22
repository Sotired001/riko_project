```powershell
# deploy_to_agent.ps1
# Deploy the agent_setup folder to an agent runner and restart the service.
# Usage: .\deploy_to_agent.ps1 -AgentHost "agent-ip" -AgentPath "C:\path\to\agent"

param(
    [Parameter(Mandatory=$true)]
    [string]$AgentHost,

    [Parameter(Mandatory=$true)]
    [string]$AgentPath,

    [string]$ServiceName = "riko-agent",

    [string]$LocalPath = $PSScriptRoot + "\..\agent_setup",  # Deploy the agent_setup folder

    [switch]$UseSCP  # If true, use scp (requires OpenSSH); else use Copy-Item (for local network)
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying agent_setup to $AgentHost at $AgentPath..."

if ($UseSCP) {
    # Assume scp is available
    $source = "$LocalPath\*"
    $dest = "$AgentHost`:$AgentPath"
    scp -r $source $dest
} else {
    # For local network
    $source = "$LocalPath\*"
    $dest = "\\$AgentHost\$AgentPath"
    Copy-Item -Path $source -Destination $dest -Recurse -Force
}

Write-Host "Files copied. Starting agent on target..."

# Start the agent remotely (assumes PowerShell remoting)
Invoke-Command -ComputerName $AgentHost -ScriptBlock {
    <#
    deploy_to_agent.ps1
    Deploy the agent_setup folder to an agent runner and restart the service.
    Usage: .\deploy_to_agent.ps1 -AgentHost "agent-ip" -AgentPath "C:\path\to\agent"
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$AgentHost,

        [Parameter(Mandatory=$true)]
        [string]$AgentPath,

        [string]$ServiceName = "riko-agent",

        [string]$LocalPath = Join-Path $PSScriptRoot "..\agent_setup",  # Deploy the agent_setup folder

        [switch]$UseSCP  # If true, use scp (requires OpenSSH); else use Copy-Item (for local network)
    )

    $ErrorActionPreference = "Stop"

    Write-Host "Deploying agent_setup to $AgentHost at $AgentPath..."

    if ($UseSCP) {
        # Assume scp is available
        $source = Join-Path $LocalPath "*"
        $dest = "$AgentHost`:$AgentPath"
        scp -r $source $dest
    } else {
        # For local network
        $source = Join-Path $LocalPath "*"
        $dest = "\\$AgentHost\$AgentPath"
        Copy-Item -Path $source -Destination $dest -Recurse -Force
    }

    Write-Host "Files copied. Starting agent on target..."

    # Start the agent remotely (assumes PowerShell remoting)
    Invoke-Command -ComputerName $AgentHost -ScriptBlock {
        param($AgentPath)
        Set-Location -Path $AgentPath
        Start-Process -FilePath ".\install_agent.bat" -NoNewWindow
    } -ArgumentList $AgentPath

    Write-Host "Deployment complete. Agent should be starting."
