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
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registration Form</title>
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
        if (isset($_POST["submit"])) {
            $fullName = $_POST["fullname"];
            $email = $_POST["email"];
            $password = $_POST["password"];
            $passwordRepeat = $_POST["repeat_password"];

            // Enkripsi Argon2ID
            $passwordHash = password_hash($password, PASSWORD_ARGON2ID);
            $errors = array();

            if (empty($fullName) OR empty($email) OR empty($password) OR empty($passwordRepeat)) {
                array_push($errors, "All fields are required");
            }
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                array_push($errors, "Email tidak valid");
            }
            if (strlen($password)<8) {
                array_push($errors,"Panjang password minimal lebih dari 8 karakter");
            }
            if ($password!==$passwordRepeat) {
                array_push($errors,"Password tidak cocok");
            }
            
            require_once "database.php";
            
            // PERBAIKAN: Cek Email menggunakan Prepared Statement (Aman SQLi)
            $sqlEmail = "SELECT * FROM users WHERE email = ?";
            $stmtEmail = mysqli_stmt_init($conn);
            if (mysqli_stmt_prepare($stmtEmail, $sqlEmail)) {
                mysqli_stmt_bind_param($stmtEmail, "s", $email);
                mysqli_stmt_execute($stmtEmail);
                $resultEmail = mysqli_stmt_get_result($stmtEmail);
                if (mysqli_num_rows($resultEmail) > 0){
                    array_push($errors,"Email sudah terdaftar");
                }
            }

            if (count($errors)>0) {
                foreach ($errors as $error) {
                    echo "<div class='alert alert-danger'>$error</div>";
                }
            } else {
                $sql = "INSERT INTO users (full_name, email, password) VALUES (?, ?, ?)";
                $stmt = mysqli_stmt_init($conn);
                $prepareStmt = mysqli_stmt_prepare($stmt, $sql);
                
                if ($prepareStmt) {
                    mysqli_stmt_bind_param($stmt, "sss", $fullName, $email, $passwordHash);  
                    mysqli_stmt_execute($stmt);
                    echo "<div class='alert alert-success'>Kamu berhasil registrasi.</div>";
                } else {
                    die("Sesuatu ada yang salah pada query database");
                } 
            }
        }
        ?>
        <form action="registrasi.php" method="post">
            <div class="form-group mb-3">
                <input type="text" class="form-control" name="fullname" placeholder="Nama lengkap">
            </div>
            <div class="form-group mb-3">
                <input type="email" class="form-control" name="email" placeholder="Email">
            </div>
            <div class="form-group mb-3">
                <input type="password" class="form-control" name="password" placeholder="Password">
            </div>
            <div class="form-group mb-3">
                <input type="password" class="form-control" name="repeat_password" placeholder="Konfirmasi Password">
            </div>
            <div class="form-btn mb-3">
                <input type="submit" class="btn btn-primary" value="Register" name="submit">
            </div>
        </form>
        <div><p>Sudah registrasi? <a href="login.php">Login di sini</a></p></div>
    </div>
</body>
</html>