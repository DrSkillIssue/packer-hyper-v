
@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'DrSIPackerHV.psm1'
    
    # Version number of this module.
    ModuleVersion     = '0.0.0'
    
    # ID used to uniquely identify this module
    GUID              = '4c281da3-59a8-4ed8-b7d7-30bb621acf4a'
    
    # Author of this module
    Author            = 'Dr. Skill Issue <https://github.com/DrSkillIssue>'
    
    # Copyright statement for this module
    Copyright         = '(c) Dr. Skill Issue. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description       = 'PowerShell module for Hyper-V Packer deployments.'
    
    # Minimum version of the PowerShell engine required by this module
    # PowerShellVersion = '5'
    
    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @("*")
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
    
        PSData = @{
    
            # A URL to the license for this module.
            # LicenseUri = ''
    
            # A URL to the main website for this project.
            # ProjectUri = ''
        }
    }
}