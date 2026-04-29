-- Script ini otomatis dijalankan saat container MySQL pertama kali dibuat

CREATE DATABASE IF NOT EXISTS `login-register`;
USE `login-register`;

CREATE TABLE IF NOT EXISTS `users` (
    `id`         INT(11) NOT NULL AUTO_INCREMENT,
    `full_name`  VARCHAR(100) NOT NULL,
    `email`      VARCHAR(100) NOT NULL UNIQUE,
    `password`   VARCHAR(255) NOT NULL,
    `role`       ENUM('admin','user') NOT NULL DEFAULT 'user',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Admin default: email=admin@argon.local | password=admin123
-- Hash di-generate dengan: password_hash('admin123', PASSWORD_BCRYPT)
INSERT IGNORE INTO `users` (full_name, email, password, role)
VALUES (
    'Admin ArgonAuth',
    'admin@argon.local',
    '$2y$10$TKh8H1.PfYkfvfOU2S/bOuMb1Y.k4SrKrSV1KQM5bB.3ThjumMhHm',
    'admin'
);

-- ==============================================================
-- ACL: MySQL User Privileges (Principle of Least Privilege)
-- ==============================================================
-- user_argon HANYA boleh SELECT, INSERT, UPDATE pada tabel users
-- TIDAK boleh: DROP, DELETE, ALTER, CREATE, atau akses tabel lain
-- ==============================================================

-- Revoke semua privilege dulu (reset)
REVOKE ALL PRIVILEGES ON `login-register`.* FROM 'user_argon'@'%';

-- Berikan hanya privilege yang dibutuhkan untuk login/register
GRANT SELECT, INSERT, UPDATE ON `login-register`.`users` TO 'user_argon'@'%';

-- Terapkan perubahan privilege
FLUSH PRIVILEGES;
