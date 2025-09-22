# vm_checks.ps1
# Run this in PowerShell on the host to verify VirtualBox, VM running state, VRDE and Guest Additions

function Write-Ok($s) { Write-Host "[OK]    $s" -ForegroundColor Green }
function Write-Warn($s) { Write-Host "[WARN]  $s" -ForegroundColor Yellow }
function Write-Err($s) { Write-Host "[ERROR] $s" -ForegroundColor Red }

Write-Host "=== Riko VM Visibility & Connectivity Checks ==="

# Check VBoxManage availability
try {
    $vbox = & VBoxManage --version 2>$null
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage not found" }
    Write-Ok "VBoxManage found: $vbox"
} catch {
    Write-Err "VBoxManage not found. Ensure VirtualBox is installed and VBoxManage is on PATH."
    exit 2
}

# List VMs and check for a Windows VM (by name pattern)
$vmList = & VBoxManage list vms
if (-not $vmList) {
    Write-Warn "No VMs registered in VirtualBox."
} else {
    Write-Ok "Registered VMs:"
    $vmList | ForEach-Object { Write-Host "  $_" }
}

# Try to find a VM named like 'Riko-Desktop' or 'Windows' or similar
$searchNames = @("Riko-Desktop", "Windows", "Win11", "Riko")
$foundVM = $null
foreach ($name in $searchNames) {
    $match = $vmList | Where-Object { $_ -match [regex]::Escape($name) }
    if ($match) { $foundVM = $match; break }
}

if (-not $foundVM) {
    Write-Warn "Could not auto-detect a VM with typical names (Riko-Desktop/Windows/Win11). Specify a VM name to inspect:"
    Write-Host "Usage: .\vm_checks.ps1 -VMName 'Your VM Name'"
    return 0
}

# Extract VM name and UUID from the vboxmanage output string: "\"Name\" {uuid}"
if ($foundVM -match '"(?<name>.+)"\s+{(?<uuid>[0-9a-f-]+)}') {
    $vmName = $matches['name']
    $vmUUID = $matches['uuid']
    Write-Ok "Found VM: $vmName ($vmUUID)"
} else {
    Write-Warn "Unable to parse VM name/UUID from: $foundVM"
    return 0
}

# Check VM running state
$running = & VBoxManage list runningvms
if ($running -match [regex]::Escape($vmName)) {
    Write-Ok "VM is currently running."
} else {
    Write-Warn "VM is not running. You may need to start it with: VBoxManage startvm \"$vmName\" --type gui"
}

# Check VRDE (Agent Display) and Guest Additions status
try {
    $vminfo = & VBoxManage showvminfo "$vmName" --machinereadable
    if ($vminfo) {
        # VRDE
        if ($vminfo -match 'vrde="(?<vrde>.+)"') {
            $vrde = $matches['vrde']
                if ($vrde -eq 'off') { Write-Warn "VRDE (agent display) is off. Enable if you need agent access." } else { Write-Ok "VRDE: $vrde" }
        }

        # Guest Additions detected via GuestAdditionsRunLevel or GuestAdditionsVersion
        if ($vminfo -match 'GuestAdditionsVersion="(?<gav>.*)"') {
            Write-Ok "Guest Additions version: $($matches['gav'])"
        } elseif ($vminfo -match 'GuestAdditionsRunLevel') {
            Write-Ok "Guest Additions runlevel detected (likely installed)"
        } else {
            Write-Warn "Guest Additions not detected in VM info. Install Guest Additions inside the VM for better integration." 
        }
    }
} catch {
    Write-Warn "Failed to get VM info via VBoxManage: $_"
}

Write-Host "\n== Suggested next steps =="
Write-Host "1) If VM is not running: VBoxManage startvm \"$vmName\" --type gui"
Write-Host "2) If Guest Additions are missing: Start the VM and install VirtualBox Guest Additions from the VM menu (Devices -> Insert Guest Additions CD image)."
Write-Host "3) For programmatic GUI control from host: consider enabling VRDE or use guest-to-host file exchange and run agents inside the guest (recommended)."
Write-Host "4) After Guest Additions installed, verify that the VM appears in `VBoxManage list runningvms` and RDP/VRDE is available if needed."

Write-Host "\nFinished checks. If you want, run this script with -VMName 'Exact VM Name' to inspect a specific VM." 
