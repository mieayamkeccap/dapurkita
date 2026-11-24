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

- `POST /auth/login`, `POST /auth/register`
- `GET /products`, `POST /products` (admin, upload foto), `GET /categories`
- `POST /orders`, `GET /orders/my-orders`, `PUT /orders/:id/status` (admin), `PUT /orders/:id/selesai` (customer)
- `GET /dashboard/summary`, `/dashboard/top-products`, `/dashboard/daily-orders` (admin)
- `GET /payments`, `/ingredients`, `/purchases`, `/expenses`

## Variabel lingkungan

Lihat `.env.example` untuk daftar lengkapnya. File `.env` berisi kredensial asli dan **tidak pernah** ikut ter-commit ke GitHub.

## Struktur

- `server.js` — titik masuk & daftar route
- `config/` — koneksi database & Cloudinary
- `controllers/` — logika per modul
- `routes/` — definisi endpoint
- `middleware/` — auth JWT, role, upload gambar
- `erd/` — file SQL ekspor & ERD database
