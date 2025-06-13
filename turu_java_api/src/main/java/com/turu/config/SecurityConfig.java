package com.turu.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(authorize -> authorize
                .requestMatchers("/register", "/login", "/css/**").permitAll()
                .requestMatchers("/api/login", "/api/register", "/api/ping").permitAll()
                
                // Perbaikan untuk fitur foto profil dan user details
                // Menggunakan {id} untuk path variable, yang lebih spesifik dan benar
                .requestMatchers(HttpMethod.POST, "/api/user/{id}/profile-picture").permitAll() 
                .requestMatchers(HttpMethod.GET, "/api/user/{id}").permitAll() 
                .requestMatchers("/uploads/**").permitAll() 
                
                // Endpoint PUT untuk update profil dan password
                .requestMatchers(HttpMethod.PUT, "/api/user/{id}").permitAll() 
                .requestMatchers(HttpMethod.PUT, "/api/user/{id}/password").permitAll() 
                
                // Semua request lainnya perlu autentikasi
                .anyRequest().authenticated())
            .formLogin(form -> form
                .loginPage("/login")
                .loginProcessingUrl("/perform_login")
                .defaultSuccessUrl("/beranda", true)
                .failureUrl("/login?error=true")
                .permitAll())
            .logout(logout -> logout
                .logoutUrl("/logout")
                .logoutSuccessUrl("/login?logout=true")
                .permitAll());

        return http.build();
    }
}