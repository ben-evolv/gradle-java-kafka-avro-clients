FROM ubuntu:20.04

RUN apt-get update && apt-get install -y curl unzip gpg

RUN curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/linux_x86_64/snowsql-1.2.24-linux_x86_64.bash
RUN curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/linux_x86_64/snowsql-1.2.24-linux_x86_64.bash.sig

RUN gpg --verify snowsql-1.2.24-linux_x86_64.bash.sig snowsql-1.2.24-linux_x86_64.bash

RUN gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 630D9F3CAB551AF3
RUN gpg --delete-key "Snowflake Computing"

RUN bash snowsql-1.2.24-linux_x86_64.bash -q
