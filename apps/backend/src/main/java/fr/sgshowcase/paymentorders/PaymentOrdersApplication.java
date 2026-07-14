package fr.sgshowcase.paymentorders;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class PaymentOrdersApplication {

    public static void main(String[] args) {
        SpringApplication.run(PaymentOrdersApplication.class, args);
    }
}
