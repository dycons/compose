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
   echo "Script dependencies: gnu_gettext (ie. gettext_base)"
   echo 'Script can only inject the REMS_API_KEY into a .env file if .env contains the following line:'
   echo '   REMS_API_KEY=${REMS_API_KEY}'
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

# Substitute ${VAR} reference to REMS API key in the .env file with its value.
# Requires gnu_gettext's envsubst be installed: apt-get install gettext-base
_set_api_key () {

    case `grep '{REMS_API_KEY}' .env > /dev/null; echo $?` in
        0)
            # Found the reference in the .env file; can substitute the value in.
            envsubst '${REMS_API_KEY}' < .env > tmp/.env
            cat tmp/.env > .env
            ;;
        1)
            # Did not find the reference in the .env file.
            echo 'WARNING: .env file does not contain the ${REMS_API_KEY} reference!'
            echo 'Unable to substitute the value of ${REMS_API_KEY} into the .env file.'
            echo 'Please do so manually, or rerun this script after adding the reference to the .env file.'
            echo 'ex. To reset the .env file to its default state, run the following command:'
            echo 'cp .default.env .env'
            return 1
            ;;
        *)
            echo 'WARNING: error when checking for presence of ${REMS_API_KEY} reference in the .env file!'
            echo 'Unable to substitute the value of ${REMS_API_KEY} into the .env file.'
            echo 'Please do so manually, or rerun this script after adding the reference to the .env file.'
            echo 'ex. To reset the .env file to its default state, run the following command:'
            echo 'cp .default.env .env'
            return 2
            ;;
    esac
}


################################# Script start

# Default docker-compose filename.
composefile="docker-compose.yaml"
# Default service name to exec the migration in.
service="rems"
# Default api key to add, if applicable.
export REMS_API_KEY="abc123"

# Optionally overwrite docker compose filename, service to migrate, or REMS_API_KEY to add
while getopts ":hk:f:s:" opt; do
  case $opt in
    h)  help
        exit
        ;;
    k)  REMS_API_KEY="$OPTARG"
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

# Error if dependency is missing
if ! command -v envsubst &> /dev/null
then
    echo "envsubst could not be found"
    echo "Please install gnu_gettext, ex.:"
    echo "      apt-get install gettext-base"
    exit 1
fi

# Create required local tmp file
mkdir -p tmp
if [[ ! -d tmp && -f tmp ]]; then
    echo "ERROR: tmp folder in current host directory is a file instead of a directory."
    echo "Please replace with tmp directory and rerun script"
    exit 1
elif [[ ! -d tmp ]]; then
    echo "ERROR: no tmp folder in current host directory."
    echo "Please create tmp directory and rerun script"
    exit 1
fi

echo "composefile: " $composefile
echo "service: " $service
echo "REMS_API_KEY: " $REMS_API_KEY

echo "Substituting the REMS API key into the docker-compose environment..."
if _set_api_key
then
    echo "REMS API key added to the environment."
fi
echo

case $service in
    rems)
        docker-compose -f $composefile exec $service sh -c \
        'java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add '$REMS_API_KEY' Testing'
        echo 'Attempted to add api-key '$REMS_API_KEY

        docker-compose -f $composefile exec $service sh -c \
        'java -Drems.config=/rems/config/config.edn -jar rems.jar grant-role owner '$user
        echo 'Attempted to grant owner role to '$user
        ;;
    *)
        echo "I do not know how to authorize users for this service. Exiting."
        ;;
esac
