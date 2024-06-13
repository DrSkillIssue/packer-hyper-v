[Cmdletbinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [String]$OS,

    [Parameter(Mandatory = $false)]
    [String]$VMName,

    [Parameter(Mandatory = $true)]
    [String]$ISOUrl,

    [Parameter(Mandatory = $false)]
    [String]$IsoCHecksum = "None",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1048576)]
    [Alias("MemoryMB")]
    [UInt]$RamMB,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 64)]
    [UInt]$CPUs,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, [UInt]::MaxValue)]
    [UInt]$DiskSizeGB,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableDynamicMemory,

    [Parameter(Mandatory = $false)]
    [String]$SwitchName,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 4096)]
    [UInt]$SwitchVLANId,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 4096)]
    [UInt]$VlanId,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 2)]
    [UInt]$Generation = 2,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableSecureBoot,

    [Parameter(Mandatory = $false)]
    [ValidateSet("MicrosoftWindows", "MicrosoftUEFICertificateAuthority")]
    [String]$SecureBootTemplate = "MicrosoftWindows",

    [Parameter(Mandatory = $false)]
    [Switch]$EnableVirtualizationExtensions,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableMACAddressSpoofing,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableTPM,

    [Parameter(Mandatory = $false)]
    [String[]]$IsoURLs,

    [Parameter(Mandatory = $false)]
    [String[]]$SecondaryIsoImages,

    [Parameter(Mandatory = $false)]
    [String]$IsoTargetPath,

    [Parameter(Mandatory = $false)]
    [String]$IsoTargetExtension,

    [Parameter(Mandatory = $false)]
    [String]$OutputDirectory,

    [Parameter(Mandatory = $false)]
    [Switch]$DisableShutdown,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableUseLegacyNetworkAdapter,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableDifferencingDisk,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableUseFixedVHDFormat,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 256)]
    [UInt]$DiskBlockSizeMIB = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(20, [UInt]::MaxValue)]
    [UInt[]]$DiskAdditionalSizeGB,

    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Attach")]
    [String]$GuestAdditionsMode = "None",

    [Parameter(Mandatory = $false)]
    [String]$GuestAdditionsPath,

    [Parameter(Mandatory = $false)]
    [String]$MACAddress,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableKeepRegistered,

    [Parameter(Mandatory = $false)]
    [String]$TempPath,

    [Parameter(Mandatory = $false)]
    [String]$ConfigurationVersion,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableSkipCompaction,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableSkipExport,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableHeadless,

    [Parameter(Mandatory = $false)]
    [String]$FirstBootDevice,

    [Parameter(Mandatory = $false)]
    [String]$BootOrder,

    [Parameter(Mandatory = $false)]
    [String]$ShutdownCommand,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1440)]
    [UInt]$ShutdownTimeoutMinutes = 5,

    [Parameter(Mandatory = $false)]
    [System.Collections.IDictionary]$CDContent,

    [Parameter(Mandatory = $false)]
    [String]$CDLabel,

    [Parameter(Mandatory = $false)]
    [ValidateSet("winrm", "ssh", "none")]
    [String]$Communicator = "winrm",

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 1440)]
    [Double]$PauseBeforeConnectingMinutes,

    [Parameter(Mandatory = $false)]
    [String]$WinrmUsername,

    [Parameter(Mandatory = $false)]
    [SecureString]$WinrmPassword,

    [Parameter(Mandatory = $false)]
    [pscredential]$RemoteCredentials,

    [Parameter(Mandatory = $false)]
    [String]$WinrmHost,

    [Parameter(Mandatory = $false)]
    [Switch]$EnableWinRMNoProxy,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [UInt]$WinrmPort = 5985,

    [Parameter(Mandatory = $false)]
    [Switch]$WinrmUseSSL,

    [Parameter(Mandatory = $false)]
    [Switch]$WinrmUseInsecure,

    [Parameter(Mandatory = $false)]
    [Switch]$WinrmUseNTLM,

    [Parameter(Mandatory = $false)]
    [String]$SSHHost,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [UInt]$SSHPort = 22,

    [Parameter(Mandatory = $false)]
    [String]$SSHUsername,

    [Parameter(Mandatory = $false)]
    [SecureString]$SSHPassword,

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "aes128-ctr",
        "aes192-ctr",
        "aes256-ctr",
        "aes128-gcm@openssh.com",
        "chacha20-poly1305@openssh.com",
        "arcfour256",
        "arcfour128",
        "aes128-cbc",
        "3des-cbc"
    )]
    [String[]]$SSHCiphers,

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "curve25519-sha256@libssh.org",
        "ecdh-sha2-nistp256",
        "ecdh-sha2-nistp384",
        "ecdh-sha2-nistp521",
        "diffie-hellman-group14-sha1",
        "diffie-hellman-group1-sha1"
    )]
    [String]$SSHKeyExchangeAlgorithms,

    [Parameter(Mandatory = $false)]
    [Switch]$SSHClearAuthorizedKeys,

    [Parameter(Mandatory = $false)]
    [String]$SSHCertificateFile,

    [Parameter(Mandatory = $false)]
    [Switch]$SSHEnablePty,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1440)]
    [UInt]$SSHTimeoutMinutes = 5,

    [Parameter(Mandatory = $false)]
    [Switch]$SSHDisableAgentForwarding,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 512)]
    [UInt]$SSHHandshakeAttempts = 10,

    [Parameter(Mandatory = $false)]
    [String]$SSHBastionHost,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [UInt]$SSHBastionPort = 22,

    [Parameter(Mandatory = $false)]
    [Switch]$SSHEnableBastionAgentAuth,

    [Parameter(Mandatory = $false)]
    [String]$SSHBastionUsername,

    [Parameter(Mandatory = $false)]
    [SecureString]$SSHBastionPassword,

    [Parameter(Mandatory = $false)]
    [Object]$SSHBastionPrivateKeyFile,

    [Parameter(Mandatory = $false)]
    [String]$SSHBastionCertificateFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("scp", "sftp")]
    [String]$SSHFileTransferMethod = "scp",

    [Parameter(Mandatory = $false)]
    [String]$SSHProxyHost,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [UInt]$SSHProxyPort = 1080,

    [Parameter(Mandatory = $false)]
    [String]$SSHProxyUsername,

    [Parameter(Mandatory = $false)]
    [SecureString]$SSHProxyPassword,

    [Parameter(Mandatory = $false)]
    [pscredential]$ProxyCredential,

    [Parameter(Mandatory = $false)]
    [ValidateRange(-1, 3600)]
    [Int]$SSHKeepAliveIntervalSeconds = 5,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 1440)]
    [UInt]$SSHReadWriteTimeoutMinutes = 0,

    [Parameter(Mandatory = $false)]
    [String[]]$SSHRemoteTunnels,

    [Parameter(Mandatory = $false)]
    [String[]]$SSHLocalTunnels,

    [Parameter(Mandatory = $false)]
    [String]$SSHPrivateKeyFile,

    [Parameter(Mandatory = $false)]
    [String]$BootCommand,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 86400)]
    [UInt]$BootKeyGroupIntervalSeconds,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 86400)]
    [UInt]$BootWaitSeconds = 1
)

