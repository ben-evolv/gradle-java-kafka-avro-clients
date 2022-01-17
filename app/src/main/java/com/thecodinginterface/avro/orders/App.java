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
        var consumer = new OrderConsumer(
                "localhost:9092",
                "orders-avro",
                "orders-avro-100",
                "http://localhost:8081"
        );
        consumer.consume();
    }
}
