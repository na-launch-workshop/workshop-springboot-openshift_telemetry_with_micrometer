package com.training;

import org.springframework.stereotype.Service;

import io.opentelemetry.api.trace.Tracer;


import io.opentelemetry.api.trace.Span;
import io.opentelemetry.instrumentation.annotations.SpanAttribute;

//TASK: Uncomment the import below
//import io.opentelemetry.instrumentation.annotations.WithSpan;
//import io.micrometer.core.annotation.Timed;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Random;

@Service
public class DownstreamLogic {

    private static final Random RND = new Random();

    private final Tracer tracer;

    public DownstreamLogic(Tracer tracer) {
        this.tracer = tracer;
    }

    //TASK: Uncomment the annotations below
    //@Timed(value = "app.downstream.logic", histogram = true, percentiles = { 0.5, 0.95 })
    public LogicResult coreLogic(@SpanAttribute("attempt") int attempt) {
        //TASK: Uncomment the annotations below
        //Span span = tracer.spanBuilder("downstream.logic").startSpan();
        //try (var scope = span.makeCurrent()) {
        
            LogicResult result = new LogicResult();

            int rnd = RND.nextInt(3);
            boolean res = rnd == 0;

            result.Code = rnd;
            result.Status = res;

            sleep(10);

            return result;
        
        //} finally {
        //    span.end();
        //}
    }

    //TASK: Uncomment the annotations below
    //@Timed(value = "app.downstream.result", histogram = true, percentiles = { 0.5, 0.95 })
    public boolean evaluateResult(LogicResult result) {
        //TASK: Uncomment the annotations below
        //Span span = tracer.spanBuilder("downstream.logic").startSpan();
        //try (var scope = span.makeCurrent()) {


            //TASK: Uncomment the annotations below
            Span span = Span.current();

            span.setAttribute("result.code", result.Code);
            span.setAttribute("result.status", result.Status);
            //span.setAttribute("result.message", LogicResult.arrayOfResultMessages[result.Code]);

            sleep(10);

            return result.Status;

        //} finally {
        //    span.end();
        //}
    }

    //TASK: This can be used ...
    public String decodeB64(String input) {
        if (input == null) throw new IllegalArgumentException("input is null");

        String s = input.trim().replaceAll("\\s+", "");

        int rem = s.length() % 4;

        if (rem == 2) s += "==";
        else if (rem == 3) s += "=";
        else if (rem == 1) throw new IllegalArgumentException("invalid Base64 length");

        try {
            byte[] bytes = Base64.getDecoder().decode(s);
            return new String(bytes, StandardCharsets.UTF_8);
        } catch (IllegalArgumentException e) {
            byte[] bytes = Base64.getUrlDecoder().decode(s);
            return new String(bytes, StandardCharsets.UTF_8);
        }
    }

    private void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ignored) {
        }
    }
}