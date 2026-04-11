<?php
$hostName = "db";           // Nama service MySQL di docker-compose.yml
$dbUser = "root";
$dbPassword = "root";       // Sesuai MYSQL_ROOT_PASSWORD di docker-compose.yml
$dbName = "login-register";

$conn = mysqli_connect($hostName, $dbUser, $dbPassword, $dbName);
if (!$conn) {
    die("Sesuatu ada yang salah dengan koneksi database: " . mysqli_connect_error());
}
?>