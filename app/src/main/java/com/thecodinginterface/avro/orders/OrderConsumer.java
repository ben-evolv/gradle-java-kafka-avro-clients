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
