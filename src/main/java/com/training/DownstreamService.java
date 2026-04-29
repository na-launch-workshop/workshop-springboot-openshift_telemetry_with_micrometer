package com.training;

import org.springframework.stereotype.Service;

import io.micrometer.core.instrument.*;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.TracerBuilder;
import io.opentelemetry.instrumentation.annotations.SpanAttribute;

//TASK: Uncomment the imports below
//import io.opentelemetry.instrumentation.annotations.WithSpan;

import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.StatusCode;

//TASK: Uncomment the imports below
//import io.micrometer.core.annotation.Timed;

import static io.opentelemetry.api.common.AttributeKey.longKey;
import static io.opentelemetry.api.common.AttributeKey.stringKey;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import java.util.Random;

@Service
class DownstreamService {

	private static final Random RND = new Random();
	private static final int maxRetries = 3;
	private static final int backoffMs = 100;

	private final Tracer tracer;

	public DownstreamService(Tracer tracer) {
		this.tracer = tracer;
	}

	//TASK: Uncomment the imports below
	//@WithSpan("downstream.call")
	public boolean callWithRetry(Counter retryCounter) {
		
		Span span = Span.current();
		int attempt = 1;

		while (true) {
			boolean ok = process(attempt);

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

	//TASK: Uncomment the imports below
	//@Timed(value = "app.downstream.process", histogram = true, percentiles = { 0.5, 0.95 })
	//@WithSpan("downstream.process")
	boolean process(@SpanAttribute("attempt") int attempt) {
		boolean processResult = false;
		
		//TASK: Uncomment the lines below
		//Span span = Span.current();
		
		LogicResult logicResult = coreLogic(attempt);

		//TASK: Uncomment the lines below
		//span.setAttribute("result.code", logicResult.Code);
		//span.setAttribute("result.status", logicResult.Status);

		processResult = evaluateResult(logicResult);

		return processResult;
	}

	//TASK: Uncomment the imports below
	//@Timed(value = "app.downstream.logic", histogram = true, percentiles = { 0.5, 0.95 })
	//@WithSpan("downstream.logic")
	LogicResult coreLogic(@SpanAttribute("attempt") int attempt) {
		LogicResult result = new LogicResult();
		
		int rnd = RND.nextInt(3);
		boolean res = rnd == 0;

		result.Code = rnd;
		result.Status = res;

		sleep(10);

		return result;
	}

	//TASK: Uncomment the imports below
	//@Timed(value = "app.downstream.result", histogram = true, percentiles = { 0.5, 0.95 })
	//@WithSpan("downstream.result")
	boolean evaluateResult(LogicResult result) {
		Span span = Span.current();
		
		span.setAttribute("result.code", result.Code);
		span.setAttribute("result.status", result.Status);
		span.setAttribute("result.message", LogicResult.arrayOfResultMessages[result.Code]);

		sleep(10);

		return result.Status;
	}

	//TASK: This can be used ...
	//@Timed(value = "puzzle.base64.decode", histogram = true)
    //@WithSpan("puzzle.base64.decode")
    String decodeB64(String input) {
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