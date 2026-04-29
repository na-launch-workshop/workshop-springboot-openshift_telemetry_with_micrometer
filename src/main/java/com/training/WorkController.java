package com.training;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import io.micrometer.core.annotation.Timed;
import io.micrometer.core.instrument.*;
import io.opentelemetry.instrumentation.annotations.WithSpan;
import java.util.concurrent.atomic.AtomicInteger;

@RestController
@RequestMapping("/work")
public class WorkController {

    private final MeterRegistry registry;
    private final DownstreamService downstream;
    private final AtomicInteger inFlight = new AtomicInteger(0);
    private final Counter retries;

    public WorkController(MeterRegistry registry, DownstreamService downstream) {
        this.registry = registry;
        this.downstream = downstream;
        this.retries = Counter.builder("app.work.retries").register(registry);
        registry.gauge("app.work.in_flight", inFlight);
    }

    @GetMapping(produces = MediaType.TEXT_PLAIN_VALUE)
    @Timed(value = "app.work.duration", histogram = true, percentiles = { 0.5, 0.95 })
    @WithSpan("work.doWork")
    public String doWork() {
        inFlight.incrementAndGet();
        try {
            if (!downstream.callWithRetry(retries)) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "downstream-failed");
            }
            return "ok";
        } catch (ResponseStatusException ex) {
            return "fail";
        } finally {
            inFlight.decrementAndGet();
        }
    }
}