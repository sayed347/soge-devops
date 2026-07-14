package fr.sgshowcase.paymentorders.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.math.BigDecimal;

public record CreateOrderRequest(

        @NotNull(message = "debtorIban is required")
        @Pattern(regexp = "^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$",
                message = "debtorIban must start with 2 uppercase letters, then 2 digits, then 11 to 30 "
                        + "letters/digits (15 to 34 characters total) — e.g. FR7630006000011234567890189")
        String debtorIban,

        @NotNull(message = "creditorIban is required")
        @Pattern(regexp = "^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$",
                message = "creditorIban must start with 2 uppercase letters, then 2 digits, then 11 to 30 "
                        + "letters/digits (15 to 34 characters total) — e.g. DE89370400440532013000")
        String creditorIban,

        @NotNull(message = "amount is required")
        @DecimalMin(value = "0.01", message = "amount must be greater than 0 — e.g. 100.00")
        BigDecimal amount,

        @NotNull(message = "currency is required")
        @Pattern(regexp = "^[A-Z]{3}$",
                message = "currency must be exactly 3 uppercase letters — e.g. EUR, USD, GBP")
        String currency
) {
}
