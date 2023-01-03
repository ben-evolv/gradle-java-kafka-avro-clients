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
#!/bin/bash

# Read config.txt and store the values in variables
while IFS='=' read -r key value; do
    case "$key" in
        "PASSPHRASE") passphrase="$value" ;;
        "WAREHOUSE_NAME") warehouse_name="$value" ;;
        "DATABASE_NAME") database_name="$value" ;;
        "SCHEMA_NAME") schema_name="$value" ;;
        "ROLE_NAME") role_name="$value" ;;
        "USER_NAME") user_name="$value" ;;
    esac
done < config.txt

# # Update snowflake-connector.json with the values from config.txt
jq --arg user_name "$user_name" --arg passphrase "$passphrase" --arg database_name "$database_name" --arg schema_name "$schema_name" '.config |= . + ({snowflake.user.name: $user_name, snowflake.private.key.passphrase: $passphrase, snowflake.database.name: $database_name, snowflake.schema.name: $schema_name})' snowflake-connector-sample.json > snowflake-connector.json.tmp 
