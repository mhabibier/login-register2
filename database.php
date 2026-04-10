<?php
$hostName = "localhost";
$dbUser = "root";
$dbPassword = "";
$dbName = "login-register"; 

$conn = mysqli_connect($hostName, $dbUser, $dbPassword, $dbName);
if (!$conn) {
    die("Sesuatu ada yang salah dengan koneksi database");
}
?>