# TURU REST API untuk Aplikasi Flutter

API Java Spring Boot untuk aplikasi TURU Flutter.

## Cara Menggunakan

### Langkah 1: Persiapan

1. Pastikan Java 17 dan MySQL sudah terinstal di komputer Anda.
2. API ini dikonfigurasi untuk terhubung ke database Aiven MySQL secara default.

### Langkah 2: Konfigurasi Database

#### Opsi 1: Menggunakan Aiven MySQL Default

API sudah dikonfigurasi untuk terhubung ke database Aiven MySQL:

```
Host: turumysql-turuproject.e.aivencloud.com
Port: 23729
Database: dbturu
Username: avnadmin
Password: AVNS_MJabb4P-Ri3h7UrS6nN
```

Jika perlu, Anda dapat mengubah kredensial ini dengan variabel lingkungan:

```
DB_HOST=your-aiven-mysql-host.aivencloud.com
DB_PORT=your-mysql-port
DB_NAME=your-database-name
DB_USER=your-username
DB_PASS=your-password
```

#### Opsi 2: Koneksi ke Database Lokal

Untuk menggunakan database lokal, edit file `src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/dbturu
spring.datasource.username=root
spring.datasource.password=your-password
```

### Langkah 3: Menjalankan API

1. Buka terminal dan masuk ke direktori `turu_java_api`
2. Jalankan perintah:
   ```bash
   ./mvnw spring-boot:run
   ```
   Atau di Windows:
   ```cmd
   mvnw.cmd spring-boot:run
   ```
3. API akan berjalan di `http://localhost:8080`

Untuk menjalankan dengan script helper:
- Di Linux/Mac: `./start.sh`
- Di Windows: `start.bat`

### Langkah 4: Penggunaan dari Aplikasi Flutter

Buka file `turu_mobile/lib/services/auth.dart` dan perbarui alamat backend:

```dart
static String get _baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8080/api';
  } else {
    try {
      if (Platform.isAndroid) {
        // Untuk emulator Android gunakan 10.0.2.2
        return 'http://10.0.2.2:8080/api';
      } else {
        return 'http://localhost:8080/api';
      }
    } catch (e) {
      return 'http://localhost:8080/api';
    }
  }
}
```

## Struktur Database

Tabel utama yang digunakan:

```sql
CREATE TABLE pengguna (
   id INT AUTO_INCREMENT PRIMARY KEY,
   username VARCHAR(50) UNIQUE NOT NULL,
   password VARCHAR(255) NOT NULL,
   jk CHAR(1) NULL,
   tanggal_lahir DATE NULL,
   state BOOLEAN DEFAULT true
);
```

## Endpoint API

### Pengguna

- **Login**: `POST /api/login`
  ```json
  {
    "username": "string",
    "password": "string"
  }
  ```

- **Register**: `POST /api/register`
  ```json
  {
    "username": "string",
    "password": "string",
    "jk": "L|P",
    "tanggal_lahir": "yyyy-MM-dd"
  }
  ```

- **Update Profil**: `PUT /api/user/{id}`
  ```json
  {
    "username": "string"
  }
  ```

- **Update Password**: `PUT /api/user/{id}/password`
  ```json
  {
    "oldPassword": "string",
    "newPassword": "string"
  }
  ```

- **Test API**: `GET /api/ping`

## Pengujian dengan cURL

- Test API:
  ```bash
  curl http://localhost:8080/api/ping
  ```

- Login:
  ```bash
  curl -X POST http://localhost:8080/api/login \
    -H "Content-Type: application/json" \
    -d '{"username":"user","password":"password"}'
  ```

- Register:
  ```bash
  curl -X POST http://localhost:8080/api/register \
    -H "Content-Type: application/json" \
    -d '{"username":"newuser","password":"password123","jk":"L","tanggal_lahir":"2000-01-01"}'
  ``` 