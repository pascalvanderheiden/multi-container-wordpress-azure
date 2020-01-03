# Multi-container WordPress on Azure deployed with Azure DevOps
A fully automated DevOps deployment of CMS WordPress on Azure App Services in a Linux Multi-Container. Setup with services like: App Service, Azure MySQL, Redis Cache (in a container), Azure CDN, Azure Storage and Key Vault (to store the mysqluser password).

The multi-container setup is used to host WordPress and Redis Cache in one App Service. This DevOps project is inspired on this tutorial: 
https://docs.microsoft.com/en-us/azure/app-service/containers/tutorial-multi-container-app

The Docker Compose YML's are based on these samples:
https://github.com/Azure-Samples/multicontainerwordpress

## Step by Step installation

### Step 1: In the Azure Portal create a Service Principal
In the Azure Cloud Shell (https://shell.azure.com): 
- az ad sp create-for-rbac --name [your-service-principal-name]

Copy the JSON Output! We'll be needing this information to create the service connection in Azure DevOps.

### Step 2: Generate your Azure DevOps Project for Continuous Integration & Deployment with the Azure DevOps Generator
- In the devops folder of this repro the Azure DevOps template is included. Download it.
- Login with your account and open the DevOps Generator: https://azuredevopsdemogenerator.azurewebsites.net/environment/createproject
- Choose a custom template and point to the zip-file in the devops folder. This repro will be imported into Azure DevOps and Pipelines are created for you.
- The project is split-up into 2 pieces; shared resources & web app resources. Enabling you to extend your project with more web apps and re-using the shared resources for cost efficiency.
- You can find the documentation on the Azure DevOps Generator here: https://vstsdemodata.visualstudio.com/AzureDevOpsDemoGenerator/_wiki/wikis/AzureDevOpsGenerator.wiki/58/Build-your-own-template

### Step 3: In Azure DevOps, create a service connection
- Login with your account Azure DevOps. Go to the Project Settings of the DevOps Project you've created in step 2.
- Go to Service Connections*.
- Create a service connection, choose Azure Resource Manager, next.
- Select Service Principal Authentication. Choose the correct Subscription first, then click the link at the bottom: "use the full version of the service connection dialog.".
- Enter a name for your Service Principal and copy the appId from step 1 in "Service principal client ID" and the password from step 1 in "Service principal key". And Verify the connection.
- Tick "Allow all pipelines to use this connection.". OK.

### Step 4: In Azure DevOps, update the Variables Group.
- Go to Pipelines, Library. Click on the Variable group "Shared Resources".
- Tick "Allow access to all pipelines.
- Update the variables to match your naming conventions needs. You can leave the Storage Account and CDN empty if you don't want to use these services. Keep in mind to pick unique naming for exposed services.
- The variable "KVMYSQLPWD" is NOT the MySQL password, but the naming tag in Key Vault for the MySQL password. Leave that as it is: "mysqladminpwd".
- Don't forget to save.

### Step 5: In Azure DevOps, update the Build pipeline and Run it.
- Go to Pipelines, Pipelines.
- Select "Build Multi-container WordPress on Azure-CI", Edit.
- In Tasks, select the Tasks which have the explaination mark "Some settings need attention", and update Azure Subscription to your Service Principal Connection.
- In Variables, update the variables to match your naming conventions needs. In my case I give the App Service Plan and the Resource Group of the Web App a more "generic" name. I want to re-use the App Service Plan for more websites, therefor all websites need to be deployed in the same Resource Group as the App Service plan. Keep in mind to pick unique naming for exposed services.
- Save & queue.
- Click the Agent Job to check the progress. Check if everything is create correctly, because of the unique naming for some services. And because it's fun :-)
- Keep in mind that the CLI scripts will check if the resource is already created, before creating. You can deploy using ARM Templates as well. I choose a bash script, because you are free to use whatever you prefer, right?!

### Step 6: In Azure DevOps, add the Key Vault secret to the variables.
- Go to Pipelines, Library. Add Variable group. Give it a name, something like "Key Vault Secrets".
- Tick "Allow access to all pipelines.
- Tick "Link secrets from an Azure key vault as variables".
- Update the Azure Subscription to your Service Principal Connection.
- Select the Key vault name. If your build pipeline ran succesfully, you can select your Key vault. Add variables, and it will popup with the secret we've created earlier "mysqladminpwd". Select it, OK. And Save.

### Step 7: In Azure DevOps, update the Release pipeline and Run it.
- Go to Pipelines, Releases.
Note. Because I've enabled continuous deployment in my template, there is a failed release there already. You can ignore that, because we are going to fix the release in the step.
- Select "Release Multi-container WordPress on Azure-CD", Edit.
- In Tasks, select the Tasks which have the explaination mark "Some settings need attention", and update Azure Subscription to your Service Principal Connection.
- In Variables, update the variables to match the naming you used in the Build pipeline. The WPDBHOST you can leave empty, because it will be updated in the pipeline.
- In Variables groups, link the "Key Vault Secrets" variable group, by clicking the Link button. 
- The TARGET_YML will need to point to the yaml configuration files in repro. This will determine how the App Service is configured. There are 4 files:
    + compose-wordpress.yml (sample multi-container setup with redis, using local (not persistent) storage)
    + docker-compose-wordpress.yml (sample multi-container setup with MySQL, using local (not persistent) storage)
    + docker-compose-mc-wordpress-storage.yml (multi-container setup with redis, using Azure Storage for wp-content folder)
    + docker-compose-mc-wordpress.yml (multi-container setup with redis, using Azure App Service as persistent storage)
The first 2 yaml's are more inspirational, the last 2 I would use for my deployment, because persistent storage is a must! Keep in mind that it would be illogical to use the last yaml file, and configure Azure Storage. Just leave the variable empty to skip this installation.
Save & Create Release.

## Step 8: Go to your websites
You need to run the website url one time, to trigger the compose script to download the WordPress image to the persistent storage location. This will take a 2-3 minutes to download.

## Redis Object Cache Plugin in WordPress
- In WordPress, the plugin "Redis Object Cache" is already pre-installed on the this image.
- Go to Plugins and Enable the plugin.

## CDN Plugin in WordPress
- In Wordpress, install the plugin "CDN Enabler". Or, when you have the wp-content folder mounted in Azure Storage, decompress the plugin from the wordpress-plugins folder in this repro and copy it into the "Plugins" folder using Azure Storage Explorer.
- Go to Plugins and Enable the plugin.
Change the settings of the plugin and point it to the CDN Endpoint you've created earlier.