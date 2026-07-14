package fr.sgshowcase.paymentorders.dto;

import fr.sgshowcase.paymentorders.domain.OrderStatus;
import fr.sgshowcase.paymentorders.domain.PaymentOrder;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record OrderResponse(
        UUID id,
        String reference,
        String debtorIban,
        String creditorIban,
        BigDecimal amount,
        String currency,
        OrderStatus status,
        Instant createdAt,
        String createdBy
) {
    public static OrderResponse from(PaymentOrder order) {
        return new OrderResponse(
                order.getId(),
                order.getReference(),
                order.getDebtorIban(),
                order.getCreditorIban(),
                order.getAmount(),
                order.getCurrency(),
                order.getStatus(),
                order.getCreatedAt(),
                order.getCreatedBy()
        );
    }
}
