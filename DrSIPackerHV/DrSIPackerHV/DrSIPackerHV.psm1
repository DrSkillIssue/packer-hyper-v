Set-StrictMode -Version Latest

$PSModuleRoot = $ExecutionContext.SessionState.Module.ModuleBase

#region Classes
class DSIIso
{
    # Specifies the path to the ISO file.
    [String]$OutputDirectory
 
    # Specifies the name of the Output ISO file.
    [String]$OutputFile = "Secondary.iso"

    # Specifies a json file that'll contain hashes for files in this ISO.
    [String]$FileHashesPath

    # Specifies the path to the temporary folder that contains files that will be converted to an ISO.
    [String]$TempDirectory

    DSIIso([String]$OutputDir)
    {
        $this._init($OutputDir)
    }
 
    static [Bool] IsFile([String]$Path)
    {
        return [System.IO.Path]::HasExtension($Path)
    }

    static [Bool] IsDirectory([String]$Path)
    {
        return -not [System.IO.Path]::HasExtension($Path)
    }

    static [String] GetTempFolder()
    {
        [String]$TempName = ("packer_{0}" -f (Get-Date).ToString("yyyyMMddHHmmss"))

        return (Join-Path -Path $ENV:TEMP -ChildPath $TempName)
    }

    hidden [Void] _init([String]$Output)
    {
        # Apply Temporary Folder Path if one has not been set.
        if ([String]::IsNullOrEmpty($this.TempDirectory))
        {
            $this.TempDirectory = [DSIIso]::GetTempFolder()
        }
 
        # Return - Don't overwrite OutputDirectory if it's already set.
        if (-not [String]::IsNullOrEmpty($this.OutputDirectory))
        {
            return
        }
 
        # Trim provided Output Directory.
        $Output = $Output.Trim()
         
        # Return - Output Directory not provided.
        if ([String]::IsNullOrEmpty($Output))
        {
            return
        }
 
        # Determine if Output is a file or directory.
        if ([DSIIso]::IsFile($Output))
        {
            [String]$OutputDir = [System.IO.Path]::GetDirectoryName($Output)
            $this.OutputFile = [System.IO.Path]::GetFileName($Output)
        }
        else
        {
            [String]$OutputDir = $Output
        }

        # Set Output Directory.
        $this.OutputDirectory = $OutputDir
 
        # Set hashes path.
        $this.FileHashesPath = Join-Path -Path $OutputDir -ChildPath "content_hashes.json"
    }

    [String] ToString()
    {
        if ([String]::IsNullOrEmpty($this.OutputDirectory))
        {
            return $this.OutputFile
        }
        else
        {
            return (Join-Path -Path $this.OutputDirectory -ChildPath $this.OutputFile)
        }
    }
}
#endregion Classes

[String[]]$Paths = @(
    (Join-Path -Path $PSModuleRoot -ChildPath 'Public'),
    (Join-Path -Path $PSModuleRoot -ChildPath 'Private')
)

[Hashtable]$GetChildItemParams = @{
    Path        = $Paths
    Recurse     = $true
    Include     = "*.ps1"
    ErrorAction = "SilentlyContinue"
}

[Object[]]$Files = Get-ChildItem @GetChildItemParams

ForEach ($File in $Files)
{
    . $File.FullName
}