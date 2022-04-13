# rems-demo
[CSCFI REMS](https://github.com/cscfi/rems) DAC Portal demo configuration and deployment.

Forked from [dycons/compose], significantly divergent due to having all components unrelated to the REMS demo stripped out.

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [rems-demo](#rems-demo)
  - [For Shaikh](#for-shaikh)
    - [Dependencies](#dependencies)
    - [Setting up the demo environment](#setting-up-the-demo-environment)
  - [For Karen](#for-karen)
    - [Preparing Postman for the demo](#preparing-postman-for-the-demo)
  - [Running the demo](#running-the-demo)

<!-- /code_chunk_output -->


## For Shaikh

### Dependencies

In addition to this repository, the following should be available in the demo VM:

- Postman for running the demo (a collection of API requests.)

### Setting up the demo environment

For ClinDIG 4.2 DAC Portal demo, ignore all (Optional) steps below.

1. **Prepare environment**: Ensure that you have a well-configured `.env` file in the `compose` root. To use the default configuration, run `cp .default.env .env`
2. **Start up Researcher IdP**:
    1. Run `docker-compose up rp-keycloak`.
3. **Prepare Keycloak**:
    1. To prepare the keycloak for use with rems, run: `. ./init/rp-keycloak.sh`
       1. This will import a keycloak realm, initialize it, and add two test users:
          - username: `applicant`, password: `applicant`
          - username: `owner`, password: `owner`
       2. This will export the following environment variables to your shell, for use in authorization. Skip sourcing the script if this is not desired.
          - REMS_CLIENT_SECRET
          - OWNER_ID
          - APPLICANT_ID
4. **Start up Katsu and OPA**:
    1. Follow the steps [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry) to authenticate to the GitHub Container Registry.
    2. Run `docker-compose up katsu`
5. (Optional) **Add Sample Katsu Data**:
    1. To add sample data to Katsu, run: `docker exec -it -w /app/chord_metadata_service/scripts katsu python ingest.py`
6. **Add Authorization Rules and Data to OPA**:
    1. To add authorization policies and data to OPA, run `./init/opa.sh`
       - Note that the only datasets that will be affected by these policies are those listed in the `data.json` file ingested in this initialization. Currently only the following dataset titles are authorized on:
       ```
       https://ega-archive.org/datasets/710
       https://ega-archive.org/datasets/712
       urn:nbn:fi:lb-201403262
       ```
       - As a result, if you are using the `rems-and-katsu-test.postman_collection.json` Postman Collection for testing, the value of the `resource-title` environment variable must be one of the above datasets.
7. **Migrate and seed REMS**:
    1. To prepare the database and migrate the required tables, run `./init/migrate.sh rems` 
    2. (Optional) To populate REMS with test data, run `docker-compose run --rm -e CMD="test-data" rems`
    3. REMS should now be ready for use. Run `docker-compose up rems`
8. **Create REMS Users**:
   You can test the REMS API by submitting requests through the instance's [Swagger UI](http://localhost:3001/swagger-ui/index.html), or by running requests from one of the [Postman Collections](https://github.com/dycons/compose/tree/develop/tests). For the latter option, testing the API outside of the browser will require you to include some authorization information in the request headers.

    We will use 2 users in this demo. We will add the owner to REMS now.

    1. **Log owner in to REMS**: Make sure your user is known to REMS.
        1. Navigate to http://127.0.0.1:3001
        2. Click "Login".
        3. Login using the username and password: `owner` / `owner`
            - REMS can be made aware of any other users via either the `/users/create` endpoint, or by logging in as that user.
        4. (Optional) In the top right, click "Sign out".
            - (Optional) To logout of REMS via the `rp-keycloak`, as the keycloak `admin`, navigate to `Sessions` > `Logout All` via the navbar on the left.
    2. **Prepare credentials for owner user**: Provide REMS with an API key **and** grant your user the `owner` role by running `./init/authorize.sh $OWNER_ID`
       - By default, the API key set by this script is `abc123`, matching the API key in the Postman collection, but you can optionally set a custom key.
       - The USERID is output by the `init/rp-keycloak.sh` script used to prepare keycloak. If you sourced the script, you can use the `$OWNER_ID` and `$APPLICANT_ID` environment variables in your shell.

Future users can be created in REMS by logging in through the browser **or** IFF you have act as a user with the `owner` role, by sending a request to the `/api/users/create` endpoint. The `userid` must match the user's id in Keycloak.

10. **Prepare Postman authorization headers**: Add headers to your requests containing the following key-value pairs:
- `x-rems-api-key`: The API key to use for authorizing your call. Must be known to REMS. Set by `./init/authorize.sh`
- `x-rems-user-id`: The ID of your user in REMS, as set by Keycloak (ex. `$OWNER_ID`)
Postman lets you easily reuse information like authorization variables with environment variables. Edit the `tests/rems-and-katsu-test.postman_environment.json` to populate environment variables for the demo, especially `rems-owner-user-id` and `rems-applicant-user-id`. Double-check `rems-api-key` as well. **Make sure to remove all `""` quotation marks from the environment variable values!!**

## For Karen

### Preparing Postman for the demo

It is recommended that you run a Postman collection in the Postman UI for this demo.

In the instructions below, bulleted items are optional. This demo can be run by just reading off the title and then clicking SEND on every request.

1. Open Postman
2. Import the `rems-and-katsu-test.postman_collection.json` and `rems-and-katsu-test.postman_environment.json` files from the `tests` directory.
3. Click on the dropdown (probably labeled `No Environment`) in the top-right of the Postman window. Select `rems-and-katsu-test`.
4. Click on the eye next to the dropdown to inspect the environment, and make sure that each variable has a CURRENT VALUE. If any are empty in this column, populate them by copy+pasting the INITIAL VALUE from the left.
5. Expand the imported `rems-and-katsu-test` API request collection by clicking on it in the left-side Collections browser.
6. Run each of the requests in `Create resources in Katsu`, in order, from top to bottom (click blue `SEND` button, or hit `Ctrl+Enter`).
    - For your interest/familiarity, look into `Body` and `Tests` for a couple of them.
    - The `Response` to the request is in the bottom-right box.
    - `Test Results` shows a `passed tests` counter. If it's green, all tests passed. If it's red, something's broken.
    - Notice that `Headers` is empty (or rather has nothing special in it). That is because Katsu doesn't care about authentication in this demo. But REMS will. So requests that we send to `rems` later will have authentication-related information in their `Headers`.
7. Run the request in `Create users in REMS`, in order, from top to bottom.
    - `"userid": {{rems-applicant-user-id}}` is calling a variable from the environment. This demo also uses lots of local collection-level variables, which allow `tests` to pass information to subsequent `requests`.
8. Expand the remaining folders and read the titles of the requests to skim the story of the demo.

## Running the demo

1. Run all remaining requests in the `rems-and-katsu-test` Collection, in order from top to bottom.
2. When you get to `Let's fetch and store researcher's permissions JWT` you can copy the value of `ga4gh_passport_v1` and paste it into [JWT.io](https://jwt.io/) to examine the contents of the researcher's REMS entitlements.
In case of error, here's an example you can examine instead. Copy the long string inside the square brackets + quotation marks `["   "]`:
```json
{
    "ga4gh_passport_v1": [
        "eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHA6Ly9sb2NhbGhvc3Q6MzAwMS9hcGkvandrIiwidHlwIjoiSldUIiwia2lkIjpudWxsfQ.eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjMwMDEvIiwic3ViIjoiMzQ2MWFhN2MtYzNmMS00MmFkLWIxNjEtYzU2MDVhM2M3ZTk0IiwiaWF0IjoxNjQ5ODE4OTQwLCJleHAiOjE2ODEzNTQ5NDAsImdhNGdoX3Zpc2FfdjEiOnsidHlwZSI6IkNvbnRyb2xsZWRBY2Nlc3NHcmFudHMiLCJ2YWx1ZSI6Imh0dHBzOi8vZWdhLWFyY2hpdmUub3JnL2RhdGFzZXRzLzcxMCIsInNvdXJjZSI6Imh0dHA6Ly9sb2NhbGhvc3Q6MzAwMS8iLCJieSI6ImRhYyIsImFzc2VydGVkIjoxNjQ5ODE4OTMwfX0.kK8ADj3TNe7EDcZJ3zFiqfLp3Eagt9QRDhTEdiMo8VYllBKSkjZltvKe2B3oEbtzHPVhXquSXJIJMHOhRkr5hPbHvhAoahVL213VDdb_TtNcGda198_ZdGD-xWb6QRUeJXTaEMYt_SZY2j-VwDx9z-f1bG7xaFfh7hiwkpe4aBYtjBeyYApepV6J-D1sNwgXullpWhmQ2Ar_dLEXTiIruL9Slgu1AaOGmuedUK_saZLnPInUfSPd91bh0gH0_D0fg0PgI9DP_Pp9K6rk9PM_8vJm7d3CNCtcxXl7gx8RtldWgU9t684fxBLFZNdDE_0Xb4SKDLrcd9ME5Pv_74b-8Q"
    ]
}
```

## Technical debt

Currently there is a `frontendUrl` hardcoded in `rp-keycloak.realm-export.json`. This was a necessary workaround in the past, to get routing from REMS to the keycloak and back to work properly, but can probably be removed now.