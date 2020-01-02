#!/bin/bash

# Arguments
# -r Resource Group Name
# -l Location Name
# -m MySQL Server Name
# -u MySQL Admin User
# -k Key Vault
# -p Key Vault Label MySQL Admin Password
# -c Content Delivery Network (CDN) - empty to be optional
# -s Storage Account - empty to be optional (otherwise it will use the container storage as persistent storage)
# 
# Executing it with minimum parameters:
#   ./azuredeploy_shared.sh -r wordpress-rg -l westeurope -m wp-mysql-svr -u mysqladmin -k wordpress-kv -p mysqladminpwd -c wordpress-cdn -s wordpressst01
#
# This script assumes that you already executed "az login" to authenticate 
#
# For Azure DevOps it's best practice to create a Service Principle for the deployement
# In the Cloud Shell:
# For example: az ad sp create-for-rbac --name multicontainerwponazure
# Copy output JSON: AppId and password

while getopts r:l:m:u:k:p:c:s: option
do
	case "${option}"
	in
		r) RESOURCEGROUP=${OPTARG};;
		l) LOCATION=${OPTARG};;
		m) MYSQLSVR=${OPTARG};;
		u) MYSQLUSER=${OPTARG};;
		k) KV=${OPTARG};;
		p) KVMYSQLPWD=${OPTARG};;
		c) CDN=${OPTARG};;
		s) STORAGEACC=${OPTARG};;
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
echo "   Resource Group: ${RESOURCEGROUP}"
echo "   Location: ${LOCATION}"
echo "   MySQL Server: ${MYSQLSVR}" 
echo "   MySQL Admin User: ${MYSQLUSER}"
echo "   Key Vault: ${KV}"
echo "   Key Vault Label MySQL Admin Pwd: ${KVMYSQLPWD}"
echo "   CDN: ${CDN}"
echo "   Storage Account: ${STORAGEACC}"; echo

#--------------------------------------------
# Registering providers & extentions
#--------------------------------------------
echo "Registering providers"
az provider register -n Microsoft.DBforMySQL
az provider register -n Microsoft.Web
az provider register -n Microsoft.DomainRegistration
az provider register -n Microsoft.Network
az provider register -n Microsoft.Compute
az provider register -n Microsoft.keyvault
az provider register -n Microsoft.CDN
az provider register -n Microsoft.Storage

#--------------------------------------------
# Creating Resource group
#-------------------------------------------- 
echo "Creating resource group ${RESOURCEGROUP}"
RESULT=$(az group exists -n $RESOURCEGROUP)
if [ "$RESULT" != "true" ]
then
	az group create -l $LOCATION -n $RESOURCEGROUP
else
	echo "   Resource group ${RESOURCEGROUP} already exists"
fi

#--------------------------------------------
# Creating Key Vault
#-------------------------------------------- 
echo "Creating Key Vault ${KV}"
RESULT=$(az keyvault show -n $KV)
if [ "$RESULT" = "" ]
then
	az keyvault create -l $LOCATION -n $KV -g $RESOURCEGROUP
	# Generate MySQL Admin Password and store in Key Vault
	MYSQLPASSWORD=$(openssl rand -base64 14)
	az keyvault secret set --vault-name "$KV" --name "$KVMYSQLPWD" --value "$MYSQLPASSWORD"
else
	echo "   Key Vault ${KV} already exists, retrieve mysqlpassword"
	MYSQLPASSWORD=$(az keyvault secret show --name "$KVMYSQLPWD" --vault-name "$KV" --query value -o tsv)
fi

#--------------------------------------------
# Creating MySQL on Azure
#-------------------------------------------- 
echo "Creating MySQL on Azure ${MYSQLSVR}"
RESULT=$(az mysql server show -n $MYSQLSVR -g $RESOURCEGROUP)
if [ "$RESULT" = "" ]
then
	az mysql server create -g $RESOURCEGROUP -n $MYSQLSVR --admin-user $MYSQLUSER --admin-password "$MYSQLPASSWORD" -l $LOCATION --ssl-enforcement Disabled --sku-name B_Gen5_1 --version 5.7
	# open the firewall (use 0.0.0.0 to allow all Azure traffic for now) 
	az mysql server firewall-rule create -g $RESOURCEGROUP --server $MYSQLSVR --name AllowAppService --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
else
	echo "   MySQL on Azure ${MYSQLSVR} already exists"
fi

#--------------------------------------------
# Creating CDN (optional)
#-------------------------------------------- 
echo "Creating CDN ${CDN}"
RESULT=$(az cdn profile show -n $CDN -g $RESOURCEGROUP)
if [[ -z "$RESULT"  &&  -n "$CDN" ]]
then
	# Profile
	az cdn profile create -n $CDN -g $RESOURCEGROUP -l $LOCATION --sku Standard_Microsoft
else
	echo "   CDN ${CDN} already exists or is not provided"
fi

#--------------------------------------------
# Creating Storage Account (optional)
#-------------------------------------------- 
echo "Creating Storage Account ${STORAGEACC}"
RESULT=$(az storage account show -n $STORAGEACC -g $RESOURCEGROUP)
if [[ -z "$RESULT"  &&  -n "$STORAGEACC" ]]
then
	az storage account create -n $STORAGEACC -g $RESOURCEGROUP -l $LOCATION --sku Standard_LRS --kind StorageV2
else
	echo "   Storage Account ${STORAGEACC} already exists or is not provided"
fi
