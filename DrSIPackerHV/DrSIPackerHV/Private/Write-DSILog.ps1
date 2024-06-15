<#
.SYNOPSIS
    Writes a message to the console and/or log file.
.DESCRIPTION
    Writes a message to the console and/or log file.

    Messages are prepended with a timestamp matching RFC 3339 in UTC.
    For Example: 2024-06-08T17:19:46.123Z

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
        [ValidateSet("DBG", "VERB", "INFO", "WARN", "ERR")]
        [String]$Level,

        [Parameter(Mandatory = $true, Position = 2)]
        [String]$Task,

        [Parameter(Mandatory = $false)]
        [Switch]$LogOnly,

        [Parameter(Mandatory = $false)]
        [String]$LogPath
    )

    [String]$LogDirectory = Join-Path -Path $ENV:SystemRoot -ChildPath "Temp"
    [String]$LogPath = Join-Path -Path $LogDirectory -ChildPath "packer_bootstrap.log"

    # Messages are prepended with a timestamp matching RFC 3339 in UTC.
    # For Example: 2024-06-08T17:19:46.123Z
    [String]$Date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    # Specifies a hashtable to store the message event.
    [Hashtable]$MessageEvent = @{
        Timestamp = $Date
        Level     = $Level
        Task      = $Task
        Message   = $Message
    }

    [String]$ConsoleMessage = ("[{0}] [{1}] [{2}] - {3}" -f $Date, $Level, $Step, $Message)

    if (-not $LogOnly)
    {
        $LogMessage | Out-File -FilePath $LogPath -Append

        switch ($Level)
        {
            "DBG"
            {
                Write-Debug -Message $LogMessage
                break
            }
            "VERB"
            {
                Write-Verbose -Message $LogMessage
                break
            }
            "INFO"
            {
                Write-Information -MessageData $LogMessage
                break
            }
            "WARN"
            {
                Write-Warning -Message $LogMessage
                break
            }
            "ERR"
            {
                Write-Error -Message $LogMessage
                break
            }
        }

       
    }
    else
    {
        $LogMessage | Out-File -FilePath $LogPath -Append
    }
}