-- Data contoh DapurKita
-- Jalankan sekali di database dapurkita_db.
-- Foto memakai gambar dari Pexels (boleh dipakai gratis), ukuran w=1200
-- supaya tidak pecah di daftar maupun di halaman detail.
-- Kredit foto:
--   Nasi Goreng Spesial  : KS photoclickz (Pexels 14038038)
--   Nasi Goreng Kampung  : Dicky Agustian (Pexels 32938735)
--   Mie Ayam Bakso       : Tamba Budiarsana (Pexels 37106455)
--   Ayam Geprek          : Umar ben (Pexels 37320395)
--   Sate Ayam            : Faisal | @Photobapak (Pexels 36088082)
--   Es Teh Manis         : Tiya Nh (Pexels 37105558)
--   Es Jeruk Segar       : Shameel mukkath (Pexels 17612821)
--   Pisang Goreng Keju   : Tiya Nh (Pexels 37048319)
--   Foto splash          : Raditya Amoret (Pexels 37067922)

-- 1) Kategori
INSERT INTO categories (name, description) VALUES
('Nasi', 'Menu nasi dan lauk pauk'),
('Mie', 'Menu mie dan bakso'),
('Minuman', 'Minuman dingin dan hangat'),
('Snack', 'Cemilan dan makanan ringan');

-- 2) Produk
INSERT INTO products (category_id, name, description, price, image_url, is_available) VALUES
((SELECT id FROM categories WHERE name = 'Nasi' LIMIT 1),
 'Nasi Goreng Spesial',
 'Nasi goreng dengan bumbu spesial, disajikan dengan telur, ayam, dan kerupuk.',
 27000,
 'https://images.pexels.com/photos/14038038/pexels-photo-14038038.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1),

((SELECT id FROM categories WHERE name = 'Nasi' LIMIT 1),
 'Nasi Goreng Kampung',
 'Nasi goreng kampung dengan telur mata sapi, kerupuk, dan lalapan segar.',
 24000,
 'https://images.pexels.com/photos/32938735/pexels-photo-32938735.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1),

((SELECT id FROM categories WHERE name = 'Mie' LIMIT 1),
 'Mie Ayam Bakso',
 'Mie ayam dengan bakso sapi, sayuran segar, dan kuah gurih.',
 23000,
 'https://images.pexels.com/photos/37106455/pexels-photo-37106455.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1),

((SELECT id FROM categories WHERE name = 'Nasi' LIMIT 1),
 'Ayam Geprek',
 'Ayam goreng crispy digeprek dengan sambal pedas dan nasi putih hangat.',
 25000,
 'https://images.pexels.com/photos/37320395/pexels-photo-37320395.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1),

((SELECT id FROM categories WHERE name = 'Nasi' LIMIT 1),
 'Sate Ayam',
 'Sate ayam bakar dengan bumbu kacang dan kecap manis.',
 22000,
 'https://images.pexels.com/photos/36088082/pexels-photo-36088082.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1),

((SELECT id FROM categories WHERE name = 'Minuman' LIMIT 1),
 'Es Teh Manis',
 'Teh manis dingin yang menyegarkan.',
 6000,
 'https://images.pexels.com/photos/37105558/pexels-photo-37105558.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1),

((SELECT id FROM categories WHERE name = 'Minuman' LIMIT 1),
 'Es Jeruk Segar',
 'Perasan jeruk segar dengan es batu.',
 9000,
 'https://images.pexels.com/photos/17612821/pexels-photo-17612821.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1),

((SELECT id FROM categories WHERE name = 'Snack' LIMIT 1),
 'Pisang Goreng Keju',
 'Pisang goreng crispy dengan topping keju dan saus manis.',
 15000,
 'https://images.pexels.com/photos/37048319/pexels-photo-37048319.jpeg?auto=compress&cs=tinysrgb&w=1200',
 1);
