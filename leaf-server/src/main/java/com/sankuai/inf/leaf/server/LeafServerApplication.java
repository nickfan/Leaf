package com.sankuai.inf.leaf.server;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import javax.annotation.PostConstruct;

@SpringBootApplication
public class LeafServerApplication {
	private static final Logger log = LoggerFactory.getLogger(LeafServerApplication.class);

    @Value("${leaf.name:}")
    private String leafName;

    @Value("${leaf.segment.enable:false}")
    private boolean segmentEnable;

    @Value("${leaf.snowflake.enable:false}")
    private boolean snowflakeEnable;

    @Value("${leaf.jdbc.url:}")
    private String jdbcUrl;

    @Value("${leaf.snowflake.zk.address:}")
    private String zkAddress;

    @PostConstruct
    public void printConfig() {
        if (Boolean.getBoolean("leaf.print.config")) {
            log.info("Leaf configuration:");
            log.info("leaf.name = {}", leafName);
            log.info("leaf.segment.enable = {}", segmentEnable);
            log.info("leaf.snowflake.enable = {}", snowflakeEnable);
            log.info("leaf.jdbc.url = {}", jdbcUrl);
            log.info("leaf.snowflake.zk.address = {}", zkAddress);
        }
    }

	public static void main(String[] args) {
		SpringApplication.run(LeafServerApplication.class, args);
	}
}
