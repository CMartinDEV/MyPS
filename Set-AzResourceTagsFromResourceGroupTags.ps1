
<#PSScriptInfo

.VERSION 1.0.1

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

.PARAMETER SubscriptionId
 The Id(s) of the subscription(s) to re-tag.

.PARAMETER All
 Indicate that you want to re-tag all subscriptions your login account can see.

.PARAMETER Force
 Set the -Force parameter on the Set-AzResource cmdlet used to re-tag each resource.

.PARAMETER Confirm
 Set the -Confirm parameter on the Set-AzResource cmdlet used to re-tag each resource.

.EXAMPLE
 Set-AzResourceTagsFromResourceGroupTags.ps1 -SubscriptionId '789c070a-4eab-4b9b-a5f1-ba83b4682ba6' -Force -Confirm:$false

 Sets all resource tags in the subscription '789c070a-4eab-4b9b-a5f1-ba83b4682ba6' to match their parent resource group, without asking you to confirm for each resource.

.EXAMPLE
 Set-AzResourceTagsFromResourceGroupTags.ps1 -All

 Sets all resource tags in all subscriptions your account can see to match their parent resource group, asking you to confirm for each resource.

#> 

#Requires -Modules Az.Accounts
#Requires -Modules Az.Resources

[CmdletBinding(DefaultParameterSetName = 'BYID')]
Param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ParameterSetName = 'BYID')]
    [Guid[]]$SubscriptionId,

    [Parameter(
        Mandatory = $false,
        ParameterSetName = 'ALL')]
    [switch]$All,

    [switch]$Force,
    [switch]$Confirm
)
Begin {

    $null = Connect-AzAccount -ErrorAction Stop

    if ($All) {
        $subs = Get-AzSubscription -ErrorAction Stop
    }

}
Process {

    $subs = $SubscriptionId | ForEach-Object -Process { Get-AzSubscription -SubscriptionId $_ -ErrorAction Continue }

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
}



