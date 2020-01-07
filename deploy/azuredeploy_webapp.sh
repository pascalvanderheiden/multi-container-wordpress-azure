#!/bin/bash

# Arguments
# -r Resource Group Name WebApp
# -s Resource Group Name Shared Resources
# -l Location Name
# -a App Service Plan Name
# -m MySQL Server Name
# -d MySQL Database Name
# -w Web App Name
# -c Content Delivery Network (CDN) - empty to be optional
# -e CDN Endpoint - empty to be optional
# -x Storage Account - empty to be optional
# -y Azure File Share - empty to be optional (otherwise it will use the container storage as persistent storage)
# 
# Executing it with minimum parameters:
#   ./azuredeploy_webapp.sh -r wordpress-rg -s wordpressshared-rg -l westeurope -a wordpress-sp -m wp-mysql-svr -d wp_wordpressdb -w wordpress-wa -c wordpress-cdn -e wordpress -x wordpressst01 -y conwordpress
#
# This script assumes that you already executed "az login" to authenticate 
#
# For Azure DevOps it's best practice to create a Service Principle for the deployement
# In the Cloud Shell:
# For example: az ad sp create-for-rbac --name multicontainerwponazure
# Copy output JSON: AppId and password

while getopts r:s:l:a:m:d:w:c:e:x:y: option
do
	case "${option}"
	in
		r) RESOURCEGROUP_WEBAPP=${OPTARG};;
        s) RESOURCEGROUP_SHARED=${OPTARG};;
		l) LOCATION=${OPTARG};;
		a) SERVICEPLAN=${OPTARG};;
		m) MYSQLSVR=${OPTARG};;
		d) MYSQLDB=${OPTARG};;
		w) WEBAPP=${OPTARG};;
		c) CDN=${OPTARG};;
		e) CDN_ENDPOINT=${OPTARG};;
		x) STORAGEACC=${OPTARG};;
		y) FILESHARE=${OPTARG};;
	esac
done

# Functions
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

# Setting up some default values if not provided
# if [ -z ${RESOURCEGROUP} ]; then RESOURCEGROUP="wordpress-rg"; fi 

echo "Input parameters"
echo "   Resource Group WebApp: ${RESOURCEGROUP_WEBAPP}"
echo "   Resource Group Shared: ${RESOURCEGROUP_SHARED}"
echo "   Location: ${LOCATION}"
echo "   App Service Plan: ${SERVICEPLAN}"
echo "   MySQL Server: ${MYSQLSVR}" 
echo "   MySQL Database: ${MYSQLDB}"
echo "   WebApp: ${WEBAPP}"
echo "   CDN: ${CDN}"
echo "   CDN Endpoint: ${CDN_ENDPOINT}"
echo "   Storage Account: ${STORAGEACC}"
echo "   Azure File Share: ${FILESHARE}"; echo

#--------------------------------------------
# Registering providers & extentions
#--------------------------------------------
echo "Registering providers"
az provider register -n Microsoft.DBforMySQL
az provider register -n Microsoft.Web
az provider register -n Microsoft.DomainRegistration
az provider register -n Microsoft.Network
az provider register -n Microsoft.Compute
az provider register -n Microsoft.ContainerService
az provider register -n Microsoft.CDN
az provider register -n Microsoft.Storage

#--------------------------------------------
# Creating Resource group WebApp
#-------------------------------------------- 
echo "Creating resource group ${RESOURCEGROUP_WEBAPP}"
RESULT=$(az group exists -n $RESOURCEGROUP_WEBAPP)
if [ "$RESULT" = "false" ]
then
	az group create -l $LOCATION -n $RESOURCEGROUP_WEBAPP
else
	echo "   Resource group ${RESOURCEGROUP_WEBAPP} already exists"
fi

#--------------------------------------------
# Creating App Service Plan
#-------------------------------------------- 
echo "Creating App Service Plan ${SERVICEPLAN}"
RESULT=$(az appservice plan show -n $SERVICEPLAN -g $RESOURCEGROUP_WEBAPP)
if [ "$RESULT" = "" ]
then
	az appservice plan create -n $SERVICEPLAN -g $RESOURCEGROUP_WEBAPP -l $LOCATION --is-linux --sku S1
else
	echo "   App Service Plan ${SERVICEPLAN} already exists"
fi

#--------------------------------------------
# Creating MySQL Database
#-------------------------------------------- 
echo "Creating MySQL Database ${MYSQLDB}"
RESULT=$(az mysql db show -g $RESOURCEGROUP_SHARED -s $MYSQLSVR -n $MYSQLDB)
if [ "$RESULT" = "" ]
then
	az mysql db create -g $RESOURCEGROUP_SHARED -s $MYSQLSVR -n $MYSQLDB
else
	echo "   MySQL Database ${MYSQLDB} already exists"
fi

#--------------------------------------------
# Creating WebApp
#-------------------------------------------- 
echo "Creating WebApp ${WEBAPP}"
RESULT=$(az webapp show -n $WEBAPP -g $RESOURCEGROUP_WEBAPP)
if [ "$RESULT" = "" ]
then
	az webapp create -n $WEBAPP -g $RESOURCEGROUP_WEBAPP -p $SERVICEPLAN -i "hello-world"
else
	echo "   WebApp ${WEBAPP} already exists"
fi
echo "Fetching WebApp Hostname"
FQDN=$(az webapp show -n $WEBAPP -g $RESOURCEGROUP_WEBAPP --query "defaultHostName" -o tsv)

#--------------------------------------------
# Creating CDN Endpoint (optional)
#-------------------------------------------- 
echo "Creating CDN Endpoint ${CDN_ENDPOINT}"
RESULT=$(az cdn endpoint show -n $CDN_ENDPOINT --profile-name $CDN -g $RESOURCEGROUP_SHARED)
if [[ -z "$RESULT" && -n "$CDN_ENDPOINT" ]]
then
	# Endpoint
	az cdn endpoint create -g $RESOURCEGROUP_SHARED -n $CDN_ENDPOINT --profile-name $CDN --origin $FQDN --origin-host-header $FQDN
else
	echo "   CDN Endpoint ${CDN_ENDPOINT} already exists or is not provided"
fi

#--------------------------------------------
# Creating Azure File Share (optional)
#-------------------------------------------- 
echo "Creating Azure File Share ${FILESHARE}"

if [[ -n "$STORAGEACC" && -n "$FILESHARE" ]]
then
	# Get Storage Access Key
	ACCESSKEY=$(az storage account keys list -g $RESOURCEGROUP_SHARED -n $STORAGEACC --query [0].value -o tsv)
	RESULT=$(az storage share exists --account-name $STORAGEACC --account-key $ACCESSKEY --name $FILESHARE --query "exists" -o tsv)
	if [ "$RESULT" = "false" ]
	then
		# Create Azure File Share
		az storage share create --name $FILESHARE --account-name $STORAGEACC --account-key $ACCESSKEY --quota 64
	else
		echo "   Azure File Share ${FILESHARE} already exists"
	fi
else
    echo "   Azure File Share is not provided"
fi