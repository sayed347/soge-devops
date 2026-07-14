package fr.sgshowcase.paymentorders.repository;

import fr.sgshowcase.paymentorders.domain.OrderStatus;
import fr.sgshowcase.paymentorders.domain.PaymentOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface PaymentOrderRepository extends JpaRepository<PaymentOrder, UUID> {

    @Query("""
            SELECT o FROM PaymentOrder o
            WHERE o.createdBy = :createdBy
            AND (:status IS NULL OR o.status = :status)
            AND (:currency IS NULL OR o.currency = :currency)
            ORDER BY o.createdAt DESC
            """)
    List<PaymentOrder> search(@Param("createdBy") String createdBy,
                              @Param("status") OrderStatus status,
                              @Param("currency") String currency);

    List<PaymentOrder> findByStatusAndCreatedAtBefore(OrderStatus status, Instant threshold);
}
