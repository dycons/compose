# compose
DyCons server configuration and deployment

## Setting up Keycloak for testing:

Setup expects the following reposto be available on the development/test machine:
- [participant-portal](https://github.com/dycons/participant-portal)
- [researcher-portal](https://github.com/dycons/researcher-portal)
- [rems](https://github.com/CSCfi/rems)

To set these up at the paths specified in this repo's `.env` file, you could run the following snippet:
```
git clone https://github.com/dycons/participant-portal.git ../participant-portal && \
git clone https://github.com/dycons/researcher-portal.git ../researcher-portal && \
git clone https://github.com/CSCfi/rems.git ../rems
```

**TODO** - Turn the following setup process into an automated step on startup.

## Participant Portal

1. First make sure the keycloak services is running via `docker-compose up pp-keycloak` .
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
   5. Enter `varchar` in both password fields, toggle `Temporary` *off*, and click "Set Password"
4. **Testing** - Now it's time to test our setup by using the bundled front end:
   1. Boot up the React frontend by running `docker-compose up pp-react`
   2. Start by going to http://127.0.0.1:3003/.
   3. Click on the "Login" button and you should be redirected to the Keycloak login screen.
   4. Access the account using `varchar`/`varchar`. You'll be redirected back to the React frontend with the user's JWT token and email displayed.
   5. ** For active development **
      1. Instead of step 1, run: `dodocker-compose run --rm --entrypoint sh --service-port pp-react`. This will log you into the application.
      2. Run `yarn start` to compile the app.
      3. Continue development on your machine - changes will be mapped to the volume inside the container and reflected at 127.0.0.1:3002

## Researcher Portal

1. **Prepare REMS**:
   * **Note**: due to limitations in REMS' repository and docker setup, it is currently necessary to build the rems jar locally. Additional reading is available [here](https://github.com/CSCfi/rems/blob/master/docs/installing-upgrading.md#option-2-build-rems-image-locally).

   1. Install [Leiningen](https://leiningen.org/). Use the official instructions, or your preferred [package manager](https://github.com/technomancy/leiningen/wiki/Packaging) (for example, `brew install leiningen` or `apt-get install leiningen`)
   2. Run `lein uberjar` in the `rems` directory to build the rems jar locally.
   3. Run `docker-compose build rems` from the `compose` directory to build the dockerfile, which will package the jar you just built.
   4. Run `docker-compose run --rm -e CMD="migrate;test-data" rems` to prepare the database, migrate the required tables, and set up seed data.
   5. REMS should now be ready for use.
2. Boot up the researcher keycloak instance by running `docker-compose up rp-keycloak`
3. **Add test Realm:**
   1. Access the Researcher IdP at http://localhost:3002/auth/admin
   2. Login using the username and password: `admin` / `admin`
   3. Add the test *Realm* by hovering over the "Master" label in the top left and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `[RESEARCHER-PORTAL-DIRECTORY]/keycloak/realm-export.json`. The name should be autofilled with `dycons-researcher-idp`.
   5. Click "Save" to finish.
4. **Add test User**:
   1. Navigate to the "Users" menu via the navbar on the left
   2. Click "Add User" on the right side of the page
   3. Set the username to `varchar` and click "Save".
   4. On the next page, click the "Credentials" tab
   5. Enter `varchar` in both password fields, toggle `Temporary` *off*, and click "Set Password"
5. **Expose Keycloak to REMS**:
   * **Note:** Because REMS only permits HTTPS connections to OIDC (ticket available here), it is necessary to use a localhost tunnelling service like https://ngrok.com/
   1. Use your tunneling service to expose the keycloak service (`localhost:3002`), and acquire a useable `https` address. ngrok example: enter `ngrok http 3002` into your terminal, then copy the address following `https://` specified in the second `Forwarding` section.
   2. Open `compose/services/rems/simple-config.edn` and modify the `:oidc-domain` param to use the host from step 1, by replacing the `[HOST]` string with the HTTPS domain acquired above. Remember to only enter the domain name following `https://`, leaving out the `https://` segment.
   3. In the Researcher IdP keycloak at http://localhost:3002/auth/admin, navigate to *Clients* (on the left side of the screen) > `researcher-portal-client` > *Credentials* and click `Regenerate Secret`. Copy the generated secret, ex. `be9d769d-a166-428c-b442-5ff703cb0a78`.
   4. Back in `compose/services/rems/simple-config.edn`, modify the `:oidc-client-secret` param to use the secret generated in step 3.
   5. Boot up REMS by running `docker-compose up rems` in the `compose` directory.
6. **Testing**
   1. Navigate to REMS at http://localhost:3001/.
   2. Click on the "Login" button to be redirected to your keycloak instance.
   3. Access the account using `varchar`/`varchar`. You should be authenticated and redirected back to REMS.