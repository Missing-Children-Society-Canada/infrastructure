#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"
$starttime = get-date

#az component update --add cosmosdb

#region Prep & signin
# sign in
Write-Host "Logging in ...";
#Login-AzureRmAccount | Out-Null

# Set variables

# select subscription
$subscriptionId = Read-Host -Prompt 'Input your Subscription ID'
$Subscription = Select-AzureRmSubscription -SubscriptionId $SubscriptionId | out-null

# select Resource Group
$ResourceGroupName = Read-Host -Prompt 'Input the Resource Group for Solution'

# select Location
$Location = Read-Host -Prompt 'Input the Location for your Resource Group'

# CosmosDB Account Name
$DBAccountName = Read-Host -Prompt 'Input the CosmosDB Account Name'
$DBAccountName = $DBAccountName.ToLower()

# DB & collections names in the CosmosDB Account
$reportingdatabaseName = "reporting"
$userdatabaseName = "user"
$eventscollectionName = "events"
$socialscollectionName = "socials"

#endregion

#region Set Template and Parameter location

$Date=Get-Date -Format yyyyMMdd

# set  Root Uri of GitHub Repo (select AbsoluteUri)

$buildingBlocksRootUriString = $env:TEMPLATE_ROOT_URI
if ($buildingBlocksRootUriString -eq $null) {
  $buildingBlocksRootUriString = "https://raw.githubusercontent.com/Missing-Children-Society-Canada/infrastructure/master/"
}

if (![System.Uri]::IsWellFormedUriString($buildingBlocksRootUriString, [System.UriKind]::Absolute)) {
  throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}

Write-Output "Using $buildingBlocksRootUriString to locate templates"

$templateRootUri = New-Object System.Uri -ArgumentList @($buildingBlocksRootUriString)

# set template files

$ServiceBusTemplate = $templateRootUri.AbsoluteUri + "mcsc-serviceBus.json"
$TwitterPullTemplate = $templateRootUri.AbsoluteUri + "TwitterPull-LogicApp.json"
$FunctionsTemplate = $templateRootUri.AbsoluteUri + "mscs-cf-functions-v2.json"
$WebHookTemplate = $templateRootUri.AbsoluteUri + "mcsc-webhook.json"
$WebAppTemplate = $templateRootUri.AbsoluteUri + "Webapp-Auth.json"
$PortalTemplate = $templateRootUri.AbsoluteUri + "Portal-Webapp-config.json"

#endregion

Write-Output  '*****************************************************'
Write-Output  '             Resource Group'
Write-Output  '*****************************************************'

#region Create the resource group

# Start the deployment
Write-Output "Starting deployment"

Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0  | Out-Null

if ($notPresent) {
    Write-Output "Could not find resource group '$ResourceGroupName' - will create it."
    Write-Output "Creating resource group '$ResourceGroupName' in location '$Location'...."
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force | out-null
}
else {
    Write-Output "Using existing resource group '$ResourceGroupName'"
}

#endregion


Write-Output  '*****************************************************'
Write-Output  '             DB account'
Write-Output  '*****************************************************'

# Create a MongoDB API Cosmos DB account
az cosmosdb create --name $DBAccountName.ToLower() --kind GlobalDocumentDB --resource-group $resourceGroupName --max-interval 10 --max-staleness-prefix 200 | out-null

Write-Output  '*****************************************************'
Write-Output  '             create DB'
Write-Output  '*****************************************************'

Write-Output  'Create Reporting Database'

# Create a database
$value = az cosmosdb database exists --db-name $reportingdatabaseName --resource-group-name $resourceGroupName --name $DBAccountName | out-null

if ($value -ne "true")
{
    az cosmosdb database create --name $DBAccountName --db-name $reportingdatabaseName --resource-group $resourceGroupName | out-null
}

# Create a database

Write-Output  'Create Users Database'

$value=az cosmosdb database exists --db-name $userdatabaseName --resource-group-name $resourceGroupName --name $DBAccountName | out-null

if ($value -ne "true")
{
    az cosmosdb database create --name $DBAccountName --db-name $userdatabaseName --resource-group $resourceGroupName | out-null
}

Write-Output  '*****************************************************'
Write-Output  '             create collections'
Write-Output  '*****************************************************'

Write-Output  'create collection events'

# Create a collection

$value = az cosmosdb collection exists --collection-name $eventscollectionName --db-name $reportingdatabaseName --resource-group-name $resourceGroupName --name $DBAccountName

if ($value -ne "true")
{
    az cosmosdb collection create --collection-name $eventscollectionName --name $DBAccountName --db-name $reportingdatabaseName --resource-group $resourceGroupName
}

# Create a collection

Write-Output  'create collection socials'

$value= az cosmosdb collection exists --collection-name $socialscollectionName --db-name $userdatabaseName --resource-group-name $resourceGroupName --name $DBAccountName | out-null

if ($value -ne "true")
{
    az cosmosdb collection create --collection-name $socialscollectionName --name $DBAccountName --db-name $userdatabaseName --resource-group $resourceGroupName | out-null
}

Write-Output  '*****************************************************'
Write-Output  '             Deploying Infrastructure'
Write-Output  '*****************************************************'

#region Deployment of Service bus

Write-Output "Deploying Service Bus..."
$DeploymentName = 'ServiceBuss-'+ $Date

$Results = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $ServiceBusTemplate -TemplateParameterObject `
    @{ `
        serviceBusNamespaceName = "MCSCChildFinderPL"; `
        tofilter_queue_name="tofilter"; `
        tostructure_queue_name="tostructure"; `
        tostore_queue_name="tostore"; `
        augment_topic_name="toaugment"; `
    } -Force | out-null

Write-Output  '*****************************************************'

#endregion

#region Deployment of Twitter Pull

Write-Output "Deploying Twitter Pull Logic App..."
$DeploymentName = 'TwitterPull-'+ $Date

$Results = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $TwitterPullTemplate -TemplateParameterObject `
    @{ `
        logicAppName="twitter-pull"; `
        serviceBusNamespaceName="MCSCChildFinderPL"; `
        serviceBusConnectionName="serviceBusConnection"; `
        serviceBusQueueName="toFilter"; `
        twitterConnectionName="twitterConnection"; `
        twitterHashtag="HFMTest"; `
    } -Force | out-null

Write-Output  '*****************************************************'

#endregion

#region Deployment of Azure Functions

Write-Output "Deploying Azure Function..."
$DeploymentName = 'Functions-'+ $Date

$Results = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $FunctionsTemplate -TemplateParameterObject `
    @{ `
        functionAppsName="PL99-mscs-cf-functions"; `
        storageAccountType="Standard_LRS"; `
        cosmosDBAccountName=$DBAccountName.tostring(); `
        serviceBusNamespaceName="MCSCChildFinderPL"; `
        facebookToken=""; `
        TwitterConsumerKey=""; `
        TwitterConsumerSecret=""; `
        TwitterAccessTokenKey=""; `
        TwitterAccessTokenSecret=""; `
        instagramToken=""; `
        repoURL="https://github.com/Missing-Children-Society-Canada/messaging"; `
        branch="master"; `
    } -Force | out-null

Write-Output  '*****************************************************'

#endregion

#region Deployment of Web Hook

Write-Output "Deploying Web Hook..."
$DeploymentName = 'WebHook-'+ $Date

$Results = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $WebHookTemplate -TemplateParameterObject `
    @{ `
        functionAppsName="PL88-mcsc-webhook"; `
        storageAccountType="Standard_LRS"; `
        serviceBusNamespaceName="MCSCChildFinderPL"; `
        facebookToken="123456789"; `
        instagramToken="123456789"; `
        repoURL="https://github.com/Missing-Children-Society-Canada/webhooks"; `
        branch="master"; `
    } -Force | out-null

Write-Output  '*****************************************************'

#endregion

#region Deployment of Web App

Write-Output "Deploying Web App Auth..."
$DeploymentName = 'WebAppAuth-'+ $Date

$Results = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $WebAppTemplate -TemplateParameterObject `
    @{ `
        sites_MCSC_Authorization_name="mcsc-authorization-pr"; `
        TWITTER_CONSUMER_KEY=""; `
        TWITTER_CONSUMER_SECRET=""; `
        ROOT=""; `
        APP_INSIGHTS_KEY=""; `
        IG_VERIFY_TOKEN=""; `
        FACEBOOK_CONSUMER_KEY=""; `
        FACEBOOK_CONSUMER_SECRET=""; `
        INSTAGRAM_CONSUMER_KEY=""; `
        INSTAGRAM_CONSUMER_SECRET=""; `
        PORTAL_APP_INSIGHTS_KEY=""; `
        WEBSITE_NODE_DEFAULT_VERSION=""; `
        repoURL="https://github.com/Missing-Children-Society-Canada/authorization"; `
        branch="master"; `
    } -Force | out-null

Write-Output  '*****************************************************'

#endregion

#region Deployment of Web App Portal

Write-Output "Deploying Web App Portal..."
$DeploymentName = 'WebAppPortal-'+ $Date

$Results = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $PortalTemplate -TemplateParameterObject `
    @{ `
        sites_MCSC_Authorization_name="mcsc-portal-dev"; `
        APP_INSIGHTS_KEY=""; `
        repoURL="https://github.com/Missing-Children-Society-Canada/portal-node"; `
        branch="master"; `
    } -Force | out-null

Write-Output $Results.

Write-Output  '*****************************************************'

#endregion

$endtime = get-date
$procestime = $endtime - $starttime
$time = "{00:00:00}" -f $procestime.Minutes
write-output " Deployment completed in '$time' "