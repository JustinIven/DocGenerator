<#
.SYNOPSIS
Creates Markdown documentations from PowerShell modules and scripts.

.DESCRIPTION
Generates a Markdown (.md) documentation for each PowerShell script (.ps1) in a folder or each Cmdlet in a Module, which has the necessary headers required by Get-Help.
Also generates an index document which lists (and links to) all generated files. Each file name can be preceded by a prefix so that they are listed together when viewing the Wiki documents.

.PARAMETER SourceScriptFolder
Source folder where the scripts are located

.PARAMETER SourceModul
Source module from which the documentation are generated  

.PARAMETER DocumentationOutputFolder
Output folder where the documentation will be created

.PARAMETER DocumentationIndexPath
The name of the main file that refer all generated files

.EXAMPLE
C:\PS> .\docgenerator.ps1 -SourceScriptFolder 'C:\temp\project\scripts' -DocumentationOutputFolder 'C:\temp\project\docs' -DocumentationIndexPath 'README.md'

.EXAMPLE
C:\PS> .\docgenerator.ps1 -SourceModul AzureAD -DocumentationOutputFolder 'C:\temp\project\docs' -DocumentationIndexPath 'README.md'
rserser

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Script", HelpMessage = "Source folder where the scripts are located")]
    [ValidateScript({ Test-Path $_ -PathType 'Container' })]
    [string]$SourceScriptFolder,

    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Module", HelpMessage = "Source folder where the scripts are located")]
    [ValidateScript({ Get-Module -Name $_ })]
    [string]$SourceModul,

    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Output folder where the documentation will be created")]
    [ValidateScript({ Test-Path $_ -PathType 'Container' })]
    [string]$DocumentationOutputFolder,

    [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Name of the index (markdown) file")]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$DocumentationIndex="index.md"
)


$arrHelpProperties = [ordered]@{
    Synopsis    = $true;
    Syntax      = $true;
    Description = $true;
    Examples    = $true;
    Parameters  = $false;
    relatedLinks= $false;
} 

$arrParameterProperties = @(
    "Required",
    "DefaultValue",
    "ParameterValue",
    "Position",
    "PipelineInput"
)

# Prefix and Suffix of files
$docNamePrefix = ""
$docNameSuffix = ".md"

function Write-Markdown {
    param (
        [string]$Titel,
        [string]$Description,
        [int]$Indent,
        [string]$Path
    )
    "#" * $Indent + " " + $Titel | Out-File $Path -Append
    if ($Description) {  
        $Description + "`n"| Out-File $Path -Append
    }
}

function Get-MarkdownScriptBlock {
    param (
        [string]$Language,
        [string]$Code
    )
    $block = "``````" + $Language
    $block += "`n{0}`n" -f $Code
    $block += "``````"
    return $block
}

function Get-DocFromHelp {
    param (
        $help,
        $name,
        $outputFile,
        $DocumentationIndexPath,
        $SourceScriptFolder="_"
    )
    if ($help.getType().Name -eq "String") {
        # If there's no inline help in the script then Get-Help returns a string
        Write-Warning -Message "Inline help not found for $($Name)"
        return
    }

    foreach ($i in $arrHelpProperties.Keys) {
        if (!($help.$i)) {  
            if ($arrHelpProperties[$i]) {
                Write-Warning -Message ("{0} not defined in {1}" -f $i, $Name)
                return
            } else { 
                Write-Warning -Message ("{0} not defined in {1}" -f $i, $Name)
            }
        }
    }

    # Delete old file
    Remove-Item -Path $outputFile -Force -ErrorAction Ignore

    # Script and Synposis to the index 
    $Titel = "[{0}]({1})" -f $name, ($docNamePrefix + $Name + $docNameSuffix)
    Write-Markdown -Titel $Titel -Description $help.synopsis -Indent 2 -Path $DocumentationIndexPath


    # Titel and Synopsis
    Write-Markdown -Titel $name -Description $help.Synopsis -Indent 1 -Path $outputFile
    
    # Syntax
    $syntax = ($help.Syntax | Out-String).trim().Replace($SourceScriptFolder + "\", "").Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
    $Description = foreach ($i in $syntax) {
        Get-MarkdownScriptBlock -Language "PowerShell" -Code $i
        "`n"
    }
    Write-Markdown -Titel "Syntax" -Description $Description -Indent 2 -Path $outputFile

    # Description
    Write-Markdown -Titel "Description" -Description $help.Description.Text -Indent 2 -Path $outputFile

    # Examples
    Write-Markdown -Titel "Examples" -Indent 2 -Path $outputFile
    forEach ($i in $help.Examples.Example) {
        $Titel = $i.title.Replace("--------------------------", "").Replace("BEISPIEL", "Example")
        $Description = Get-MarkdownScriptBlock -Language "PowerShell" -Code $i.Code
        $Description += if (![string]::IsNullOrWhiteSpace($i.Remarks.Text)) {
            "`n"
            ($i.Remarks | Out-String).Trim()
        }
        Write-Markdown -Titel $Titel -Description $Description -Indent 3 -Path $outputFile
    }
    
    # Paramaters
    Write-Markdown -Titel "Paramaters" -Indent 2 -Path $outputFile
    forEach ($i in $help.Parameters.Parameter) {
        $Titel = "``-{0}``" -f $i.name
        $Description = "{0}`n`n" -f ($i.Description | Out-String).Trim()
        $Description += "| | |`n|---|---|`n"
        $Description += "| Type: | {0} |`n" -f $i.Type.Name
        $Description += forEach ($j in $arrParameterProperties) {
            if ($i.$j) {
                "| {0}: | {1} |`n" -f $j, $i.$j
            }
        }
        Write-Markdown -Titel $Titel -Description $Description -Indent 3 -Path $outputFile
    }

    # Related Links
    $relatedLinks = $help.relatedLinks.navigationLink.linkText
    $relatedLinks += $help.relatedLinks.navigationLink.uri
    
    $Description = ForEach ($i in $relatedLinks) {
        if ($i) {
            "* $i`n"
        }
    }
    Write-Markdown -Titel "Related Links" -Description $Description -Indent 2 -Path $outputFile    
}

$DocumentationIndexPath = Join-Path -Path $DocumentationOutputFolder -ChildPath $DocumentationIndex
Remove-Item -Path $DocumentationIndexPath -Force -ErrorAction Ignore

if ($SourceScriptFolder) {
    # Index header
    Write-Markdown -Titel "PowerShell Scripts" -Indent 1 -Path $DocumentationIndexPath

    # Get the scripts from the folder
    $SourceScriptFolder = Resolve-Path -Path $SourceScriptFolder
    $scripts = Get-Childitem $SourceScriptFolder -Filter "*.ps1"

    $index = 0
    foreach ($script in $scripts) {
        $index ++
        Write-Progress -Activity "Documenting scripts" -Status ("Script $index of $($scripts.count)") -CurrentOperation ("Documenting: $($Script.BaseName)") -PercentComplete ($index / $scripts.count * 100)
        
        $help = Get-Help $script.FullName -ErrorAction "SilentlyContinue"
        $outputFile = Join-Path -Path $DocumentationOutputFolder -ChildPath ($docNamePrefix + $script.BaseName + $docNameSuffix)
        Get-DocFromHelp -help $help -name $script.name -outputFile $outputFile -DocumentationIndexPath $DocumentationIndexPath
    }    
} else {
    # Index header
    Write-Markdown -Titel "$SourceModul Module" -Indent 1 -Path $DocumentationIndexPath

    # Get Cmdlets from Modul
    $moduls = Get-Command -Module $SourceModul

    $index = 0
    foreach ($modul in $moduls.Name) {
        $index ++
        Write-Progress -Activity "Documenting Modul" -Status ("Script $index of $($moduls.count)") -CurrentOperation ("Documenting: $($Script.BaseName)") -PercentComplete ($index / $moduls.count * 100)
        
        $help = Get-Help $modul -ErrorAction "SilentlyContinue"
        $outputFile = Join-Path -Path $DocumentationOutputFolder -ChildPath ($docNamePrefix + $modul + $docNameSuffix)
        Get-DocFromHelp -help $help -name $modul -outputFile $outputFile -DocumentationIndexPath $DocumentationIndexPath
    }
}

Write-Progress -Activity "Documenting scripts" -Completed