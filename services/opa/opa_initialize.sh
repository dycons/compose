#!/bin/bash

source .env
curl -X PUT --data-binary @${OPA_DIR}/data.json localhost:8181/v1/data
curl -X PUT --data-binary @${OPA_DIR}/passport.rego localhost:8181/v1/policies/ga4ghPassport