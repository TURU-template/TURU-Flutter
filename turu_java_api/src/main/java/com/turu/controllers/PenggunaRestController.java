package com.turu.controllers;

import com.turu.model.Pengguna;
import com.turu.service.PenggunaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

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

        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Username and password are required"));
        }

        Optional<Pengguna> userOptional = penggunaService.findByUsername(username);

        if (userOptional.isEmpty()) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Invalid username or password"));
        }

        Pengguna user = userOptional.get();
        if (!passwordEncoder.matches(password, user.getPassword())) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Invalid username or password"));
        }

        Map<String, Object> userData = new HashMap<>();
        userData.put("id", user.getId());
        userData.put("username", user.getUsername());
        userData.put("jk", user.getJk());
        userData.put("tanggalLahir", user.getTanggalLahir() != null ? user.getTanggalLahir().toString() : null);
        userData.put("profilePictureUrl", user.getProfilePictureUrl()); 

        return ResponseEntity.ok(userData);
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, Object> registerData) {
        String username = (String) registerData.get("username");
        String password = (String) registerData.get("password");
        String jk = (String) registerData.get("jk");
        String tanggalLahirStr = (String) registerData.get("tanggal_lahir");

        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Username and password are required"));
        }

        Optional<Pengguna> existingUser = penggunaService.findByUsername(username);
        if (existingUser.isPresent()) {
            return ResponseEntity.status(409)
                    .body(Map.of("error", "Username already exists"));
        }

        try {
            Pengguna newUser = new Pengguna();
            newUser.setUsername(username);
            newUser.setPassword(password);
            newUser.setJk(jk);
            newUser.setState(true);

            if (tanggalLahirStr != null && !tanggalLahirStr.isEmpty()) {
                try {
                    LocalDate tanggalLahir = LocalDate.parse(tanggalLahirStr);
                    newUser.setTanggalLahir(tanggalLahir);
                } catch (Exception e) {
                }
            }

            penggunaService.savePengguna(newUser);
            return ResponseEntity.ok(Map.of("message", "Register successful"));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(Map.of("error", "Registration failed due to an unexpected error"));
        }
    }

    @PutMapping("/user/{id}")
    public ResponseEntity<?> updateProfile(@PathVariable int id, @RequestBody Map<String, String> updateData) {
        String username = updateData.get("username");

        if (username == null || username.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Username is required"));
        }

        Optional<Pengguna> userOpt = penggunaService.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404)
                    .body(Map.of("error", "User not found"));
        }

        Pengguna user = userOpt.get();

        Optional<Pengguna> existingUser = penggunaService.findByUsername(username);
        if (existingUser.isPresent() && existingUser.get().getId() != id) {
            return ResponseEntity.status(409)
                    .body(Map.of("error", "Username already exists"));
        }

        try {
            user.setUsername(username);
            penggunaService.savePengguna(user);
            return ResponseEntity.ok(Map.of("message", "Profile updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(Map.of("error", "Error updating profile"));
        }
    }

    @PutMapping("/user/{id}/password")
    public ResponseEntity<?> updatePassword(@PathVariable int id, @RequestBody Map<String, String> passwordData) {
        String oldPassword = passwordData.get("oldPassword");
        String newPassword = passwordData.get("newPassword");

        if (oldPassword == null || newPassword == null || oldPassword.isEmpty() || newPassword.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Old and new passwords are required"));
        }

        Optional<Pengguna> userOpt = penggunaService.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404)
                    .body(Map.of("error", "User not found"));
        }

        Pengguna user = userOpt.get();

        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Old password is incorrect"));
        }

        try {
            user.setPassword(newPassword);
            penggunaService.savePengguna(user);
            return ResponseEntity.ok(Map.of("message", "Password updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(Map.of("error", "Error updating password"));
        }
    }

    @GetMapping("/ping")
    public ResponseEntity<?> ping() {
        return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "TURU REST API is running!"
        ));
    }

    @PostMapping("/user/{id}/profile-picture")
    public ResponseEntity<?> uploadProfilePicture(@PathVariable int id, @RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.status(400)
                    .body(Map.of("error", "Please select a file to upload"));
        }

        Optional<Pengguna> userOpt = penggunaService.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404)
                    .body(Map.of("error", "User not found"));
        }

        try {
            String uploadDir = "uploads";
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            String originalFilename = file.getOriginalFilename();
            String fileExtension = "";
            int dotIndex = originalFilename.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFilename.substring(dotIndex);
            }
            String uniqueFileName = UUID.randomUUID().toString() + fileExtension;
            Path filePath = uploadPath.resolve(uniqueFileName);

            Files.copy(file.getInputStream(), filePath);

            Pengguna user = userOpt.get();
            // Tambahkan timestamp sebagai query parameter untuk mencegah caching
            String profilePictureUrl = "/uploads/" + uniqueFileName + "?t=" + System.currentTimeMillis(); // BARIS INI BERUBAH
            user.setProfilePictureUrl(profilePictureUrl);
            penggunaService.savePengguna(user);

            return ResponseEntity.ok(Map.of("message", "Profile picture updated successfully", "profilePictureUrl", profilePictureUrl));

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to upload image: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "An unexpected error occurred: " + e.getMessage()));
        }
    }

    @GetMapping("/user/{id}")
    public ResponseEntity<?> getUserProfile(@PathVariable int id) {
        Optional<Pengguna> userOptional = penggunaService.findById(id);
        if (userOptional.isPresent()) {
            Pengguna user = userOptional.get();
            Map<String, Object> userData = new HashMap<>();
            userData.put("id", user.getId());
            userData.put("username", user.getUsername());
            userData.put("jk", user.getJk());
            userData.put("tanggalLahir", user.getTanggalLahir() != null ? user.getTanggalLahir().toString() : null);
            userData.put("profilePictureUrl", user.getProfilePictureUrl());

            return ResponseEntity.ok(userData);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "User not found"));
        }
    }
}