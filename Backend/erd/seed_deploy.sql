-- Data awal untuk database DapurKita yang baru dibuat (misalnya di Aiven).
--
-- Dipisah dari dapurkita_db.sql karena file itu adalah ekspor mysqldump apa
-- adanya tanpa satu pun INSERT. Kalau digabung, file ekspor tidak lagi sama
-- dengan hasil mysqldump dan isinya bercampur dengan data buatan.
--
-- Jalankan SETELAH struktur tabel diimpor:
--   mysql -h <HOST> -P <PORT> -u <USER> -p <NAMA_DB> < seed_deploy.sql
--
-- Password di bawah adalah hash bcrypt salt 10 dari password berikut:
--   admin@gmail.com / admin123
--   eros@gmail.com  / eros123
-- Ganti password setelah aplikasi online.

START TRANSACTION;

-- ===== Pengguna =====
INSERT INTO users (name, email, password, phone, role) VALUES
('Admin DapurKita', 'admin@gmail.com',
 '$2b$10$JSShsbqDpsaPB1BgQeCYIOXrdjLL3WEd6MewF7GsysTGOA.AYyqpi',
 '081234567890', 'admin'),
('Eros Wasis', 'eros@gmail.com',
 '$2b$10$E3pMmfXOURcrRld5GxRUMOXnn.ZJJ.NjEH9B5eu7sCCmk.aw9DB1q',
 '081234567891', 'customer');

-- ===== Kategori =====
INSERT INTO categories (name, description) VALUES
('Nasi', 'Menu berbahan dasar nasi'),
('Mie', 'Menu berbahan dasar mie'),
('Minuman', 'Minuman dingin dan hangat'),
('Snack', 'Makanan ringan dan camilan');

-- ===== Produk =====
-- category_id memakai subquery nama, supaya id tetap benar walaupun
-- AUTO_INCREMENT di database baru dimulai dari 1.
-- image_url sengaja NULL: foto lama tersimpan di Cloudinary akun lokal dan
-- tidak boleh dirujuk ulang dari database lain. Tampilan sudah menangani
-- produk tanpa foto.
INSERT INTO products (category_id, name, description, price, image_url, is_available) VALUES
((SELECT id FROM categories WHERE name = 'Nasi'),
 'Ayam Balado', 'Ayam goreng dengan sambal balado khas DapurKita', 24000.00, NULL, 1),
((SELECT id FROM categories WHERE name = 'Nasi'),
 'Ayam Bakar', 'Ayam bakar dengan bumbu kecap manis pedas', 25000.00, NULL, 1),
((SELECT id FROM categories WHERE name = 'Nasi'),
 'Ayam Geprek', 'Ayam goreng geprek dengan sambal bawang', 24000.00, NULL, 1);

COMMIT;

-- Periksa hasilnya: harus 2, 4, 3.
SELECT
    (SELECT COUNT(*) FROM users) AS jumlah_users,
    (SELECT COUNT(*) FROM categories) AS jumlah_categories,
    (SELECT COUNT(*) FROM products) AS jumlah_products;
