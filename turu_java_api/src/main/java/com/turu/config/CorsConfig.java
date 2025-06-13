package com.turu.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // Mapping untuk semua endpoint API
        registry.addMapping("/**")
                // Daftar origin (URL lengkap dengan port) yang diizinkan untuk mengakses backend
                // Tambahkan semua port yang mungkin digunakan Flutter web kamu
                .allowedOrigins(
                    "http://localhost:51324",
                    "http://localhost:52692", 
                    "http://localhost:50477", // Port sebelumnya
                    "http://localhost:60101", // Port sebelumnya
                    "http://localhost:6080",  // Port sebelumnya
                    "http://127.0.0.1:51324", // Versi 127.0.0.1 juga
                    "http://127.0.0.1:50477",
                    "http://127.0.0.1:60101",
                    "http://127.0.0.1:6080"
                    // Jika ada port lain yang muncul di Flutter, tambahkan di sini
                )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS") // Metode HTTP yang diizinkan
                .allowedHeaders("*") // Mengizinkan semua header
                .allowCredentials(true); // Sangat penting: mengizinkan kredensial (misal cookie, header otorisasi)
    }
}