<?php
// =============================================
//  Security Headers
// =============================================
header("Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; font-src 'self' https://cdnjs.cloudflare.com; img-src 'self' data:;");
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

// =============================================
//  CSRF Token Generation
// =============================================
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// =============================================
//  Rate Limiting — Login Throttle
// =============================================
define('MAX_LOGIN_ATTEMPTS', 5);   // Maks percobaan gagal
define('LOCKOUT_DURATION',   900); // Lockout 15 menit (detik)

$error_msg   = "";
$is_locked   = false;
$lockout_msg = "";

// Cek apakah akun sedang dikunci
if (!empty($_SESSION['lockout_until'])) {
    if (time() < $_SESSION['lockout_until']) {
        $remaining   = ceil(($_SESSION['lockout_until'] - time()) / 60);
        $is_locked   = true;
        $lockout_msg = "Terlalu banyak percobaan login. Coba lagi dalam <strong>{$remaining} menit</strong>.";
    } else {
        // Lockout sudah habis — reset counter
        unset($_SESSION['login_attempts'], $_SESSION['lockout_until']);
    }
}

if (isset($_POST["login"]) && !$is_locked) {

    // =============================================
    //  CSRF Validation
    // =============================================
    if (empty($_POST['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'])) {
        $error_msg = "Permintaan tidak valid. Silakan muat ulang halaman.";
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32)); // Regenerate
    } else {

        $email    = trim($_POST["email"]);
        $password = $_POST["password"];

        require_once "database.php";

        $sql  = "SELECT * FROM users WHERE email = ?";
        $stmt = mysqli_stmt_init($conn);

        if (mysqli_stmt_prepare($stmt, $sql)) {
            mysqli_stmt_bind_param($stmt, "s", $email);
            mysqli_stmt_execute($stmt);
            $result = mysqli_stmt_get_result($stmt);
            $user   = mysqli_fetch_array($result, MYSQLI_ASSOC);

            if ($user && password_verify($password, $user["password"])) {
                // Login berhasil — reset rate limiter & cegah session fixation
                unset($_SESSION['login_attempts'], $_SESSION['lockout_until']);
                session_regenerate_id(true);

                $_SESSION["user"]      = "yes";
                $_SESSION["user_id"]   = $user["id"];
                //  MITIGASI XSS: Escape saat menyimpan ke session (defense-in-depth)
                $_SESSION["full_name"] = htmlspecialchars($user["full_name"], ENT_QUOTES, 'UTF-8');
                $_SESSION["role"]      = $user["role"];

                header("Location: index.php");
                die();
            } else {
                // Login gagal — increment attempt counter
                $_SESSION['login_attempts'] = ($_SESSION['login_attempts'] ?? 0) + 1;
                if ($_SESSION['login_attempts'] >= MAX_LOGIN_ATTEMPTS) {
                    $_SESSION['lockout_until'] = time() + LOCKOUT_DURATION;
                    $is_locked   = true;
                    $lockout_msg = "Terlalu banyak percobaan. Akun dikunci selama <strong>15 menit</strong>.";
                } else {
                    $sisa      = MAX_LOGIN_ATTEMPTS - $_SESSION['login_attempts'];
                    $error_msg = "Email atau password salah. Sisa percobaan: <strong>{$sisa}</strong>.";
                }
            }
        } else {
            $error_msg = "Terjadi kesalahan pada sistem.";
        }
    }
}

// Jika sudah login, redirect ke dashboard
if (isset($_SESSION["user"])) {
    header("Location: index.php");
    die();
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | ArgonAuth</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="style.css">
</head>

<body class="d-flex align-items-center justify-content-center vh-100 bg-light">
    <div class="container">
        <?php if ($is_locked && $lockout_msg): ?>
            <div class="alert alert-warning">&#9203; <?= $lockout_msg ?></div>
        <?php elseif ($error_msg): ?>
            <div class="alert alert-danger"><?= $error_msg ?></div>
        <?php endif; ?>
        <div class="text-center mb-4">
            <img src="assets/logo.png" alt="ArgonAuth Logo" style="width: 160px; height: 160px; object-fit: contain;" class="mb-3">
            <h4 class="fw-bold">Login ArgonAuth</h4>
        </div>
        <form action="login.php" method="post">
            <div class="form-group mb-3">
                <input type="email" class="form-control" name="email" placeholder="Masukkan Email" maxlength="120"
                    required>
            </div>
            <div class="form-group mb-3">
                <input type="password" class="form-control" name="password" placeholder="Masukkan Password"
                    maxlength="255" required>
            </div>
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token']) ?>">
            <div class="form-btn mb-3 d-grid">
                <input type="submit" class="btn btn-primary" value="Login" name="login"
                    <?= $is_locked ? 'disabled title="Akun dikunci sementara"' : '' ?>>
            </div>
        </form>
        <div class="text-center">
            <p class="mb-0">Belum registrasi? <a href="registrasi.php" class="text-decoration-none">Registrasi di
                    sini</a></p>
        </div>
    </div>
</body>

</html>