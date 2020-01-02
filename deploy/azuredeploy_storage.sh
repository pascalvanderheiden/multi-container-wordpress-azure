#!/bin/bash

# Arguments
# -r Resource Group Name
# -s Resource Group Name Shared Resources
# -w Web App Name
# -x Storage Account
# -y Azure File Share - empty to be optional (otherwise it will use the container storage as persistent storage)
# -c Custom ID - empty to be optional (unique identifier for linking the storage acccount with the WebApp)
# 
# Executing it with minimum parameters:
#   ./azuredeploy_storage.sh -r wordpress-rg -s wordpressshared-rg -w wordpress-wa -x wordpressst01 -y conwordpress -c wpcontainer
#
# This script assumes that you already executed "az login" to authenticate 
#
# For Azure DevOps it's best practice to create a Service Principle for the deployement
# In the Cloud Shell:
# For example: az ad sp create-for-rbac --name multicontainerwponazure
# Copy output JSON: AppId and password

while getopts r:s:w:x:y:c: option
do
	case "${option}"
	in
		r) RESOURCEGROUP_WEBAPP=${OPTARG};;
        s) RESOURCEGROUP_SHARED=${OPTARG};;
		w) WEBAPP=${OPTARG};;
		x) STORAGEACC=${OPTARG};;
		y) FILESHARE=${OPTARG};;
        c) CUSTOMID=${OPTARG};;
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
echo "   WebApp: ${WEBAPP}"
echo "   Storage Account: ${STORAGEACC}"
echo "   Azure File Share: ${FILESHARE}"
echo "   Custom-id: ${CUSTOMID}"; echo

#--------------------------------------------
# Registering providers & extentions
#--------------------------------------------
echo "Registering providers"
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Web

#--------------------------------------------
# Linking Storage Account to WebApp (optional)
#-------------------------------------------- 
echo "Linking Storage Account ${STORAGEACC} to WebApp ${WEBAPP}"

RESULT=$(az webapp config storage-account list -n $WEBAPP -g $RESOURCEGROUP_WEBAPP --query [0].value -o tsv)
if [[ -z "$RESULT" && -n "$CUSTOMID" && -n "$STORAGEACC" && -n "$FILESHARE" ]]
then
    # Get Storage Access Key
    ACCESSKEY=$(az storage account keys list -g $RESOURCEGROUP_SHARED -n $STORAGEACC --query [0].value -o tsv)
    
    # Link Storage
	az webapp config storage-account add \
    --resource-group $RESOURCEGROUP_WEBAPP \
    --name $WEBAPP \
    --custom-id $CUSTOMID \
    --storage-type AzureFiles \
    --share-name $FILESHARE \
    --account-name $STORAGEACC \
    --access-key "$ACCESSKEY" \
    --mount-path "/www"

    echo "   Storage Account ${STORAGEACC} linked"
else
	echo "   Storage Account ${STORAGEACC} already linked, or not added"
fi

# Update Application Setting not to look at local
if [[ -n "$CUSTOMID" && -n "$STORAGEACC" && -n "$FILESHARE" ]]
then
    az webapp config appsettings set \
    -n $WEBAPP \
    -g $RESOURCEGROUP_WEBAPP \
    --settings "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false"
    echo "   Application Settings ${WEBAPP} updated"
else
	echo "   Application Settings ${WEBAPP} not updated, looking at container storage"
fi