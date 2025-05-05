package com.turu.service;

import com.turu.model.Pengguna;
import com.turu.repository.PenggunaRepository;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final PenggunaRepository penggunaRepository;

    public CustomUserDetailsService(PenggunaRepository penggunaRepository) {
        this.penggunaRepository = penggunaRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Pengguna pengguna = penggunaRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Pengguna tidak ditemukan"));

        return User.builder()
                .username(pengguna.getUsername())
                .password(pengguna.getPassword()) // password harus sudah terenkripsi
                .roles("USER") // Set roles sesuai kebutuhan
                .build();
    }
} 