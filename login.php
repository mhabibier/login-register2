<?php
session_start();

$error_msg = "";

if (isset($_POST["login"])) {
    $email = htmlspecialchars($_POST["email"], ENT_QUOTES, 'UTF-8');
    $password = $_POST["password"];

    require_once "database.php";

    $sql = "SELECT * FROM users WHERE email = ?";
    $stmt = mysqli_stmt_init($conn);

    if (mysqli_stmt_prepare($stmt, $sql)) {
        mysqli_stmt_bind_param($stmt, "s", $email);
        mysqli_stmt_execute($stmt);
        $result = mysqli_stmt_get_result($stmt);
        $user = mysqli_fetch_array($result, MYSQLI_ASSOC);

        if ($user) {
            if (password_verify($password, $user["password"])) {
                $_SESSION["user"]      = "yes";
                $_SESSION["user_id"]   = $user["id"];
                $_SESSION["full_name"] = $user["full_name"];
                $_SESSION["role"]      = $user["role"];

                // Redirect berdasarkan role
                if ($user["role"] === "admin") {
                    header("Location: admin.php");
                } else {
                    header("Location: index.php");
                }
                die();
            } else {
                $error_msg = "Password salah.";
            }
        } else {
            $error_msg = "Email tidak terdaftar.";
        }
    } else {
        $error_msg = "Terjadi kesalahan pada sistem.";
    }
}

// Jika sudah login, redirect sesuai role
if (isset($_SESSION["user"])) {
    if (isset($_SESSION["role"]) && $_SESSION["role"] === "admin") {
        header("Location: admin.php");
    } else {
        header("Location: index.php");
    }
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
        <?php if ($error_msg): ?>
            <div class="alert alert-danger"><?= htmlspecialchars($error_msg) ?></div>
        <?php endif; ?>
        <div class="text-center mb-4">
            <i class="fas fa-lock fa-3x text-primary mb-3"></i>
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
            <div class="form-btn mb-3 d-grid">
                <input type="submit" class="btn btn-primary" value="Login" name="login">
            </div>
        </form>
        <div class="text-center">
            <p class="mb-0">Belum registrasi? <a href="registrasi.php" class="text-decoration-none">Registrasi di
                    sini</a></p>
        </div>
    </div>
</body>

</html>