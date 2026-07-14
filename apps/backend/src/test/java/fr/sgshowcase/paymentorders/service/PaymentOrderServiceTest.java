package fr.sgshowcase.paymentorders.service;

import fr.sgshowcase.paymentorders.domain.OrderStatus;
import fr.sgshowcase.paymentorders.domain.PaymentOrder;
import fr.sgshowcase.paymentorders.dto.CreateOrderRequest;
import fr.sgshowcase.paymentorders.exception.InvalidCurrencyException;
import fr.sgshowcase.paymentorders.exception.OrderNotFoundException;
import fr.sgshowcase.paymentorders.exception.UnauthenticatedException;
import fr.sgshowcase.paymentorders.repository.PaymentOrderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PaymentOrderServiceTest {

    private static final String USERNAME = "alice";

    @Mock
    private PaymentOrderRepository repository;

    private PaymentOrderService service;

    @BeforeEach
    void setUp() {
        service = new PaymentOrderService(repository);
    }

    @Test
    void createSavesOrderAsPendingWithGeneratedReferenceOwnedByCaller() {
        CreateOrderRequest request = new CreateOrderRequest(
                "FR7630006000011234567890189", "DE89370400440532013000",
                new BigDecimal("250.00"), "EUR");
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        PaymentOrder created = service.create(request, USERNAME);

        assertThat(created.getStatus()).isEqualTo(OrderStatus.PENDING);
        assertThat(created.getReference()).startsWith("PO-");
        assertThat(created.getAmount()).isEqualByComparingTo("250.00");
        assertThat(created.getCreatedBy()).isEqualTo(USERNAME);

        ArgumentCaptor<PaymentOrder> captor = ArgumentCaptor.forClass(PaymentOrder.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getCurrency()).isEqualTo("EUR");
    }

    @Test
    void createRejectsInvalidCurrency() {
        CreateOrderRequest request = new CreateOrderRequest(
                "FR7630006000011234567890189", "DE89370400440532013000",
                new BigDecimal("250.00"), "ZZZ");

        assertThatThrownBy(() -> service.create(request, USERNAME))
                .isInstanceOf(InvalidCurrencyException.class);
    }

    @Test
    void createRejectsMissingUsername() {
        CreateOrderRequest request = new CreateOrderRequest(
                "FR7630006000011234567890189", "DE89370400440532013000",
                new BigDecimal("250.00"), "EUR");

        assertThatThrownBy(() -> service.create(request, " "))
                .isInstanceOf(UnauthenticatedException.class);
    }

    @Test
    void findByIdThrowsWhenMissing() {
        UUID id = UUID.randomUUID();
        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id, USERNAME))
                .isInstanceOf(OrderNotFoundException.class);
    }

    @Test
    void findByIdThrowsWhenOwnedBySomeoneElse() {
        UUID id = UUID.randomUUID();
        PaymentOrder othersOrder = new PaymentOrder(id, "PO-AAAAAAAA",
                "FR7630006000011234567890189", "DE89370400440532013000",
                new BigDecimal("10.00"), "EUR", OrderStatus.PENDING, Instant.now(), "bob");
        when(repository.findById(id)).thenReturn(Optional.of(othersOrder));

        assertThatThrownBy(() -> service.findById(id, USERNAME))
                .isInstanceOf(OrderNotFoundException.class);
    }
}
