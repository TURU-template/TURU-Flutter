package com.turu.repository;

import com.turu.model.Pengguna;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PenggunaRepository extends JpaRepository<Pengguna, Integer> {
    Optional<Pengguna> findByUsername(String username);
} 