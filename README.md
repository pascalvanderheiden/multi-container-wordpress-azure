# Multi-container WordPress on Azure deployed with Azure DevOps
A fully automated DevOps deployment of CMS WordPress on Azure App Services in a Linux Container. Setup with services like: App Service, Azure MySQL, Redis Cache, CDN, Azure Storage and Key Vault (to store mysql password).

The multi-container setup is used to host WordPress and Redis Cache in one App Service. This DevOps project is inspired on: 
https://docs.microsoft.com/en-us/azure/app-service/containers/tutorial-multi-container-app

The Docker Compose YML's are based on these samples:
https://github.com/Azure-Samples/multicontainerwordpress

## DevOps Project included
In the DevOps folder the Azure DevOps template is included. Login with your account and Open the DevOps Generator: 
https://azuredevopsdemogenerator.azurewebsites.net/environment/createproject

You can find the documentation on the Azure DevOps Generator here:
https://vstsdemodata.visualstudio.com/AzureDevOpsDemoGenerator/_wiki/wikis/AzureDevOpsGenerator.wiki/58/Build-your-own-template

## Create a Service Principle for the deployement
In the Cloud Shell: 

az ad sp create-for-rbac --name multicontainerwponazure

Copy output JSON: AppId and password and use this SP in DevOps to deploy your project.

## Redis Object Cache Plugin in WordPress
In WordPress, install plug-in "Redis Object Cache"
Just click Enable.

## CDN Plugin in WordPress
In Wordpress, install plug-in "CDN Enabler"
Change the settings of the plugin: url http://cdn.<FQDN>