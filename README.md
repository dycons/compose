# compose
DyCons server configuration and deployment

## Table of Contents
- [compose](#compose)
  - [Table of Contents](#table-of-contents)
  - [Repository Superstructure](#repository-superstructure)
  - [Katsu + OPA](#katsu-opa)
  - [Participant Portal + Participant IdP](#participant-portal-participant-idp)
  - [Researcher Portal + Researcher IdP + Katsu + REMS + OPA](#researcher-portal-researcher-idp-katsu-rems-opa)
    - [REMS + Consents](#rems-consents)
  - [Consents](#consents)
  - [Key Relay Service](#key-relay-service)

## Repository Superstructure
[Services diagram](https://drive.google.com/file/d/1nuDjgWV1jvaqV5nd4O-_Fzx6J7kEWH3f/view?usp=sharing) describing the current milestone for the DyCons stack and core workflows (called `demo1`).

Setup expects the following repos to be available on the development/test machine:
- [participant-portal](https://github.com/dycons/participant-portal)
- [researcher-portal](https://github.com/dycons/researcher-portal)
- [rems](https://github.com/CSCfi/rems)
- [consents](https://github.com/dycons/consents)
- [relay](https://github.com/dycons/relay)
- [candigv2_opa](https://github.com/CanDIG/candigv2_opa)

To set these up at the paths specified in this repo's `.env` file, you could run the following snippet from the `compose` root folder:
```
git clone https://github.com/dycons/participant-portal.git ../participant-portal && \
git clone https://github.com/dycons/researcher-portal.git ../researcher-portal && \
git clone https://github.com/CSCfi/rems.git ../rems && \
git clone https://github.com/dycons/consents.git ../consents && \
git clone https://github.com/dycons/relay.git ../relay && \
git clone https://github.com/CanDIG/candigv2_opa.git ../candigv2_opa
```

## Katsu + OPA
[Services diagram](https://drive.google.com/file/d/1QyDr21pLXR98w4Al1IG9MhWah6nFYlHZ/view?usp=sharing) describing the OPA-powered authorization of Katsu.

[Sequence diagram](https://github.com/dycons/design/blob/develop/demo1/diagrams/researcher_query.md) describing the process of authorizing a researcher's request to Katsu via the DyCons `researcher-portal`.

Spin up these components as follows:
1. **Prepare environment**: Ensure that you have a well-configured `.env` file in the `compose` root. To use the default configuration, run `cp .default.env .env`
2. **Start up Katsu and OPA**:
   1. Follow the steps [here](https://docs.github.com/en/packages/guides/pushing-and-pulling-docker-images#authenticating-to-github-container-registry) to authenticate to the GitHub Container Registry. This is necessary for pulling the `katsu` image.
   2. Run `docker-compose up katsu`
3. (Optional) **Add Sample Katsu Data**:
   1. To add sample data to Katsu, run: `docker exec -it -w /app/chord_metadata_service/scripts katsu python ingest.py`
4. **Add Authorization Rules to OPA**:
   1. Run `./services/opa/opa_initialize.sh`

## Participant Portal + Participant IdP
1. **Prepare environment**: Ensure that you have a well-configured `.env` file in the `compose` root. To use the default configuration, run `cp .default.env .env`
2. First make sure the keycloak service is running via `docker-compose up pp-keycloak`
3. **Add test Realm:**
   1. Navigate to http://127.0.0.1:8080/auth/admin.
   2. Login using the username and password: `admin` / `admin`
   3. Add the test **Realm** by hovering over the "Master" label in the top left, and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `../participant-portal/keycloak/realm-export.json`. The name should be autofilled with `dycons-participant-idp`.
   5. Click "Save" to finish.
4. **Add test User**:
   1. Navigate to the "Users" menu via the navbar on the left
   2. Click "Add User" on the right side of the page
   3. Set the username to `varchar` and click "Save".
   4. On the next page, click the "Credentials" tab
   5. Enter `varchar` in both password fields, toggle `Temporary` *off*, and click "Set Password"
5. **Testing** - Now it's time to test our setup by using the bundled front end:
   1. Boot up the React frontend by running `docker-compose up pp-react`
   2. Start by going to http://127.0.0.1:3003/.
   3. Click on the "Login" button and you should be redirected to the Keycloak login screen.
   4. Access the account using `varchar`/`varchar`. You'll be redirected back to the React frontend with the user's JWT token and email displayed.
   5. ** For active development **
      1. Instead of step 1, run: `docker-compose run --rm --entrypoint sh --service-port pp-react`. This will log you into the application.
      2. Run `yarn start` to compile the app.
      3. Continue development on your machine - changes will be mapped to the volume inside the container and reflected at http://127.0.0.1:3002

## Researcher Portal + Researcher IdP + Katsu + REMS + OPA
1. **Prepare environment**: Ensure that you have a well-configured `.env` file in the `compose` root. To use the default configuration, run `cp .default.env .env`
2. **Start up Researcher IdP**:
   1. Run `docker-compose up rp-keycloak`.
3. **Prepare Keycloak**:
   1. To prepare the keycloak for use with rems, run: `. ./init/rp-keycloak.sh -e`. This will accomplish the following:
      1. Create a generic `.env` file from the `.default.env` template provided, complete with the REMS client secret from keycloak.
      2. Add two test users
         - username: `applicant`, password: `applicant`
         - username: `owner`, password: `owner`
      3. Export the following environment variables to your shell, for use in authorization. Skip sourcing the script if this is not desired.
         - REMS_CLIENT_SECRET
         - OWNER_ID
         - APPLICANT_ID
4. **Start up Katsu and OPA**:
   1. Follow the steps [here](https://docs.github.com/en/packages/guides/pushing-and-pulling-docker-images#authenticating-to-github-container-registry) to authenticate to the GitHub Container Registry.
   2. Run `docker-compose up katsu`.
5. **Add Sample Katsu Data**:
   1. To add sample data to Katsu, run: `docker exec -it -w /app/chord_metadata_service/scripts katsu python ingest.py`.
6. **Add Authorization Rules to OPA**:
   1. Run `./services/opa/opa_initialize.sh`.
7. **Migrate and seed REMS**:
   1. Run `./init/migrate.sh rems` to prepare the database and migrate the required tables.
   2. (Optional) Run `docker-compose run --rm -e CMD="test-data" rems` to populate REMS with test data.
   3. REMS should now be ready for use. Run `docker-compose up rems`.
8. **Log In to REMS**:
   1. Navigate to http://127.0.0.1:3001.
   2. Click "Login".
   3. Login using the username and password: `owner` / `owner`.
   4. In the top right, click "Sign out".
   5. REMS can be made aware of any other users via either the `/users/create` endpoint, or by logging in as that user. To logout of REMS via the `rp-keycloak`, as the keycloak `admin`, navigate to `Sessions` > `Logout All` via the navbar on the left.
9. **Using the REMS API**:
   You can test the REMS API by submitting requests through the instance's [Swagger UI](http://localhost:3001/swagger-ui/index.html), or by running requests from the [Postman collection and test data](https://github.com/dycons/compose/tree/develop/tests). For the latter option, testing the API outside of the browser will require you to include some authorization information in the request headers.
   1. **Prepare credentials**: Provide REMS with an API key **and** grant your user the `owner` role by running `./init/authorize.sh USERID [options]`. By default, the API key set by this script is `abc123`, matching the API key in the Postman collection, but you can optionally set a custom key.
      - The USERID is output by the `init/rp-keycloak.sh` script used to prepare keycloak. If you sourced the script, you can use the `$OWNER_ID` and `$APPLICANT_ID` environment variables in your shell.
   2. Make sure your user is known to REMS. This can be accomplished by logging in through the browser **or** by sending a request to the `/api/users/create` endpoint. The `userid` must match the user's id in Keycloak.
   3. Add headers to your requests containing the following key-value pairs:
      - `x-rems-api-key`: The API key to use for authorizing your call. Must be known to REMS.
      - `x-rems-user-id`: The ID of your user in REMS, as set by Keycloak (ex. `$OWNER_ID`)
10. **Using the Researcher-Portal frontend** - Now it's time to test our setup by using the bundled front end:
   1. Boot up the React frontend by running `docker-compose up rp-react`.
   2. Start by going to http://127.0.0.1:3004/.
   3. Click on the "Log In" button and you should be redirected to the Keycloak login screen.
   4. Access the account using `applicant`/`applicant`. You'll be redirected back to the React frontend.
   5. ** For active development **
      1. Instead of step 1, run: `docker-compose run --rm --entrypoint sh --service-port rp-react`. This will log you into the application.
      2. Run `npm start` to compile the app.
      3. Continue development on your machine - changes will be mapped to the volume inside the container and reflected at http://127.0.0.1:3004/.

### REMS + Consents
To push new `entitlements` to the Consents service, uncomment the following line in `simple-config.edn` prior to running the REMS container:
```
:entitlements-target {:add "http://consents:3005/v0/rems/add_entitlements"}
```

## Consents
1. **Prepare environment**: Ensure that you have a well-configured `.env` file in the `compose` root. To use the default configuration, run `cp .default.env .env`
2. **Run** the Consents service with `docker-compose up consents`
3. **Migrate** the Consents service with `./init/migrate.sh consents`
4. (Optional) **Test** the Consents service by running requests from the [Postman collection and test data](https://github.com/dycons/consents/tree/develop/tests).

## Key Relay Service
1. **Prepare environment**: Ensure that you have a well-configured `.env` file in the `compose` root. To use the default configuration, run `cp .default.env .env`
2. **Run** the Relay sevrice with `docker-compose up relay`
3. (Optional) **Test** the Relay service by running the Postman collection at `../relay/tests/key-relay-service.postman_collection.json`
