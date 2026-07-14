package fr.sgshowcase.paymentorders.service;

import fr.sgshowcase.paymentorders.domain.OrderStatus;
import fr.sgshowcase.paymentorders.domain.PaymentOrder;
import fr.sgshowcase.paymentorders.dto.CreateOrderRequest;
import fr.sgshowcase.paymentorders.exception.InvalidCurrencyException;
import fr.sgshowcase.paymentorders.exception.OrderNotFoundException;
import fr.sgshowcase.paymentorders.exception.UnauthenticatedException;
import fr.sgshowcase.paymentorders.repository.PaymentOrderRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Currency;
import java.util.List;
import java.util.UUID;

@Service
public class PaymentOrderService {

    private final PaymentOrderRepository repository;

    public PaymentOrderService(PaymentOrderRepository repository) {
        this.repository = repository;
    }

    public List<PaymentOrder> findAll(OrderStatus status, String currency, String username) {
        return repository.search(requireUsername(username), status, currency);
    }

    public PaymentOrder findById(UUID id, String username) {
        String owner = requireUsername(username);
        PaymentOrder order = repository.findById(id).orElseThrow(() -> new OrderNotFoundException(id));
        if (!order.getCreatedBy().equals(owner)) {
            // Don't reveal that an order with this id exists for someone else.
            throw new OrderNotFoundException(id);
        }
        return order;
    }

    public PaymentOrder create(CreateOrderRequest request, String username) {
        String owner = requireUsername(username);
        validateCurrency(request.currency());

        PaymentOrder order = new PaymentOrder(
                UUID.randomUUID(),
                generateReference(),
                request.debtorIban(),
                request.creditorIban(),
                request.amount(),
                request.currency(),
                OrderStatus.PENDING,
                Instant.now(),
                owner
        );
        return repository.save(order);
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new UnauthenticatedException();
        }
        return username;
    }

    private void validateCurrency(String currency) {
        try {
            Currency.getInstance(currency);
        } catch (IllegalArgumentException ex) {
            throw new InvalidCurrencyException(currency);
        }
    }

    private String generateReference() {
        return "PO-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
}
