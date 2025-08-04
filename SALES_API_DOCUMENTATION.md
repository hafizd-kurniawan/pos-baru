# Sales API Endpoints - Backend Implementation Required

Berikut adalah endpoint API yang perlu diimplementasikan di backend Go untuk mendukung fitur Point of Sales (POS):

## 1. Endpoint Sales Transaction

### POST `/api/sales/transactions`

**Deskripsi**: Membuat transaksi penjualan baru

**Request Body**:

```json
{
  "vehicle_id": 123,
  "customer_id": 456,
  "selling_price": 25000000,
  "down_payment": 5000000, // Optional, untuk DP
  "payment_method": "cash", // cash, transfer, credit, debit
  "payment_status": "partial", // paid, partial, pending
  "transaction_date": "2024-01-15T10:30:00Z",
  "notes": "Kendaraan dalam kondisi baik, sudah termasuk STNK"
}
```

**Response Success (201)**:

```json
{
  "message": "Transaction created successfully",
  "data": {
    "id": 789,
    "transaction_code": "TXN-20240115-001",
    "vehicle_id": 123,
    "customer_id": 456,
    "selling_price": 25000000,
    "down_payment": 5000000,
    "payment_method": "cash",
    "payment_status": "partial",
    "transaction_date": "2024-01-15T10:30:00Z",
    "notes": "Kendaraan dalam kondisi baik, sudah termasuk STNK",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "vehicle": {
      "id": 123,
      "code": "VH-001",
      "brand": {
        "id": 1,
        "name": "Honda"
      },
      "model": "Beat Street",
      "year": 2023,
      "color": "Merah",
      "license_plate": "B 1234 ABC",
      "odometer": 1500,
      "fuel_type": "Bensin",
      "transmission_type": "Manual"
      // ... data kendaraan lainnya
    },
    "customer": {
      "id": 456,
      "name": "John Doe",
      "phone": "081234567890",
      "email": "john@example.com",
      "address": "Jl. Sudirman No. 123, Jakarta"
      // ... data customer lainnya
    },
    "salesperson": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@bengkel.com"
    }
  }
}
```

**Response Error (400)**:

```json
{
  "error": "Validation failed",
  "message": "Vehicle or customer not found",
  "details": {
    "vehicle_id": "Vehicle with ID 123 not found",
    "customer_id": "Customer with ID 456 not found"
  }
}
```

### GET `/api/sales/transactions`

**Deskripsi**: Mendapatkan daftar transaksi penjualan

**Query Parameters**:

- `page` (optional): Nomor halaman (default: 1)
- `limit` (optional): Jumlah data per halaman (default: 10)
- `status` (optional): Filter berdasarkan payment_status
- `date_from` (optional): Filter tanggal mulai (format: YYYY-MM-DD)
- `date_to` (optional): Filter tanggal akhir (format: YYYY-MM-DD)
- `customer_id` (optional): Filter berdasarkan customer

**Response Success (200)**:

```json
{
  "message": "Transactions retrieved successfully",
  "data": [
    {
      "id": 789,
      "transaction_code": "TXN-20240115-001",
      "vehicle": {
        "code": "VH-001",
        "brand": "Honda",
        "model": "Beat Street"
      },
      "customer": {
        "name": "John Doe",
        "phone": "081234567890"
      },
      "selling_price": 25000000,
      "payment_status": "partial",
      "transaction_date": "2024-01-15T10:30:00Z"
    }
    // ... transaksi lainnya
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_items": 50,
    "items_per_page": 10
  }
}
```

### GET `/api/sales/transactions/{id}`

**Deskripsi**: Mendapatkan detail transaksi penjualan

**Response Success (200)**:

```json
{
  "message": "Transaction retrieved successfully",
  "data": {
    // ... sama dengan response POST create transaction
  }
}
```

### PUT `/api/sales/transactions/{id}`

**Deskripsi**: Update transaksi penjualan (untuk update status pembayaran, dll)

**Request Body**: Sama dengan POST, semua field optional

### DELETE `/api/sales/transactions/{id}`

**Deskripsi**: Hapus transaksi penjualan

## 2. Endpoint Customer Search untuk POS

### GET `/api/customers/search`

**Deskripsi**: Cari customer berdasarkan nomor telepon untuk POS

**Query Parameters**:

- `phone`: Nomor telepon customer (required)

**Response Success (200)**:

```json
{
  "message": "Customer found",
  "data": {
    "id": 456,
    "name": "John Doe",
    "phone": "081234567890",
    "email": "john@example.com",
    "address": "Jl. Sudirman No. 123, Jakarta",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

**Response Not Found (404)**:

```json
{
  "error": "Customer not found",
  "message": "No customer found with phone number 081234567890"
}
```

## 3. Endpoint Vehicle Filter untuk POS

### GET `/api/vehicles/available`

**Deskripsi**: Mendapatkan kendaraan yang tersedia untuk dijual

**Query Parameters**:

- `search` (optional): Pencarian berdasarkan brand, model, atau kode
- `brand` (optional): Filter berdasarkan brand
- `year_from` (optional): Filter tahun minimal
- `year_to` (optional): Filter tahun maksimal
- `sort_by` (optional): Pengurutan (odometer_asc, odometer_desc, year_asc, year_desc, price_asc, price_desc)
- `status` (optional): Filter status kendaraan (default: available)

**Response Success (200)**:

```json
{
  "message": "Available vehicles retrieved successfully",
  "data": [
    {
      "id": 123,
      "code": "VH-001",
      "brand": {
        "id": 1,
        "name": "Honda"
      },
      "model": "Beat Street",
      "year": 2023,
      "color": "Merah",
      "license_plate": "B 1234 ABC",
      "odometer": 1500,
      "fuel_type": "Bensin",
      "transmission_type": "Manual",
      "condition": "Baik",
      "purchase_price": 20000000,
      "selling_price": 25000000,
      "status": "available",
      "images": [
        {
          "id": 1,
          "vehicle_id": 123,
          "image_url": "/uploads/vehicles/vh-001-1.jpg",
          "is_primary": true
        }
      ]
    }
    // ... kendaraan lainnya
  ]
}
```

## 4. Database Schema Update Required

Pastikan tabel `sales_transactions` memiliki struktur sebagai berikut:

```sql
CREATE TABLE sales_transactions (
    id SERIAL PRIMARY KEY,
    transaction_code VARCHAR(50) UNIQUE NOT NULL,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE RESTRICT,
    customer_id INTEGER REFERENCES customers(id) ON DELETE RESTRICT,
    salesperson_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    selling_price DECIMAL(15,2) NOT NULL,
    down_payment DECIMAL(15,2),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'transfer', 'credit', 'debit')),
    payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('paid', 'partial', 'pending')),
    transaction_date TIMESTAMP NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index untuk optimasi query
CREATE INDEX idx_sales_transactions_date ON sales_transactions(transaction_date);
CREATE INDEX idx_sales_transactions_status ON sales_transactions(payment_status);
CREATE INDEX idx_sales_transactions_customer ON sales_transactions(customer_id);
CREATE INDEX idx_sales_transactions_vehicle ON sales_transactions(vehicle_id);
```

## 5. Business Logic Notes

1. **Transaction Code Generation**: Generate kode transaksi otomatis dengan format `TXN-YYYYMMDD-XXX`
2. **Vehicle Status Update**: Setelah transaksi dibuat, update status kendaraan menjadi 'sold'
3. **Payment Validation**:
   - Jika payment_status = 'paid', down_payment harus sama dengan selling_price atau null
   - Jika payment_status = 'partial', down_payment harus kurang dari selling_price
   - Jika payment_status = 'pending', down_payment bisa 0 atau null
4. **User Context**: Ambil salesperson_id dari JWT token user yang sedang login

## 6. Error Handling

Pastikan semua endpoint memiliki error handling yang konsisten:

- 400: Bad Request (validation errors)
- 401: Unauthorized (JWT token invalid)
- 403: Forbidden (user tidak memiliki akses)
- 404: Not Found (resource tidak ditemukan)
- 422: Unprocessable Entity (business logic errors)
- 500: Internal Server Error (database errors, dll)

## 7. Security Considerations

1. Validasi semua input data
2. Pastikan user memiliki permission untuk membuat transaksi
3. Log semua transaksi penjualan untuk audit trail
4. Implementasi rate limiting untuk mencegah spam
5. Validasi referential integrity (vehicle dan customer harus exist)

---

**Catatan**: Setelah backend API ini diimplementasikan, fitur POS akan bisa berfungsi penuh dengan kemampuan:

- Filter dan search kendaraan
- Pencarian customer berdasarkan telepon
- Registrasi customer baru
- Pembuatan transaksi penjualan
- Preview dan cetak invoice
- Manajemen status pembayaran
