# compose
DyCons server configuration and deployment

## Setting up Keycloak for testing:

**TODO** - Turn the following setup process into an automated step on startup.

1. First make sure the services are running via `docker-compose up` .
2. **Add test Realm:**
   1. Navigate to http://127.0.0.1:8080/auth/admin.
   2. Login using the username and password: `admin` / `admin`
   3. Add the test **Realm** by hovering over the "Master" label in the top left, and click "Add realm".
   4. Click "Select File" and choose the preconfigured realm at `../participant-portal/keycloak/realm-export.json`. The name should be autofilled with `dycons`.
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