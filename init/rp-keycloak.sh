#!/bin/bash

# This script is adapted from instructions in the following resources:
#   https://github.com/keycloak/keycloak-documentation/blob/master/server_admin/topics/admin-cli.adoc
#   https://wjw465150.gitbooks.io/keycloak-documentation/content/securing_apps/topics/client-registration/client-registration-cli.html
#   https://www.keycloak.org/docs-api/5.0/rest-api/index.html
# As well as this keycloak setup script:
#   https://github.com/CanDIG/CanDIGv2/blob/brouillette/dev/authz-arbiter/etc/setup/scripts/subtasks/keycloak_setup.sh

################################################################################
# Help                                                                         #
################################################################################
help () {
   # Display Help
   echo "Prepare the rp-keycloak for testing REMS, including exchanging client secrets and creating the following test users:"
   echo "   owner (uname: owner, pass: owner)"
   echo "   applicant (uname: applicant, pass: applicant)"
   echo
   echo "Script dependencies: jq, gnu_gettext (ie. gettext_base)"
   echo "Script assumes that dycons-researcher-idp realm has already been imported into rp-keycloak. Set the following environment variable to do so:"
   echo '   KEYCLOAK_IMPORT: "/imports/realm-export.json -Dkeycloak.profile.feature.upload_scripts=enabled"'
   echo 'Script can only inject the OIDC REMS_CLIENT_SECRET into a .env file if .env contains the following line:'
   echo '   OIDC_CLIENT_SECRET=${REMS_CLIENT_SECRET}'
   echo 'Can run the following command to reset the the .env file to its default values, then run this script:'
   echo '   cp .default.env .env && . ./init/rp-keycloak.sh'
   echo
   echo "If desireable, source this script (ie. run: . ./init/keycloak.sh) to have the script set the following environment variables in the shell:"
   echo "   REMS_CLIENT_SECRET"
   echo "   OWNER_ID"
   echo "   APPLICANT_ID"
   echo
   echo "Usage:"
   echo "   ./init/migrate.sh [options]"
   echo "Options:"
   echo "   -h      Display this help text"
   echo
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

# Get the REMS client secret from Keycloak, as follows:
#   1) Authenticate into the dycons-researcher-idp realm
#   2) Generate the client secret for REMS, whose client ID is $REMS_CLIENT_ID
#   3) Get the client secret for REMS. Save it into a temporary file, so that it can be retrieved for use in REMS.
#   4) Retrieve the client secret from the temp file, using jq.
_get_secret () {
    # Output from this command is silenced so that the output from the function can be captured as a return value
    docker-compose exec rp-keycloak sh -c \
    '/opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth \
    --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD &&\
    /opt/jboss/keycloak/bin/kcadm.sh create http://localhost:8080/auth/admin/realms/dycons-researcher-idp/clients/$REMS_CLIENT_ID/client-secret &&\
    /opt/jboss/keycloak/bin/kcadm.sh get http://localhost:8080/auth/admin/realms/dycons-researcher-idp/clients/$REMS_CLIENT_ID/client-secret \
    > /tmp/rems-client-secret.json' \
    > /dev/null

    # Copy the REMS client secret from the keycloak container to the host, then fetch the secret.
    # Once the secret is in a variable, it can:
    #   (1) be substituted into the .env file using envsubst from the gnu_gettext package
    #   (2) be fed to Newman as an environment variable to use when sending API requests.
    docker cp rp-keycloak:/tmp/rems-client-secret.json tmp
    echo $(jq .value tmp/rems-client-secret.json)
}


# Substitute ${VAR} reference to client secret in the .env file with its value.
# Requirs gnu_gettext's envsubst be installed: apt-get install gettext-base
_set_secret () {

    case `grep '{REMS_CLIENT_SECRET}' .env > /dev/null; echo $?` in
        0)
            # Found the reference in the .env file; can substitute the value in.
            envsubst '${REMS_CLIENT_SECRET}' < .env > tmp/.env
            cat tmp/.env > .env
            ;;
        1)
            # Did not find the reference in the .env file.
            echo 'WARNING: .env file does not contain the ${REMS_CLIENT_SECRET} reference!'
            echo 'Unable to substitute the value of ${REMS_CLIENT_SECRET} into the .env file.'
            echo 'Please do so manually, or rerun this script after adding the reference to the .env file.'
            echo 'note: To reset the .env file to its default state, run either of the following commands:'
            echo '      When not sourcing this script:  cp .default.env .env && ./init/rp-keycloak.sh'
            echo '      When sourcing this script:      cp .default.env .env && . ./init/rp-keycloak.sh'
            return 1
            ;;
        *)
            echo 'WARNING: error when checking for presence of ${REMS_CLIENT_SECRET} reference in the .env file!'
            echo 'Unable to substitute the value of ${REMS_CLIENT_SECRET} into the .env file.'
            echo 'It may already have a value populated.'
            echo 'note: To reset the .env file to its default state, run the following command:'
            echo '      When not sourcing this script:  cp .default.env .env && ./init/rp-keycloak.sh'
            echo '      When sourcing this script:      cp .default.env .env && . ./init/rp-keycloak.sh'
            return 2
            ;;
    esac
}


# Add test users: owner (password: owner), applicant (password: applicant)
_add_users () {
    docker-compose exec rp-keycloak sh -c \
    '/opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth \
    --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD &&\
    /opt/jboss/keycloak/bin/kcadm.sh create users -r dycons-researcher-idp -s username=owner -s enabled=true &&\
    /opt/jboss/keycloak/bin/kcadm.sh set-password -r dycons-researcher-idp --username owner --new-password owner &&\
    /opt/jboss/keycloak/bin/kcadm.sh create users -r dycons-researcher-idp -s username=applicant -s enabled=true &&\
    /opt/jboss/keycloak/bin/kcadm.sh set-password -r dycons-researcher-idp --username applicant --new-password applicant'
}


# The nuser is fetched and saved to a temporary file on the host machine.
# The user ID is then parsed from this temp file.
_get_user () {
    local username="$1"

    # Output from this command is silenced so that the output from the function can be captured as a return value
    docker-compose exec rp-keycloak sh -c \
    '/opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth \
    --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD &&\
    /opt/jboss/keycloak/bin/kcadm.sh get http://localhost:8080/auth/admin/realms/dycons-researcher-idp/users?username='$username' \
    > /tmp/user.json' \
    > /dev/null

    # Copy the user info from the keycloak container to the host, then fetch the user ID.
    # Once the user ID is in a variable, it can be fed to Newman as an environment variable to use when sending API requests.
    docker cp rp-keycloak:/tmp/user.json tmp

    echo $(jq .[].id tmp/user.json)
}


################################# Script start

# Process options
while getopts ":h" opt; do
  case $opt in
    h)  help
        exit
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
        ;;
  esac
done

# Error if dependencies are missing
if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    echo "Please install jq, ex.:"
    echo "      apt-get install jq"
    exit 1
fi
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


# Run keycloak-preparing script

echo "Getting the REMS client secret from Keycloak..."
export REMS_CLIENT_SECRET=$(_get_secret)
echo
echo "REMS_CLIENT_SECRET: " $REMS_CLIENT_SECRET
echo

echo "Substituting the REMS client secret into the docker-compose environment..."
if _set_secret
then
    echo "REMS client secret added to the environment."
fi
echo

echo "Creating the following users into keycloak:"
echo "   owner (uname: owner, pass: owner)"
echo "   applicant (uname: applicant, pass: applicant)"
_add_users
echo "Users have been added to keycloak."
echo

echo "Getting the user IDs from keycloak..."
export OWNER_ID=$(_get_user owner)
echo "OWNER_ID: " $OWNER_ID
export APPLICANT_ID=$(_get_user applicant)
echo "APPLICANT_ID: " $APPLICANT_ID
echo
