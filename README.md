# docgenerator.ps1
Creates Markdown documentations from PowerShell modules and scripts.

## Syntax
```PowerShell
Z:\Raidserver_Daten\SIM\PSScripts\docgenerator.ps1 [-SourceScriptFolder] <String> [-DocumentationOutputFolder] <String> [[-DocumentationIndex] <String>] [<CommonParameters>]
``` 
 ```PowerShell
Z:\Raidserver_Daten\SIM\PSScripts\docgenerator.ps1 [-SourceModul] <String> [-DocumentationOutputFolder] <String> [[-DocumentationIndex] <String>] [<CommonParameters>]
``` 


## Description
Generates a Markdown (.md) documentation for each PowerShell script (.ps1) in a folder or each Cmdlet in a Module, which has the necessary headers required by Get-Help.
Also generates an index document which lists (and links to) all generated files. Each file name can be preceded by a prefix so that they are listed together when viewing the Wiki documents.

## Examples
###  Example 1 
```PowerShell
.\docgenerator.ps1 -SourceScriptFolder 'C:\temp\project\scripts' -DocumentationOutputFolder 'C:\temp\project\docs' -DocumentationIndexPath 'README.md'
```

###  Example 2 
```PowerShell
.\docgenerator.ps1 -SourceModul AzureAD -DocumentationOutputFolder 'C:\temp\project\docs' -DocumentationIndexPath 'README.md'
```
 rserser

## Paramaters
### `-SourceScriptFolder`
Source folder where the scripts are located

| | |
|---|---|
| Type: | String |
| Required: | true |
 | ParameterValue: | String |
 | Position: | 1 |
 | PipelineInput: | false |


### `-SourceModul`
Source module from which the documentation are generated

| | |
|---|---|
| Type: | String |
| Required: | true |
 | ParameterValue: | String |
 | Position: | 1 |
 | PipelineInput: | false |


### `-DocumentationOutputFolder`
Output folder where the documentation will be created

| | |
|---|---|
| Type: | String |
| Required: | true |
 | ParameterValue: | String |
 | Position: | 2 |
 | PipelineInput: | false |


### `-DocumentationIndex`


| | |
|---|---|
| Type: | String |
| Required: | false |
 | DefaultValue: | index.md |
 | ParameterValue: | String |
 | Position: | 3 |
 | PipelineInput: | false |


## Related Links
* https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7


