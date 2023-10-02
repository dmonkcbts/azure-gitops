## Set the correct Azure subscription, get the key for the storage account containing the tf state,
## and set the required environment variable. ** Assumes already authenticated to Azure

Set-AzContext -SubscriptionId a362b710-5701-4fbc-8d74-c2d4e344427f
$ACCOUNT_KEY=(Get-AzStorageAccountKey -ResourceGroupName rg-infraops-centralus -Name stcinfraopsbtscentus)[0].value
$env:ARM_ACCESS_KEY=$ACCOUNT_KEY
