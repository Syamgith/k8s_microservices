package main

import (
	"context"
	"log"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
)

// CustomMetrics holds all custom metrics for the checkout service
type CustomMetrics struct {
	ordersTotal          metric.Int64Counter
	orderValue           metric.Float64Histogram
	paymentMethodCounter metric.Int64Counter
	processingDuration   metric.Float64Histogram
	cartItemCount        metric.Int64Histogram
	activeCheckouts      metric.Int64UpDownCounter
}

// NewCustomMetrics initializes all custom metrics
func NewCustomMetrics(ctx context.Context) (*CustomMetrics, error) {
	meter := otel.Meter("checkoutservice")

	ordersTotal, err := meter.Int64Counter(
		"checkout.orders.total",
		metric.WithDescription("Total number of orders processed"),
		metric.WithUnit("{orders}"),
	)
	if err != nil {
		return nil, err
	}

	orderValue, err := meter.Float64Histogram(
		"checkout.order.value",
		metric.WithDescription("Distribution of order values"),
		metric.WithUnit("USD"),
	)
	if err != nil {
		return nil, err
	}

	paymentMethodCounter, err := meter.Int64Counter(
		"checkout.payment_method.total",
		metric.WithDescription("Count of orders by payment method"),
		metric.WithUnit("{orders}"),
	)
	if err != nil {
		return nil, err
	}

	processingDuration, err := meter.Float64Histogram(
		"checkout.processing.duration",
		metric.WithDescription("Duration of order processing"),
		metric.WithUnit("ms"),
	)
	if err != nil {
		return nil, err
	}

	cartItemCount, err := meter.Int64Histogram(
		"checkout.cart.items",
		metric.WithDescription("Number of items in cart per order"),
		metric.WithUnit("{items}"),
	)
	if err != nil {
		return nil, err
	}

	activeCheckouts, err := meter.Int64UpDownCounter(
		"checkout.active",
		metric.WithDescription("Number of active checkout sessions"),
		metric.WithUnit("{sessions}"),
	)
	if err != nil {
		return nil, err
	}

	log.Println("Custom metrics initialized successfully")

	return &CustomMetrics{
		ordersTotal:          ordersTotal,
		orderValue:           orderValue,
		paymentMethodCounter: paymentMethodCounter,
		processingDuration:   processingDuration,
		cartItemCount:        cartItemCount,
		activeCheckouts:      activeCheckouts,
	}, nil
}

// RecordOrder records metrics for a completed order
func (m *CustomMetrics) RecordOrder(ctx context.Context, orderValue float64, paymentMethod string, itemCount int64, durationMs float64) {
	// Record total orders
	m.ordersTotal.Add(ctx, 1,
		metric.WithAttributes(
			attribute.String("status", "success"),
		),
	)

	// Record order value
	m.orderValue.Record(ctx, orderValue,
		metric.WithAttributes(
			attribute.String("currency", "USD"),
		),
	)

	// Record payment method
	m.paymentMethodCounter.Add(ctx, 1,
		metric.WithAttributes(
			attribute.String("method", paymentMethod),
		),
	)

	// Record processing duration
	m.processingDuration.Record(ctx, durationMs,
		metric.WithAttributes(
			attribute.String("status", "success"),
		),
	)

	// Record cart item count
	m.cartItemCount.Record(ctx, itemCount)

	log.Printf("Recorded order metrics: value=%.2f, method=%s, items=%d, duration=%.2fms",
		orderValue, paymentMethod, itemCount, durationMs)
}

// RecordOrderFailure records metrics for a failed order
func (m *CustomMetrics) RecordOrderFailure(ctx context.Context, reason string, durationMs float64) {
	m.ordersTotal.Add(ctx, 1,
		metric.WithAttributes(
			attribute.String("status", "failed"),
			attribute.String("reason", reason),
		),
	)

	m.processingDuration.Record(ctx, durationMs,
		metric.WithAttributes(
			attribute.String("status", "failed"),
		),
	)
}

// IncrementActiveCheckouts increments the active checkout counter
func (m *CustomMetrics) IncrementActiveCheckouts(ctx context.Context) {
	m.activeCheckouts.Add(ctx, 1)
}

// DecrementActiveCheckouts decrements the active checkout counter
func (m *CustomMetrics) DecrementActiveCheckouts(ctx context.Context) {
	m.activeCheckouts.Add(ctx, -1)
}
