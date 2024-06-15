function ConvertTo-DSIIso
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [Object]$InputObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [String]$OutputPath,

        [Parameter(Mandatory = $false)]
        [Switch]$Force,

        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [Switch]$RunAsAdmin
    )

    Begin
    {
        #Write-DSILog ("{0} - Start: Converting files to ISO." -f $MyInvocation.MyCommand.Name) -Type INFO
        #Write-DSILog ("{0} - Start: ISO Conversion Prep." -f $MyInvocation.MyCommand.Name) -Type DBG
        #Write-DSILog ("{0} - Validating existence of ISO dependencies." -f $MyInvocation.MyCommand.Name) -Type DBG

        # Validate required assemblies to convert files to an ISO.
        $PSModuleRoot = $ExecutionContext.SessionState.Module.ModuleBase

        # Specifies the path to library folder containing required assemblies.
        [String]$LibFolder = Join-Path -Path $PSModuleRoot -ChildPath "Lib"

        # Specifies the path to mkisofs.exe.
        [String]$MkIsoFsPath = Join-Path -Path $LibFolder -ChildPath "mkisofs.exe"

        # Specifies the path to cygwin1.dll
        [String]$CygwinPath = Join-Path -Path $LibFolder -ChildPath "cygwin1.dll"

        # Error - mkisofs or dependencies not found.
        if (-not (Resolve-Path -Path $MkIsoFsPath, $CygwinPath -ErrorVariable ResolveError))
        {
            $ErrorMsg = [System.Text.StringBuilder]::new()

            [Void] $ErrorMsg.AppendLine("Unable create ISO due to missing dependencies. Error(s): ")
        
            $ResolveError.ForEach({ [Void] $ErrorMsg.AppendLine($_.ToString()) })

            #Write-DSILog $ErrorMsg.ToString() -Type CRIT -LogOnly
            $PSCmdlet.ThrowTerminatingError($ResolveError[0])
        }

        # Initialize new DSIIso object.
        $DSIIso = [DSIIso]::new($OutputPath)

        # If OutputPath is a file, ensure it's an ISO file.
        #Write-DSIlog ("{0} - Validating provided Output Path." -f $MyInvocation.MyCommand.Name) -Type DBG
        
        # Error - Invalid Output Path.
        if ([System.IO.Path]::GetExtension($DSIIso.OutputFile) -ne ".iso")
        {
            $ErrorMsg = [System.Text.StringBuilder]::new()
            [Void] $ErrorMsg.AppendLine("Invalid Output Path. Parameter '-OutputPath' expects one of the following:")
            [Void] $ErrorMsg.AppendLine("  - A directory path.")
            [Void] $ErrorMsg.AppendLine("  - A file path with the extension '.iso'.")
            
            #Write-DSILog $ErrorMsg.ToString() -Type CRIT -LogOnly

            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.ArgumentException]::new($ErrorMsg.ToString()),
                "InvalidOutputPath",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $OutputPath
            )

            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        # Specifies path to the new ISO file.
        [String]$ISOPath = $DSIIso.ToString()

        # Specifies the tempoary folder to store files that will be converted to an ISO.
        [String]$ISOTempDirectory = $DSIIso.TempDirectory

        #Write-DSILog ("{0} - Creating Temporary Folder and Output Folder (if applicable)." -f $MyInvocation.MyCommand.Name) -Type DBG
        
        # Specifies Parameter Splat for New-Item
        [Hashtable]$NewItemParams = @{
            Path          = $ISOTempDirectory
            ItemType      = "Directory"
            ErrorVariable = "NewItemError"
            ErrorAction   = "SilentlyContinue"
        }

        $null = New-Item @NewItemParams

        # Error - Failed to create temporary folder.
        if (-not (Test-Path -Path $ISOTempDirectory -PathType Container))
        {
            [String]$ErrorMsg = (
                "{0} - Failed to create Temporary Folder '{1}'. Error: {2}" -f 
                $MyInvocation.MyCommand.Name, $ISOTempDirectory, $NewItemError[0].ToString()
            )
            
            #Write-DSILog $ErrorMsg -Type CRIT -LogOnly
            $PSCmdlet.ThrowTerminatingError($NewItemError[0])
        }

        #Write-DSILog ("{0} - Temporary Folder '{1}' created." -f $MyInvocation.MyCommand.Name, $ISOTempDirectory) -Type DBG

        # Create/Skip output directory.
        # Specifies the path to OutputPath.
        [String]$ISOOutputDirectory = $DSIIso.OutputDirectory

        # Create Output Folder if it doesn't exist.
        if (-not (Test-Path -Path $ISOOutputDirectory -PathType Container))
        {
            #Write-DSILog ("{0} - Output Folder '{1}' doesn't exist. Creating now." -f $MyInvocation.MyCommand.Name, $ISOOutputDirectory) -Type DBG

            # Update New-Item Parameter Splat.
            $NewItemParams.set_Item("Path", $ISOOutputDirectory)

            $null = New-Item @NewItemParams

            # Error - Failed to create Output folder.
            if (-not (Test-Path -Path $ISOOutputDirectory -PathType Container))
            {
                [String]$ErrorMsg = (
                    "{0} - Failed to create Output Folder '{1}'. Error: {2}" -f 
                    $MyInvocation.MyCommand.Name, $ISOOutputDirectory, $NewItemError[0].ToString()
                )
            
                #Write-DSILog $ErrorMsg -Type CRIT -LogOnly
                $PSCmdlet.ThrowTerminatingError($NewItemError[0])
            }

            #Write-DSILog ("{0} - Output Folder '{1}' created." -f $MyInvocation.MyCommand.Name, $ISOOutputDirectory) -Type DBG
        }

        # Specifies a list of files that will be copied to the tempoarily file.
        $Files = [System.Collections.Generic.List[Object]]::new()

        #Write-DSILog ("{0} - Finish: ISO Conversion Prep." -f $MyInvocation.MyCommand.Name) -Type DBG
        #Write-DSILog ("{0} - Starting InputObject iteration." -f $MyInvocation.MyCommand.Name) -Type DBG
    }
    Process
    {
        # Warning - InputObject doesn't exist.
        if (-not (Test-Path -Path $InputObject -PathType Any))
        {
            #Write-DSILog ("{0} - Item '{1}' does not exist. Skipping." -f $MyInvocation.MyCommand.Name, $InputObject) -Type WARN
            return
        }

        $Files.Add($InputObject)
    }
    End
    {
        try
        {
            # Warning - No files provided to convert to ISO.
            if ($Files.Count -eq 0)
            {
                #Write-DSILog ("{0} - No files provided to convert to ISO." -f $MyInvocation.MyCommand.Name) -Type WARN
                return
            }

            # Retrieve Hashes Path from DSI Iso object.
            [String]$HashesPath = $DSIIso.FileHashesPath

            # Retrieve Hash values from Hashes Path.
            if (Test-Path -Path $HashesPath -PathType Leaf)
            {
                #Write-DSILog ("{0} - Retrieving Hash values from '{1}'." -f $MyInvocation.MyCommand.Name, $HashesPath) -Type VRB

                # Retrieve Hash values from Hashes Path.
                [String[]]$Hashes = (
                    (Get-Content -Path $HashesPath -ErrorAction SilentlyContinue) | 
                    ConvertFrom-Json | 
                    Sort-Object
                )
            }
            else
            {
                # Initialize an empty array if $HashesPath doesn't exist.
                [String[]]$Hashes = @()
            }

            #Write-DSILog ("{0} - Calculating hashes from provided files." -f $MyInvocation.MyCommand.Name) -Type DBG
            #Write-DSILog ("{0} - Retrieving all provided files." -f $MyInvocation.MyCommand.Name) -Type DBG

            # Specifies Parameter Splat for Get-ChildItem
            [Hashtable]$GetChildItemParams = @{
                Path          = $Files
                Recurse       = $true
                Force         = $true
                ErrorAction   = "SilentlyContinue"
                ErrorVariable = "GetChildItemError"
            }

            # Retrieve all files from provided paths.
            [Object[]]$AllFiles = Get-ChildItem @GetChildItemParams

            # Error - Get-ChildItem failed to retrieve all files.
            if ($GetChildItemError.Count -gt 0)
            {
                $ErrorMsg = [System.Text.StringBuilder]::new()
                [Void] $ErrorMsg.AppendLine("Failed to retrieve all files. Error(s): ")

                # Iterating through each error and appending to $ErrorMsg.
                $GetChildItemError.ForEach({ [Void] $ErrorMsg.AppendLine("{0}" -f $_.ToString()) })

                #Write-DSILog $ErrorMsg.ToString() -Type CRIT -LogOnly
                $PSCmdlet.ThrowTerminatingError($GetChildItemError[0])
            }

            # Retrieve all hashes from provided files.
            #Write-DSILog ("{0} - Calculating hashes from provided files." -f $MyInvocation.MyCommand.Name) -Type VRB
            [Object[]]$AllHashes = Get-FileHash -Path $AllFiles -Algorithm "SHA256" | Sort-Object -Property Hash

            # Specifies whether to skip comparing hashes between previous and current files.
            [Bool]$SkipCompareHashes = (
                $Force -or
                $Hashes.Count -ne $AllHashes.Count -or
                -not (Test-Path -Path $ISOPath -PathType Leaf)
            )

            # Compare hashes between previous and current files.
            if (-not $SkipCompareHashes)
            {
                # Easiest thing to do would be to compare the before and after by combining the hashes into a single string.
                # If the string is the same, then the hashes are the same.
                # Hashes must be sorted and joined to a single string before comparison.
                #Write-DSILog ("{0} - Comparing hashes between previous and current files." -f $MyInvocation.MyCommand.Name) -Type VRB
            
                # Specifies previous file hashes.
                [String]$PreviousHashes = $Hashes -join ""

                # Specifies current file hashes. Make sure they're sorted before comparison.
                [String]$CurrentHashes = $AllHashes.Hash -join ""

                # Skip - Hashes are the same.
                if ($PreviousHashes -eq $CurrentHashes)
                {
                    #Write-DSILog ("{0} - Previous and Current Files are the same. Skipping ISO creation." -f $MyInvocation.MyCommand.Name) -Type INFO
                    return
                }
                else
                {
                    #Write-DSILog ("{0} - Previous and Current Files are different. Creating ISO." -f $MyInvocation.MyCommand.Name) -Type INFO
                }
            }

            # Copy files to temporary folder.
            #Write-DSILog ("{0} - Copying files to Temporary Folder." -f $MyInvocation.MyCommand.Name) -Type VRB
        
            # Specifies Parameter Splat for Copy-Item
            [Hashtable]$CopyItemParams = @{
                Path          = $AllFiles
                Destination   = $ISOTempDirectory
                Force         = $true
                ErrorVariable = "CopyItemError"
                ErrorAction   = "SilentlyContinue"
            }

            Copy-Item @CopyItemParams

            # Error - Copy-Item failed to retrieve all files.
            if ($CopyItemError.Count -gt 0)
            {
                $ErrorMsg = [System.Text.StringBuilder]::new()
                [Void] $ErrorMsg.AppendLine("Failed to copy files to Temporary Folder. Error(s): ")

                # Iterating through each error and appending to $ErrorMsg.
                $CopyItemError.ForEach({ [Void] $ErrorMsg.AppendLine("{0}" -f $_.ToString()) })

                #Write-DSILog $ErrorMsg.ToString() -Type CRIT -LogOnly
                $PSCmdlet.ThrowTerminatingError($CopyItemError[0])
            }

            # Create ISO file.
            #Write-DSILog ("{0} - Creating ISO file." -f $MyInvocation.MyCommand.Name) -Type INFO

            # Specifies Parameter SPlat for Start-Process
            [Hashtable]$StartProcessParams = @{
                FilePath     = $MkIsoFsPath
                ArgumentList = @(
                    "-r",
                    "-iso-level", 
                    "4",
                    "-UDF",
                    "-o", 
                    $ISOPath,
                    $ISOTempDirectory
                )
                Wait         = $true
                WindowStyle  = "Hidden"
                #RedirectStandardOutput = "log.log"
                #RedirectStandardError  = "log.log"
            }

            # Append RunAs if specified.
            if ($RunAsAdmin)
            {
                $StartProcessParams.Add("Verb", "RunAs")
            }

            # Append Credentials if specified.
            if ($PSBoundParameters.ContainsKey("Credential"))
            {
                $StartProcessParams.Add("Credential", $Credential)
            }

            $null = Start-Process @StartProcessParams

            # Error - Failed to create ISO file.
            if (-not (Test-Path -Path $ISOPath -PathType Leaf))
            {
                #Write-Error -Message ("{0} - Failed to create ISO file '{1}'." -f $MyInvocation.MyCommand.Name, $ISOPath) -Category InvalidOperation
                return
            }

            # Save Hashes to Hashes Path.
            #Write-DSILog ("{0} - Saving Hashes to '{1}'." -f $MyInvocation.MyCommand.Name, $HashesPath) -Type VRB
            ($AllHashes.Hash | ConvertTo-Json) | Out-File -FilePath $HashesPath -Force
        }
        finally
        {

            #Write-DSILog ("{0} - Performing cleanup by removing Temporary Folder '{1}'." -f $MyInvocation.MyCommand.Name, $ISOTempDirectory) -Type DBG

            Remove-Item -Path $ISOTempDirectory -Recurse -Force -ErrorAction SilentlyContinue

            #Write-DSILog ("{0} - Finish: Converting files to ISO." -f $MyInvocation.MyCommand.Name) -Type INFO
        }
    }
}