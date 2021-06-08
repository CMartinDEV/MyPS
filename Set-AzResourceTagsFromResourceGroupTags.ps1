
<#PSScriptInfo

.VERSION 1.0.0

.GUID 402e048d-d91b-46b7-b040-710fbe7e89e1

.AUTHOR Chris Martin

.COMPANYNAME Microsoft

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES Az.Accounts,Az.Resources

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Sets resource tags to match their parent resource group. 

#> 

#Requires -Modules Az.Accounts
#Requires -Modules Az.Resources

[CmdletBinding()]
Param(
    [switch]$Force,
    [switch]$Confirm
)

$null = Connect-AzAccount -ErrorAction Stop

$subs = Get-AzSubscription -ErrorAction Stop

foreach ($sub in $subs) {

    Write-Verbose -Message "Moving to the '$($sub.Name)' subscription"

    $null = Select-AzSubscription $sub -ErrorAction Stop

    $groupsHash = @{}

    Get-AzResourceGroup | ForEach-Object -Process { $groupsHash[$_.ResourceGroupName] = $_ }

    $resources = Get-AzResource -ErrorAction Stop

    $resourcesGrouped = $resources | Group-Object -Property ResourceGroupName

    foreach ($group in $resourcesGrouped) {
        
        Write-Verbose -Message "Working on resource group $($group.Name)"

        $matchingRg = $groupsHash[$group.Name]

        $groupTags = $matchingRg.Tags

        foreach ($resource in $group.Group) {
            
            $resourceTags = $resource.Tags

            if ($null -eq $resourceTags) {

                $resourceTags = @{}

            }

            foreach ($key in $groupTags.Keys) {

                $resourceTags[$key] = $groupTags[$key]

            }

            Set-AzResource -ResourceId $resource.Id -Tag $resourceTags -Confirm:$Confirm -Force:$Force -ErrorAction Continue
        }

    }

}
