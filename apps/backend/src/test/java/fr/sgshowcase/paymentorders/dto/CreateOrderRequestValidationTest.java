package fr.sgshowcase.paymentorders.dto;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class CreateOrderRequestValidationTest {

    private static ValidatorFactory factory;
    private static Validator validator;

    @BeforeAll
    static void setUp() {
        factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @AfterAll
    static void tearDown() {
        factory.close();
    }

    @Test
    void acceptsAValidOrder() {
        CreateOrderRequest request = new CreateOrderRequest(
                "FR7630006000011234567890189", "DE89370400440532013000",
                new BigDecimal("100.00"), "EUR");

        Set<ConstraintViolation<CreateOrderRequest>> violations = validator.validate(request);

        assertThat(violations).isEmpty();
    }

    @Test
    void rejectsNonPositiveAmount() {
        CreateOrderRequest request = new CreateOrderRequest(
                "FR7630006000011234567890189", "DE89370400440532013000",
                new BigDecimal("0"), "EUR");

        Set<ConstraintViolation<CreateOrderRequest>> violations = validator.validate(request);

        assertThat(violations).anyMatch(v -> v.getPropertyPath().toString().equals("amount"));
    }

    @Test
    void rejectsMalformedIban() {
        CreateOrderRequest request = new CreateOrderRequest(
                "not-an-iban", "DE89370400440532013000",
                new BigDecimal("100.00"), "EUR");

        Set<ConstraintViolation<CreateOrderRequest>> violations = validator.validate(request);

        assertThat(violations).anyMatch(v -> v.getPropertyPath().toString().equals("debtorIban"));
    }

    @Test
    void rejectsMalformedCurrency() {
        CreateOrderRequest request = new CreateOrderRequest(
                "FR7630006000011234567890189", "DE89370400440532013000",
                new BigDecimal("100.00"), "euro");

        Set<ConstraintViolation<CreateOrderRequest>> violations = validator.validate(request);

        assertThat(violations).anyMatch(v -> v.getPropertyPath().toString().equals("currency"));
    }
}
