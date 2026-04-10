<?php
session_start();
if (isset($_SESSION["user"])){
    header("Location: index.php");
    die();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Form</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="style.css">
   <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="style.css">
    <title>ArgonAuth | Portal Autentikasi</title>
</head>
<body>
  <body class="d-flex align-items-center justify-content-center vh-100 bg-light">
    <div class="container">
        <?php
        if (isset($_POST["login"])) {
            $email = $_POST["email"];
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
                        $_SESSION["user"]= "yes";
                        header("Location: index.php");
                        die();
                    } else {
                        echo "<div class='alert alert-danger'>Password salah.</div>";
                    }
                } else {
                    echo "<div class='alert alert-danger'>Email tidak terdaftar.</div>";
                }
            } else {
                echo "<div class='alert alert-danger'>Terjadi kesalahan pada sistem.</div>";
            }
        }
        ?>

        <form action="login.php" method="post">
            <div class="form-group mb-3">
                <input type="email" class="form-control" name="email" placeholder="Masukkan Email" required>
            </div>
            <div class="form-group mb-3">
                <input type="password" class="form-control" name="password" placeholder="Masukkan Password" required>
            </div>
            <div class="form-btn mb-3">
                <input type="submit" class="btn btn-primary" value="Login" name="login">
            </div>
        </form>
        <div><p>Belum registrasi? <a href="registrasi.php">Registrasi di sini</a></p></div>
    </div>
</body>
</html>