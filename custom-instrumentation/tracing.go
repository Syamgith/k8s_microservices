package main

import (
	"context"
	"fmt"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

var tracer = otel.Tracer("checkoutservice")

// TraceOrderValidation creates a span for order validation
func TraceOrderValidation(ctx context.Context, userID string, itemCount int) (context.Context, trace.Span) {
	ctx, span := tracer.Start(ctx, "ValidateOrder",
		trace.WithSpanKind(trace.SpanKindInternal),
		trace.WithAttributes(
			attribute.String("user.id", userID),
			attribute.Int("cart.items", itemCount),
		),
	)

	span.AddEvent("Order validation started")
	return ctx, span
}

// TracePaymentProcessing creates a span for payment processing
func TracePaymentProcessing(ctx context.Context, amount float64, method string) (context.Context, trace.Span) {
	ctx, span := tracer.Start(ctx, "ProcessPayment",
		trace.WithSpanKind(trace.SpanKindInternal),
		trace.WithAttributes(
			attribute.Float64("order.value", amount),
			attribute.String("payment.method", method),
			attribute.String("currency", "USD"),
		),
	)

	span.AddEvent("Payment processing initiated",
		trace.WithAttributes(
			attribute.Float64("amount", amount),
		),
	)
	return ctx, span
}

// TraceChargeOperation creates a span for the actual charge operation
func TraceChargeOperation(ctx context.Context, amount float64, cardInfo string) (context.Context, trace.Span) {
	ctx, span := tracer.Start(ctx, "ChargeCard",
		trace.WithSpanKind(trace.SpanKindClient),
		trace.WithAttributes(
			attribute.Float64("charge.amount", amount),
			attribute.String("card.last4", cardInfo[len(cardInfo)-4:]),
		),
	)

	return ctx, span
}

// TraceEmailNotification creates a span for sending email confirmation
func TraceEmailNotification(ctx context.Context, userEmail string, orderID string) (context.Context, trace.Span) {
	ctx, span := tracer.Start(ctx, "SendConfirmationEmail",
		trace.WithSpanKind(trace.SpanKindInternal),
		trace.WithAttributes(
			attribute.String("order.id", orderID),
			attribute.String("notification.type", "email"),
		),
	)

	// Don't log full email for privacy, just domain
	span.AddEvent("Email notification queued")
	return ctx, span
}

// TraceInventoryCheck creates a span for checking inventory
func TraceInventoryCheck(ctx context.Context, productID string, quantity int32) (context.Context, trace.Span) {
	ctx, span := tracer.Start(ctx, "CheckInventory",
		trace.WithSpanKind(trace.SpanKindClient),
		trace.WithAttributes(
			attribute.String("product.id", productID),
			attribute.Int("requested.quantity", int(quantity)),
		),
	)

	return ctx, span
}

// RecordSpanError records an error in the span
func RecordSpanError(span trace.Span, err error, message string) {
	span.RecordError(err)
	span.SetStatus(codes.Error, message)
	span.AddEvent("Error occurred",
		trace.WithAttributes(
			attribute.String("error.message", err.Error()),
		),
	)
}

// RecordSpanSuccess records successful completion
func RecordSpanSuccess(span trace.Span, message string) {
	span.SetStatus(codes.Ok, message)
	span.AddEvent("Operation completed successfully")
}

// Example usage in PlaceOrder function:
/*
func (cs *checkoutService) PlaceOrder(ctx context.Context, req *pb.PlaceOrderRequest) (*pb.PlaceOrderResponse, error) {
	// Start order placement span (auto-created by gRPC interceptor)
	// But we add custom attributes
	span := trace.SpanFromContext(ctx)
	span.SetAttributes(
		attribute.String("user.id", req.UserId),
		attribute.String("user.currency", req.UserCurrency),
	)

	// Track active checkouts
	customMetrics.IncrementActiveCheckouts(ctx)
	defer customMetrics.DecrementActiveCheckouts(ctx)

	startTime := time.Now()

	// Validate order with custom span
	ctx, validateSpan := TraceOrderValidation(ctx, req.UserId, len(req.Address.StreetAddress))
	// ... validation logic ...
	RecordSpanSuccess(validateSpan, "Order validated successfully")
	validateSpan.End()

	// Calculate order value
	orderValue := calculateOrderValue(req.Items)

	// Process payment with custom span
	ctx, paymentSpan := TracePaymentProcessing(ctx, orderValue, req.CreditCard.CreditCardNumber)
	// ... payment logic ...
	if paymentErr != nil {
		RecordSpanError(paymentSpan, paymentErr, "Payment processing failed")
		paymentSpan.End()

		duration := float64(time.Since(startTime).Milliseconds())
		customMetrics.RecordOrderFailure(ctx, "payment_failed", duration)
		return nil, paymentErr
	}
	RecordSpanSuccess(paymentSpan, "Payment processed successfully")
	paymentSpan.End()

	// Send confirmation email
	ctx, emailSpan := TraceEmailNotification(ctx, req.Email, orderID)
	// ... email logic ...
	emailSpan.End()

	// Record successful order metrics
	duration := float64(time.Since(startTime).Milliseconds())
	customMetrics.RecordOrder(ctx, orderValue, "credit_card", int64(len(req.Items)), duration)

	return &pb.PlaceOrderResponse{
		Order: order,
	}, nil
}
*/
