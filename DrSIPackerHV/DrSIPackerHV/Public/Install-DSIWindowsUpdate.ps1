class DSIWindowsUpdate
{
    # Specifies the current ComputerName
    [String]$ComputerName = $env:COMPUTERNAME

    # Specifies the current OS Version.
    [System.Version]$OS = [System.Environment]::OSVersion.Version

    # Updates that are found will be placed in this collection.
    $Updates = [System.Collections.Generic.List[System.MarshalByRefObject]]::new()

    # Flag to determine whether to search for ALL updates.
    # Criteria: "IsInstalled=$($this.IsInstalled)"
    [Bool]$AllUpdates = $true

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

    # Initialize an Update Session.
    # This will be used to search for updates.
    hidden $UpdateSession = (New-Object -ComObject "Microsoft.Update.Session")

    DSIWindowsUpdate()
    {
        $this.UpdateSession.ClientApplicationID = "packer-windows-update"
    }

    hidden [String] _GetSearchCriteria()
    {
        # If AllUpdates is set to $true, return the criteria for all updates.
        if ($this.AllUpdates)
        {
            return ("IsInstalled={0}" -f [Int32]$this.IsInstalled)
        }

        $Criteria = [System.Text.StringBuilder]::new()

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

        # Apply isInstalled criteria.
        $Criteria.Append(("IsInstalled={0}" -f [Int32]$this.IsInstalled))

        return $Criteria.ToString()
    }

    [Void] SearchUpdates()
    {
        $Criteria = $this._GetSearchCriteria()

        $UpdateSearcher = $this.UpdateSession.CreateUpdateSearcher()
        $SearchResult = $UpdateSearcher.Search($Criteria)
        $SearchResult.Updates
    }
}

function Get-DSIWindowsUpdate
{
    [CmdletBinding()]
    Param ()

    # Criterias
    # Type | String | =, != | Finds updates of a specific type, such as "'Driver'" and "'Software'".
    $Criteria = "IsInstalled=0"
    # Specifies the current ComputerName
    [String]$ComputerName = $env:COMPUTERNAME

    # Specifies the current OS Version.
    [System.Version]$OS = [System.Environment]::OSVersion.Version

    # Initialize an Update Session.
    # This will be used to search for updates.
    $UpdateSession = (New-Object -ComObject "Microsoft.Update.Session")

    $TestStorage = [System.Collections.Generic.List[System.MarshalByRefObject]]::new()

    # Initialize an empty UpdateColl to store updates.
    [System.__ComObject]$Updates = (New-Object -ComObject "Microsoft.Update.UpdateColl")

    $UpdateSession.ClientApplicationID = "packer-windows-update"
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResults = $UpdateSearcher.Search($Criteria)
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