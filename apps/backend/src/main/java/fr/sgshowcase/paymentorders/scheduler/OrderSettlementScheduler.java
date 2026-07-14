package fr.sgshowcase.paymentorders.scheduler;

import fr.sgshowcase.paymentorders.domain.OrderStatus;
import fr.sgshowcase.paymentorders.domain.PaymentOrder;
import fr.sgshowcase.paymentorders.repository.PaymentOrderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Moves PENDING orders to SETTLED after a short delay so the demo/dashboard
 * shows live state changes instead of a static list.
 */
@Component
public class OrderSettlementScheduler {

    private static final Logger log = LoggerFactory.getLogger(OrderSettlementScheduler.class);
    private static final Duration SETTLEMENT_DELAY = Duration.ofSeconds(10);

    private final PaymentOrderRepository repository;

    public OrderSettlementScheduler(PaymentOrderRepository repository) {
        this.repository = repository;
    }

    @Scheduled(fixedDelay = 5000)
    public void settlePendingOrders() {
        Instant threshold = Instant.now().minus(SETTLEMENT_DELAY);
        List<PaymentOrder> toSettle = repository.findByStatusAndCreatedAtBefore(OrderStatus.PENDING, threshold);
        for (PaymentOrder order : toSettle) {
            order.setStatus(OrderStatus.SETTLED);
        }
        if (!toSettle.isEmpty()) {
            repository.saveAll(toSettle);
            log.info("Settled {} payment order(s)", toSettle.size());
        }
    }
}
