
# Set variables
$SUBSCRIPTION_ID = $(az account show --query id -o tsv)

$CLUSTER_EAST = "ai-cx-n-caching-eastus-rc"
$CLUSTER_WEST = "ai-cx-n-caching-westus-rc"
$LOCATION_EAST = "EastUS"
$LOCATION_WEST = "WestUS"
$SKU = "Enterprise_E10"
$DB_NAME = "default"
$GROUP_NICKNAME = "redis-geo-group"
$RESOURCE_GROUP = "ai-cx-n-hydapmtest-rg"

# Select subscription
Select-AzSubscription -SubscriptionId $SUBSCRIPTION_ID

# Create resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $RESOURCE_GROUP -ErrorAction SilentlyContinue)) {
    Write-Host "Creating resource group..."
    New-AzResourceGroup -Name $RESOURCE_GROUP -Location $LOCATION_EAST
} else {
    Write-Host "Resource group already exists."
}

Write-Host "Using subscription: $SUBSCRIPTION_ID"

# Create Redis Enterprise clusters
Write-Host "Creating Redis Enterprise cluster in East US..."
az redisenterprise create `
  --name $CLUSTER_EAST `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION_EAST `
  --sku $SKU

Write-Host "Creating Redis Enterprise cluster in West US..."
az redisenterprise create `
  --name $CLUSTER_WEST `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION_WEST `
  --sku $SKU

# Wait for clusters to be ready
Write-Host "Waiting for clusters to be ready..."
Start-Sleep -Seconds 60

# Create databases in each cluster
Write-Host "Creating database in East US cluster..."
az redisenterprise database create `
  --cluster-name $CLUSTER_EAST `
  --resource-group $RESOURCE_GROUP `
  --name $DB_NAME

Write-Host "Creating database in West US cluster..."
az redisenterprise database create `
  --cluster-name $CLUSTER_WEST `
  --resource-group $RESOURCE_GROUP `
  --name $DB_NAME

# Wait for databases to be ready
Write-Host "Waiting for databases to be ready..."
Start-Sleep -Seconds 60

# Enable active geo-replication
Write-Host "Setting up geo-replication..."
$EAST_DB_ID = "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Cache/redisEnterprise/$CLUSTER_EAST/databases/$DB_NAME"
$WEST_DB_ID = "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Cache/redisEnterprise/$CLUSTER_WEST/databases/$DB_NAME"

az redisenterprise database update `
  --cluster-name $CLUSTER_EAST `
  --resource-group $RESOURCE_GROUP `
  --name $DB_NAME `
  --linked-database-id $WEST_DB_ID `
  --group-nickname $GROUP_NICKNAME

az redisenterprise database update `
  --cluster-name $CLUSTER_WEST `
  --resource-group $RESOURCE_GROUP `
  --name $DB_NAME `
  --linked-database-id $EAST_DB_ID `
  --group-nickname $GROUP_NICKNAME

Write-Host "Azure Managed Redis Enterprise multi-region with geo-replication provisioned."
