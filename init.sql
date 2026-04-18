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

-- Admin default: email=admin@argon.local | password=AdminArgon123!
-- Hash di-generate dengan: password_hash('AdminArgon123!', PASSWORD_BCRYPT)
INSERT IGNORE INTO `users` (full_name, email, password, role)
VALUES (
    'Admin ArgonAuth',
    'admin@argon.local',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'admin'
);
