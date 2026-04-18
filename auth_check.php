<?php
/**
 * auth_check.php — Helper Autentikasi & Otorisasi ArgonAuth
 *
 * Cara pakai:
 *   require_once "auth_check.php";
 *   requireLogin();   // Wajib login (redirect ke login.php jika belum)
 *   requireAdmin();   // Wajib role admin (403 jika bukan admin)
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Pastikan user sudah login.
 * Jika belum, redirect ke halaman login.
 */
function requireLogin(): void
{
    if (!isset($_SESSION["user"]) || $_SESSION["user"] !== "yes") {
        header("Location: login.php");
        exit;
    }
}

/**
 * Pastikan user sudah login DAN memiliki role 'admin'.
 * Jika belum login → redirect ke login.php
 * Jika bukan admin → tampilkan 403 Forbidden
 */
function requireAdmin(): void
{
    requireLogin();
    if (!isset($_SESSION["role"]) || $_SESSION["role"] !== "admin") {
        http_response_code(403);
        echo '<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>403 Forbidden | ArgonAuth</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <style>
        body { background: #0f172a; color: #e2e8f0; display: flex; align-items: center;
               justify-content: center; height: 100vh; font-family: "Segoe UI", sans-serif; }
        .box { text-align: center; }
        h1 { font-size: 6rem; font-weight: 900; color: #ef4444; margin: 0; }
        p  { font-size: 1.2rem; color: #94a3b8; }
        a  { color: #6366f1; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="box">
        <h1>403</h1>
        <p>🔒 Akses Ditolak — Halaman ini hanya untuk <strong>Admin</strong>.</p>
        <a href="index.php">← Kembali ke Dashboard</a>
    </div>
</body>
</html>';
        exit;
    }
}

/**
 * Ambil nama lengkap user yang sedang login.
 */
function getCurrentUser(): string
{
    return htmlspecialchars($_SESSION["full_name"] ?? "Unknown", ENT_QUOTES, 'UTF-8');
}

/**
 * Ambil role user yang sedang login.
 */
function getCurrentRole(): string
{
    return $_SESSION["role"] ?? "user";
}
