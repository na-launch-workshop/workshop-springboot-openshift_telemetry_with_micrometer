package com.training;

import org.springframework.stereotype.Service;

import io.micrometer.core.instrument.*;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.StatusCode;

//TASK: Uncomment the import below
//import io.opentelemetry.instrumentation.annotations.WithSpan;

import static io.opentelemetry.api.common.AttributeKey.longKey;
import static io.opentelemetry.api.common.AttributeKey.stringKey;

@Service
public class DownstreamService {

    private static final int maxRetries = 3;
    private static final int backoffMs = 100;

    private final DownstreamProcessor processor;

    public DownstreamService(DownstreamProcessor processor) {
        this.processor = processor;
    }

    //TASK: Uncomment the annotation below
    //@WithSpan("downstream.call")
    public boolean callWithRetry(Counter retryCounter) {

        Span span = Span.current();
        int attempt = 1;

        while (true) {
            boolean ok = processor.process(attempt);

            span.addEvent("attempt", Attributes.of(
                    longKey("attempt"), (long) attempt,
                    stringKey("outcome"), ok ? "ok" : "fail"));

            if (ok) {
                span.setAttribute("attempts_total", attempt);
                return true;
            }

            if (attempt >= maxRetries + 1) {
                span.setAttribute("attempts_total", attempt);
                span.setStatus(StatusCode.ERROR, "retry-exhausted");
                return false;
            }

            retryCounter.increment();
            span.addEvent("retry", Attributes.of(
                    AttributeKey.longKey("next_attempt"), (long) (attempt + 1),
                    AttributeKey.longKey("backoff_ms"), (long) backoffMs,
                    AttributeKey.stringKey("reason"), "transient"));

            sleep(backoffMs);
            attempt++;
        }
    }

    private void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ignored) {
        }
    }
}