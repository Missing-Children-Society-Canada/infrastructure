break;
# Set variables for the new account, database, and collection

echo '*****************************************************'
echo '             variables'
echo '*****************************************************'

$resourceGroupName = "MCSC-Dev2-RG"
$location = "eastus2"

# Create a resource group
az group create --name $resourceGroupName --location $location

az group deployment create --name DeployServiceBus --resource-group $resourceGroupName --template-file mcsc-serviceBus.json --parameters @mcsc-serviceBus.parameters.json

az group deployment create --name DeployLogicApp --resource-group $resourceGroupName --template-file TwitterPull-LogicApp.json --parameters @TwitterPull-LogicApp.parameters.json

az group deployment create --name DeploySupporting-api --resource-group $resourceGroupName --template-file mcsc-supporting-api.json --parameters @mcsc-supporting-api.parameters.json

az group deployment create --name DeployWebHooksFunctionApp --resource-group $resourceGroupName --template-file mcsc-webhook.json --parameters @mcsc-webhook.parameters.json

az group deployment create --name DeployCFFunctionApp --resource-group $resourceGroupName --template-file mscs-cf-functions-v2.json --parameters @mscs-cf-functions-v2.parameters.json



