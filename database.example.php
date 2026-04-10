<?php
// ============================================================
// SALIN file ini menjadi database.php dan isi sesuai konfigurasi
// lokal kamu. Jangan pernah push file database.php langsung!
// ============================================================

$hostName = "localhost";         // Biasanya: localhost
$dbUser   = "root";              // Default XAMPP: root
$dbPassword = "";                // Default XAMPP: kosong
$dbName   = "login-register";   // Sesuaikan nama database kamu

$conn = mysqli_connect($hostName, $dbUser, $dbPassword, $dbName);
if (!$conn) {
    die("Sesuatu ada yang salah dengan koneksi database");
}
?>
