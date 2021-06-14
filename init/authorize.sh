#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################
help ()
{
   # Display Help
   echo "Initialize the authorizations for a dockerized service."
   echo "FOR DEMO PURPOSES ONLY; DO NOT USE IN PRODUCTION."
   echo "Default behaviour is to assume that REMS is the target."
   echo
   echo "Usage:"
   echo "   ./init/authorize.sh [options] USERID"
   echo "Arguments:"
   echo "   USERID  The ID of the user to authorize."
   echo "Options:"
   echo "   -h      Display this help text"
   echo "   -k      The api key to add. Default: abc123"
   echo "   -f      Docker-compose filename. Default: docker-compose.yaml"
   echo "   -s      Docker service container to exec the migration in. Default: rems"
   echo
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################
# Default docker-compose filename.
composefile="docker-compose.yaml"
# Default service name to exec the migration in.
service="rems"
# Default api key to add, if applicable.
apikey="abc123"

# Optionally overwrite docker compose filename, service to migrate, or apikey to add
while getopts ":hk:f:s:" opt; do
  case $opt in
    h)  help
        exit
        ;;
    k)  apikey="$OPTARG"
        ;;
    f)  composefile="$OPTARG"
        ;;
    s)  service="$OPTARG"
	    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        ;;
  esac
done
shift $((OPTIND - 1))

user="$1"

echo "composefile: " $composefile
echo "service: " $service
echo "apikey: " $apikey

case $service in
    rems)
        docker-compose -f $composefile exec $service sh -c \
        'java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add '$apikey' Testing'
        echo 'Attempted to add api-key '$apikey

        docker-compose -f $composefile exec $service sh -c \
        'java -Drems.config=/rems/config/config.edn -jar rems.jar grant-role owner '$user
        echo 'Attempted to grant owner role to '$user
        ;;
    *)
        echo "I do not know how to authorize users for this service. Exiting."
        ;;
esac
