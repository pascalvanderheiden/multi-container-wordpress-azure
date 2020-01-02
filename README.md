# Multi-container WordPress on Azure deployed with Azure DevOps
A fully automated DevOps deployment of CMS WordPress on Azure App Services in a Linux Container. Setup with services like: App Service, Azure MySQL, Redis Cache (in a container), Azure CDN, Azure Storage and Key Vault (to store the mysqluser password).

The multi-container setup is used to host WordPress and Redis Cache in one App Service. This DevOps project is inspired on this tutorial: 
https://docs.microsoft.com/en-us/azure/app-service/containers/tutorial-multi-container-app

The Docker Compose YML's are based on these samples:
https://github.com/Azure-Samples/multicontainerwordpress

## DevOps Project included
In the devops folder the Azure DevOps template is included. Login with your account and Open the DevOps Generator: 
https://azuredevopsdemogenerator.azurewebsites.net/environment/createproject

Choose a custom template and point to the zip-file in the devops folder. This repro will be imported into Azure DevOps and Pipelines are created for you.
The project is split-up into 2 pieces; shared resources & web app resources. Enabling you to extend your project with more web apps and re-using the shared resources for cost efficiency.

Update the variables, and create a service principle (see below) to deploy your resources to Azure. 

Note. Use unique names for your Web App and Storage. Check the log in DevOps to see if all resources have been created accordingly.

You can find the documentation on the Azure DevOps Generator here:
https://vstsdemodata.visualstudio.com/AzureDevOpsDemoGenerator/_wiki/wikis/AzureDevOpsGenerator.wiki/58/Build-your-own-template

## Create a Service Principle for the deployment
In the Cloud Shell: 
- az ad sp create-for-rbac --name <your-service-principle-name>

Copy output JSON: AppId and password and use this SP in DevOps to deploy your project.

## Redis Object Cache Plugin in WordPress
In WordPress, install plug-in "Redis Object Cache"
Just click Enable.

## CDN Plugin in WordPress
In Wordpress, install plug-in "CDN Enabler"
Change the settings of the plugin and point it to the CDN Endpoint you've created.