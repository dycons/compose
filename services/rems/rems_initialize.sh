#!/bin/bash

source .env
docker exec -it rems java -Drems.config=config/config.edn -jar rems.jar api-key add rp
docker exec -it rems java -Drems.config=config/config.edn -jar rems.jar api-key allow rp get '/api/permissions/.*'
docker exec -it rems java -Drems.config=config/config.edn -jar rems.jar grant-role owner ${REMS_OWNER_ID}
docker exec -it rems java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add abc123 Testing