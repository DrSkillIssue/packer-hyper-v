using namespace System
using namespace System.Collections.Generic
using namespace System.Text

enum DSIWinUpdateSearchStatus : Int32
{
    NotStarted = 0
    InProgress = 1
    Succeeded = 2
    SucceededWithErrors = 3
    Failed = 4
    Aborted = 5
}

class DSISkipWindowsUpdate
{
    # Specifies the Update to be skipped.
    [System.__ComObject]$Update

    # Specifies the reason for skipping the update.
    [String]$Reason

    DSISkipWindowsUpdate([System.__ComObject]$Update, [String]$Reason)
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

class DSISearchWindowsUpdate
{
    # Specifies the current Search Status.
    [DSIWinUpdateSearchStatus]$SearchStatus

    # Updates that are found will be placed in this collection.
    [List[__ComObject]]$Updates = [List[__ComObject]]::new()

    # Updates to be skipped will be placed in this collection.
    [List[DSISkipWindowsUpdate]]$SkippedUpdates = [List[DSISkipWindowsUpdate]]::new()

    # Specifies the category of updates to search for.
    [String[]]$Categories

    # Flag to determine whether to search for ALL updates.
    # Criteria: "IsInstalled=$($this.IsInstalled)"
    [Bool]$AllUpdates = $true

    # Flag to determine to search for updates that are hidden.
    [Bool]$IsHidden = $false

    # Flag to determine to search for updates that are installed.
    # To search for updates that are NOT installed. Leave this as 'False'.
    [Bool]$IsInstalled = $false

    # Flag to determine whether to search for recommended updates.
    # Criteria: "BrowseOnly=0"
    [Bool]$IsRecommended = $false

    # Flag to determine whether to search for important updates.
    # Criteria: "AutoSelectOnWebSites=1"
    [Bool]$IsImportant = $false

    # Flag to determine whether to search for optional updates.
    # Criteria: "AutoSelectOnWebSites=0 AND BrowseOnly=1"
    [Bool]$IsOptional = $false

    # Specifies the current OS Version.
    hidden [Version]$OS = [Environment]::OSVersion.Version
     
    # Initialize an Update Session.
    # This will be used to search for updates.
    hidden [__ComObject]$_UpdateSession

    hidden [String]$_ClientApplicationID = "packer-windows-update"

    DSIWindowsUpdate()
    {
        $this.SearchStatus = [DSIWinUpdateSearchStatus]::NotStarted
        $this._Init()
    }

    hidden [Void] _Init()
    {
        $this._UpdateSession = (New-Object -ComObject "Microsoft.Update.Session")
        $this._UpdateSession.ClientApplicationID = $this._ClientApplicationID
    }

    [__ComObject] GetUpdateSession()
    {
        return $this._UpdateSession
    }

    [List[__ComObject]] GetUpdates()
    {   
        return $this.Updates
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

    [Void] SearchUpdates()
    {
        $Criteria = $this.GetSearchCriteria()

        # Reset the Update Session before searching for updates.
        $this._Init()

        # Generate an UpdateSearcher and search for updates.
        $UpdateSearcher = $this._UpdateSession.CreateUpdateSearcher()
        $SearchResults = $UpdateSearcher.Search($Criteria)

        # Update the Search Status.
        $this.SearchStatus = $SearchResults.ResultCode

        # Return - No updates found.
        if ($SearchResults.Updates.Count -le 0)
        {
            return
        }

        # Clear the collection before adding new updates.
        if ($this.Updates.Count -gt 0)
        {
            $this.Updates.Clear()
            $this.SkippedUpdates.Clear()
        }

        # If Categories were not provided, add all updates.
        if ($this.Categories.Count -le 0)
        {
            $SearchResults.Updates | ForEach-Object {

                $CurrentUpdate = $_

                <# Skip - Update requires user input.
                if ($CurrentUpdate.InstallationBehavior.CanRequestUserInput)
                {
                    $SkippedUpdates.Add($CurrentUpdate)
                    return
                }#>

                # Accept EULA if required.
                if (-not $CurrentUpdate.EulaAccepted)
                {
                    $CurrentUpdate.AcceptEula()
                }
                
                $this.Updates.Add($CurrentUpdate)
            }
            return
        }

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
                $SkippedUpdates.Add([DSISkipWindowsUpdate]::new($CurrentUpdate, "Update does not match provided Categories."))
                return
            }
            <# Skip - Update requires user input.
            elseif ($CurrentUpdate.InstallationBehavior.CanRequestUserInput)
            {
                $SkippedUpdates.Add($CurrentUpdate)
                return
            }#>

            # Accept EULA if required.
            if (-not $CurrentUpdate.EulaAccepted)
            {
                $CurrentUpdate.AcceptEula()
            }
                 
            $this.Updates.Add($CurrentUpdate)
        }
    }
}

enum DSIWindowsUpdateStatus : Int32
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

class DSIWindowsUpdateResults : DSISearchWindowsUpdate
{
    # Specifies the name of the target machine.
    [String]$ComputerName = $env:COMPUTERNAME

    # Specifies the list of updates that were installed (if any).
    [String[]]$Installed = @()

    # Specifies a list of updates that failed to install (if any).
    [String[]]$Failed = @()

    # Specifies the current status of Windows Update.
    [DSIWindowsUpdateStatus]$Status

    # Specifies the current status message of Windows Update.
    [String]$LastMessage

    DSIWindowsUpdateResults() : base()
    {
        $this.Status = [DSIWindowsUpdateStatus]::Not_Started
        $this.LastMessage = "Windows Update has not started."
    }

    [Void] SetStatus([DSIWindowsUpdateStatus]$StatusCode)
    {
        $this.Status = $StatusCode
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
    DSISearchWindowsUpdate
    Upon successful completion, this function will return a DSISearchWindowsUpdate object.
#>
function Search-DSIWindowsUpdate
{
    [CmdletBinding()]
    [OutputType([DSISearchWindowsUpdate])]
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
        # Initialize a new Search Windows Update object.
        $Search = [DSISearchWindowsUpdate]::new()

        # Set Categories if provided.
        if ($Categories.Count -gt 0)
        {
            $Search.SetCategories($Categories)
        }

        # Set IsHidden flag if provided.
        if ($IsHidden)
        {
            $Search.SetIsHidden($true)
        }

        # Set IsInstalled flag if provided.
        if ($IsInstalled)
        {
            $Search.SetIsInstalled($true)
        }

        # Set IsRecommended flag if provided.
        if ($IsRecommended)
        {
            $Search.SetIsRecommended($true)
        }

        # Set IsImportant flag if provided.
        if ($IsImportant)
        {
            $Search.SetIsImportant($true)
        }

        # Set IsOptional flag if provided.
        if ($IsOptional)
        {
            $Search.SetIsOptional($true)
        }

        # Search for updates.
        $Search.SearchUpdates()
    }
    finally
    {
        $Search
    }
}

<#
.SYNOPSIS
    Starts the download process for the provided Windows Updates.
.DESCRIPTION
    Starts the download process for the provided Windows Updates. Each update has flag 'IsDownloaded' to
        determine whether an update has been downloaded.

    This function will query 'DSISearchWindowsUpdate' object for updates that were found during the search process with
        the specified flag marked as 'False'.

    If an update has already been downloaded, it will be skipped.
.PARAMETER Search
    Specifies the DSISearchWindowsUpdate object that contains the updates to download.

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
        [DSISearchWindowsUpdate]$Search
    )
    Process
    {
        Write-Verbose ("{0} - Starting download process." -f $MyInvocation.MyCommand.Name)

        # Retrieve Updates from $Search.
        $Updates = $Search.GetUpdates()

        # Skip - No updates found.
        if ($Updates.Count -le 0)
        {
            Write-Verbose -Message ("{0} - No updates found. Skipping download process." -f $MyInvocation.MyCommand.Name)
            return
        }

        # Specifies a list of updates to be downloaded.
        [List[__ComObject]]$UpdatesToDownload = $Updates.Where({ -not $_.IsDownloaded })

        # Skip - No updates to download.
        if ($UpdatesToDownload.Count -le 0)
        {
            Write-Verbose -Message ("{0} - All updates have already been downloaded." -f $MyInvocation.MyCommand.Name)
            return
        }

        # Start the download process.
        Write-Verbose -Message ("{0} - Must download {1} updates." -f $MyInvocation.MyCommand.Name, $UpdatesToDownload.Count)
        $Downloader = $Search.GetUpdateSession().CreateUpdateDownloader()

        # Add updates to download.
        $Downloader.Updates = $UpdatesToDownload
    }
}

function Install-DSIWindowsUpdate
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UpdatePath
    )

    $UpdatePath = Resolve-Path $UpdatePath
    $UpdatePath = $UpdatePath.ToString()

}