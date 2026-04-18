<?php
require_once "auth_check.php";
requireAdmin(); // Hanya admin yang boleh masuk

require_once "database.php";

// Ambil semua data user untuk ditampilkan di tabel
$sql    = "SELECT id, full_name, email, role, created_at FROM users ORDER BY created_at DESC";
$result = mysqli_query($conn, $sql);
$users  = mysqli_fetch_all($result, MYSQLI_ASSOC);
$total  = count($users);
?>
<!DOCTYPE html>
<html lang="id">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard | ArgonAuth</title>
    <meta name="description" content="Panel administrasi ArgonAuth — kelola user dan pantau sistem keamanan.">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        /* ============================================
           ADMIN DASHBOARD — ArgonAuth Design System
        ============================================ */
        :root {
            --bg-base:    #0f172a;
            --bg-surface: #1e293b;
            --bg-card:    #273549;
            --accent:     #6366f1;
            --accent-glow:#818cf8;
            --danger:     #ef4444;
            --success:    #10b981;
            --warning:    #f59e0b;
            --text-primary: #f1f5f9;
            --text-muted:   #94a3b8;
            --border:     rgba(99,102,241,0.2);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', sans-serif;
            background: var(--bg-base);
            color: var(--text-primary);
            min-height: 100vh;
        }

        /* ---- Sidebar ---- */
        .sidebar {
            position: fixed; top: 0; left: 0;
            width: 240px; height: 100vh;
            background: var(--bg-surface);
            border-right: 1px solid var(--border);
            display: flex; flex-direction: column;
            padding: 1.5rem 1rem;
            z-index: 100;
        }
        .sidebar-logo {
            display: flex; align-items: center; gap: .75rem;
            padding: .75rem 1rem; border-radius: 12px;
            background: linear-gradient(135deg, #4f46e5, #7c3aed);
            margin-bottom: 2rem;
        }
        .sidebar-logo img { width: 36px; height: 36px; object-fit: contain; }
        .sidebar-logo span { font-weight: 800; font-size: 1.1rem; letter-spacing: .5px; }

        .nav-link-admin {
            display: flex; align-items: center; gap: .75rem;
            padding: .65rem 1rem; border-radius: 10px;
            color: var(--text-muted); text-decoration: none;
            font-size: .9rem; font-weight: 500;
            transition: all .2s ease;
        }
        .nav-link-admin:hover,
        .nav-link-admin.active {
            background: rgba(99,102,241,.15);
            color: var(--accent-glow);
        }
        .nav-link-admin i { width: 18px; text-align: center; }

        .sidebar-bottom { margin-top: auto; }

        /* ---- Main Content ---- */
        .main-content {
            margin-left: 240px;
            padding: 2rem;
            min-height: 100vh;
        }

        /* ---- Topbar ---- */
        .topbar {
            display: flex; align-items: center;
            justify-content: space-between;
            margin-bottom: 2rem;
        }
        .topbar h1 { font-size: 1.5rem; font-weight: 800; }
        .admin-badge {
            display: flex; align-items: center; gap: .5rem;
            background: var(--bg-surface);
            border: 1px solid var(--border);
            padding: .5rem 1rem; border-radius: 50px;
            font-size: .875rem;
        }
        .admin-badge .dot {
            width: 8px; height: 8px; border-radius: 50%;
            background: var(--success);
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%,100% { opacity:1; } 50% { opacity:.4; }
        }

        /* ---- Stat Cards ---- */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.25rem;
            margin-bottom: 2rem;
        }
        .stat-card {
            background: var(--bg-surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 1.5rem;
            transition: transform .2s, box-shadow .2s;
        }
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 24px rgba(99,102,241,.15);
        }
        .stat-icon {
            width: 48px; height: 48px; border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
            font-size: 1.25rem; margin-bottom: 1rem;
        }
        .stat-icon.purple { background: rgba(99,102,241,.2); color: var(--accent-glow); }
        .stat-icon.green  { background: rgba(16,185,129,.2); color: var(--success); }
        .stat-icon.red    { background: rgba(239, 68,68,.2);  color: var(--danger); }
        .stat-value { font-size: 2rem; font-weight: 800; line-height: 1; }
        .stat-label { color: var(--text-muted); font-size: .875rem; margin-top: .25rem; }

        /* ---- User Table ---- */
        .card-panel {
            background: var(--bg-surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            overflow: hidden;
        }
        .card-panel-header {
            padding: 1.25rem 1.5rem;
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center;
            justify-content: space-between;
        }
        .card-panel-header h2 {
            font-size: 1rem; font-weight: 700;
        }

        table { width: 100%; border-collapse: collapse; }
        thead th {
            background: var(--bg-base);
            padding: .875rem 1.5rem;
            text-align: left; font-size: .8rem;
            font-weight: 600; text-transform: uppercase;
            letter-spacing: .5px; color: var(--text-muted);
        }
        tbody tr {
            border-bottom: 1px solid rgba(255,255,255,.04);
            transition: background .2s;
        }
        tbody tr:hover { background: var(--bg-card); }
        tbody tr:last-child { border-bottom: none; }
        tbody td {
            padding: 1rem 1.5rem;
            font-size: .9rem;
            vertical-align: middle;
        }
        .avatar {
            width: 36px; height: 36px; border-radius: 50%;
            background: linear-gradient(135deg, var(--accent), #7c3aed);
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: .875rem; color: white;
            flex-shrink: 0;
        }
        .user-info { display: flex; align-items: center; gap: .75rem; }
        .user-name  { font-weight: 600; }
        .user-email { font-size: .8rem; color: var(--text-muted); }

        .badge-role {
            display: inline-flex; align-items: center;
            gap: .35rem; padding: .25rem .75rem;
            border-radius: 50px; font-size: .75rem; font-weight: 600;
        }
        .badge-admin { background: rgba(99,102,241,.2); color: var(--accent-glow); border: 1px solid rgba(99,102,241,.3); }
        .badge-user  { background: rgba(16,185,129,.15); color: var(--success);       border: 1px solid rgba(16,185,129,.3); }

        .date-text { color: var(--text-muted); font-size: .85rem; }

        /* ---- Snort Log Preview Section ---- */
        .log-box {
            background: #0a0f1e;
            border: 1px solid rgba(99,102,241,.25);
            border-radius: 10px;
            padding: 1rem 1.25rem;
            font-family: 'Courier New', monospace;
            font-size: .8rem;
            color: #4ade80;
            max-height: 180px;
            overflow-y: auto;
            line-height: 1.8;
        }
        .log-line-warn  { color: #f59e0b; }
        .log-line-alert { color: #ef4444; }
    </style>
</head>

<body>

    <!-- ============ SIDEBAR ============ -->
    <aside class="sidebar">
        <div class="sidebar-logo">
            <img src="assets/logo.png" alt="ArgonAuth Logo">
            <span>ArgonAuth</span>
        </div>

        <nav>
            <a href="admin.php" class="nav-link-admin active">
                <i class="fas fa-gauge-high"></i> Dashboard
            </a>
            <a href="index.php" class="nav-link-admin">
                <i class="fas fa-house"></i> User View
            </a>
            <a href="#" class="nav-link-admin" style="margin-top:1rem; opacity:.5; cursor:not-allowed;">
                <i class="fas fa-shield-halved"></i> Snort Alerts
            </a>
            <a href="#" class="nav-link-admin" style="opacity:.5; cursor:not-allowed;">
                <i class="fas fa-list-check"></i> ACL Logs
            </a>
        </nav>

        <div class="sidebar-bottom">
            <a href="logout.php" class="nav-link-admin" style="color: #ef4444;">
                <i class="fas fa-right-from-bracket"></i> Logout
            </a>
        </div>
    </aside>

    <!-- ============ MAIN ============ -->
    <main class="main-content">

        <!-- Topbar -->
        <div class="topbar">
            <h1>🛡️ Admin Dashboard</h1>
            <div class="admin-badge">
                <span class="dot"></span>
                <?= getCurrentUser() ?> &mdash; <em>Admin</em>
            </div>
        </div>

        <!-- Stats -->
        <?php
            $total_admin = count(array_filter($users, fn($u) => $u['role'] === 'admin'));
            $total_user  = count(array_filter($users, fn($u) => $u['role'] === 'user'));
        ?>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon purple"><i class="fas fa-users"></i></div>
                <div class="stat-value"><?= $total ?></div>
                <div class="stat-label">Total User Terdaftar</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon red"><i class="fas fa-user-shield"></i></div>
                <div class="stat-value"><?= $total_admin ?></div>
                <div class="stat-label">Admin</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-user"></i></div>
                <div class="stat-value"><?= $total_user ?></div>
                <div class="stat-label">User Biasa</div>
            </div>
        </div>

        <!-- User Table -->
        <div class="card-panel mb-4">
            <div class="card-panel-header">
                <h2><i class="fas fa-table-list" style="color:var(--accent)"></i>&ensp;Daftar Semua User</h2>
                <span style="font-size:.8rem; color:var(--text-muted);"><?= $total ?> records</span>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>User</th>
                        <th>Role</th>
                        <th>Tanggal Daftar</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($users as $i => $u): ?>
                    <tr>
                        <td style="color:var(--text-muted); width:48px;"><?= $i + 1 ?></td>
                        <td>
                            <div class="user-info">
                                <div class="avatar"><?= strtoupper(substr($u['full_name'], 0, 1)) ?></div>
                                <div>
                                    <div class="user-name"><?= htmlspecialchars($u['full_name'], ENT_QUOTES, 'UTF-8') ?></div>
                                    <div class="user-email"><?= htmlspecialchars($u['email'], ENT_QUOTES, 'UTF-8') ?></div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <?php if ($u['role'] === 'admin'): ?>
                                <span class="badge-role badge-admin"><i class="fas fa-star" style="font-size:.65rem;"></i> Admin</span>
                            <?php else: ?>
                                <span class="badge-role badge-user"><i class="fas fa-user" style="font-size:.65rem;"></i> User</span>
                            <?php endif; ?>
                        </td>
                        <td class="date-text"><?= date('d M Y, H:i', strtotime($u['created_at'])) ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>

        <!-- Snort Log Preview (placeholder) -->
        <div class="card-panel">
            <div class="card-panel-header">
                <h2><i class="fas fa-terminal" style="color:#4ade80;"></i>&ensp;Snort IDS — Alert Log Preview</h2>
                <span style="font-size:.75rem; color:var(--text-muted);">Live terbaca dari /var/log/snort/alert.log</span>
            </div>
            <div style="padding:1.25rem;">
                <div class="log-box" id="snortLog">
                    <div>[ArgonAuth IDS] Snort container aktif — monitoring traffic HTTPS port 443...</div>
                    <div>[ArgonAuth IDS] HOME_NET = 172.18.0.0/16 | Rules loaded: 7</div>
                    <div class="log-line-warn">[WARN] Snort berjalan di mode IDS (Detection Only). Lihat docker logs argonauth_snort untuk live alert.</div>
                    <div>--- Tidak ada alert baru ---</div>
                </div>
            </div>
        </div>

    </main>

</body>
</html>
