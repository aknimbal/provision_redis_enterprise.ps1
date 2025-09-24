
# Set variables
$SUBSCRIPTION_ID = $(az account show --query id -o tsv)
$CLUSTER_EAST = "aks-ai-cx-n-caching-eastus-rc"
$CLUSTER_WEST = "aks-ai-cx-n-caching-westus-rc"
$LOCATION_EAST = "East US"
$LOCATION_WEST = "West US"
$SKU = "Balanced_B10"
$DB_NAME = "default"
$GROUP_NICKNAME = "redis-geo-group"
$RESOURCE_GROUP = "myRedisRG"
$MODULE_NAME = "RediSearch"

# Login and set subscription
az login
az account set --subscription $subscriptionId

# Create Redis Enterprise clusters in EAST and linked database
az redisenterprise create --location $LOCATION_EAST --cluster-name $CLUSTER_EAST --sku $SKU --resource-group $RESOURCE_GROUP --group-nickname $GROUP_NICKNAME --clustering-policy EnterpriseCluster --linked-databases id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Cache/redisEnterprise/$CLUSTER_EAST/databases/$DB_NAME" --modules name=$MODULE_NAME --eviction-policy "NoEviction"

# Create Redis Enterprise clusters in WEST and create a linked database to EAST
az redisenterprise create --location $LOCATION_WEST --cluster-name $CLUSTER_WEST --sku $SKU --resource-group $RESOURCE_GROUP --group-nickname $GROUP_NICKNAME --clustering-policy EnterpriseCluster --linked-databases id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Cache/redisEnterprise/$CLUSTER_EAST/databases/$DB_NAME" --linked-databases id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Cache/redisEnterprise/$CLUSTER_WEST/databases/$DB_NAME" --modules name=$MODULE_NAME --eviction-policy "NoEviction" 
