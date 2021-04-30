#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################
help ()
{
   # Display Help
   echo "Initialize the authorizations for a dockerized service."
   echo "Default behaviour is to assume that REMS is the target."
   echo
   echo "Usage:"
   echo "   ./init/authorize.sh USERID [options]"
   echo "Arguments:"
   echo "   USERID  The ID of the user to authorize."
   echo "Options:"
   echo "   -h      Display this help text"
   echo "   -k      The api key to add. Default: 123abc"
   echo "   -f      Docker-compose filename. Default: docker-compose.yaml"
   echo "   -s      Docker service container to exec the migration in. Default: rems"
   echo
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

user="$1"

# Default docker-compose filename.
composefile="docker-compose.yaml"
# Default service name to exec the migration in.
service="rems"
# Default api key to add, if applicable.
apikey="abc123"


# Optionally overwrite docker compose filename or service to migrate
while getopts ":hf:s:" opt; do
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

echo "composefile: " $composefile
echo "service: " $service

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
