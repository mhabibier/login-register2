<?php
session_start();
// PERBAIKAN: Harus pakai tanda seru (!)
if (!isset($_SESSION["user"])){
    header("Location: login.php");
    die();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="style.css">
    <title>ArgonAuth | Portal Autentikasi v2</title>
</head>
    

<body>
  <body class="d-flex align-items-center justify-content-center vh-100 bg-light">
    <div class="container mt-5 text-center">
    <div class="mb-4">
        <i class="fas fa-user-circle fa-7x text-primary"></i>
    </div>
    
    <h1>Selamat datang, <?php echo htmlspecialchars($_SESSION["full_name"], ENT_QUOTES, 'UTF-8'); ?>!</h1>
    <p class="lead mb-4">Anda berhasil login ke sistem aman kami.</p>
    
    <a href="logout.php" class="btn btn-warning">
        <i class="fas fa-sign-out-alt mb-1"></i> Logout
    </a>
</div>
</body>
</html>