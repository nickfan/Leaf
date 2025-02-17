package com.sankuai.inf.leaf.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;

import java.io.IOException;
import java.util.Properties;

public class PropertyFactory {
    private static final Logger logger = LoggerFactory.getLogger(PropertyFactory.class);
    private static Properties prop = new Properties();

    static {
        reloadProperties();
    }

    public static void reloadProperties() {
        Properties newProp = new Properties();
        
        try {
            ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
            
            // 1. 首先加载 classpath 中的默认配置
            Resource[] resources = resolver.getResources("classpath*:leaf.properties");
            if (resources.length > 0) {
                newProp.load(resources[0].getInputStream());
                logger.info("Loaded configuration from classpath:leaf.properties");
            }

            // 2. 尝试加载外部配置文件
            try {
                Resource externalResource = resolver.getResource("file:conf/leaf.properties");
                if (externalResource.exists()) {
                    Properties externalProp = new Properties();
                    externalProp.load(externalResource.getInputStream());
                    newProp.putAll(externalProp); // 外部配置覆盖默认配置
                    logger.info("Loaded configuration from external file:conf/leaf.properties");
                }
            } catch (IOException e) {
                logger.warn("Failed to load external configuration file", e);
            }

            // 3. 从系统属性和环境变量中加载配置
            String[] propertyNames = {
                "leaf.name", "leaf.segment.enable", "leaf.snowflake.enable",
                "leaf.jdbc.url", "leaf.jdbc.username", "leaf.jdbc.password",
                "leaf.snowflake.zk.address", "leaf.snowflake.port"
            };
            
            for (String name : propertyNames) {
                // 首先尝试从系统属性获取
                String value = System.getProperty(name);
                
                // 如果系统属性中没有，尝试从环境变量获取
                if (value == null) {
                    // 将属性名转换为环境变量格式 (例如: leaf.jdbc.url -> LEAF_JDBC_URL)
                    String envName = name.toUpperCase().replace('.', '_');
                    value = System.getenv(envName);
                    if (value != null) {
                        logger.info("Loaded property from environment variable: {}={}", envName, 
                                  name.contains("password") ? "******" : value);
                    }
                } else {
                    logger.info("Loaded property from system property: {}={}", name, 
                              name.contains("password") ? "******" : value);
                }
                
                if (value != null) {
                    newProp.setProperty(name, value);
                }
            }

            // 更新配置
            prop = newProp;
            
            // 打印最终的配置（如果开启了配置打印）
            if ("true".equalsIgnoreCase(System.getProperty("leaf.print.config"))) {
                logger.info("Final Leaf configuration:");
                for (String name : prop.stringPropertyNames()) {
                    String value = name.contains("password") ? "******" : prop.getProperty(name);
                    logger.info("{}={}", name, value);
                }
            }
            
        } catch (IOException e) {
            logger.error("Failed to load properties", e);
        }
    }

    public static Properties getProperties() {
        return prop;
    }
}
