-- ================================================
-- ArgonAuth — Database Schema
-- Database: login-register
-- ================================================

CREATE DATABASE IF NOT EXISTS `login-register`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `login-register`;

-- Tabel pengguna
CREATE TABLE IF NOT EXISTS `users` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `full_name`  VARCHAR(100) NOT NULL,
  `email`      VARCHAR(120) NOT NULL UNIQUE,
  `password`   VARCHAR(255) NOT NULL COMMENT 'Hashed dengan Argon2ID',
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- Cara import:
-- 1. Buka phpMyAdmin → http://localhost/phpmyadmin
-- 2. Klik tab SQL → paste query ini → klik Go
-- ATAU via terminal:
--   mysql -u root -p < database.sql
-- ================================================
