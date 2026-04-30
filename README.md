# 🚀 **Module: Using Red Hat build of OpenTelemetry with Micrometer**

**Technology Stack:**

- SpringBoot

This project uses SpringBoot.

If you want to learn more about SpringBoot, please visit its website: <https://SpringBoot.io/>.

---

## 🎯 **Scenario**

Welcome! In this hands-on you’ll use Red Hat build of OpenTelemetry together with Micrometer in a SpringBoot app deployed to OpenShift. You’ll start with a flaky service, instrument it, ship metrics & traces, and use OpenShift Observe -> Metrics (Prometheus) and Jaeger/Tempo to diagnose and fix the issue.

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

Before we go over the application running and what to fully do lets deploy it in a `partial` working state.

## Step 1.

Look at `src/resources/application.properties`

We need to change these to valid names.  This will ensure your traces in otel are accurately reflected in Jaeger.

```bash
otel.service.name=<<oc whoami>>-micrometer-module
spring.application.name=<<oc whoami>>-micrometer-module
```

```bash
() workshop-springboot-openshift-telemetry-with-micrometer (main) $ oc whoami

miketest
```

Your name here will be different but use whatever value to replace the `application.properties` values here are my new properties

```bash
otel.service.name=miketest-micrometer-module
spring.application.name=miketest-micrometer-module
```

## Step 2.

Deploy the application

You can do this two ways...

Option 1

```bash
mvn clean package oc:build oc:resource oc:apply -DskipTests
```

Option 2

```bash
workshop.sh deploy
```

Either way works and for deploying the application and your any future changes either of these options are what you will use.


## Step 3.

So how does the app work at a high level...

The application simulates a backend service under load. A scheduler fires every 2 seconds and calls the REST endpoint, which hands off to a downstream service that attempts to process a request with up to 3 retries. The logic randomly succeeds or fails to simulate real-world transient errors. Throughout all of this, Micrometer instruments the timing and retry counts while OpenTelemetry traces each step of the call chain.

All telemetry flows through an OTel collector sidecar into Tempo for traces and Prometheus for metrics

Call flow

```bash
TrafficGeneratorService (every 2s)
    -> WorkController.doWork()
        -> DownstreamService.callWithRetry()
            -> DownstreamProcessor.process()
                -> DownstreamLogic.coreLogic()       [random success/fail]
                -> DownstreamLogic.evaluateResult()  [sets span attributes + result.message]
            ↩ retry loop if fail (max 3)
        ↩ 502 if all retries exhausted
    ↩ "ok" or "fail"
```

## Step 4.

Now that the app should be deployed The question is should we see our traces or metrics in openshift.

Lets look at `Jaeger` first

Naigate to `DeveloperHub`

Then `Home` and in Quick Access you should see a Jaeger url click it

Notice no traces are available.


## Step 5.

OTel gives us a sidecar that we can use to collect telemetry and metrics being exposed by an application

```bash
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: sidecar
spec:
  mode: sidecar
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http: {}
    processors:
      batch: {}
    exporters:
      otlp:
        # aws
        endpoint: tempo-tempo-stack-distributor.opentelemetry.svc.cluster.local:4317
        # local
        #endpoint: tempo-sample-distributor.observability.svc.cluster.local:4317
        # lab
        #endpoint: tempo-tempo-sample-distributor.observability.svc.cluster.local:4317
        tls:
          insecure: true
      prometheus:
        endpoint: 0.0.0.0:9091
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [otlp]
        metrics:
          receivers: [otlp]
          processors: [batch]
          exporters: [prometheus]
```

How does it map to our `application.properties`

```bash
otel.exporter.otlp.endpoint=http://localhost:4318
otel.exporter.otlp.protocol=http/protobuf

management.otlp.metrics.export.url=http://localhost:4318/v1/metrics
management.otlp.metrics.export.step=10s

management.otlp.tracing.endpoint=http://localhost:4318/v1/traces
management.tracing.enabled=true
```

Notice our servicemonitor scraping a new 9091 endpoint

```bash
apiVersion: v1
kind: Service
metadata:
  name: greeting-otel-metrics
  labels:
    app: micrometer-module
spec:
  selector:
    app.kubernetes.io/name: micrometer-module
  ports:
    - name: otel-metrics
      port: 9091
      targetPort: 9091
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: greeting-otel
  labels:
    app: micrometer-module
spec:
  selector:
    matchLabels:
      app: micrometer-module
  endpoints:
    - port: otel-metrics
      path: /metrics
      interval: 30s
```

## Step 6.

Lets deploy these resources to see if we will now get traces and metrics

You can either deploy the resources in src/resources/otel .
Or you can use the workshop.sh script

Option 1

```bash
oc apply -f src/resources/otel/.
```

--or--

```bash
workshop.sh components
```

Now go back to Jaeger to see your traces hopefully coming into the system.

## Step 7.

Mission Statement

Now that your application is running you should be seeing a stream of errors appearing in your traces. Your mission from here is to use the observability tools at your disposal, traces in Jaeger and metrics in Grafana, to diagnose what is actually going wrong inside the application. Start by uncommenting the instrumentation in the codebase and redeploying to get more visibility into the call chain. There is no prescribed path so feel free to treat this like a real production investigation. Use the spans, attributes, and metrics to narrow down which part of the code is responsible and why.


## Hint 1.

The span attributes on evaluateResult are telling you something try looking closely at result.code and result.message across successful and failed traces. Do you see a pattern?

## Hint 2.

The retry counter metric is your friend so how many retries are happening per request on average? What does that tell you about how often the underlying logic is actually succeeding?

## Hint 3.

coreLogic is where the fate of each attempt is decided. Look at what it does with a random number and think about the probability of success on any given attempt.

## Fix... sorta

In `DownstreamLogic.coreLogic()`, change one line:

```bash
boolean res = true
```

But... did you find the Easter Egg?


### Notes

Some additional notes.  This module isn't intended to be much longer then 30 minutes.  Most tasks will either by reviewing the UI components related to MicroMeter and OTEL.  Other tasks will be uncommenting existing code.
