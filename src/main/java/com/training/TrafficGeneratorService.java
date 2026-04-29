package com.training;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class TrafficGeneratorService {

    private static final Logger LOG = LoggerFactory.getLogger(TrafficGeneratorService.class);

    private final WorkController work;

    public TrafficGeneratorService(WorkController work) {
        this.work = work;
    }

    @Scheduled(fixedRate = 2000, initialDelay = 3000)
    void createTraffic() {
        LOG.info("work process");
        try {
            work.doWork();
        } catch (Exception e) {
            LOG.warn("createTraffic failed", e);
        }
    }
}