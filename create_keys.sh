#!/bin/bash

# Read the passphrase from a configuration file
PASSPHRASE=$(cat config.txt | grep PASSPHRASE | cut -d "=" -f2)

# Create a private key (use the passphrase provided in the configuration file) for authenticating to Snowflake.
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -passout pass:$PASSPHRASE -out rsa_key.p8

# Extract the key contents from rsa_key.p8. This will be used in the snowflake-connector.json
private_key=$(sed -n '/-----BEGIN ENCRYPTED PRIVATE KEY-----/,/-----END ENCRYPTED PRIVATE KEY-----/p' rsa_key.p8 | tr -d '\n')

# Create a public key (use the passphrase provided in the configuration file) for authenticating to Snowflake.
openssl rsa -in rsa_key.p8 -pubout -passin pass:$PASSPHRASE -out rsa_key.pub

# Extract the key contents from rsa_key.pub. This will be used to assign the public key to the user in Snowflake during user creation
public_key=$(sed -n '/-----BEGIN PUBLIC KEY-----/,/-----END PUBLIC KEY-----/p' rsa_key.pub | sed -e '1d' -e '$d' | tr -d '\n')
echo 'RSA_PUBLIC_KEY = "'$public_key'"' > RSA_PUBLIC_KEY.txt

# Update the value of "snowflake.private.key" in connector_config.json
jq --arg SNOWFLAKE_PRIVATE_KEY "$private_key" '.config |= .+{"snowflake.private.key":$SNOWFLAKE_PRIVATE_KEY}' kafka-connect-integration/snowflake-connector-sample.json > kafka-connect-integration/snowflake-connector.json
