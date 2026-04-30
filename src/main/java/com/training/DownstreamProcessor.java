package com.training;

import io.opentelemetry.api.trace.Tracer;

import org.springframework.stereotype.Service;

import io.micrometer.core.annotation.Timed;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.instrumentation.annotations.SpanAttribute;

//TASK: Uncomment the import below
import io.opentelemetry.instrumentation.annotations.WithSpan;

@Service
public class DownstreamProcessor {

    private final DownstreamLogic logic;
    private final Tracer tracer;

    public DownstreamProcessor(DownstreamLogic logic, Tracer tracer) {
        this.logic = logic;
        this.tracer = tracer;
    }

    //TASK: Uncomment the annotations below
    @Timed(value = "app.downstream.process", histogram = true, percentiles = { 0.5, 0.95 })
    @WithSpan("downstream.process")
    public boolean process(@SpanAttribute("attempt") int attempt) {
        Span span = tracer.spanBuilder("downstream.process")
            .startSpan();
        try (var scope = span.makeCurrent()) {
            LogicResult logicResult = logic.coreLogic(attempt);
            span.setAttribute("result.code", logicResult.Code);
            span.setAttribute("result.status", logicResult.Status);
            return logic.evaluateResult(logicResult);
        } finally {
            span.end();
        }
    }
}