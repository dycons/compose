#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################
help ()
{
   # Display Help
   echo "Run migrations on the database out of a Docker container."
   echo
   echo "Usage:"
   echo "   ./init/migrate.sh [options] SERVICE"
   echo "Arguments:"
   echo "   SERVICE Docker service container to exec the migration in.."
   echo "Options:"
   echo "   -h      Display this help text"
   echo "   -f      Docker-compose filename. Default: docker-compose.yaml"
   echo
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

# Default docker-compose filename. Can overwrite with -f argument.
composefile="docker-compose.yaml"

# Optionally overwrite docker compose filename or service to migrate
while getopts ":hf:" opt; do
  case $opt in
    h)  help
        exit
        ;;
    f)  composefile="$OPTARG"
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
        ;;
  esac
done
shift $((OPTIND - 1))

service="$1"

echo "composefile: " $composefile
echo "service: " $service

case $service in
    rems)
        docker-compose run --rm -e CMD="migrate" rems
        ;;
    rp-keycloak)
        # Authenticate the keycloak admin, then import the dycons-researcher-idp realm

        docker-compose -f $composefile exec $service sh -c \
        '/opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth \
        --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD'
        
        docker-compose -f $composefile exec $service sh -c \
        '/opt/jboss/keycloak/bin/kcadm.sh create realms -f /imports/realm-export.json -s enabled=true'
        ;;
    *)
        echo "I do not know how to migrate this service. Exiting."
        ;;
esac