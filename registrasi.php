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

if (isset($_SESSION["user"])) {
    header("Location: index.php");
    die();
}

// =============================================
//  CSRF Token Generation
// =============================================
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ArgonAuth | Portal Autentikasi</title>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
        integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="style.css">
</head>

<body class="d-flex align-items-center justify-content-center vh-100 bg-light">
    <div class="container">
        <div class="text-center mb-4">
            <h4 class="fw-bold">Registrasi ArgonAuth</h4>
            <p class="text-muted small">Silakan lengkapi data diri Anda</p>
        </div>

        <?php
        if (isset($_POST["submit"])) {

            // =============================================
            //  CSRF Validation
            // =============================================
            if (empty($_POST['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'])) {
                echo "<div class='alert alert-danger py-2'>Permintaan tidak valid. Silakan muat ulang halaman.</div>";
                $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
            } else {

                //  MITIGASI XSS: Sanitasi dilakukan saat OUTPUT, bukan INPUT
                //  Data disimpan dalam bentuk asli (raw) di database,
                //  lalu di-escape dengan htmlspecialchars() saat ditampilkan.
                $fullName = trim($_POST["fullname"]);
                $email = trim($_POST["email"]);

                $password = $_POST["password"];
                $passwordRepeat = $_POST["repeat_password"];

                //  INTEGRITY: Argon2ID Hash
                $passwordHash = password_hash($password, PASSWORD_ARGON2ID);
                $errors = array();

                if (empty($fullName) OR empty($email) OR empty($password) OR empty($passwordRepeat)) {
                    array_push($errors, "Semua kolom wajib diisi");
                }
                //  MITIGASI XSS: Whitelist validation untuk nama lenkapss
                //  Hanya boleh huruf, spasi, titik, koma, dan tanda hubung
                if (!preg_match('/^[a-zA-Z\s\.\,\-\']+$/u', $fullName)) {
                    array_push($errors, "Nama hanya boleh mengandung huruf, spasi, titik, koma, dan tanda hubung");
                }
                if (strlen($fullName) > 100) {
                    array_push($errors, "Nama maksimal 100 karakter");
                }
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    array_push($errors, "Format email tidak valid");
                }
                if (strlen($password) < 8) {
                    array_push($errors, "Password minimal 8 karakter");
                }
                if ($password !== $passwordRepeat) {
                    array_push($errors, "Konfirmasi password tidak cocok");
                }

                require_once "database.php";

                //  MITIGASI SQL INJECTION: Prepared Statement untuk Cek Email
                $sqlEmail = "SELECT * FROM users WHERE email = ?";
                $stmtEmail = mysqli_stmt_init($conn);
                if (mysqli_stmt_prepare($stmtEmail, $sqlEmail)) {
                    mysqli_stmt_bind_param($stmtEmail, "s", $email);
                    mysqli_stmt_execute($stmtEmail);
                    $resultEmail = mysqli_stmt_get_result($stmtEmail);
                    if (mysqli_num_rows($resultEmail) > 0) {
                        array_push($errors, "Email sudah terdaftar");
                    }
                }

                if (count($errors) > 0) {
                    foreach ($errors as $error) {
                        echo "<div class='alert alert-danger py-2'>$error</div>";
                    }
                } else {
                    //  MITIGASI SQL INJECTION: Prepared Statement untuk Insert
                    $sql = "INSERT INTO users (full_name, email, password) VALUES (?, ?, ?)";
                    $stmt = mysqli_stmt_init($conn);
                    $prepareStmt = mysqli_stmt_prepare($stmt, $sql);

                    if ($prepareStmt) {
                        mysqli_stmt_bind_param($stmt, "sss", $fullName, $email, $passwordHash);
                        mysqli_stmt_execute($stmt);

                        //  Regenerate CSRF token setelah aksi berhasil
                        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));

                        echo "<div class='alert alert-success'>Registrasi berhasil! <a href='login.php'>Login sekarang</a></div>";
                    } else {
                        die("Gagal memproses database.");
                    }
                }
            } // end else (CSRF valid)
        }
        ?>

        <form action="registrasi.php" method="post">
            <div class="form-group mb-3">
                <input type="text" class="form-control" name="fullname" placeholder="Nama Lengkap" maxlength="100"
                    required>
            </div>
            <div class="form-group mb-3">
                <input type="email" class="form-control" name="email" placeholder="Email" maxlength="100" required>
            </div>
            <div class="form-group mb-3">
                <input type="password" class="form-control" name="password" placeholder="Password (Min. 8 Karakter)"
                    maxlength="255" required>
            </div>
            <div class="form-group mb-3">
                <input type="password" class="form-control" name="repeat_password" placeholder="Konfirmasi Password"
                    maxlength="255" required>
            </div>
            <div class="form-btn mb-3 d-grid">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token']) ?>">
                <input type="submit" class="btn btn-primary" value="Register" name="submit">
            </div>
        </form>
        <div class="text-center">
            <p class="small">Sudah punya akun? <a href="login.php" class="text-decoration-none">Login di sini</a></p>
        </div>
    </div>
</body>

</html>