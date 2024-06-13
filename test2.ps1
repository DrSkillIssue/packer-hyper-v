[CmdletBinding()]
Param (
)

#region Functions
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

Write-Log -Message "Test" -Level "INF" -Step "Test" -LogOnly