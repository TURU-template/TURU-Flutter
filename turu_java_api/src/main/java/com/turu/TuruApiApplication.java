package com.turu;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import java.io.IOException; // Tambahkan import ini
import java.nio.file.Files; // Tambahkan import ini
import java.nio.file.Paths; // Tambahkan import ini

@SpringBootApplication
public class TuruApiApplication implements WebMvcConfigurer { 
    
    public TuruApiApplication() {
        try {
            Files.createDirectories(Paths.get("./uploads/"));
        } catch (IOException e) {
            System.err.println("Failed to create upload directory: " + e.getMessage());
            // Kamu mungkin ingin menangani error ini lebih lanjut
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(TuruApiApplication.class, args);
    }
    
    
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:./uploads/");
    }
    
    
    @Bean
    public CommandLineRunner logDatabaseInfo(Environment env) {
        return args -> {
            System.out.println("=== Database Configuration ===");
            System.out.println("Database Host: " + getValueOrDefault(env, "DB_HOST", "localhost"));
            System.out.println("Database Port: " + getValueOrDefault(env, "DB_PORT", "3306"));
            System.out.println("Database Name: " + getValueOrDefault(env, "DB_NAME", "turu_db"));
            System.out.println("Database User: " + getValueOrDefault(env, "DB_USER", "root"));
            System.out.println("================================");
        };
    }
    
    private String getValueOrDefault(Environment env, String key, String defaultValue) {
        String value = System.getenv(key);
        if (value != null && !value.isEmpty()) {
            return value;
        }
        
        value = env.getProperty(key);
        if (value != null && !value.isEmpty()) {
            return value;
        }
        
        return defaultValue;
    }
}