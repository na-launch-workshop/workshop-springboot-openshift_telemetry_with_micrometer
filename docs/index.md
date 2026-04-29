# 🚀 **Module: Using Red Hat build of OpenTelemetry with Micrometer**

**Technology Stack:**

- Springboot

This project uses Springboot.

---

## 🎯 **Scenario**

Welcome! In this hands-on you’ll use Red Hat build of OpenTelemetry together with Micrometer in a SpringBoot app deployed to OpenShift. You’ll start with a flaky service, instrument it, ship metrics & traces, and use OpenShift Observe → Metrics (Prometheus) and Jaeger/Tempo to diagnose and fix the issue.

---

## 🧩 **Challenge**

What you’ll do:

- [ ] Run a quick environment validator in DevSpaces.
- [ ] Deploy a SpringBoot app to OpenShift using S2I (no Dockerfile needed).
- [ ] Instrument the app with Micrometer (@Timed, Counter, Gauge) and OpenTelemetry (@WithSpan, span attributes, events).
- [ ] Use PromQL to spot the problem in OpenShift metrics.
- [ ] Confirm the root cause in Jaeger traces.
- [ ] Ship a fix, re-deploy, and verify the improvement.

---

### Story

You’ve been paged: the endpoint is sometimes ~200 ms slower and occasionally fails. Your first clue must come from Micrometer metrics; then you’ll drill down with OpenTelemetry traces to see exactly where the time goes.

---

### Layout

src/main/java/com/training
- WorkResource.java             # The main endpoint with instrumentation already
- DownstreamService.java        # Called by WorkResource to do processing
- TrafficGeneratorService.java  # Generates traffic so you don't have to

---

### MicroMeter promQL

p95 latency

```bash
histogram_quantile(0.95,
  sum by (le) (rate(app_work_duration_seconds_bucket[5m]))
)
```

Rate of the Counter

```bash
sum(rate(app_work_retries_total[5m]))
```

---

### Environment setup

There are a few scripts to minimize and validate the environment for the workshop.

First lets run setup-env.sh

```bash
chmod +x setup-env.sh
setup-env.sh
```

This script checks to see if you are logged in and various env variables and capabilies are present.

After running this you should see some success.

```bash
1. Checking Environment Variables...
[✓] Using OpenShift user: userid
[ℹ] User set to: userid
[ℹ] Sourcing validation script from .../resources/scripts/validate-workshop.sh
[ℹ] Making [validate-workshop.sh] executable...
[✓] Validation script [validate-workshop.sh] is now executable
[ℹ] Sourcing validation script from .../resources/scripts/deploy-dep.sh
[ℹ] Making [deploy-dep.sh] executable...
[✓] Validation script [deploy-dep.sh] is now executable
[ℹ] Sourcing validation script from .../resources/scripts/build-deploy.sh
[ℹ] Making [build-deploy.sh] executable...
[✓] Validation script [build-deploy.sh] is now executable
[ℹ] Sourcing validation script from .../workshop.sh
[ℹ] Making [workshop.sh] executable...
[✓] Validation script [workshop.sh] is now executable
[✓] Current project follows convention: userid-devspaces
```

---

### Workshop core script

There is workshop script that does some common tasks and has additional checks available.  the setup-env.sh sets this script up among others to be available.

```bash
workshop.sh
```

The result is

```bash
===========================================
  Workshop Script
===========================================

Usage: ./workshop.sh [command]

Available commands:
  check      - Validate workshop environment
  deploy     - Deploy the application
  components - Check/deploy required components

Examples:
  ./workshop.sh check
  ./workshop.sh deploy
  ./workshop.sh components
```

---

### Steps

In this workshop you'll be given a link to a document.  That document will give you a step by step guide to completing this module.

Some additional notes.  This module isn't intended to be much longer then 30 minutes.  Most tasks will either by reviewing the UI components related to MicroMeter and OTEL.  Other tasks will be uncommenting existing code.
