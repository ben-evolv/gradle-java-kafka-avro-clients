FROM ubuntu:20.04

# Install bash
RUN apt-get update && apt-get install -y bash

# Set the working directory
WORKDIR /app

# Copy the script and the config file to the working directory
COPY scripts/build_script.sh .
COPY config.txt .

# Run the script when the container starts
CMD ["bash", "./build_script.sh"]
