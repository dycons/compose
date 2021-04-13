# This script depends upon jq, gettext-base being installed.

# Adapted from instructions in the following resources:
#   https://github.com/keycloak/keycloak-documentation/blob/master/server_admin/topics/admin-cli.adoc
#   https://wjw465150.gitbooks.io/keycloak-documentation/content/securing_apps/topics/client-registration/client-registration-cli.html
#   https://www.keycloak.org/docs-api/5.0/rest-api/index.html

# TODO all commands below are generic, need to populate them with specific names, wrap API calls in the admin CLI syntax, etc.
# TODO replace REMS client ID string with an env variable $REMS_CLIENT_ID

# 1) Authenticate into the dycons-researcher-idp realm
# 2) Generate the client secret for REMS, whose client ID is edf83af5-9964-427b-b70b-25d9a1bb5ff2
# 3) Get the client secret for REMS

echo "Generating the OIDC secret for the REMS client"
docker-compose exec rp-keycloak sh -c \
'/opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth \
--realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD &&\
/opt/jboss/keycloak/bin/kcadm.sh create http://localhost:8080/auth/admin/realms/dycons-researcher-idp/clients/edf83af5-9964-427b-b70b-25d9a1bb5ff2/client-secret &&\
/opt/jboss/keycloak/bin/kcadm.sh get http://localhost:8080/auth/admin/realms/dycons-researcher-idp/clients/edf83af5-9964-427b-b70b-25d9a1bb5ff2/client-secret > tmp/rems-client-secret.json'

echo "Updating the .env file with the OIDC secret for the REMS client"

# Copy the REMS client secret from the keycloak container to the host, then fetch the secret.
# Once the secret is in a variable, it can be substituted into the .env file using envsubst from the gnu_gettext package.
docker cp compose_rp-keycloak_1:/tmp/rems-client-secret.json tmp
if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    echo "Please install jq"
    exit
fi
export REMS_CLIENT_SECRET=$(jq .value tmp/rems-client-secret.json)

# Substitute all ${VAR} references in the .env file with their values.
# Requirs gnu_gettext's envsubst be installed: apt-get install gettext-base
if ! command -v envsubst &> /dev/null
then
    echo "envsubst could not be found"
    echo "Please install gnu_gettext, ex.:"
    echo "      apt-get install gettext-base"
    exit
fi
envsubst '${REMS_CLIENT_SECRET}' < .env > tmp/.env
cat tmp/.env > .env

# Add test users
echo "Adding test users to keycloak"
docker-compose exec rp-keycloak sh -c \
'/opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth \
--realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD &&\
/opt/jboss/keycloak/bin/kcadm.sh create http://localhost:8080/auth/admin/realms/dycons-researcher-idp/users -s username=owner -s enabled=true &&\
/opt/jboss/keycloak/bin/kcadm.sh set-password -r demorealm --username owner --password owner'
#kcadm.sh create users -r demorealm -s username=owner -s enabled=true
#kcadm.sh set-password -r demorealm --username owner --password owner


#kcadm.sh create users -r demorealm -s username=applicant -s enabled=true
#kcadm.sh set-password -r demorealm --username applicant --password applicant

# TODO add users' IDs to Postman iteration data
# TODO reconfigure Postman collection to fetch userIDs from iteration data

# TODO have Travis run this script as part of the before_script process
# TODO once this script is complete & fully functioning, document its existence in the README