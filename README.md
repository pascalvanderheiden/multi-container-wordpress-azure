# Multi-container WordPress on Azure with Azure DevOps
A fully automated DevOps deployment of CMS WordPress on Azure App Services in a Linux Container. Setup with services like: Azure MySQL, Redis Cache, CDN, Azure Storage and Key Vault (to store mysql password).

The multi-container setup is used to host WordPress and Redis Cache in one App Service. This DevOps project is inspired on: https://docs.microsoft.com/en-us/azure/app-service/containers/tutorial-multi-container-app

## DevOps Project included
In the DevOps folder the Azure DevOps template is included. Login with your account and Open the DevOps Generator: 
https://azuredevopsdemogenerator.azurewebsites.net/environment/createproject

Choose Template, Private and download the Zip from this URL:
https://github.com/pascalvanderheiden/multi-container-wordpress-azure/blob/master/devops/Multi-container%20WordPress%20on%20Azure.zip

Point to this downloaded file.

## Create a Service Principle for the deployement
In the Cloud Shell: 

az ad sp create-for-rbac --name multicontainerwponazure

Copy output JSON: AppId and password and use this SP in DevOps to deploy your project.

## Redis Object Cache Plugin in WordPress
In WordPress, install plug-in "Redis Object Cache"
Just click Enable

## CDN Plugin in WordPress
In Wordpress, install plug-in "CDN Enabler"
Change the settings of the plugin: url http://cdn.<FQDN>
  
## Create wildcard SSL Certificate for your website (optional)
wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
sudo ./certbot-auto

sudo ./certbot-auto certonly \
--server https://acme-v02.api.letsencrypt.org/directory \
--manual --preferred-challenges dns \
-d *.<your-domain.com>

## Renew Certificate
certbot-auto renew

## Convert to PFX
sudo openssl pkcs12 \
-inkey /etc/letsencrypt/live/<your-domain.com>/privkey.pem \
-in /etc/letsencrypt/live/<your-domain.com>/cert.pem \
-export -out ./<your-domain.com>.pfx
