#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################
help () {
   # Display Help
   echo "Prepare OPA by ingesting the authorization policies and data."
   echo
   echo "Script assumes that repository containing authorization policies and data to ingest into OPA is cloned locally."
   echo "Clone the following repository to do so:"
   echo "   https://github.com/CanDIG/candigv2_opa"
   echo
   echo "Usage:"
   echo "   ./init/opa.sh [options]"
   echo "Options:"
   echo "   -h      Display this help text"
   echo "   -p      Path to the repository containing authorization policies and data to ingest into OPA. Default: ../candigv2_opa"
   echo
}


################################# Script start

# Default path to repository. Can overwrite with -p argument.
path="../candigv2_opa"

# Process options
while getopts ":hp:" opt; do
  case $opt in
    h)  help
        exit
        ;;
    p)  path="$OPTARG"
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
        ;;
  esac
done

# Error if path is invalid or necessary files are missing from cloned repository
if [[ ! -d $path || ! -f "$path/data.json" || ! -f "$path/passport.rego" ]]
then
    echo "ERROR: $path is an invalid path"
    echo "Please ensure the following repository is cloned locally and the -p flag contains the path to this repository:"
    echo "   https://github.com/CanDIG/candigv2_opa"
    echo "Furthermore, please ensure that files data.json and passport.rego are present in the cloned repository and have not been moved."
    echo "Please rerun the script once these issues have been resolved."
    exit 1
fi

# Initialize OPA

echo "Ingesting authorization data into OPA..."

HTTP_STATUS_CODE=$(curl -Ss -w '%{http_code}\n' -X PUT --data-binary @$path/data.json localhost:8181/v1/data -o /dev/null)
if [[ $? -ne 0 ]]
then
    echo "Error: Failed to connect to localhost:8181/v1/data"
    echo "Please ensure the OPA service is running and rerun the script."
    exit 1
elif [[ $HTTP_STATUS_CODE -ne 204 ]]
then
    echo "Error: Failed to ingest authorization data into OPA"
    echo "Please ensure $path/data.json has not been modified and rerun the script."
    exit 1
fi

echo "Authorization data successfully ingested into OPA."
echo

echo "Ingesting authorization policies into OPA..."

HTTP_STATUS_CODE=$(curl -Ss -w '%{http_code}\n' -X PUT --data-binary @$path/passport.rego localhost:8181/v1/policies/ga4ghPassport -o /dev/null)
if [[ $? -ne 0 ]]
then
    echo "Error: Failed to connect to localhost:8181/v1/policies/ga4ghPassport"
    echo "Please ensure the OPA service is running and rerun the script."
    exit 1
elif [[ $HTTP_STATUS_CODE -ne 200 ]]
then
    echo "Error: Failed to ingest authorization policies into OPA"
    echo "Please ensure $path/passport.rego has not been modified and rerun the script."
    exit 1
fi

echo "Authorization policies successfully ingested into OPA."
echo
