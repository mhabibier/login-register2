-- Script ini otomatis dijalankan saat container MySQL pertama kali dibuat

CREATE DATABASE IF NOT EXISTS `login-register`;
USE `login-register`;

CREATE TABLE IF NOT EXISTS `users` (
    `id`        INT(11) NOT NULL AUTO_INCREMENT,
    `full_name` VARCHAR(100) NOT NULL,
    `email`     VARCHAR(100) NOT NULL UNIQUE,
    `password`  VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
