function Invoke-Reboot {
<#
.SYNOPSIS
Reboots the local machine ensuring Boxstarter restarts 
automatically after reboot and sets up autologon if it a 
password was provided.

.DESCRIPTION
Use this command inside of a boxstarter package instead 
of calling Restart-Computer

This command will often be used with the Test-PendingReboot
command. If Test-PendingReboot returns true, one may want 
to call Invoke-Reboot to restart otherwise the remainder of 
the package might fail.

.NOTES
One can use the $Boxstarter variable's RebootOk to enable/disable
reboots. If this is set to $False (the default) then Invoke-Reboot
will not do anything. If Boxstarter was invoked with the -RebootOk
parameter $Boxstarter.RebootOk is set to True.

.LINK
http://boxstarter.org
Test-PendingReeboot
Invoke-Boxstarter
about_boxstarter_bootstrapper
about_boxstarter_variable_in_bootstrapper
#>
    if(!$Boxstarter.RebootOk) { 
        Write-BoxstarterMessage "A Reboot was requested but Reboots are suppressed. Either call Invoke-Boxstarter with -RebootOk or set `$Boxstarter.RebootOk to `$true"
        return 
    }
    if(!(Get-IsRemote -PowershellRemoting) -and !($Boxstarter.DisableRestart)){
        Write-BoxstarterMessage "writing restart file"
        New-Item "$(Get-BoxstarterTempDir)\Boxstarter.script" -type file -value $boxstarter.ScriptToCall -force | Out-Null
        $startup = "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup"
        $restartScript="Call PowerShell -NoProfile -ExecutionPolicy bypass -command `"Import-Module '$($Boxstarter.BaseDir)\Boxstarter.Bootstrapper\boxstarter.bootstrapper.psd1';Invoke-Boxstarter -RebootOk -NoPassword:`$$($Boxstarter.NoPassword.ToString())`""
        New-Item "$startup\boxstarter-post-restart.bat" -type file -force -value $restartScript | Out-Null
    }
    try {
        if(Get-Module Bitlocker -ListAvailable){
            Get-BitlockerVolume | ? {$_.ProtectionStatus -eq "On"  -and $_.VolumeType -eq "operatingSystem"} | Suspend-Bitlocker -RebootCount 1 | out-null
        }
    }
    catch {} # There are several reports of the bitlocker module throwing errors
    $Boxstarter.IsRebooting=$true
    Restart
}

function Restart {
    exit
}
