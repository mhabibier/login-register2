# 🔐 ArgonAuth — Sistem Login & Registrasi Aman

> **Proyek Keamanan Sistem** | Telkom University — Tingkat 3 (2026)

![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-005C84?style=for-the-badge&logo=mysql&logoColor=white)
![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-7952B3?style=for-the-badge&logo=bootstrap&logoColor=white)
![Apache](https://img.shields.io/badge/Apache-2.4-D22128?style=for-the-badge&logo=apache&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![HTTPS](https://img.shields.io/badge/HTTPS-mkcert%20ECDSA-00C853?style=for-the-badge&logo=letsencrypt&logoColor=white)
![Snort](https://img.shields.io/badge/Snort-2.9.x%20IDS-FF0000?style=for-the-badge&logo=snort&logoColor=white)

---

## 📌 Deskripsi Proyek

**ArgonAuth** adalah aplikasi web autentikasi (login & registrasi) berbasis PHP dan MySQL yang dirancang dengan menerapkan berbagai teknik **mitigasi keamanan** sesuai standar modern, antara lain:

| Ancaman | Mitigasi yang Diterapkan |
|---|---|
| **SQL Injection** | Prepared Statement (`mysqli_stmt`) |
| **XSS (Cross-Site Scripting)** | `htmlspecialchars()` + Content-Security-Policy header |
| **CSRF (Cross-Site Request Forgery)** | CSRF Token (`hash_equals` + `random_bytes`) |
| **Brute Force Login** | Rate limiting (5 percobaan → lockout 15 menit) |
| **Session Fixation** | `session_regenerate_id(true)` setelah login |
| **Password Plaintext** | Hashing **Argon2ID** dengan salt otomatis |
| **Buffer Overflow** | `maxlength` HTML + validasi `strlen` server-side |
| **Man-in-the-Middle** | **HTTPS TLS (ECDSA P-256)** via mkcert |
| **Port Scan / Recon** | Snort IDS (SYN, NULL, FIN, XMAS scan detection) |
| **DoS / DDoS** | Snort IDS (ICMP flood, UDP flood, HTTP GET flood) |
| **Unauthorized DB Access** | ACL jaringan Docker (backend_net isolasi) + Snort rule |

---

## 🗂️ Struktur Direktori

```
login-register2/
├── apache/
│   └── default-ssl.conf  # Konfigurasi Apache Virtual Host untuk HTTPS
├── assets/
│   ├── logo.png           # Logo ArgonAuth
│   ├── laman.png          # Screenshot halaman dashboard
│   ├── login2.png         # Screenshot halaman login
│   └── regis2.png         # Screenshot halaman registrasi
├── ssl/                   # ⚠️ Folder ini diisi mkcert di VM (tidak di-push ke GitHub)
│   ├── localhost.pem      # Sertifikat SSL (di-generate mkcert)
│   └── localhost-key.pem  # Private key SSL (di-generate mkcert)
├── database.php           # Konfigurasi koneksi database
├── docker-compose.yml     # Konfigurasi Docker Compose
├── Dockerfile             # Image PHP + Apache + SSL
├── index.php              # Halaman dashboard (butuh login)
├── init.sql               # SQL otomatis buat tabel saat Docker pertama jalan
├── login.php              # Halaman login
├── logout.php             # Proses logout (hapus session)
├── registrasi.php         # Halaman registrasi pengguna baru
├── style.css              # CSS tambahan
└── README.md              # Dokumentasi proyek ini
```

---

## ✨ Fitur Utama

- ✅ **Registrasi** pengguna baru dengan validasi lengkap
- ✅ **Login** dengan verifikasi password terenkripsi (Argon2ID + salt)
- ✅ **Logout** yang membersihkan session
- ✅ Proteksi halaman dashboard (redirect jika belum login)
- ✅ Validasi email, panjang password (min. 8 karakter), dan konfirmasi password
- ✅ **CSRF Protection** — token acak per-session di semua form
- ✅ **Rate Limiting** — lockout 15 menit setelah 5 percobaan login gagal
- ✅ **Session Fixation Protection** — `session_regenerate_id()` setelah login
- ✅ Tampilan responsif menggunakan **Bootstrap 5.3**
- ✅ **HTTPS** dengan sertifikat **mkcert** (ECDSA P-256, tanpa warning browser)
- ✅ **Containerized** menggunakan **Docker & Docker Compose** (4 container)
- ✅ Security headers (HSTS, CSP, X-Frame-Options, X-XSS-Protection)
- ✅ **Snort IDS** — deteksi intrusi jaringan real-time
- ✅ **ACL** jaringan Docker (isolasi DB di backend_net)

---

## ⚙️ Prasyarat (Prerequisites)

| Software | Versi Minimum | Keterangan |
|---|---|---|
| **Docker** | 24.x | Container runtime |
| **Docker Compose** | 2.x | Multi-container orchestration |
| **mkcert** | 1.4.x | Generate SSL sertifikat lokal terpercaya |
| **Git** | Terbaru | Clone repository |
| **Web Browser** | Terbaru | Chrome, Firefox, Edge, dll. |

> ⚠️ **Penting:** `PASSWORD_ARGON2ID` memerlukan PHP versi **7.3 ke atas**. Docker image `php:8.2-apache` sudah mendukung ini.

---

## 🚀 Cara Instalasi & Menjalankan (Docker + HTTPS)

### Langkah 1 — Clone Repository

```bash
git clone https://github.com/mhabibier/login-register2.git
cd login-register2
```

---

### Langkah 2 — Install mkcert

#### Ubuntu / Debian (VMware)

```bash
# Install dependency
sudo apt update && sudo apt install -y libnss3-tools curl

# Download mkcert
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert

# Verifikasi instalasi
mkcert --version
```

#### Windows (opsional)

```powershell
# Menggunakan winget
winget install FiloSottile.mkcert

# Atau menggunakan Chocolatey
choco install mkcert
```

---

### Langkah 3 — Install CA & Generate Sertifikat SSL

```bash
# Daftarkan CA ke sistem & browser (jalankan sekali saja)
mkcert -install

# Masuk ke folder project
cd login-register2

# Buat folder ssl
mkdir -p ssl

# Generate sertifikat untuk localhost
mkcert -key-file ssl/localhost-key.pem \
       -cert-file ssl/localhost.pem \
       localhost 127.0.0.1 ::1
```

Hasil: dua file akan tersimpan di folder `ssl/`:
- `ssl/localhost.pem` → Sertifikat SSL
- `ssl/localhost-key.pem` → Private Key

> ⚠️ Folder `ssl/` **tidak di-push ke GitHub** (sudah ada di `.gitignore`). Langkah ini harus diulang di setiap mesin baru.

---

### Langkah 4 — Jalankan dengan Docker Compose

```bash
# Pertama kali / setelah ada perubahan Dockerfile
docker compose down -v
docker compose build --no-cache
docker compose up -d

# Jika tidak ada perubahan Dockerfile
docker compose up -d
```

Cek status container:

```bash
docker compose ps
```

Output yang diharapkan:
```
NAME                          STATUS          PORTS
argonauth_app_101032300005    Up              0.0.0.0:8080->80/tcp, 0.0.0.0:8443->443/tcp
argonauth_db_101032300005     Up (healthy)    0.0.0.0:3307->3306/tcp
```

---

### Langkah 5 — Akses Aplikasi

| URL | Keterangan |
|-----|-----------|
| `https://localhost:8443` | ✅ HTTPS (disarankan) |
| `https://localhost:8443/login.php` | Halaman Login |
| `https://localhost:8443/registrasi.php` | Halaman Registrasi |
| `http://localhost:8080` | HTTP → otomatis redirect ke HTTPS |

> 💡 **Pastikan** `mkcert -install` sudah dijalankan agar browser tidak menampilkan warning "Not Secure".

---

## 🔒 Penjelasan Keamanan

### 1. HTTPS dengan mkcert (Transport Layer Security)

```
Browser ←── TLS/SSL (mkcert) ──→ Apache Docker
```

Semua data yang dikirim antara browser dan server **dienkripsi** menggunakan protokol **TLS 1.3**, mencegah serangan **Man-in-the-Middle (MitM)**.

Security headers yang aktif:
```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-XSS-Protection "1; mode=block"
```

---

### 2. SQL Injection Prevention — Prepared Statement

```php
$sql = "SELECT * FROM users WHERE email = ?";
$stmt = mysqli_stmt_init($conn);
mysqli_stmt_prepare($stmt, $sql);
mysqli_stmt_bind_param($stmt, "s", $email);
mysqli_stmt_execute($stmt);
```

Parameter query dipisahkan dari data pengguna sehingga query tidak bisa dimanipulasi.

---

### 3. XSS Prevention — htmlspecialchars()

```php
$email = htmlspecialchars($_POST["email"], ENT_QUOTES, 'UTF-8');
```

Karakter berbahaya seperti `<`, `>`, `"` dikonversi menjadi entitas HTML yang aman.

---

### 4. Password Hashing — Argon2ID

```php
// Saat registrasi
$passwordHash = password_hash($password, PASSWORD_ARGON2ID);

// Saat login (verifikasi)
password_verify($password, $user["password"]);
```

Argon2ID adalah algoritma hashing modern yang tahan terhadap serangan brute-force dan side-channel attack.

---

## 🖥️ Screenshot

### Halaman Login
![Login](assets/login2.png)

### Halaman Registrasi
![Registrasi](assets/regis2.png)

### Halaman Dashboard
![Dashboard](assets/laman.png)

---

## 🛠️ Teknologi yang Digunakan

| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| **PHP** | 8.2 | Backend scripting |
| **MySQL** | 8.0 | Penyimpanan data pengguna |
| **Apache** | 2.4 | Web server |
| **Bootstrap** | 5.3 | Framework CSS responsif |
| **Font Awesome** | 6 | Icon library |
| **Docker** | 24.x | Containerization |
| **Docker Compose** | 2.x | Multi-container orchestration |
| **mkcert** | 1.4.x | SSL sertifikat lokal terpercaya |

---

## ❓ Troubleshooting

### Browser masih tampilkan "Not Secure"
```bash
# Pastikan mkcert CA sudah terdaftar
mkcert -install
# Restart browser setelah install
```

### Error `dpkg lock` saat install di Ubuntu
```bash
sudo kill -9 $(lsof /var/lib/dpkg/lock-frontend | awk 'NR>1{print $2}')
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
sudo dpkg --configure -a
```

### Error `init.sql: not a directory` saat docker compose up
```bash
# Hapus volume lama dan jalankan ulang
docker compose down -v
docker compose up -d
```

### Container tidak jalan / port tidak terbuka
```bash
# Cek status container
docker compose ps

# Lihat log error
docker compose logs app
```

---

## 🛡️ Snort IDS — Pengujian & Monitoring

### Cek Status Snort

```bash
# Pastikan Snort berjalan (healthy)
docker compose ps

# Lihat log Snort secara real-time
docker logs -f argonauth_snort_101032300005

# Monitor alert secara langsung
docker exec argonauth_snort_101032300005 tail -f /var/log/snort/snort.alert.fast
```

---

### Cara Trigger Setiap Rule (Pengujian)

> Jalankan perintah berikut **dari container user** (simulasi attacker):
> ```bash
> docker exec -it argonauth_user_101032300005 sh
> ```

| Rule yang Diuji | Perintah Pengujian |
|---|---|
| **ICMP Ping** | `ping -c 3 172.20.0.1` |
| **ICMP Flood** | `ping -f 172.20.0.1` |
| **HTTP GET login.php** | `curl -k https://172.20.0.2:443/login.php` |
| **Brute Force Login** | `for i in $(seq 1 10); do curl -k -X POST https://172.20.0.2/login.php -d 'email=test@test.com&password=wrong'; done` |
| **SYN Scan** | `nmap -sS 172.20.0.2` |
| **NULL Scan** | `nmap -sN 172.20.0.2` |
| **FIN Scan** | `nmap -sF 172.20.0.2` |
| **XMAS Scan** | `nmap -sX 172.20.0.2` |
| **Akses MySQL langsung** | `nc -zv 172.21.0.2 3306` |

---

### Update Community Rules (Emerging Threats)

**Auto-update** — terjadi otomatis saat container pertama kali start.

**Manual update** — jalankan kapan saja:
```bash
# Update rule dari Emerging Threats (web-server, dos, scan, sql)
docker exec argonauth_snort_101032300005 /usr/local/bin/update_rules.sh

# Cek info update terakhir
docker exec argonauth_snort_101032300005 cat /etc/snort/rules/.community_rules_meta
```

Output contoh setelah update berhasil:
```
last_update=2026-04-25 14:00:00
total_rules=4823
success=4
failed=0
```

---

### Struktur Rule Lokal (argonauth.rules)

| Section | SID Range | Deskripsi |
|---|---|---|
| SECTION 1 | 9001001–9001004 | ICMP Ping, Flood, Redirect, UDP Flood |
| SECTION 2 | 9001010–9001012 | HTTP akses login/registrasi |
| SECTION 3 | 9001020–9001022 | Brute Force & HTTP GET Flood |
| SECTION 4 | 9001030–9001033 | SYN, NULL, FIN, XMAS Scan |
| SECTION 5 | 9001040 | Unauthorized MySQL Access |
| SECTION 6 | 9001050–9001051 | HTTPS Connection Monitor |

---

## ❓ Troubleshooting

### Browser masih tampilkan "Not Secure"
```bash
# Pastikan mkcert CA sudah terdaftar
mkcert -install
# Restart browser setelah install
```

### Error `dpkg lock` saat install di Ubuntu
```bash
sudo kill -9 $(lsof /var/lib/dpkg/lock-frontend | awk 'NR>1{print $2}')
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
sudo dpkg --configure -a
```

### Error `init.sql: not a directory` saat docker compose up
```bash
# Hapus volume lama dan jalankan ulang
docker compose down -v
docker compose up -d
```

### Container tidak jalan / port tidak terbuka
```bash
# Cek status container
docker compose ps

# Lihat log error
docker compose logs app
```

### Snort container unhealthy
```bash
# Cek log Snort
docker logs argonauth_snort_101032300005

# Jalankan ulang Snort
docker compose restart snort
```

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan **akademis** — Mata Kuliah Keamanan Sistem, Telkom University 2026.
Dilarang menggunakan untuk tujuan komersial tanpa izin.
