Implementation Plan: Microservices Observability with Signoz

     Phase 1: Environment Setup

     1. Create project structure with kubernetes manifests directory
     2. Document prerequisites (kubectl, Minikube/Kind, Helm)
     3. Create setup scripts for local Kubernetes cluster

     Phase 2: Signoz Deployment

     4. Create Helm values file for Signoz configuration
     5. Deploy Signoz to Kubernetes cluster using Helm
     6. Verify Signoz components (query-service, collector, frontend) are
     running
     7. Configure port-forwarding for Signoz UI access

     Phase 3: Microservices Demo Deployment

     8. Clone/reference Google's microservices-demo repository
     9. Modify deployment manifests to add OpenTelemetry sidecar/collector
     10. Configure services to export metrics, logs, and traces to Signoz
     11. Deploy all microservices (frontend, cart, checkout, payment, etc.)
     12. Verify all pods are running and healthy

     Phase 4: Custom Instrumentation (Checkout Service)

     13. Add custom OpenTelemetry metrics to Checkout Service (e.g., order
     value, payment method distribution)
     14. Add custom trace spans for key operations (order placement,
     inventory check)
     15. Rebuild and redeploy Checkout Service with instrumentation
     16. Verify custom metrics appear in Signoz

     Phase 5: Traffic Generation

     17. Create Locust test scenarios (browse products, add to cart,
     checkout)
     18. Deploy Locust in Kubernetes
     19. Configure Locust to generate realistic traffic patterns
     20. Verify traffic is generating telemetry data

     Phase 6: Dashboards & Verification

     21. Create Signoz dashboard showing application metrics (request rate,
     latency, errors)
     22. Configure log queries to show application logs
     23. Verify distributed traces are visible across services
     24. Document custom instrumentation in dashboard

     Phase 7: Documentation

     25. Create comprehensive README.md with setup instructions
     26. Add screenshots/links to Signoz dashboard
     27. Document the custom instrumentation added
     28. Update ai_changes_log.md with all changes

     Deliverables: Fully instrumented microservices demo running locally
     with Signoz dashboards showing metrics, logs, traces, and custom
     instrumentation.
