package fr.sgshowcase.paymentorders.exception;

import java.util.UUID;

public class OrderNotFoundException extends RuntimeException {

    public OrderNotFoundException(UUID id) {
        super("Payment order not found: " + id);
    }
}
