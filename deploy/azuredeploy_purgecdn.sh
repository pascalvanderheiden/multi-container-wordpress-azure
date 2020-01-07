#!/bin/bash

# Arguments
# -r Resource Group Name WebApp
# -s Resource Group Name Shared Resources
# -w Web App Name
# -c Content Delivery Network (CDN) - empty to be optional
# -e CDN Endpoint - empty to be optional
# 
# Executing it with minimum parameters:
#   ./azuredeploy_purgecdn.sh -r wordpress-rg -s wordpressshared-rg -w wordpress-wa -c wordpress-cdn -e wordpress
#
# This script assumes that you already executed "az login" to authenticate 
#
# For Azure DevOps it's best practice to create a Service Principle for the deployement
# In the Cloud Shell:
# For example: az ad sp create-for-rbac --name multicontainerwponazure
# Copy output JSON: AppId and password

while getopts r:s:w:c:e: option
do
	case "${option}"
	in
		r) RESOURCEGROUP_WEBAPP=${OPTARG};;
        s) RESOURCEGROUP_SHARED=${OPTARG};;
		w) WEBAPP=${OPTARG};;
		c) CDN=${OPTARG};;
		e) CDN_ENDPOINT=${OPTARG};;
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
echo "   CDN: ${CDN}"
echo "   CDN Endpoint: ${CDN_ENDPOINT}"; echo

#--------------------------------------------
# Registering providers & extentions
#--------------------------------------------
echo "Registering providers"
az provider register -n Microsoft.CDN

#--------------------------------------------
# Purge CDN Endpoint (optional)
#-------------------------------------------- 
echo "Fetching WebApp Hostname"
FQDN=$(az webapp show -n $WEBAPP -g $RESOURCEGROUP_WEBAPP --query "defaultHostName" -o tsv)

echo "Creating CDN Endpoint ${CDN_ENDPOINT}"
RESULT=$(az cdn endpoint show -n $CDN_ENDPOINT --profile-name $CDN -g $RESOURCEGROUP_SHARED)
if [[ -z "$RESULT" && -n "$CDN_ENDPOINT" ]]
then
	# Purge
    az cdn endpoint purge -g $RESOURCEGROUP_SHARED -n $CDN_ENDPOINT --profile-name $CDN --content-paths \
    '/var/www/html/wp-content/*' '/var/www/html/wp-includes/*'

    echo "   CDN Endpoint ${CDN_ENDPOINT} purged."
else
	echo "   CDN Endpoint ${CDN_ENDPOINT} is not provided, purge skipped."
fi