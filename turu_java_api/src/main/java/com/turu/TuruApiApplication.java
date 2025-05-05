package com.turu;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;

@SpringBootApplication
public class TuruApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(TuruApiApplication.class, args);
    }
    
    @Bean
    public CommandLineRunner logDatabaseInfo(Environment env) {
        return args -> {
            System.out.println("=== Database Configuration ===");
            System.out.println("Database Host: " + getValueOrDefault(env, "DB_HOST", "localhost"));
            System.out.println("Database Port: " + getValueOrDefault(env, "DB_PORT", "3306"));
            System.out.println("Database Name: " + getValueOrDefault(env, "DB_NAME", "turu_db"));
            System.out.println("Database User: " + getValueOrDefault(env, "DB_USER", "root"));
            // Don't log the password
            System.out.println("================================");
        };
    }
    
    private String getValueOrDefault(Environment env, String key, String defaultValue) {
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