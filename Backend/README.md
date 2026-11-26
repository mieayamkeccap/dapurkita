# Backend DapurKita

Bagian backend aplikasi **DapurKita** (Node.js + Express + MySQL). Dokumentasi lengkap ada di README di root repo.

## Cara jalan

```bash
cp .env.example .env   # isi kredensial database & Cloudinary
npm install
npm run dev            # jalan di http://localhost:8000
```

## Endpoint utama

Semua endpoint diawali `/api`:

- `POST /auth/login`, `POST /auth/register`, `GET /auth/profile`, `PUT /auth/profile`
- `GET /products`, `POST /products` (admin, upload foto), `GET /categories`
- `GET /addresses`, `POST /addresses`, `PUT /addresses/:id`, `PUT /addresses/:id/utama`, `DELETE /addresses/:id` (customer)
- `GET /favorites`, `GET /favorites/ids`, `POST /favorites/:productId`, `DELETE /favorites/:productId` (customer)
- `POST /orders`, `GET /orders/my-orders`, `PUT /orders/:id/status` (admin), `PUT /orders/:id/selesai` (customer)
- `GET /dashboard/summary`, `/dashboard/top-products`, `/dashboard/daily-orders`, `/dashboard/product-sales` (admin)
- `GET /payments`

## Variabel lingkungan

Lihat `.env.example` untuk daftar lengkapnya. File `.env` berisi kredensial asli dan **tidak pernah** ikut ter-commit ke GitHub.

## Struktur

- `server.js` — titik masuk & daftar route
- `config/` — koneksi database & Cloudinary
- `controllers/` — logika per modul
- `routes/` — definisi endpoint
- `middleware/` — auth JWT, role, upload gambar
- `erd/` — file SQL ekspor & ERD database
