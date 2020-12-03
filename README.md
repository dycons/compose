# compose
DyCons server configuration and deployment

## Setting up Keycloak for testing:

Setup expects the `participant-portal`, `researcher-portal`, and `rems` repos to be available on the development/test machine
**TODO** - Turn the following setup process into an automated step on startup.


# Participant Portal

1. First make sure the services are running via `docker-compose up` .
2. **Add test Realm:**
   1. Navigate to http://127.0.0.1:8080/auth/admin.
   2. Login using the username and password: `admin` / `admin`
   3. Add the test **Realm** by hovering over the "Master" label in the top left, and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `[PARTICIPANT-PORTAL-DIRECTORY]/keycloak/realm-export.json`. The name should be autofilled with `dycons`.
   5. Click "Save" to finish.
3. **Add test User**:
   1. Navigate to the "Users" menu via the navbar on the left
   2. Click "Add User" on the right side of the page
   3. Set the username to `varchar` and click "Save".
   4. On the next page, click the "Credentials" tab
   5. Enter `varchar` in both password fields and click "Set Password"
4. **Testing** - Now it's time to test our setup by using the bundled front end:
   1. Start by going to http://127.0.0.1:3000/. You should be automatically redirected to the Keycloak login screen.
   2. Access the account using `varchar`/`varchar`. You'll be redirected back to the Vue front end with the user's JWT token.

# Researcher Portal

1. **Prepare REMS**:
   * **Note**: due to limitations in REMS' repository and docker setup, it is currently necessary to build the rems jar locally. Additional reading is available at [here](https://github.com/CSCfi/rems/blob/master/docs/installing-upgrading.md#option-2-build-rems-image-locally. )

   1. Install [Leiningen](https://leiningen.org/). Use the official instructions, or your preferred [package manager](https://github.com/technomancy/leiningen/wiki/Packaging) ( `brew install leiningen` for example)
   2. Run `lein uberjar` in the `[REMS-DIRECTORY]` directory to build the rems jar locally
   3. Run `docker-compose build rems` from the `compose` directory to build the dockerfile, which will package the jar you just built
   4. Run `docker-compose run --rm -e CMD="migrate;test-data"` to prepare the database, migrate the required tables, and set up seed data.
   5. REMs should now be ready for use.
2. Boot up the researcher keycloak instance by running `docker-compose up rp-keycloak`
3. **Add test Realm:**
   1. Access the Researcher IdP at http://localhost:3002/auth/admin
   2. Login using the username and password: `admin` / `admin`
   3. Add the test **Realm* by hovering over the "Master" label in the top left and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `[RESEARCHER-PORTAL-DIRECTORY]/portal/keycloak/realm-export.json`. The name should be autofilled with `dycons-researcher-idp`.
   5. Click "Save" to finish.
4. **Add test User**:
   1. Navigate to the "Users" menu via the navbar on the left
   2. Click "Add User" on the right side of the page
   3. Set the username to `varchar` and click "Save".
   4. On the next page, click the "Credentials" tab
   5. Enter `varchar` in both password fields and click "Set Password"
5. **Expose Keycloak to REMS**:
   * **Note:** Because REMS only permits https connections to OIDC (ticket available here), it is necessary to use a localhost tunnelling service like https://ngrok.com/
   1. Use your tunneling service to expose the keycloak service (`localhost:3002`), and acquire a useable `https` address.
   2. Open `compose/services/rems/simple-config.edn` and modify the `:oidc-domain` params to use the host from step 1.
   3. Boot up REMS by running `docker-compose up rems`
6. **Testing**
   1. Navigate to REMs at http://localhost:3001/.
   2. Click on the "Login" button to be redirected to your keycloak instance.
   3. Access the account using `varchar`/`varchar`. You should be authenticate and redirected back to REMS.