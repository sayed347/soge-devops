package fr.sgshowcase.paymentorders.exception;

public class InvalidCurrencyException extends RuntimeException {

    public InvalidCurrencyException(String currency) {
        super("'" + currency + "' is not a real ISO 4217 currency code — try EUR, USD, or GBP instead");
    }
}
