#!/bin/bash

# Set variables for the new account, database, and collection

echo '*****************************************************'
echo '             variables'
echo '*****************************************************'
echo ' '


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
echo ' '

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

echo '*****************************************************'
echo '             DB account'
echo '*****************************************************'
echo ' '

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
echo ' '

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
echo ' '


echo 'create collection profile'

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

