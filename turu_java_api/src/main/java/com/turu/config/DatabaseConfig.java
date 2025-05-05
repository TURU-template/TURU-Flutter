package com.turu.config;

import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import javax.sql.DataSource;

/**
 * Database configuration for Aiven MySQL
 * This class provides a way to override the default application.properties
 * configuration with environment variables at runtime
 */
@Configuration
public class DatabaseConfig {

    private final Environment env;

    public DatabaseConfig(Environment env) {
        this.env = env;
    }

    @Bean
    public DataSource dataSource() {
        String dbHost = getEnvOrDefault("DB_HOST", "turumysql-turuproject.e.aivencloud.com");
        String dbPort = getEnvOrDefault("DB_PORT", "23729");
        String dbName = getEnvOrDefault("DB_NAME", "dbturu");
        String dbUser = getEnvOrDefault("DB_USER", "avnadmin");
        String dbPass = getEnvOrDefault("DB_PASS", "AVNS_MJabb4P-Ri3h7UrS6nN");

        String jdbcUrl = String.format(
            "jdbc:mysql://%s:%s/%s?ssl-mode=REQUIRED",
            dbHost, dbPort, dbName
        );
        
        return DataSourceBuilder.create()
                .url(jdbcUrl)
                .username(dbUser)
                .password(dbPass)
                .driverClassName("com.mysql.cj.jdbc.Driver")
                .build();
    }
    
    private String getEnvOrDefault(String key, String defaultValue) {
        // Check system environment variables first
        String value = System.getenv(key);
        if (value != null && !value.isEmpty()) {
            return value;
        }
        
        // Then check Spring environment (application.properties)
        value = env.getProperty(key);
        if (value != null && !value.isEmpty()) {
            return value;
        }
        
        return defaultValue;
    }
} 