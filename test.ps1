<#
.SYNOPSIS
    Creates an ISO file from a list of files.
.DESCRIPTION
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Win2022")]
    [String]$OS,

    [Parameter(Mandatory = $false)]
    [Switch]$Force
)

Begin
{
    Write-Host -ForegroundColor Yellow ("{0} - Start - Creating ISO." -f $MyInvocation.MyCommand.Name)

    # If adding another OS, specify the folder location that contain files that must
    # be converted to an ISO.
    [Hashtable]$FolderPaths = @{
        "Win2022" = (Join-Path -Path $PSScriptRoot -ChildPath "data\win_2022")
    }

    # Specifies the path to MKIsoFs.exe.
    [String]$MkIsoFsPath = (Join-Path -Path $PSScriptRoot -ChildPath "lib\mkisofs.exe")

    # Specifies the path to mkisofs.exe and its dependencies.
    [String[]]$MKIsoFiles = @(
        $MkIsoFsPath,
        (Join-Path -Path $PSScriptRoot -ChildPath "lib\cygwin1.dll")
    )

    # Specifies whether to create the ISO file.
    [Bool]$CreateISO = $false

    # Force was provided. Create ISO file.
    if ($Force)
    {
        $CreateISO = $true
    }
}

Process
{
    # Step 1 - Verify mkisofs.exe exists.
    Write-Debug -Message ("{0} - Verifying mkisofs and dependencies exist." -f $MyInvocation.MyCommand.Name)

    # Error - mkisofs or dependencies not found.
    if (-not (Resolve-Path -Path $MKIsoFiles -ErrorVariable ResolveError))
    {
        $Message = [System.Text.StringBuilder]::new()
        [Void] $Message.AppendLine("Unable to copy all files to temporary directory. Error: ")
    
        $ResolveError.ForEach({ [Void] $Message.AppendLine($_.ToString()) })

        Write-Error -Message $Message.ToString() -Category InvalidOperation
        return
    }

    # Step 2 - Create temporary folder
    [String]$TempFolder = Join-Path -Path $ENV:TEMP -ChildPath ("packer_{0}" -f (Get-Date).ToString("yyyyMMddHHmmss"))
    Write-Debug -Message ("{0} - Creating temporary folder '{1}'." -f $MyInvocation.MyCommand.Name, $TempFolder)

    $null = New-Item -Path $TempFolder -ItemType Directory -ErrorAction Stop

    # Error - Failed to create temporary folder.
    if (-not (Test-Path -Path $TempFolder -PathType Container))
    {
        Write-Error -Message (
            "{0} - Failed to create temporary folder '{1}'." -f $MyInvocation.MyCommand.Name, $TempFolder
        ) -Category PermissionDenied
        return
    }

    # Step 3 - Retrieve files based on OS version.
    Write-Debug -Message ("{0} - Retrieving files based on OS version." -f $MyInvocation.MyCommand.Name)
    [String]$FolderPath = $FolderPaths[$OS]

    # Specifies the name of the ISO file.
    [String]$IsoFile = "secondary.iso"
    
    # Specifies the path to the ISO file.
    [String]$IsoPath = Join-Path -Path $FolderPath -ChildPath $IsoFile

    # if Iso doens't exist, update $CreateISO to true.
    if (-not (Test-Path -Path $IsoPath -PathType Leaf))
    {
        $CreateISO = $true
    }

    # Specifies the name of the hashes file.
    [String]$HashFile = "hashes.json"

    # Specifies the path to Hash json file.
    # This file is used to keep track of file hashes.
    [String]$HashPath = Join-Path -Path $FolderPath -ChildPath $HashFile

    # Validate whether $FolderPaths contains OS.
    # Error - Missing Folder Path in variable $FolderPaths.
    if (-not $FolderPath)
    {
        Write-Error -Message (
            "{0} - Folder path for OS version '{1}' does not exist in parameter 'FolderPaths'." -f $MyInvocation.MyCommand.Name, $OS
        ) -Category InvalidArgument
        return
    }

    # Test the existance of the folder path.
    # Error - Folder path does not exist.
    if (-not (Test-Path -Path $FolderPath -PathType Container))
    {
        Write-Error -Message (
            "{0} - Expected directory '{1}' for OS '{2}', but it does not exist." -f $MyInvocation.MyCommand.Name, $FolderPath, $OS
        ) -Category ObjectNotFound
        return
    }

    # Retrieve files based on OS version.
    switch ($OS)
    {
        "Win2022"
        {
            # Retrieve files within $FolderPath's directory.
            [Object[]]$Files = Get-ChildItem -Path $FolderPath -Recurse -Exclude "*.iso", $HashFile

            # Error - No files found.
            if ($Files.Count -eq 0)
            {
                Write-Error -Message (
                    "{0} - No files found in directory '{1}'." -f $MyInvocation.MyCommand.Name, $FolderPath
                ) -Category ObjectNotFound
                return
            }

            # Specifies whether to calculate hashes for files.
            [Bool]$CalcHashes = (
                -not $CreateISO -and 
                (Test-Path -Path $IsoPath -PathType Leaf) -and
                (Test-Path -Path $HashPath -PathType Leaf)
            )

            # Must calculate hashes.
            if ($CalcHashes)
            {
                Write-Debug -Message ("{0} - Calculating file hashes." -f $MyInvocation.MyCommand.Name)

                # This is used to determine if an ISO file needs to be recreated.
                $FileHashes = [System.Collections.Generic.List[PSCustomObject]]::new()

                Get-FileHash -Path $Files -Algorithm SHA256 | ForEach-Object {
                    $FileHashes.Add(
                        [PSCustomObject]@{
                            Path = $_.Path
                            Hash = $_.Hash
                        }
                    )
                }

                # Retrieve previous hashes.
                $PreviousHashes = Get-Content -Path $HashPath | ConvertFrom-Json

                # Compare hashes.
                if (Compare-Object -ReferenceObject $PreviousHashes -DifferenceObject $FileHashes -Property Path, Hash)
                {
                    Write-Debug -Message ("{0} - Hashes are different. Creating ISO." -f $MyInvocation.MyCommand.Name)
                    $CreateISO = $true
                }
            }
            else
            {
                Write-Debug -Message ("{0} - Skipping file hash calculation." -f $MyInvocation.MyCommand.Name)
            }

            $FileHashes | ConvertTo-Json | Out-File -FilePath $HashPath -Force
            break
        }

        default
        {
            Write-Error -Message (
                "{0} - OS version '{1}' is not implemented." -f $MyInvocation.MyCommand.Name, $OS
            ) -Category InvalidArgument
            return
        }
    }

    # Exit - No need to create ISO file.
    if (-not $CreateISO)
    {
        Write-Host -ForegroundColor Yellow ("{0} - No changes detected. Skipping ISO creation." -f $MyInvocation.MyCommand.Name)
        return
    }

    # Step 4 - Copy files to temporary directory.
    Copy-Item -Path $Files -Destination $TempFolder -Recurse -ErrorVariable CopyError

    # Error - Failed to copy files to temporary directory.
    if ($CopyError.Count -gt 0)
    {
        $Message = [System.Text.StringBuilder]::new()

        [Void] $Message.AppendLine("Unable to copy all files to temporary directory. Error: ")
        $CopyError.ForEach({ [Void] $Message.AppendLine($_.ToString()) })

        Write-Error -Message $Message.ToString() -Category InvalidOperation
        return
    }

    # Step 5 - Create ISO file.
    Write-Debug -Message ("{0} - Creating ISO file." -f $MyInvocation.MyCommand.Name)

    # Specifies Parameter SPlat for Start-Process
    [Hashtable]$StartProcessParams = @{
        FilePath     = $MkIsoFsPath
        ArgumentList = @(
            "-r",
            "-iso-level", 
            "4",
            "-UDF",
            "-o", 
            $IsoPath,
            $TempFolder
        )
        Wait         = $true
        WindowStyle  = "Hidden"
    }
    
    $null = Start-Process @StartProcessParams

    # Error - Failed to create ISO file.
    if (-not (Test-Path -Path $IsoPath -PathType Leaf))
    {
        Write-Error -Message (
            "{0} - Failed to create ISO file '{1}'." -f $MyInvocation.MyCommand.Name, $IsoPath
        ) -Category InvalidOperation
        return
    }
}
End
{
    Write-Host -ForegroundColor Yellow ("{0} - Finished - Creating ISO. Performing Cleanup." -f $MyInvocation.MyCommand.Name)
    Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
}