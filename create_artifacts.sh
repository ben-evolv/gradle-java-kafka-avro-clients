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

# Read config.txt and store the values in variables
while IFS='=' read -r key value; do
    case "$key" in
        "PASSPHRASE") passphrase="$value" ;;
        "WAREHOUSE_NAME") warehouse_name="$value" ;;
        "DATABASE_NAME") database_name="$value" ;;
        "SCHEMA_NAME") schema_name="$value" ;;
        "ROLE_NAME") role_name="$value" ;;
        "USER_NAME") user_name="$value" ;;
        "SNOWFLAKE_URL_NAME") snowflake_url_name="$(echo -e "${value}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ;;
    esac
# echo "key: $key"
# echo "value: $value"
# echo "Exit status of read: $?"

done < config.txt

# Update snowflake-connector.json with the values from config.txt and the private key
jq --arg SNOWFLAKE_PRIVATE_KEY "$private_key" --arg user_name "$user_name" --arg passphrase "$passphrase" --arg database_name "$database_name" --arg schema_name "$schema_name" --arg snowflake_url_name "$snowflake_url_name" '.config |= . + {"snowflake.private.key":$SNOWFLAKE_PRIVATE_KEY, "snowflake.user.name": $user_name, "snowflake.private.key.passphrase": $passphrase, "snowflake.database.name": $database_name, "snowflake.schema.name": $schema_name, "snowflake.url.name": $snowflake_url_name}' kafka-connect-integration/snowflake-connector-sample.json > kafka-connect-integration/snowflake-connector.json

# Execute the build_script.sh using bash
bash scripts/build_script.sh 

# Execute the SQL script using snowsql
snowsql --config ~/.snowsql/config -f create_user.sql -c poc -o log_level=DEBUG
