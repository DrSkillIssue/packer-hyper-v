[CmdletBinding()]
Param (
)

#region Functions
<#
.SYNOPSIS
    Writes a message to the console and/or log file.
.DESCRIPTION
    Writes a message to the console and/or log file.

    A log file will be placed at the following location:
        C:\Windows\Temp\packer_bootstrap.log
.PARAMETER Message
    The message to write.
.PARAMETER Level
    The level of the message.

    Valid values are DBG, VRB, INF, WRN, or ERR.
.PARAMETER Step
    The step the message is associated with.
.PARAMETER LogOnly
    Specifies if the message should only be written to the log file.
.EXAMPLE
    Write-Log -Message "This is a message." -Level INF -Step "Example"
    Writes an informational message to the console and log file.
.INPUTS
    None
.OUTPUTS
    None
#>
function Write-Log
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("DBG", "VRB", "INF", "WRN", "ERR")]
        [String]$Level,

        [Parameter(Mandatory = $true, Position = 2)]
        [String]$Step,

        [Parameter(Mandatory = $false)]
        [Switch]$LogOnly
    )

    [String]$LogDirectory = Join-Path -Path $ENV:SystemRoot -ChildPath "Temp"
    [String]$LogPath = Join-Path -Path $LogDirectory -ChildPath "packer_bootstrap.log"

    # Example: 2024-06-08 17:19:46
    [String]$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    [String]$LogMessage = ("[{0}] [{1}] [{2}] - {3}" -f $Date, $Level, $Step, $Message)

    if (-not $LogOnly)
    {

        switch ($Level)
        {
            "DBG"
            {
                Write-Debug -Message $LogMessage
                break
            }
            "VRB"
            {
                Write-Verbose -Message $LogMessage
                break
            }
            "INF"
            {
                Write-Information -MessageData $LogMessage
                break
            }
            "WRN"
            {
                Write-Warning -Message $LogMessage
                break
            }
            "ERR"
            {
                # Override error to prevent accidental termination.
                Write-Warning -Message $LogMessage
                break
            }
        }

        $LogMessage | Out-File -FilePath $LogPath -Append
    }
    else
    {
        $LogMessage | Out-File -FilePath $LogPath -Append
    }
}

<#
.SYNOPSIS
    Updates the network profile of all network connections to specified Category.
.DESCRIPTION
    Updates the network profile of all network connections to specified Category.

    Category:
        0 - Public
        1 - Private
        2 - DomainAuthenticated
.PARAMETER Category
    The category to set the network profile to.

    Valid values are 0, 1, or 2.
.EXAMPLE
    Update-NetworkProfile -Category 1
    Updates the network profile of all network connections to Private.
.INPUTS
    None
.OUTPUTS
    None
#>
function Update-NetworkProfile
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 2)]
        [Int32]$Category
    )

    Begin
    {
        Write-Log -Message "Start - Updating Network Profiles." -Level INF -Step "Update-NetworkProfile"

        # Specifies the name of the provided Category.
        [String]$CategoryName = "Public"

        # Update CategoryName based on Category.
        if ($Category -eq 1)
        {
            $CategoryName = "Private"
        }
        else
        {
            $CategoryName = "DomainAuthenticated"
        }
    
        Write-Log -Message ("Category '{0}' selected." -f $CategoryName) -Level DBG -Step "Update-NetworkProfile"

        # Specifies the CLSID for the Network List Manager
        $NLMID = [Guid]::Parse("DCB00C01-570F-4A9B-8D69-199FDBA5723B")
    }
    
    Process
    {
        # Specifies the ComObject generated from the CLSID.
        Write-Log -Message "Generating ComObject via CLSID." -Level DBG -Step "Update-NetworkProfile"
        $ComObject = [Type]::GetTypeFromCLSID($NLMID)

        # Initialize the Network List Manager via ComObject.
        Write-Log -Message "Initialize the Network List Manager via ComObject." -Level DBG -Step "Update-NetworkProfile"
        $NetworkListManager = [Activator]::CreateInstance($ComObject)

        # Retrieve all connections from initialized Network List Manager.
        Write-Log -Message "Retrieve all connections from Network List Manager." -Level DBG -Step "Update-NetworkProfile"
        $Connections = $NetworkListManager.GetNetworkConnections()

        # Return - No Connections.
        if (-not $Connections)
        {
            Write-Log -Message "Connection Profiles not found." -Level WRN -Step "Update-NetworkProfile"
            return
        }

        Write-Log -Message ("Updating Network Profiles to Category '{0}'." -f $CategoryName) -Level VRB -Step "Update-NetworkProfile"

        # Set network location to Private
        $Connections | ForEach-Object {
            Write-Log -Message (
                "{0} - Setting network connection '{1}' to Category '{2}'." -f $MyInvocation.MyCommand.Name, $_.GetNetwork().GetName(), $Category
            ) -Level VRB -Step "Update-NetworkProfile"

            $_.GetNetwork().SetCategory($Category)
        }
    }

    End
    {
        Write-Log -Message "Finished - Updating Network Profiles." -Level INF -Step "Update-NetworkProfile"
    }
}

Function Enable-WinRM
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("HTTP", "HTTPS")]
        [String]$Protocol
    )
    
    Begin
    {
        Write-Log -Message "Start - Enabling WinRM." -Level INF -Step "Enable-WinRM"
    }
    Process
    {
        Write-Log -Message "Enabling Http WinRM via 'Set-WSManQuickConfig'." -Level VRB -Step "Enable-WinRM"
        Set-WSManQuickConfig -Force

        # Basic Authentication is required for Packer.
        # If disabled, HTTPS will not work.
        $null = winrm set "winrm/config/service/auth" '@{Basic="true"}'

        if ($Protocol -eq "HTTPS")
        {
            Write-Log -Message "Creating Self-Signed Certificate for WinRM over HTTPS." -Level VRB -Step "Enable-WinRM"
            $Cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation "Cert:\LocalMachine\My"

            Write-Log -Message "Creating WinRM Listener for HTTPS." -Level VRB -Step "Enable-WinRM"
            $null = New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

            Write-Log -Message "Creating WinRM over HTTPS firewall rule." -Level VRB -Step "Enable-WinRM"
            
            # Specifies Parameter Splat for New-NetFirewallRule.
            [Hashtable]$NewFirewallRuleParams = @{
                DisplayName         = "Windows Remote Management (HTTPS-In)"
                Name                = "WINRM-HTTPS-In-TCP"
                Direction           = "Inbound"
                Action              = "Allow"
                Enabled             = "true"
                EdgeTraversalPolicy = "Block"
                Group               = "Windows Remote Management"
                LocalPort           = 5986
                Protocol            = "TCP"
                Profile             = "Private"
            }

            New-NetFirewallRule @NewFirewallRuleParams
        }

        Write-Log -Message "Enabling PowerShell Remoting via 'Enable-PSRemoting'." -Level VRB -Step "Enable-WinRM"
        Enable-PSRemoting -Force

        # Retrieve the WinRM service
        $Service = Get-Service -Name WinRM

        Write-Log -Message "Modifying WinRM Service to start automatically." -Level VRB -Step "Enable-WinRM"

        # Ensure the WinRM service is set to start automatically.
        if ($Service.StartType -ne "Automatic")
        {
            Write-Log -Message "Setting WinRM service to start automatically." -Level DBG -Step "Enable-WinRM"
            Set-Service -Name WinRM -StartupType Automatic
        }
        else
        {
            Write-Log -Message "WinRM service is already set to start automatically." -Level DBG -Step "Enable-WinRM"
        }

        Write-Log -Message "Restarting WinRM service." -Level VRB -Step "Enable-WinRM"

        # Ensure the WinRM service is running. If so, restart it.
        if ($Service.Status -ne "Running")
        {
            Write-Log -Message "WinRM service is not running. Starting." -Level DBG -Step "Enable-WinRM"
            Start-Service -Name WinRM
        }
        else
        {
            Write-Log -Message "WinRM service is already running. Restarting." -Level DBG -Step "Enable-WinRM"
            Restart-Service -Name WinRM -Force

            # Retrieve the WinRM service again.
            $Service = Get-Service -Name WinRM

            # Exit if the WinRM service is running.
            if ($Service.Status -eq "Running")
            {
                Write-Log -Message "WinRM service successfully restarted." -Level VRB -Step "Enable-WinRM"
                return
            }

            # Warning - WinRM service failed to restart.
            Write-Log -Message "WinRM service failed to restart. Trying again." -Level WRN -Step "Enable-WinRM"
            
            # Attempt to stop the WinRM service.
            Get-Service -Name WinRM | Stop-Service -Force -ErrorAction SilentlyContinue
            Get-Service -Name WinRM | Start-Service -ErrorVariable WinRMError

            # Error - WinRM service failed to restart.
            if ($WinRMError.Count -gt 0)
            {

                $Message = [System.Text.StringBuilder]::new()
                [Void] $Message.Append("WinRM service failed to restart. ")
                [Void] $Message.Append("Error: {0}" -f $WinRMError[0].ToString())

                Write-Log -Message $Message.ToString() -Level ERR -Step "Enable-WinRM"
                return
            }
        }
    }
    End
    {
        Write-Log -Message "Finished - Enabling WinRM." -Level INF -Step "Enable-WinRM"
    }
}

<#
.SYNOPSIS
    Disables password expiration for a specified account.
.DESCRIPTION
    Disables password expiration for a specified account.
.PARAMETER Username
    The username of the account to disable password expiration for.
.EXAMPLE
    Disable-PasswordExpiration -Username "Administrator"

    Disables password expiration for the Administrator account.
.INPUTS
    None
.OUTPUTS
    None
#>
function Disable-PasswordExpiration
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$Username
    )
    
    Begin
    {
        Write-Log -Message "Start - Disabling Password Expiration." -Level INF -Step "Disable-PasswordExpiration"
    }
    Process
    {
        
        Write-Log -Message ("Retrieving Account '{0}'." -f $Username) -Level VRB -Step "Disable-PasswordExpiration"

        [String]$Query = "SELECT * FROM Win32_UserAccount WHERE Name = '$Username' AND LocalAccount = 'True'"
        [CimInstance]$Account = Get-CimInstance -Query $Query

        # Warning - Account not found.
        if (-not $Account)
        {
            Write-Log -Message ("Account '{0}' not found." -f $Username) -Level WRN -Step "Disable-PasswordExpiration"
            return
        }

        # Return - Password does not expire.
        if ($Account.PasswordExpires -eq $false)
        {
            Write-Log -Message ("Password Expiration is already disabled for '{0}'." -f $Username) -Level VRB -Step "Disable-PasswordExpiration"
            return
        }

        # Disable Password Expiration.
        Write-Log -Message ("Disabling Password Expiration for '{0}'." -f $Username) -Level VRB -Step "Disable-PasswordExpiration"
        $Account | Set-CimInstance -Arguments @{PasswordExpires = 0 }

        if (($Account | Get-CimInstance).PasswordExpires -eq $false)
        {
            Write-Log -Message ("Password Expiration successfully disabled for '{0}'." -f $Username) -Level VRB -Step "Disable-PasswordExpiration"
            return
        }
        else
        {
            Write-Log -Message ("Failed to disable Password Expiration for '{0}'." -f $Username) -Level ERR -Step "Disable-PasswordExpiration"
            return
        }
    }
    End
    {
        Write-Log -Message "Finished - Disabling Password Expiration." -Level INF -Step "Disable-PasswordExpiration"
    }
}
#endregion Functions

# Set PowerShell Preferences
$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Update network interfaces to use Private network profile.
# Private network profile is required for WinRM.
Update-NetworkProfile -Category 1

# Disable Password Expiration for Administrator.
# Typically, this is already configured.
Disable-PasswordExpiration -Username "Administrator"

# Enable WinRM over HTTPs.
Enable-WinRM -Protocol HTTPS