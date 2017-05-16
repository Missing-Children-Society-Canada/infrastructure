#!/bin/bash

# install azurecli

echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

# Set variables for the new account, database, and collection

echo '*****************************************************'
echo '             variables'
echo '*****************************************************'

resourceGroupName='mcsc-test'
location='westus'
name='missingchildrendata2'
reportingdatabaseName='reporting'
userdatabaseName='user'
eventscollectionName='events'
socialscollectionName='socials'

echo '*****************************************************'
echo '             Resource Group'
echo '*****************************************************'

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

echo '*****************************************************'
echo '             DB account'
echo '*****************************************************'

# Create a MongoDB API Cosmos DB account
az cosmosdb create \
	--name $name \
	--kind MongoDB \
	--resource-group $resourceGroupName \
	--max-interval 10 \
	--max-staleness-prefix 200

echo '*****************************************************'
echo '             create DB'
echo '*****************************************************'

echo 'Create Reporting Database'

# Create a database
value=$(az cosmosdb database exists --db-name $reportingdatabaseName --resource-group-name $resourceGroupName --name $name)

if [ $value != 'true' ]
then
az cosmosdb database create \
	--name $name \
	--db-name $reportingdatabaseName \
	--resource-group $resourceGroupName
fi

# Create a database

echo 'Create Users Database'

value=$(az cosmosdb database exists --db-name $userdatabaseName --resource-group-name $resourceGroupName --name $name)

if [ $value != 'true' ]
then
az cosmosdb database create \
        --name $name \
        --db-name $userdatabaseName \
        --resource-group $resourceGroupName
fi

echo '*****************************************************'
echo '             create collections'
echo '*****************************************************'

echo 'create collection events'

# Create a collection

value=$(az cosmosdb collection exists \
	--collection-name $eventscollectionName \
	--db-name $reportingdatabaseName  \
	--resource-group-name $resourceGroupName \
	--name $name)

if [ $value != 'true' ]
then
az cosmosdb collection create \
	--collection-name $eventscollectionName \
	--name $name \
	--db-name $reportingdatabaseName \
	--resource-group $resourceGroupName
fi

# Create a collection

echo 'create collection socials'

value=$(az cosmosdb collection exists \
	--collection-name $socialscollectionName \
	--db-name $userdatabaseName \
	--resource-group-name $resourceGroupName \
	--name $name)

if [ $value != 'true' ]
then
az cosmosdb collection create \
        --collection-name $socialscollectionName \
        --name $name \
        --db-name $userdatabaseName \
        --resource-group $resourceGroupName
fi

echo 'done'
