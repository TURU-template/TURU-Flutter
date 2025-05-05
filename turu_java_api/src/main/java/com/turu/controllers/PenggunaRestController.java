package com.turu.controllers;

import com.turu.model.Pengguna;
import com.turu.service.PenggunaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api")
public class PenggunaRestController {

    private final PenggunaService penggunaService;
    private final PasswordEncoder passwordEncoder;

    @Autowired
    public PenggunaRestController(PenggunaService penggunaService, PasswordEncoder passwordEncoder) {
        this.penggunaService = penggunaService;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String username = credentials.get("username");
        String password = credentials.get("password");

        // Debug
        System.out.println("[Login Debug] Raw request: " + credentials);
        System.out.println("[Login Debug] username: " + username + ", password: " + password);

        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Username and password are required"));
        }

        Optional<Pengguna> userOptional = penggunaService.findByUsername(username);
        
        if (userOptional.isEmpty()) {
            System.out.println("[Login Debug] Username '" + username + "' not found");
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Invalid username or password"));
        }

        Pengguna user = userOptional.get();
        if (!passwordEncoder.matches(password, user.getPassword())) {
            System.out.println("[Login Debug] Password incorrect for user '" + username + "'");
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Invalid username or password"));
        }

        // Format response sesuai dengan yang diharapkan oleh aplikasi Flutter
        Map<String, Object> response = new HashMap<>();
        Map<String, Object> userData = new HashMap<>();
        userData.put("id", user.getId());
        userData.put("username", user.getUsername());
        userData.put("jk", user.getJk());
        userData.put("tanggal_lahir", user.getTanggalLahir() != null ? user.getTanggalLahir().toString() : null);
        
        response.put("message", "Login successful");
        response.put("user", userData);
        
        System.out.println("[Login Debug] Login successful for user '" + username + "'");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, Object> registerData) {
        String username = (String) registerData.get("username");
        String password = (String) registerData.get("password");
        String jk = (String) registerData.get("jk");
        String tanggalLahirStr = (String) registerData.get("tanggal_lahir");

        // Debug
        System.out.println("[Register Debug] Raw request: " + registerData);
        
        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Username and password are required"));
        }

        // Check for username duplication
        Optional<Pengguna> existingUser = penggunaService.findByUsername(username);
        if (existingUser.isPresent()) {
            System.out.println("[Register Debug] Username '" + username + "' already exists");
            return ResponseEntity.status(409)
                    .body(Map.of("error", "Username already exists"));
        }

        try {
            Pengguna newUser = new Pengguna();
            newUser.setUsername(username);
            newUser.setPassword(password); // password encoder applied in service
            newUser.setJk(jk);
            newUser.setState(true);
            
            // Handle tanggal_lahir conversion if needed
            if (tanggalLahirStr != null && !tanggalLahirStr.isEmpty()) {
                try {
                    LocalDate tanggalLahir = LocalDate.parse(tanggalLahirStr);
                    newUser.setTanggalLahir(tanggalLahir);
                } catch (Exception e) {
                    System.out.println("[Register Debug] Error parsing date: " + e.getMessage());
                }
            }

            penggunaService.savePengguna(newUser);
            System.out.println("[Register Debug] Registration successful for user '" + username + "'");
            return ResponseEntity.ok(Map.of("message", "Register successful"));
        } catch (Exception e) {
            System.out.println("[Register Debug] Registration failed: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("error", "Registration failed due to an unexpected error"));
        }
    }

    @PutMapping("/user/{id}")
    public ResponseEntity<?> updateProfile(@PathVariable int id, @RequestBody Map<String, String> updateData) {
        String username = updateData.get("username");
        
        // Debug
        System.out.println("[UpdateProfile Debug] Request for user ID: " + id + ", data: " + updateData);
        
        if (username == null || username.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Username is required"));
        }
        
        // Check if user exists
        Optional<Pengguna> userOpt = penggunaService.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404)
                    .body(Map.of("error", "User not found"));
        }
        
        Pengguna user = userOpt.get();
        
        // Check if username is already taken by another user
        Optional<Pengguna> existingUser = penggunaService.findByUsername(username);
        if (existingUser.isPresent() && existingUser.get().getId() != id) {
            return ResponseEntity.status(409)
                    .body(Map.of("error", "Username already exists"));
        }
        
        try {
            user.setUsername(username);
            penggunaService.savePengguna(user);
            System.out.println("[UpdateProfile Debug] Profile updated for user ID: " + id);
            return ResponseEntity.ok(Map.of("message", "Profile updated successfully"));
        } catch (Exception e) {
            System.out.println("[UpdateProfile Debug] Profile update failed: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("error", "Error updating profile"));
        }
    }

    @PutMapping("/user/{id}/password")
    public ResponseEntity<?> updatePassword(@PathVariable int id, @RequestBody Map<String, String> passwordData) {
        String oldPassword = passwordData.get("oldPassword");
        String newPassword = passwordData.get("newPassword");
        
        // Debug
        System.out.println("[UpdatePassword Debug] Request for user ID: " + id);
        
        if (oldPassword == null || newPassword == null || oldPassword.isEmpty() || newPassword.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Old and new passwords are required"));
        }
        
        // Check if user exists
        Optional<Pengguna> userOpt = penggunaService.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404)
                    .body(Map.of("error", "User not found"));
        }
        
        Pengguna user = userOpt.get();
        
        // Verify old password
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Old password is incorrect"));
        }
        
        try {
            user.setPassword(newPassword); // Service will encode it
            penggunaService.savePengguna(user);
            System.out.println("[UpdatePassword Debug] Password updated for user ID: " + id);
            return ResponseEntity.ok(Map.of("message", "Password updated successfully"));
        } catch (Exception e) {
            System.out.println("[UpdatePassword Debug] Password update failed: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("error", "Error updating password"));
        }
    }
    
    // Test endpoint to verify API is working
    @GetMapping("/ping")
    public ResponseEntity<?> ping() {
        return ResponseEntity.ok(Map.of(
            "status", "success",
            "message", "TURU REST API is running!"
        ));
    }
} 