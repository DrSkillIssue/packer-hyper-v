using namespace System
using namespace System.Collections.Generic
using namespace System.Text

enum LogLevel
{
    DBG = 1
    VERB = 2
    INFO = 3
    WARN = 4
    ERR = 5
    CRIT = 6
}

<#
.SYNOPSIS
    Writes a message to a log file.
.DESCRIPTION
    Writes a message to a log file.

    A log file will be placed at the following location:
        "{0}\Temp\packer_win_update.log" -f $Env:SystemRoot
.PARAMETER Message
    The message to write.
.PARAMETER Level
    The level of the message.

    Valid values are DBG, VRB, INF, WRN, or ERR.
.PARAMETER Step
    The step the message is associated with.
.EXAMPLE
    Write-Log -Message "This is a message." -Level INF -Step "Example"

    The above example writes an informational message to a log file.
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
        [LogLevel]$Level,

        [Parameter(Mandatory = $true, Position = 2)]
        [String]$Step
    )

    [String]$LogDirectory = Join-Path -Path $Env:SystemRoot -ChildPath "Temp"
    [String]$LogPath = Join-Path -Path $LogDirectory -ChildPath "packer_win_update.log"

    # Example: 06/27/2024 07:29:34
    [String]$Date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    [String]$LogMessage = ("[{0}] [{1}] - {3}" -f $Date, $Level, $Step, $Message)

    $LogMessage | Out-File -FilePath $LogPath -Append -ErrorAction SilentlyContinue
}

enum DSIWUSearchStatus
{
    NotStarted = 0
    InProgress = 1
    Succeeded = 2
    SucceededWithErrors = 3
    Failed = 4
    Aborted = 5
    UnknownStatus = 101
}

enum DSIWUDownloadStatus
{
    NotStarted = 0
    InProgress = 1
    Succeeded = 2
    SucceededWithErrors = 3
    Failed = 4
    Aborted = 5
    UnknownStatus = 101
}

enum DSIWUInstallStatus
{
    NotStarted = 0
    InProgress = 1
    Succeeded = 2
    SucceededWithErrors = 3
    Failed = 4
    Aborted = 5
    UnknownStatus = 101
}

class DSISkipWindowsUpdate
{
    # Specifies the Update to be skipped.
    [MarshalByRefObject]$Update

    # Specifies the reason for skipping the update.
    [String]$Reason

    DSISkipWindowsUpdate([MarshalByRefObject]$Update, [String]$Reason)
    {
        $this.Update = $Update
        $this.Reason = $Reason
    }

    [String] ToString()
    {
        # Skip - Update is null.
        if (-not $this.Update)
        {
            return $null
        }

        return ("Update: {0} - Skip Reason: {1}" -f $this.Update.Title, $this.Reason)
    }
}

class DSIWindowsUpdateHandler
{
    # Specifies the current Search Status.
    # This state is set after running InvokeSearchUpdates().
    [DSIWUSearchStatus]$SearchStatus

    # Specifies the current Download Status.
    [DSIWUDownloadStatus]$DownloadStatus

    # Specifies the current Install Status.
    [DSIWUInstallStatus]$InstallStatus

    # Specifies whether a reboot is required.
    [Bool]$RebootRequired = $false

    # Updates that are found will be placed in this collection.
    [List[MarshalByRefObject]]$Updates = [List[MarshalByRefObject]]::new()

    # Updates to be skipped will be placed in this collection.
    hidden [List[DSISkipWindowsUpdate]]$UpdatesToSkip = [List[DSISkipWindowsUpdate]]::new()

    # Updates to be downloaded will be placed in this object.
    # This represents object 'Microsoft.Update.UpdateColl' which is a collection.
    hidden [MarshalByRefObject]$UpdatesToDownload

    # Updates to be installed will be placed in this object.
    # This represents object 'Microsoft.Update.UpdateColl' which is a collection.
    hidden [MarshalByRefObject]$UpdatesToInstall

    # Initialize an Update Session.
    # This will be used to search, download, and install updates.
    hidden [MarshalByRefObject]$UpdateSession

    # Specifies the category of updates to search for.
    hidden [String[]]$Categories

    # Flag to determine whether to search for ALL updates.
    # Criteria: "IsInstalled=$($this.IsInstalled)"
    hidden [Bool]$AllUpdates = $true

    # Flag to determine to search for updates that are hidden.
    hidden [Bool]$IsHidden = $false

    # Flag to determine to search for updates that are installed.
    # To search for updates that are NOT installed. Leave this as 'False'.
    hidden [Bool]$IsInstalled = $false

    # Flag to determine whether to search for recommended updates.
    # Criteria: "BrowseOnly=0"
    hidden [Bool]$IsRecommended = $false

    # Flag to determine whether to search for important updates.
    # Criteria: "AutoSelectOnWebSites=1"
    hidden [Bool]$IsImportant = $false

    # Flag to determine whether to search for optional updates.
    # Criteria: "AutoSelectOnWebSites=0 AND BrowseOnly=1"
    hidden [Bool]$IsOptional = $false

    # Specifies the Client Application ID.
    hidden [String]$_ClientApplicationID = "packer-windows-update"

    # Specifies the current OS Version.
    hidden [Version]$OS = [Environment]::OSVersion.Version

    DSIWindowsUpdateHandler()
    {
        $this.SearchStatus = [DSIWUSearchStatus]::NotStarted
        $this.DownloadStatus = [DSIWUDownloadStatus]::NotStarted
        $this.InstallStatus = [DSIWUInstallStatus]::NotStarted
    }

    hidden [Void] _Init()
    {
        # Initialize the Update Session.
        $this.UpdateSession = (New-Object -ComObject "Microsoft.Update.Session")
        $this.UpdateSession.ClientApplicationID = $this._ClientApplicationID

        # Initialize an Update Collections to store updates to be downloaded.
        $this.UpdatesToDownload = (New-Object -ComObject "Microsoft.Update.UpdateColl")
        $this.UpdatesToInstall = (New-Object -ComObject "Microsoft.Update.UpdateColl")
    }

    [MarshalByRefObject] GetUpdateSession()
    {
        return $this.UpdateSession
    }

    [List[MarshalByRefObject]] GetUpdates()
    {   
        return $this.Updates
    }

    [List[DSISkipWindowsUpdate]] GetUpdatesToSkip()
    {
        return $this.UpdatesToSkip
    }

    [MarshalByRefObject] GetUpdatesToDownload()
    {
        return $this.UpdatesToDownload
    }

    [MarshalByRefObject] GetUpdatesToInstall()
    {
        return $this.UpdatesToInstall
    }

    [String[]] GetCategories()
    {
        return $this.Categories
    }

    [Void] SetCategories([String[]]$UpdateCategories)
    {
        # Skip - No Categories provided.
        if ($UpdateCategories.Count -le 0)
        {
            return
        }

        # Initialize a GUID in case the category is a GUID.
        $Guid = [System.Guid]::NewGuid()

        # Perform the following actions:
        # - Trim whitespace for each category.
        # - If the category does NOT match a GUID, toLower() the category.
        $UpdateCategories = $UpdateCategories.ForEach({
                $CurrentCategory = $_

                # Skip - Null Category.
                if (-not $CurrentCategory)
                {
                    return
                }

                # Trim whitespace.
                $CurrentCategory = $CurrentCategory.Trim()

                # Skip - Empty Category.
                if ([String]::IsNullOrEmpty($CurrentCategory))
                {
                    return
                }

                # If Category does NOT match a GUID, toLower() the category.
                if (-not [System.Guid]::TryParse($CurrentCategory, [ref]$Guid))
                {
                    # NOTE: This assumes a category name were provided.
                    # A partial GUID would still be considered a category name.
                    $CurrentCategory.ToLower()
                }
                else
                {
                    # GUID were provided.
                    $CurrentCategory
                }
            })

        # Skip - Only null or empty categories were provided.
        if ($UpdateCategories.Count -le 0)
        {
            return
        }

        # Sort the categories and remove duplicates.
        [String[]]$SortedCategories = $UpdateCategories | Sort-Object -Unique

        # Store categories.
        $this.Categories = $SortedCategories
    }

    [Void] SetIsInstalled([Bool]$IsInstalled)
    {
        $this.IsInstalled = $IsInstalled
    }

    [Void] SetIsRecommended([Bool]$IsRecommended)
    {
        $this.IsRecommended = $IsRecommended
    }

    [Void] SetIsImportant([Bool]$IsImportant)
    {
        $this.IsImportant = $IsImportant
    }

    [Void] SetIsOptional([Bool]$IsOptional)
    {
        $this.IsOptional = $IsOptional
    }

    [Void] SetIsHidden([Bool]$IsHidden)
    {
        $this.IsHidden = $IsHidden
    }

    [String] GetSearchCriteria()
    {
        # Specifies whether to disable searching for all updates.
        [Bool]$DisableSearchAllUpdates = (
            $this.IsRecommended -or
            $this.IsImportant -or
            $this.IsOptional
        )

        # Disable searching for all updates.
        if ($DisableSearchAllUpdates)
        {
            $this.AllUpdates = $false
        }

        # Specifies the search criteria.
        $Criteria = [StringBuilder]::new() 

        # Apply isRecommended criteria.
        if ($this.IsRecommended)
        {
            $Criteria.Append("BrowseOnly=0 and ")
        }

        # Apply isImportant criteria.
        if ($this.IsImportant)
        {
            $Criteria.Append("AutoSelectOnWebSites=1 and ")
        }

        # Apply isOptional criteria.
        if ($this.IsOptional)
        {
            if ($this.IsImportant)
            {
                $Criteria.Append("BrowseOnly=1 and ")
            }
            else
            {
                $Criteria.Append("AutoSelectOnWebSites=0 and BrowseOnly=1 and ")
            }
        }

        # Apply IsHidden criteria.
        if ($this.IsHidden)
        {
            $Criteria.Append("IsHidden=1 and ")
        }

        # Apply isInstalled criteria.
        # If no criteria is provided, this will be the only criteria.
        $Criteria.Append(("IsInstalled={0}" -f [Int32]$this.IsInstalled))

        return $Criteria.ToString()
    }

    [Void] InvokeDownloadUpdates() 
    {
        # Retrieve Updates to Download
        $UToDownload = $this.UpdatesToDownload

        # Skip - No updates found.
        if ($UToDownload.Count -le 0)
        {
            Write-Log -Message "No updates marked as 'To Download' found." -Level 2 -Step "InvokeDownloadUpdates"
            return
        }

        # Start the download process.
        # First - Create an UpdateDownloader object.
        $Downloader = $this.UpdateSession.CreateUpdateDownloader()

        # Second - Add updates to download.
        # NOTE: You must cast to [MarshalByRefObject] to avoid 'Unable to cast COM object' exceptions.
        $Downloader.Updates = [MarshalByRefObject]$UToDownload

        # Third - Start downloading updates.
        # Write-Verbose -Message ("{0} - Downloading updates." -f $MyInvocation.MyCommand.Name)
        $DownloadResults = $Downloader.Download()

        Write-Log -Message ("Download Results: {0}" -f $DownloadResults.ResultCode) -Level 2 -Step "InvokeDownloadUpdates"

        # Record the status of the install process.
        if ([DSIWUDownloadStatus].GetEnumName($DownloadResults.ResultCode))
        {
            $this.InstallStatus = $DownloadResults.ResultCode
        }
        else
        {
            $this.InstallStatus = [DSIWUDownloadStatus]::UnknownStatus
        }

        # Finally - Add downloaded updates to the 'UpdatesToInstall' collection.
        $this.UpdatesToDownload | ForEach-Object {

            $CurrentUpdate = $_

            if ($CurrentUpdate.IsDownloaded)
            {
                Write-Log -Message ("To be installed: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeDownloadUpdates"
                [Void] $this.UpdatesToInstall.Add($CurrentUpdate)
            }
            else
            {
                Write-Log -Message ("Skipping Update as it's not downloaded: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeDownloadUpdates"
            }
        }
    }
    
    [Void] InvokeSearchUpdates()
    {
        Write-Log -Message "Retrieve Search Criteria" -Level 1 -Step "InvokeSearchUpdates"
        
        # Retrieve Search Criteria
        $Criteria = $this.GetSearchCriteria()

        Write-Log -Message ("Search Criteria: {0}" -f $Criteria) -Level 1 -Step "InvokeSearchUpdates"

        # Reset the Update Session before searching for updates.
        Write-Log -Message "Resetting Update Session." -Level 1 -Step "InvokeSearchUpdates"
        $this._Init()

        # Generate an UpdateSearcher and search for updates.
        Write-Log -Message "Searching for updates." -Level 2 -Step "InvokeSearchUpdates"
        $UpdateSearcher = $this.UpdateSession.CreateUpdateSearcher()
        $SearchResults = $UpdateSearcher.Search($Criteria)

        # Record the Search Status.
        Write-Log -Message ("Search Results: {0}" -f $SearchResults.ResultCode) -Level 2 -Step "InvokeSearchUpdates"
        if ([DSIWUSearchStatus].GetEnumName($SearchResults.ResultCode))
        {
            $this.SearchStatus = $SearchResults.ResultCode
        }
        else
        {
            $this.SearchStatus = [DSIWUSearchStatus]::UnknownStatus
        }

        # Return - No updates found.
        if ($SearchResults.Updates.Count -le 0)
        {
            Write-Log -Message "No updates found." -Level 1 -Step "InvokeSearchUpdates"
            return
        }

        Write-Log -Message ("{0} updates found." -f $SearchResults.Updates.Count) -Level 1 -Step "InvokeSearchUpdates"

        # Clear the collection before adding new updates.
        if ($this.Updates.Count -gt 0)
        {
            Write-Log -Message "Previous updates found. Clearing existing updates." -Level 1 -Step "InvokeSearchUpdates"
            $this.Updates.Clear()
            $this.UpdatesToSkip.Clear()
            $this.UpdatesToDownload.Clear()
            $this.UpdatesToInstall.Clear()
        }

        # If Categories were not provided, add all updates.
        if ($this.Categories.Count -le 0)
        {
            Write-Log -Message "No categories provided. Adding all updates." -Level 1 -Step "InvokeSearchUpdates"

            $SearchResults.Updates | ForEach-Object {

                $CurrentUpdate = $_

                <# Skip - Update requires user input.
                if ($CurrentUpdate.InstallationBehavior.CanRequestUserInput)
                {
                    $UpdatesToSkip.Add($CurrentUpdate)
                    return
                }#>

                # Accept EULA if required.
                if (-not $CurrentUpdate.EulaAccepted)
                {
                    Write-Log -Message ("Accepting EULA for: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeSearchUpdates"
                    $CurrentUpdate.AcceptEula()
                }

                # Add 'UpdatesToDownload' if not already downloaded.
                if (-not $CurrentUpdate.IsDownloaded)
                {
                    # Update is not downloaded, add to 'UpdatesToDownload'.
                    Write-Log -Message ("To be downloaded: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeSearchUpdates"
                    $this.UpdatesToDownload.Add($CurrentUpdate)
                }
                else
                {
                    # Update is already downloaded, add to 'UpdatesToInstall'.
                    Write-Log -Message ("To be installed: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeSearchUpdates"
                    $this.UpdatesToInstall.Add($CurrentUpdate)
                }
                
                $this.Updates.Add($CurrentUpdate)
            }

            # No categories were provided, we can exit.
            return
        }

        Write-Log -Message "Categories provided. Filtering updates based on categories." -Level 2 -Step "InvokeSearchUpdates"

        # Build a hashset of categories to search for.
        # This will be used to filter updates based on categories.
        $CategorySet = [HashSet[String]]::new($this.Categories.Count)
            
        # Prepare Category Hashset if Categories were provided.
        if ($this.Categories.Count -gt 0)
        {
            # Add each category to the hashset.
            $this.Categories.ForEach({ [Void] $CategorySet.Add($_) })
        }

        # Specifies the FilterScript used to determine if the current update matches provided Categories.
        [ScriptBlock]$FilterScript = {
            $CategorySet.Contains($_.Name.ToLower()) -or $CategorySet.Contains($_.CategoryID)
        }

        # Add found updates to the collection.
        # If categories were provided, filter updates based on categories.
        #
        # NOTE: We have to use a ForEach-Object instead of Where-Object as..
        # ..it's possible for an update to have multiple categories.
        $SearchResults.Updates | ForEach-Object {
            
            $CurrentUpdate = $_

            # Specifies whether current update matches provided Categories.
            $MatchingCategories = $CurrentUpdate.Categories | Where-Object -FilterScript $FilterScript
    
            # Skip - Update does not match provided Categories.
            if (-not $MatchingCategories)
            {
                Write-Log -Message ("Skipping Update as it does not match provided Categories: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeSearchUpdates"
                $UpdatesToSkip.Add([DSISkipWindowsUpdate]::new($CurrentUpdate, "Update does not match provided Categories."))
                return
            }
            <# Skip - Update requires user input.
            elseif ($CurrentUpdate.InstallationBehavior.CanRequestUserInput)
            {
                $UpdatesToSkip.Add($CurrentUpdate)
                return
            }#>

            # Accept EULA if required.
            if (-not $CurrentUpdate.EulaAccepted)
            {
                Write-Log -Message ("Accepting EULA for: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeSearchUpdates"
                $CurrentUpdate.AcceptEula()
            }

            # Add 'UpdatesToDownload' if not already downloaded.
            if (-not $CurrentUpdate.IsDownloaded)
            {
                # Update is not downloaded, add to 'UpdatesToDownload'.
                Write-Log -Message ("To be downloaded: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeSearchUpdates"
                $this.UpdatesToDownload.Add($CurrentUpdate)
            }
            else
            {
                # Update is already downloaded, add to 'UpdatesToInstall'.
                Write-Log -Message ("To be installed: {0}." -f $CurrentUpdate.Title) -Level 1 -Step "InvokeSearchUpdates"
                $this.UpdatesToInstall.Add($CurrentUpdate)
            }
                 
            $this.Updates.Add($CurrentUpdate)
        }
    }

    [Void] InvokeInstallUpdates()
    {
        # Retrieve Updates to Install
        $UToInstall = $this.UpdatesToInstall

        # Skip - No updates found.
        if ($UToInstall.Count -le 0)
        {
            return
        }

        # Start the installation process.
        # First - Create an UpdateInstaller object.
        $Installer = $this.UpdateSession.CreateUpdateInstaller()

        # Second - Add updates to install.
        # NOTE: You must cast to [MarshalByRefObject] to avoid 'Unable to cast COM object' exceptions.
        $Installer.Updates = [MarshalByRefObject]$UToInstall

        # Third - Start installing updates.
        # Write-Verbose -Message ("{0} - Installing updates." -f $MyInvocation.MyCommand.Name)
        # https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdateinstaller-install
        $InstallResults = $Installer.Install()

        # Record the status of the install process.
        if ([DSIWUInstallStatus].GetEnumName($InstallResults.ResultCode))
        {
            $this.InstallStatus = $InstallResults.ResultCode
        }
        else
        {
            $this.InstallStatus = [DSIWUInstallStatus]::UnknownStatus
        }

        # Record the reboot required status.
        $this.RebootRequired = $InstallResults.RebootRequired
    }
}

enum DSIWindowsUpdateStatus
{
    # Specifies the default status code. This is used when the script has not started.
    Not_Started = -1
    # Specifies that Windows Update has completed successfully.
    # This could imply that no updates were found or that all updates were installed.
    Success = 0
    # Catch-all for failures without a specific reason.
    Failed = 1
    # Some updates were installed, but others failed.
    # If this error occurs, the script will attempt to install the failed updates.
    Failed_Partial_Install = 2
    # Failed as search was stopped.
    Failed_Search_Stopped = 3
    # Unable to search for Windows Updates due to WSUS being enabled.
    Failed_WSUS_Enabled = 3
    # Unrelated search errors.
    Failed_Search_Error = 4
    # Failed after performing a retry search
    # A retry search is performed if the previous error was 'Failed_Search_Error'.
    Failed_Retry_Search = 5
    # Failed to search for updates after reboot.
    Failed_Retry_Search_After_Reboot = 6
    # Failed to retry install partial updates.
    Failed_Retry_Partial_Install = 7
    # Failed to retry install partial updates after reboot.
    Failed_Retry_Partial_Install_After_reboot = 8
    # Specifies that a reboot is required but no updates were installed.
    # This would occur before searching for updates.
    Reboot_Required_No_Updates_Installed = 30
    # Specifies that reboot is required to complete the installation of updates.
    Reboot_Required_Updates_Installed = 31
    # Specifies that a Search for updates is in progress.
    Search_In_Progress = 81
}

class DSIWindowsUpdate : DSIWindowsUpdateHandler
{
    # Specifies the name of the target machine.
    [String]$ComputerName = $env:COMPUTERNAME

    # Specifies the current status of Windows Update.
    [DSIWindowsUpdateStatus]$Status

    # Specifies the current status message of Windows Update.
    [String]$LastMessage

    DSIWindowsUpdate() : base()
    {
        $this.Status = [DSIWindowsUpdateStatus]::Not_Started
        $this.LastMessage = "Windows Update has not started."
    }

    [Void] SearchUpdates()
    {
        $this.Status = [DSIWindowsUpdateStatus]::Search_In_Progress
        $this.InvokeSearchUpdates()
    }

    [Void] SetStatus([DSIWindowsUpdateStatus]$CurrentStatus)
    {
        $this.Status = $CurrentStatus
    }

    [Int64] GetStatus()
    {
        return [Int64]$this.Status
    }

    [Void] SetLastMessage([String]$Message)
    {
        $this.LastMessage = $Message
    }

    [String] GetLastMessage()
    {
        return $this.LastMessage
    }

    [String] ToString()
    {
        return ("Computer: {0} - Status: {1} - LastMessage: {2}" -f $this.ComputerName, $this.Status, $this.LastMessage)
    }
}

<#
.SYNOPSIS
    Searches for Windows Updates based on provided criteria.
.DESCRIPTION
    Searches for Windows Updates based on provided criteria.

    This function will search for updates based on the following criteria:
    - Categories
    - IsHidden
    - IsInstalled
    - IsRecommended
    - IsImportant
    - IsOptional

    NOTE: if no criteria is provided, all updates will be searched. If categories are provided,
        and no other criteria is provided, all updates will be searched and filtered based on categories.

    Also, default behavior is to not search for hidden updates. If you want to search for hidden updates,
    you must specify the IsHidden flag.
.PARAMETER Categories
    Specifies the category/categories of updates to search for. 
    
    You can specify the name of the category, GUID, or both.

    For example (Category Names):
    - "Drivers"
    - "Feature Packs"
    - "Security Updates"
    - "Service Packs"
    - "Tools"
    - "Update Rollups"
    - "Updates"
    - "Upgrades"
    - "Microsoft"
    - "Definition Update"

    For example (Category GUIDs):
    - Feature Packs: "b54e7d24-7add-428f-8b75-90a396fa584f"
    - Security Updates: "0fa1201d-4330-4fa8-8ae9-b877473b6441"
    - Service Packs: "68c5b0a3-d1a6-4553-ae49-01d3a7827828"
    - Tools: "b4832bd8-e735-4761-8daf-37f882276dab"
    - Update Rollups: "28bc880e-0592-4cbf-8f95-c79b17911d5f"
    - Updates: "cd5ffd1e-e932-4e3a-bf74-18bf0b1bbd83"
    - Upgrades: "3689bdc8-b205-4af4-8d4a-a63924c5e9d5"
.PARAMETER IsHidden
    Specifies whether to search for hidden updates.

    By default, this is set to $false.
.PARAMETER IsInstalled
    Specifies whether to search for installed updates.

    By default, this is set to $false.
.PARAMETER IsRecommended
    Specifies whether to search for recommended updates.

    By default, this is set to $false. If you want to install all updates, specifying this flag is unnecessary.
.PARAMETER IsImportant
    Specifies whether to search for important updates.

    By default, this is set to $false. If you want to install all updates, specifying this flag is unnecessary.
.PARAMETER IsOptional
    Specifies whether to search for optional updates.

    By default, this is set to $false. If you want to install all updates, specifying this flag is unnecessary.
.EXAMPLE
    $Search = Search-DSIWindowsUpdate

    This example will search for all non-hidden updates.
.EXAMPLE
    $Search = Search-DSIWindowsUpdate -Categories "Security Updates", "cd5ffd1e-e932-4e3a-bf74-18bf0b1bbd83"

    This example will search for all non-hidden updates that are categorized as "Security Updates" and "Updates".
.EXAMPLE
    $Search = Search-DSIWindowsUpdate -IsHidden

    This example will search for all updates.
.INPUTS
    None
.OUTPUTS
    DSIWindowsUpdate
    Upon successful completion, this function will return a DSIWindowsUpdate object.
#>
function Search-DSIWindowsUpdate
{
    [CmdletBinding()]
    [OutputType([DSIWindowsUpdate])]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [DSIWindowsUpdate]$WindowsUpdate,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [String[]]$Categories,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Switch]$IsHidden,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Switch]$IsRecommended,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Switch]$IsImportant,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Switch]$IsOptional,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Switch]$IsInstalled
    )

    try
    {
        # Set Categories if provided.
        if ($Categories.Count -gt 0)
        {
            $WindowsUpdate.SetCategories($Categories)
        }

        # Set IsHidden flag if provided.
        if ($IsHidden)
        {
            $WindowsUpdate.SetIsHidden($true)
        }

        # Set IsInstalled flag if provided.
        if ($IsInstalled)
        {
            $WindowsUpdate.SetIsInstalled($true)
        }

        # Set IsRecommended flag if provided.
        if ($IsRecommended)
        {
            $WindowsUpdate.SetIsRecommended($true)
        }

        # Set IsImportant flag if provided.
        if ($IsImportant)
        {
            $WindowsUpdate.SetIsImportant($true)
        }

        # Set IsOptional flag if provided.
        if ($IsOptional)
        {
            $WindowsUpdate.SetIsOptional($true)
        }

        # Search for updates.
        $WindowsUpdate.SearchUpdates()
    }
    finally
    {
        $WindowsUpdate
    }
}

<#
.SYNOPSIS
    Starts the download process for the provided Windows Updates.
.DESCRIPTION
    Starts the download process for the provided Windows Updates. Each update has flag 'IsDownloaded' to
        determine whether an update has been downloaded.

    This function will query 'DSIWindowsUpdate' object for updates that were found during the search process with
        the specified flag marked as 'False'.

    If an update has already been downloaded, it will be skipped.
.PARAMETER Search
    Specifies the DSIWindowsUpdate object that contains the updates to download.

    You can use the 'Search-DSIWindowsUpdate' function to create a new search object.
.EXAMPLE
    $Search = Search-DSIWindowsUpdate
    $Search | Invoke-DSIWindowsUpdateDownload

    This example will start the download process for the updates found during the search process.
#>
function Invoke-DSIWindowsUpdateDownload
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [DSIWindowsUpdate]$Search
    )
    Process
    {
        try
        {
            Write-Verbose ("{0} - Starting download process." -f $MyInvocation.MyCommand.Name)

            
        }
        finally
        {
            [PSCustomObject]@{
                Search     = $Search
                Downloader = $Downloader
            }
        }
    }
}

function Invoke-DSIWindowsUpdate
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [String[]]$Categories,

        [Parameter(Mandatory = $false)]
        [Switch]$IsHidden,

        [Parameter(Mandatory = $false)]
        [Switch]$IsRecommended,

        [Parameter(Mandatory = $false)]
        [Switch]$IsImportant,

        [Parameter(Mandatory = $false)]
        [Switch]$IsOptional,

        [Parameter(Mandatory = $false)]
        [Switch]$IsInstalled
    )

    try
    {
        # Initialize a new DSIWindowsUpdateResults object.
        $WindowsUpdate = [DSIWindowsUpdate]::new()

        # Specifies Parameter Splat for Search-DSIWindowsUpdate.
        [Hashtable]$SearchUpdateParams = @{
            WindowsUpdate = $WindowsUpdate
            Categories    = $Categories
            IsHidden      = $IsHidden
            IsRecommended = $IsRecommended
            IsImportant   = $IsImportant
            IsOptional    = $IsOptional
            IsInstalled   = $IsInstalled
        }

        Write-Debug ("{0} - Searching for Windows Updates." -f $MyInvocation.MyCommand.Name)
        $WindowsUpdate = Search-DSIWindowsUpdate @SearchUpdateParams

        # TODO: Update Status based on Search Results.
    }
    catch
    {
        $_
    }
    finally
    {
        $WindowsUpdate
    }
}

$Updates = Invoke-DSIWindowsUpdate