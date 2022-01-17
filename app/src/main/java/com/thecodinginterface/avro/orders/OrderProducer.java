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
