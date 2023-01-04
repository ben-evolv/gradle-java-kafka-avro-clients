# Avro Based Producers and Consumers, Dockerized Apache Kafka and Pipelining Kafka Events to Snwoflake Cloud Data Warehouse

This is the demo project source code to tutorials posted on thecodinginterface.com listed below.

[Kafka Clients in Java with Avro Serialization and Confluent Schema Registry](https://thecodinginterface.com/blog/gradle-java-avro-kafka-clients/)

[Pipelining Kafka Events into Snowflake with Dockerized Kafka Connect](https://thecodinginterface.com/blog/snowflake-kafka-connect-data-pipeline/)

[Pipelining Kafka Events into Snowflake with Dockerized Kafka Connect](https://thecodinginterface.com/blog/snowflake-kafka-connect-data-pipeline/)

<br>

## Purpose of the forked repo
This fork leverages the work of Adam McQuistan. I created this fork to get experience setting up Kafka connect to stream events into Snowflake. I wanted to be able to script this for quick setup of various topics so the create_artifacts.sh script takes as input the values from the config.txt file and outputs two files that are both in .gitignore to keep keys from being committed to the repo. 
<br>
The files created by create_artifacts.sh are:
- kafka-connect/snowflake-connector-sample.json
- scripts/build_script.sh

## Prerequisites

In order to run the scripts in this repository, you will need the following:

- A Snowflake account
- A Linux-based operating system (tested on Ubuntu 18.04 and 20 on Windows 10 using WSL)
- openssl
- sed
- tr
- jq (install using `sudo apt install jq`
 in the terminal)
- Install the appropriate version of Docker desktop or docker compoose for your O/S:
  - For Windows: https://docs.docker.com/desktop/windows/wsl/
  - to run on an AWS Linux image of Ubuntu I used `sudo apt  install docker-compose`
## Compatibility

This has been developed on Windows 10 machines using VS Code on various Ubuntu distros (18.04 and 20) Windows Subsystem for Linux (WSL). It has not been tested on a Mac, but it may work due to both being Linux-based.

## Note

If you are using a Windows machine, you will need to enable WSL and choose a Linux distro in order to run these scripts.

## Additional Information

The script requires access to the following files and directories:

- `config.txt`
- `kafka-connect-integration` directory

These should be located in the same directory as the script.

To create the `config.txt` file, follow these steps:

1. Copy the `config_sample.txt` file and rename the copy to `config.txt`.
2. Open `config.txt` in a text editor.
3. Modify the sample values to your desired values.
4. Save the file and place it in the same directory as the script.

**Note: Do not commit the `config.txt` file to the repository, as it may contain sensitive information such as passwords or private keys. This should not happen as long as the file is named config.txt because it is in the .gitignore file already**

## How to Run

To run the create_artifacts script, open a terminal and navigate to the directory where the script is located. Then enter the following command:

either `bash create_artifacts.sh` or `. create_artifacts.sh`

After that you will 
- change directories to the scripts directory: `cd scripts` and run either `bash build_script.sh` or `. build_script.sh`
- copy the contents of the code in `scripts/build_script.sh` to the clipboard and run it in a new worksheet in Snowflake 
- follow along with the rest of Adam's blog post [Pipelining Kafka Events into Snowflake with Dockerized Kafka Connect](https://thecodinginterface.com/blog/snowflake-kafka-connect-data-pipeline/) beginning to begin streaming events here: 

### Launch the Docker Compose services.

`docker-compose up`

## Hints
** You will need to change to the `kafka-connect-integration` directory to run this `http POST http://localhost:8083/connectors @snowflake-connector.json`

** As an alternative to viewing the data in Snowsql you can review the data by logging into with Snowsight using the newly created users credentials.
