# compose
DyCons server configuration and deployment

## Table of Contents
- [compose](#compose)
  - [Table of Contents](#table-of-contents)
  - [Setting up Keycloak for testing:](#setting-up-keycloak-for-testing)
  - [Participant Portal + Participant IdP](#participant-portal--participant-idp)
  - [Researcher Portal + Researcher IdP + Katsu + REMS + OPA](#researcher-portal--researcher-idp--katsu--rems--opa)
  - [REMS + Researcher IdP](#rems--researcher-idp)

## Setting up Keycloak for testing:

Setup expects the following repos to be available on the development/test machine:
- [participant-portal](https://github.com/dycons/participant-portal)
- [researcher-portal](https://github.com/dycons/researcher-portal)
- [rems](https://github.com/CSCfi/rems)
- [consents](https://github.com/dycons/consents)
- [relay](https://github.com/dycons/relay)
- [candigv2_opa](https://github.com/CanDIG/candigv2_opa)

To set these up at the paths specified in this repo's `.env` file, you could run the following snippet:
```
git clone https://github.com/dycons/participant-portal.git ../participant-portal && \
git clone https://github.com/dycons/researcher-portal.git ../researcher-portal && \
git clone https://github.com/CSCfi/rems.git ../rems && \
git clone https://github.com/dycons/consents.git ../consents && \
git clone https://github.com/dycons/relay.git ../relay && \
git clone https://github.com/CanDIG/candigv2_opa.git ../candigv2_opa
```

**TODO** - Turn the following setup process into an automated step on startup.

## Participant Portal + Participant IdP
1. First make sure the keycloak service is running via `docker-compose up pp-keycloak`
2. **Add test Realm:**
   1. Navigate to http://127.0.0.1:8080/auth/admin.
   2. Login using the username and password: `admin` / `admin`
   3. Add the test **Realm** by hovering over the "Master" label in the top left, and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `../participant-portal/keycloak/realm-export.json`. The name should be autofilled with `dycons-participant-idp`.
   5. Click "Save" to finish.
3. **Add test User**:
   1. Navigate to the "Users" menu via the navbar on the left
   2. Click "Add User" on the right side of the page
   3. Set the username to `varchar` and click "Save".
   4. On the next page, click the "Credentials" tab
   5. Enter `varchar` in both password fields, toggle `Temporary` *off*, and click "Set Password"
4. **Testing** - Now it's time to test our setup by using the bundled front end:
   1. Boot up the React frontend by running `docker-compose up pp-react`
   2. Start by going to http://127.0.0.1:3003/.
   3. Click on the "Login" button and you should be redirected to the Keycloak login screen.
   4. Access the account using `varchar`/`varchar`. You'll be redirected back to the React frontend with the user's JWT token and email displayed.
   5. ** For active development **
      1. Instead of step 1, run: `docker-compose run --rm --entrypoint sh --service-port pp-react`. This will log you into the application.
      2. Run `yarn start` to compile the app.
      3. Continue development on your machine - changes will be mapped to the volume inside the container and reflected at http://127.0.0.1:3002

## Researcher Portal + Researcher IdP + Katsu + REMS + OPA
1. **Start up Researcher IdP, Katsu and OPA**:
   1. Run `docker-compose up rp-keycloak katsu`.
2. **Add Test Realm**:
   1. Navigate to http://127.0.0.1:3002/auth/admin.
   2. Login using the username and password: `admin` / `admin`.
   3. Add the test **Realm** by hovering over the "Master" label in the top left, and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `../researcher-portal/keycloak/realms-export.json`. The name should be autofilled with `dycons-researcher-idp`.
   5. Click "Create" to finish.
3. **Add Test Users**:
   1. Navigate to the "Users" menu via the navbar on the left.
   2. Click "Add user" on the right side of the page.
   3. Set the username to `varchar` and click "Save".
   4. On the next page, click the "Credentials" tab.
   5. Enter `varchar` in both password fields, toggle `Temporary` *off*, and click "Set Password".
   6. Navigate to the "Users" menu via the navbar on the left.
   7. Click "Add user" on the right side of the page.
   8. Set the username to `owner` and click "Save".
   9. Copy the value in the `ID` field and assign this value to `REMS_OWNER_ID` in the `.env` file.
   10. On the next page, click the "Credentials" tab.
   11. Enter `owner` in both password fields, toggle `Temporary` *off*, and click "Set Password".
4. **Expose Keycloak to REMS**:
   1. Navigate to "Clients" via the navbar on the left.
   2. Under column "Client ID", select `rems-client`.
   3. Click the "Credentials" tab.
   4. Click `Regenerate Secret` and copy the secret generated.
   5. Open `services/rems/simple-config.edn` and modify the `:oidc-client-secret` key to use the secret generated.
5. **Add Sample Katsu Data**:
   1. To add sample data to Katsu, run: `docker exec -it -w /app/chord_metadata_service/scripts katsu python ingest.py`.
6. **Add Authorization Rules to OPA**:
   1. Run `./services/opa/opa_initialize.sh`.
7. **Migrate and Seed REMS**:
   1. Run `./migrations/migrate.sh -s rems` to prepare the database and migrate the required tables.
   2. Run `docker-compose run --rm -e CMD="test-data" rems` to populate REMS with test data.
8. **Start up REMS**:
   1. Run `docker-compose up rems`.
9. **Log In to REMS**:
   1. Navigate to http://127.0.0.1:3001.
   2. Click "Login".
   3. Login using the username and password: `owner` / `owner`.
   4. In the top right, click "Sign out".
   5. In a new tab, navigate to http://127.0.0.1:3002/auth/admin.
   6. Login using the username and password: `admin` / `admin`.
   7. Navigate to the "Sessions" menu via the navbar on the left.
   8. Click "Logout all" on the right side of the page.
   9. Navigate to the tab http://127.0.0.1:3001.
   10. Click "Login".
   11. Login using the username and password: `varchar` / `varchar`.
   12. In the top right, click "Sign out".
   13. Navigate to the tab http://127.0.0.1:3002/auth/admin.
   14. Navigate to the "Sessions" menu via the navbar on the left.
   15. Click "Logout all" on the right side of the page.
10. **Initialize REMS**:
   1. Run `./services/rems/rems_initialize.sh`.
11. **Testing** - Now it's time to test our setup by using the bundled front end:
   1. Boot up the React frontend by running `docker-compose up rp-react`.
   2. Start by going to http://127.0.0.1:3004/.
   3. Click on the "Log In" button and you should be redirected to the Keycloak login screen.
   4. Access the account using `varchar`/`varchar`. You'll be redirected back to the React frontend.
   5. ** For active development **
      1. Instead of step 1, run: `docker-compose run --rm --entrypoint sh --service-port rp-react`. This will log you into the application.
      2. Run `npm start` to compile the app.
      3. Continue development on your machine - changes will be mapped to the volume inside the container and reflected at http://127.0.0.1:3004/.

## REMS + Researcher IdP

1. (Optional) **Build REMS instead of pulling the image**:
   * **Note**: due to limitations in REMS' repository and docker setup, it is currently necessary to build the rems jar locally. Additional reading is available [here](https://github.com/CSCfi/rems/blob/master/docs/installing-upgrading.md#option-2-build-rems-image-locally).

   1. Install [Leiningen](https://leiningen.org/). Use the official instructions, or your preferred [package manager](https://github.com/technomancy/leiningen/wiki/Packaging) (for example, `brew install leiningen` or `apt-get install leiningen`)
   2. Run `lein uberjar` in the `rems` directory to build the rems jar locally.
   3. Modify `docker-compose.yaml` to build the container instead of pulling the CSCFI REMS image by removing the `image` param and adding build instructions:
      ```
      rems:
         build:
            context: ${REMS_DIR}
            dockerfile: Dockerfile
      ```
   4. Run `docker-compose build rems` from the `compose` directory to build the dockerfile, which will package the jar you just built.
2. **Migrate and seed REMS**:
   1. Run `./migrations/migrate.sh -s rems` to prepare the database and migrate the required tables.
   2. (Optional) Run `docker-compose run --rm -e CMD="test-data" rems` to populate REMS with test data.
   3. REMS should now be ready for use.
3. Boot up the researcher keycloak instance by running `docker-compose up rp-keycloak`
4. **Add test Realm**:
   1. Access the Researcher IdP at http://localhost:3002/auth/admin
   2. Login using the username and password: `admin` / `admin`
   3. Add the test *Realm* by hovering over the "Master" label in the top left and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `../researcher-portal/keycloak/realm-export.json`. The name should be autofilled with `dycons-researcher-idp`.
   5. Click "Save" to finish.
5. **Add test User**:
   1. Navigate to the "Users" menu via the navbar on the left
   2. Click "Add User" on the right side of the page
   3. Set the username to `varchar` and click "Save".
   4. On the next page, click the "Credentials" tab
   5. Enter `varchar` in both password fields, toggle `Temporary` *off*, and click "Set Password"
6. **Expose Keycloak to REMS**:
   1. In the Researcher IdP keycloak at http://localhost:3002/auth/admin, navigate to *Clients* (on the left side of the screen) > `researcher-portal-client` > *Credentials* and click `Regenerate Secret`. Copy the generated secret, ex. `be9d769d-a166-428c-b442-5ff703cb0a78`.
   2. Open `compose/services/rems/simple-config.edn` and modify the `:oidc-client-secret` param to use the secret generated in step 3.
   3. Boot up REMS by running `docker-compose up rems` in the `compose` directory.
7. **Testing**
   1. Navigate to REMS at http://localhost:3001/.
   2. Click on the "Login" button to be redirected to your keycloak instance.
   3. Access the account using `varchar`/`varchar`. You should be authenticated and redirected back to REMS.

### REMS + Consents
To push new `entitlements` to the Consents service, uncomment the following line in `simple-config.edn` prior to running the REMS container:
```
:entitlements-target {:add "http://consents:3005/v0/rems/add_entitlement"}
```

## Consents
1. **Run** the Consents service with `docker-compose up consents`
2. **Migrate** the Consents service with `./migrations/migrate.sh -s consents`
3. (Optional) **Test** the Consents service by running requests from the [Postman collection and test data](https://github.com/dycons/consents/tree/develop/tests).

## Key Relay Service
1. **Run** the Relay sevrice with `docker-compose up relay`
2. (Optional) **Test** the Relay service by running the Postman collection at `tests/key-relay-service.postman_collection.json`
