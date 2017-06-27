# Missing Children Society of Canada

## Description
All required Azure infrastructure in the form of ARM Templates.

## Quick start
1. Clone
2. Fill Out:
- [mcsc-serviceBus.parameters.json](https://github.com/Missing-Children-Society-Canada/infrastructure/blob/master/mcsc-serviceBus.parameters.json)
- [TwitterPull-LogicApp.parameters.json](https://github.com/Missing-Children-Society-Canada/infrastructure/blob/master/TwitterPull-LogicApp.parameters.json)
- [mcsc-webhook.parameters.json](https://github.com/Missing-Children-Society-Canada/infrastructure/blob/master/mcsc-webhook.parameters.json)
- [mscs-cf-functions-v2.parameters.json](https://github.com/Missing-Children-Society-Canada/infrastructure/blob/master/mscs-cf-functions-v2.parameters.json)
3. Powershell dev-deploy.ps1 $resourceGroupName $location