FROM confluentinc/cp-kafka-connect-base:6.1.4

ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components,/data/connect-jars"

########################################################################################
# The following commented out section was used to download the snowsql installer
# mostly for the purpose of verifying connectivity from the container to the
# Snowflake cloud data warehouse.
#
# This only downloads the installer because running it requires interactive inputs
# not capable during the image build phase.
#
# To finish the install:
# 1. open a shell connection to the container after its been launched
# docker exec -it kafka-connect /bin/sh
#
# 2. create a directory /root/.snowsql
# mkdir /root/.snowsql
#
# 3. run the installer
# snowsql-1.2.3-linux_x86_64.bash
#
# 4. switch user to the appuser
# su - appuser
#
# 5. Copy the private key into the appuser home directory, name it rsa_key.p8
# tee rsa_key.p8 &>/dev/null <<EOF
# -----BEGIN ENCRYPTED PRIVATE KEY-----
# the-rest-of-the-contents
# -----END ENCRYPTED PRIVATE KEY-----
# EOF
#
# 6. Update file permissions
# chmod 600 rsa_key.p8
#
# 7. Connect to snowflake with snowsql
# snowsql -a somealphanumeric.us-east-2.aws -u ORDERS_CONNECT_USER --private-key-path=rsa_key.p8
#
# uncomment below USER and RUN statements to download snowsql installer then comment
# out the confluent-hub snowflake connector install before building image /
# launching with docker-compose
#USER root
#RUN yum install unzip -y  \
#        && cd /usr/local/bin \
#        && curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/linux_x86_64/snowsql-1.2.3-linux_x86_64.bash \
#        && chmod +x snowsql-1.2.3-linux_x86_64.bash \
#        && confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.7.0

# 1/2/23 B Jenkins updated to 1.6.9 as 1.7.0 was not working, Snowflake documentation said 1.7 not supported and We strongly recommend using the latest version: 1.6.9.
RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.6.9

