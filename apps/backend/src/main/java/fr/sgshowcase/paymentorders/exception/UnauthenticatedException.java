package fr.sgshowcase.paymentorders.exception;

public class UnauthenticatedException extends RuntimeException {

    public UnauthenticatedException() {
        super("Missing or empty X-Username header");
    }
}
