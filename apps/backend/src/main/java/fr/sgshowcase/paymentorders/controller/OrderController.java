package fr.sgshowcase.paymentorders.controller;

import fr.sgshowcase.paymentorders.domain.OrderStatus;
import fr.sgshowcase.paymentorders.dto.CreateOrderRequest;
import fr.sgshowcase.paymentorders.dto.OrderResponse;
import fr.sgshowcase.paymentorders.service.PaymentOrderService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Ownership is enforced via the X-Username header (demo-grade "auth": no
 * password check, just scopes every read/write to the caller's own orders).
 */
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private static final String USERNAME_HEADER = "X-Username";

    private final PaymentOrderService service;

    public OrderController(PaymentOrderService service) {
        this.service = service;
    }

    @GetMapping
    public List<OrderResponse> findAll(@RequestParam(required = false) OrderStatus status,
                                        @RequestParam(required = false) String currency,
                                        @RequestHeader(value = USERNAME_HEADER, required = false) String username) {
        return service.findAll(status, currency, username).stream().map(OrderResponse::from).toList();
    }

    @GetMapping("/{id}")
    public OrderResponse findById(@PathVariable UUID id,
                                   @RequestHeader(value = USERNAME_HEADER, required = false) String username) {
        return OrderResponse.from(service.findById(id, username));
    }

    @PostMapping
    public ResponseEntity<OrderResponse> create(@Valid @RequestBody CreateOrderRequest request,
                                                 @RequestHeader(value = USERNAME_HEADER, required = false) String username) {
        OrderResponse response = OrderResponse.from(service.create(request, username));
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
