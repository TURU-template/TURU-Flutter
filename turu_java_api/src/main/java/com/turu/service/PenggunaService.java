package com.turu.service;

import com.turu.model.Pengguna;
import com.turu.repository.PenggunaRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PenggunaService {

    private final PenggunaRepository penggunaRepository;
    private final PasswordEncoder passwordEncoder;

    public PenggunaService(PenggunaRepository penggunaRepository, PasswordEncoder passwordEncoder) {
        this.penggunaRepository = penggunaRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<Pengguna> getAllPengguna() {
        return penggunaRepository.findAll();
    }

    public Optional<Pengguna> findByUsername(String username) {
        return penggunaRepository.findByUsername(username);
    }
    
    public Optional<Pengguna> findById(int id) {
        return penggunaRepository.findById(id);
    }

    public void savePengguna(Pengguna pengguna) {
        // Jika password belum di-encode, encode di sini
        if (pengguna.getId() == 0 || (pengguna.getPassword() != null && !pengguna.getPassword().startsWith("$2a$"))) {
            pengguna.setPassword(passwordEncoder.encode(pengguna.getPassword()));
        }
        penggunaRepository.save(pengguna);
    }
    
    public void updatePengguna(Pengguna pengguna) {
        penggunaRepository.save(pengguna);
    }
} 