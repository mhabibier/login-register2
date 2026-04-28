<?php
// =============================================
//  Security Headers
// =============================================
header("Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; font-src 'self' https://cdnjs.cloudflare.com; img-src 'self' data:;");
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");

// =============================================
//  Secure Session Configuration
// =============================================
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);
ini_set('session.use_strict_mode', 1);
ini_set('session.cookie_samesite', 'Strict');
session_start();

// PERBAIKAN: Harus pakai tanda seru (!)
if (!isset($_SESSION["user"])) {
    header("Location: login.php");
    die();
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
        integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="style.css">
    <title>ArgonAuth | Portal Autentikasi v2</title>
</head>


<body>

    <body class="d-flex align-items-center justify-content-center vh-100 bg-light">
        <div class="container mt-5 text-center">
            <div class="mb-4">
                <img src="assets/logo.png" alt="ArgonAuth Logo" style="width: 180px; height: 180px; object-fit: contain;">
            </div>

            <h1>Selamat datang, <?php echo htmlspecialchars($_SESSION["full_name"], ENT_QUOTES, 'UTF-8'); ?>!</h1>
            <p class="lead mb-4">Anda berhasil login ke sistem aman kami.</p>

            <a href="logout.php" class="btn btn-warning">
                <i class="fas fa-sign-out-alt mb-1"></i> Logout
            </a>
        </div>
    </body>

</html>