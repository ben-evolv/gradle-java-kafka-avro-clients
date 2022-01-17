# Java Kafka Clients with Avro Serialization and Confluent Schema Registry

## Introduction

In this article I present a minimal Java Gradle project that utilizes [Apache Avro serialization](https://avro.apache.org/docs/1.10.0/index.html) and integrates with the [Confluent Schema Registry](https://docs.confluent.io/platform/current/schema-registry/index.html) for managing message data formats used by Apache Kafka producers and consumers. To implement the Avro schemas I utilize JSON based definitions then utilize the [gradle-avro-plugin](https://github.com/davidmc24/gradle-avro-plugin) which generates Java Source Classes I can use in the producer and consumer implementation classes. For provisioning a Kafka and Confluent Schema Registry enabled environment I rely on the [Confluent provided community edition](https://github.com/confluentinc/cp-all-in-one/blob/7.0.1-post/cp-all-in-one-community/docker-compose.yml) Docker images and docker-compose starter service files.

For this article I'm using Gradle version 6.8.3 and the AdoptOpenJDK version 11 as shown below.

```
gradle --version
```

Output.

```
------------------------------------------------------------
Gradle 6.8.3
------------------------------------------------------------

Build time:   2021-02-22 16:13:28 UTC
Revision:     9e26b4a9ebb910eaa1b8da8ff8575e514bc61c78

Kotlin:       1.4.20
Groovy:       2.5.12
Ant:          Apache Ant(TM) version 1.10.9 compiled on September 27 2020
JVM:          11.0.8 (AdoptOpenJDK 11.0.8+10)
OS:           Mac OS X 10.16 x86_64
```

The completed project's source can be found on my [GitHub account](https://github.com/amcquistan/gradle-java-kafka-avro-clients).

## Gradle Project Setup

First off I reate a project directory and change directories into into it.

```
mkdir java-avro-clients-faker-orders
cd java-avro-clients-faker-orders
```

Next start a Gradle Java Application project with the gradle init command.

```
$ gradle init

Select type of project to generate:
  1: basic
  2: application
  3: library
  4: Gradle plugin
Enter selection (default: basic) [1..4] 2

Select implementation language:
  1: C++
  2: Groovy
  3: Java
  4: Kotlin
  5: Scala
  6: Swift
Enter selection (default: Java) [1..6] 3

Split functionality across multiple subprojects?:
  1: no - only one application project
  2: yes - application and library projects
Enter selection (default: no - only one application project) [1..2] 1

Select build script DSL:
  1: Groovy
  2: Kotlin
Enter selection (default: Groovy) [1..2]

Select test framework:
  1: JUnit 4
  2: TestNG
  3: Spock
  4: JUnit Jupiter
Enter selection (default: JUnit 4) [1..4]

Project name (default: java-avro-clients-faker-orders):
Source package (default: java.avro.clients.faker.orders): com.thecodinginterface.avro.orders

> Task :init
Get more help with your project: https://docs.gradle.org/6.8.3/samples/sample_building_java_applications.html

BUILD SUCCESSFUL in 28s
2 actionable tasks: 2 executed
```

Following that I update the settings.gradle file to include the following to instruct it where to find plugins at.

```
pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

rootProject.name = 'java-avro-clients-faker-orders'
include('app')
```

Then I update app/build.gradle to include the required plugins along with the Apache Avro and Kafka dependencies.

```
plugins {
    id 'java'
    id 'application'
    id "com.github.davidmc24.gradle.plugin.avro" version "1.3.0"
}

repositories {
    mavenCentral()
    maven { url "http://packages.confluent.io/maven/" }
}

sourceCompatibility = 11
targetCompatibility = 11

dependencies {
    // Use JUnit test framework.
    testImplementation 'junit:junit:4.13'

    implementation group: 'org.apache.kafka', name: 'kafka-clients', version: '2.6.0'

    implementation group: 'org.apache.avro', name: 'avro', version: '1.11.0'
    implementation group: 'org.apache.avro', name: 'avro-tools', version: '1.11.0'
    implementation group: 'io.confluent', name: 'kafka-avro-serializer', version: '6.0.0'

    implementation group: 'org.slf4j', name: 'slf4j-log4j12', version: '1.7.30'
    implementation 'com.github.javafaker:javafaker:1.0.2'
}

application {
    // Define the main class for the application.
    mainClass = 'com.thecodinginterface.avro.orders.App'
}
```

Next I add the following Confluent based Docker Compose file named docker-compose.yml at the root of my Gradle project which I've trimmed down to just Zookeeper, Kafka and Schema Registry exposing their standard ports.

```
---
version: '2'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:6.2.0
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  broker:
    image: confluentinc/cp-kafka:6.2.0
    hostname: broker
    container_name: broker
    depends_on:
      - zookeeper
    ports:
      - "29092:29092"
      - "9092:9092"
      - "9101:9101"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_JMX_PORT: 9101
      KAFKA_JMX_HOSTNAME: localhost

  schema-registry:
    image: confluentinc/cp-schema-registry:6.2.0
    hostname: schema-registry
    container_name: schema-registry
    depends_on:
      - broker
    ports:
      - "8081:8081"
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: 'broker:29092'
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
```

Now I can spin up the Docker Compose services with the connonical up command.

```
docker-compose up
```

And in another terminal I can create a topic to produce to and consume from named orders-avro utilizing the kafka-topics CLI binary that comes bundled with the confluentinc/cp-kafka Docker image.

```
docker exec -it broker kafka-topics --bootstrap-server broker:9092 --create --topic orders-avro --partitions 3 --replication-factor 1
```

Then just for completeness I list all the topics present.

```
docker exec -it broker kafka-topics --bootstrap-server broker:9092 --list
```

Output.

```
__consumer_offsets
_schemas
orders-avro
```

You can see the ordersavro topic listed along with the \__consumer\_offsets topic for tracking the comsumer group checkpoints along with the \_schemas topic which Confluent Schema Registry uses to manage the schemas. 

## Define Avro Specification Files and Generate Java Serializers

Here I create a directory for defining the Avro schema JSON definitions named src/main/avro with a file inside the avro directory named order_value.avsc containing the following Avro specification. The gradle-avro-plugin knows to look for .avsc definition files within the avro sourceset directory.

```
{
    "namespace": "com.thecodinginterface.avro.orders",
    "type": "record",
    "name": "OrderValue",
    "fields": [
        { "name": "id", "type": "string"},
        { "name": "amount", "type": "int"},
        { "name": "created",
          "type": {
              "type": "long",
              "logicalType": "local-timestamp-millis"
          }
        },
        {"name": "customer", "type": "string"},
        {"name": "creditcard", "type": "string"}
    ]
}
```

Build the gradle project to generate the Avro Java Serialization/Deserialization source classes which will show up under the app/build/generated-main-afro-java directory.

```
gradlew build
```

Here are the generated files.

```
app/build/generated-main-avro-java
└── com
    └── thecodinginterface
        └── avro
            └── orders
                └── OrderValue.java
```

## Create the Java Producer

Now I create a new OrderProducer.java source file in the com.thecodinginterface.avro.orders package and place the following Java source code in it.

```
package com.thecodinginterface.avro.orders;

import com.github.javafaker.Faker;
import io.confluent.kafka.serializers.KafkaAvroSerializer;
import io.confluent.kafka.serializers.KafkaAvroSerializerConfig;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;
import java.util.Properties;
import java.util.UUID;

public class OrderProducer {
    final static int MIN_AMT = 100; // one dollar
    final static int MAX_AMT = 10000; // one hundred dollars
    final static Logger logger = LoggerFactory.getLogger(OrderProducer.class);

    final String topic;
    final KafkaProducer<String, OrderValue> producer;

    public OrderProducer(String bootstrapServers, String topic, String clientId, String schemaRegistry) {
        logger.info("Initializing Producer");
        this.topic = topic;
        var props = new Properties();
        props.put(ProducerConfig.CLIENT_ID_CONFIG, clientId);
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);
        props.put(KafkaAvroSerializerConfig.SCHEMA_REGISTRY_URL_CONFIG, schemaRegistry);
        props.put(ProducerConfig.LINGER_MS_CONFIG, 500);

        producer = new KafkaProducer<String, OrderValue>(props);
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("Shutting down producer");
            producer.close();
        }));
    }

    public void produce() throws Exception {
        var faker = new Faker();
        while(true) {
            var orderValue = OrderValue.newBuilder()
                    .setId(UUID.randomUUID().toString())
                    .setCustomer(faker.name().fullName())
                    .setAmount(faker.number().numberBetween(MIN_AMT, MAX_AMT))
                    .setCreated(LocalDateTime.now())
                    .setCreditcard(faker.number().digits(4))
                    .build();
            var record = new ProducerRecord<String, OrderValue>(topic, orderValue.getId(), orderValue);
            producer.send(record, ((metadata, exception) -> {
                logger.info("Produced record to topic {} partition {} at offset {}",
                        metadata.topic(), metadata.partition(), metadata.offset());
            }));
            Thread.sleep(100);
        }
    }
}
```

This new OrderProducer class provides a constructor that accepts the kafka broker (ie, bootstrap servers) urls, the name of a topic to produce to (orders-avro), along with a client ID followed by the url of the Confluent Schema Registry.

Within the OrderProducer constructor I configure the producer with the parameters passed in to the constructor signature. I also instruct the producer to use the standard Kafka String serializer for record keys and the KafkaAvroSerializer from Confluent for serializing record values. I also tell the producer to wait up to half a second (500 ms) before publishing messages to Kafka which allows for batching up multiple records per request increasing throughput.  

Following the configuration setup I construct the KafkaProducer class specifying the key of type string and the value of type OrderValue as was specified in the order_value.avsc definition ealrier. Lastly, I add a shutdown hook callback to call close() on the producer which will hold it open allowing it to finish sending any lingering records upon program shutdown.

Then in the produce() method I utilize the [JavaFaker](https://github.com/DiUS/java-faker) library to generate some fake data used to populate OrderValue objects of the gradle-avro-plugin. These OrderValue objects are then passed to instantiate ProducerRecord instances. The fake order records are then fed to the producer to be sent off to the Kafka broker.

Next I update the App.java main class to launch the OrderProducer class when the Gradle project is passed a command line argument of "producer".

```
package com.thecodinginterface.avro.orders;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class App {
    static final Logger logger = LoggerFactory.getLogger(App.class);

    public static void main(String[] args) {
        logger.info("Starting Kafka Avro Client Application");

        String action = args.length > 0 ? args[0] : "producer";
        try {
            switch (action) {
                case "producer":
                    runProducer();
                    break;
                case "consumer":
                    runConsumer();
                    break;
                default:
                    logger.error("Unknown action {}", action);
                    break;
            }
        } catch (Exception e) {
            logger.error("Error in main app", e);
        }
    }

    static void runProducer() throws Exception {
        var producer = new OrderProducer(
                "localhost:9092",
                "orders-avro",
                "orders-avro-1",
                "http://localhost:8081"
        );
        producer.produce();
    }

    static void runConsumer() {
        logger.info("Choose consumer");
    }
}
```

The runConsumer() method will be updated latter.

Run project with gradle run like so.

```
./gradlew run
```

Then in another terminal use the kafka-avro-console-consumer that is bundled in the confluentinc/cp-schema-registry Docker image to verify that Avro based Order records are making it into Kafka.

```
docker exec -it schema-registry kafka-avro-console-consumer --bootstrap-server broker:29092 --from-beginning --topic orders-avro --property schema.registry.url=http://schema-registry:8081
```

Here are the last few lines of output I recieved but, your's will differ as this is autogenerated fake data.

```
...
{"id":"bd2820e3-c938-482b-8c21-54437e32f61f","amount":8958,"created":1642415297562,"customer":"Della Gleichner","creditcard":"0802"}
{"id":"283d079d-566e-486d-94c8-0c5d88374536","amount":9100,"created":1642415297769,"customer":"Ozie Ritchie","creditcard":"0341"}
{"id":"74a36f73-e1d0-47ef-b790-c0d29a4bf059","amount":8103,"created":1642415297977,"customer":"Randee Bailey","creditcard":"7880"}
{"id":"d981fee6-1027-410f-ab33-b72eb9485bd1","amount":3030,"created":1642415298186,"customer":"Leslie Streich III","creditcard":"2705"}
{"id":"8a5dcb83-0837-4249-8e91-3dba6f48502b","amount":6479,"created":1642415298395,"customer":"Zackary Bogisich MD","creditcard":"5663"}
```

Its also worth taking a second to play around with the [Confluent Schema Registry REST API](https://docs.confluent.io/platform/current/schema-registry/develop/api.html#schemas) to inspect the data its managing for schemas. To query the REST API I'll be using the [HttpPie HTTP CLI client](https://httpie.io/) but, you could use curl or Postman if you prefer them.

```
http :8081/schemas
```

Output shows that I have one schema being managed for the orders-avro topic's message value and it's on the first version.

```
HTTP/1.1 200 OK
Content-Encoding: gzip
Content-Length: 241
Content-Type: application/vnd.schemaregistry.v1+json
Date: Mon, 17 Jan 2022 16:40:33 GMT
Vary: Accept-Encoding, User-Agent

[
    {
        "id": 1,
        "schema": "{\"type\":\"record\",\"name\":\"OrderValue\",\"namespace\":\"com.thecodinginterface.avro.orders\",\"fields\":[{\"name\":\"id\",\"type\":{\"type\":\"string\",\"avro.java.string\":\"String\"}},{\"name\":\"amount\",\"type\":\"int\"},{\"name\":\"created\",\"type\":{\"type\":\"long\",\"logicalType\":\"local-timestamp-millis\"}},{\"name\":\"customer\",\"type\":{\"type\":\"string\",\"avro.java.string\":\"String\"}},{\"name\":\"creditcard\",\"type\":{\"type\":\"string\",\"avro.java.string\":\"String\"}}]}",
        "subject": "orders-avro-value",
        "version": 1
    }
]
```

You can see that the value of the id field is 1. This id field is used to send with the message payload to Kafka and is what is used to lookup the schema on the consuming client side to figure out how to decode the Avro back to business objects. More can read about this [here](https://docs.confluent.io/platform/current/schema-registry/index.html).

## Create a Java Consumer

Now that I have a producer happily producing Avro serialized order data to Kafka all that remains is to code up a client implementation and complete the pub/sub circle of life.  I create a new Java source file named OrderConsumer.java in the com.thecodinginterface.avro.orders package and place the following source in it.


```
package com.thecodinginterface.avro.orders;

import io.confluent.kafka.serializers.KafkaAvroDeserializer;
import io.confluent.kafka.serializers.KafkaAvroDeserializerConfig;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.List;
import java.util.Properties;

public class OrderConsumer {
    final static Logger logger = LoggerFactory.getLogger(OrderConsumer.class);
    final static int POLL_TIME_MS = 1000;

    final KafkaConsumer<String, OrderValue> consumer;

    public OrderConsumer(String bootstrapServers, String topic, String groupId, String schemaRegistry) {
        var props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaAvroDeserializer.class);
        props.put(KafkaAvroDeserializerConfig.SPECIFIC_AVRO_READER_CONFIG, "true");
        props.put(KafkaAvroDeserializerConfig.SCHEMA_REGISTRY_URL_CONFIG, schemaRegistry);

        consumer = new KafkaConsumer<String, OrderValue>(props);
        consumer.subscribe(List.of(topic));
    }

    public void consume() {
        try {
            while(true) {
                ConsumerRecords<String, OrderValue> records = consumer.poll(Duration.ofMillis(POLL_TIME_MS));
                for (ConsumerRecord<String, OrderValue> record: records) {
                    var order = (OrderValue) record.value();
                    logger.info("id = {}, customer = {}, created = {}, amount = {}, creditcard = {}",
                            order.getId(), order.getCustomer(), order.getAmount(), order.getCreated(), order.getCreditcard());
                }
            }
        } finally {
            logger.info("Closing consumer");
            consumer.close();
        }
    }
}
```

Update the App.java source so that the runConsumer() method constructs the OrderConsumer class and initiates fetching of messages from Kafak.

```
    static void runConsumer() {
        logger.info("Choose consumer");
        var consumer = new OrderConsumer(
                "localhost:9092",
                "orders-avro",
                "orders-avro-100",
                "http://localhost:8081"
        );
        consumer.consume();
    }
```

Then I can launch my Gradle project passing the --args="consumer" argument to the Gradle run task to test the consumer just implemented.

```
./gradlew run --args="consumer"
```

Here are the last few rows of output.

```
...
22/01/17 11:13:38 INFO orders.OrderConsumer: id = bd2820e3-c938-482b-8c21-54437e32f61f, customer = Della Gleichner, created = 8958, amount = 2022-01-17T10:28:17.562, creditcard = 0802
22/01/17 11:13:38 INFO orders.OrderConsumer: id = 283d079d-566e-486d-94c8-0c5d88374536, customer = Ozie Ritchie, created = 9100, amount = 2022-01-17T10:28:17.769, creditcard = 0341
22/01/17 11:13:38 INFO orders.OrderConsumer: id = 74a36f73-e1d0-47ef-b790-c0d29a4bf059, customer = Randee Bailey, created = 8103, amount = 2022-01-17T10:28:17.977, creditcard = 7880
22/01/17 11:13:38 INFO orders.OrderConsumer: id = d981fee6-1027-410f-ab33-b72eb9485bd1, customer = Leslie Streich III, created = 3030, amount = 2022-01-17T10:28:18.186, creditcard = 2705
22/01/17 11:13:38 INFO orders.OrderConsumer: id = 8a5dcb83-0837-4249-8e91-3dba6f48502b, customer = Zackary Bogisich MD, created = 6479, amount = 2022-01-17T10:28:18.395, creditcard = 5663
```


## Conclusion

In this article I gave a practical example of how to write a simple Java Gradle based project with producer and consumer clients which utilize the Avro serialization technology along with the Confluent Schema Registry. 