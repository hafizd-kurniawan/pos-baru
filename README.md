# POS Showroom Kendaraan - Backend API

Sistem backend untuk Point of Sale (POS) showroom kendaraan yang dibangun dengan Go, Gin, SQLX, dan PostgreSQL menggunakan clean architecture.

## 📋 Fitur

- **Autentikasi & Otorisasi**: JWT-based authentication dengan role-based access control
- **Manajemen Pengguna**: Admin, Kasir, dan Mekanik dengan permission yang berbeda
- **Manajemen Kendaraan**: CRUD kendaraan dengan tracking status dan HPP
- **Manajemen Customer**: Database customer untuk transaksi
- **Sistem Transaksi**: Pembelian dan penjualan kendaraan dengan perhitungan profit
- **Sistem Perbaikan**: Tracking perbaikan kendaraan dengan assignment mekanik dan spare parts
- **Inventory**: Manajemen spare parts dengan stock tracking dan low stock alerts
- **Dashboard**: Metrics dan laporan untuk berbagai role
- **Laporan**: Statistik repair, workload mekanik, dan financial reporting

## 🏗️ Arsitektur

Sistem ini menggunakan Clean Architecture dengan struktur:

```
├── cmd/server/          # Main application
├── internal/
│   ├── config/          # Configuration management
│   ├── domain/models/   # Domain entities
│   ├── repository/      # Data access layer
│   ├── service/         # Business logic layer
│   ├── handler/         # HTTP handlers
│   └── middleware/      # HTTP middleware
├── pkg/
│   ├── database/        # Database connection
│   └── utils/           # Utility functions
└── migrations/          # Database migrations
```

## 🚀 Quick Start

### Prerequisites

- Go 1.21+
- Docker & Docker Compose
- PostgreSQL (via Docker)

### Installation

1. **Clone repository**
```bash
git clone https://github.com/hafizd-kurniawan/pos-baru.git
cd pos-baru
```

2. **Setup environment**
```bash
cp .env.example .env
# Edit .env sesuai kebutuhan
```

3. **Start database**
```bash
docker compose up -d
```

4. **Build dan run aplikasi**
```bash
go mod tidy
go build ./cmd/server
./server
```

Server akan berjalan di `http://localhost:8080`

### Default Admin User

- **Username**: `admin`
- **Password**: `admin123`
- **Role**: Administrator

## 📚 API Documentation

### Authentication

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

#### Get Profile
```http
GET /api/auth/profile
Authorization: Bearer <token>
```

#### Register User (Admin only)
```http
POST /api/auth/register
Authorization: Bearer <token>
Content-Type: application/json

{
  "username": "kasir1",
  "email": "kasir1@showroom.com",
  "password": "password123",
  "full_name": "Kasir Satu",
  "phone": "081234567891",
  "role_id": 2
}
```

### Customer Management

#### List Customers
```http
GET /api/customers?page=1&limit=10
Authorization: Bearer <token>
```

#### Get Customer Details
```http
GET /api/customers/{id}
Authorization: Bearer <token>
```

#### Get Customer by Phone
```http
GET /api/customers/phone/{phone}
Authorization: Bearer <token>
```

#### Get Customer by Email
```http
GET /api/customers/email/{email}
Authorization: Bearer <token>
```

#### Create Customer (Kasir/Admin)
```http
POST /api/customers
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Doe",
  "phone": "081234567890",
  "email": "john.doe@email.com",
  "address": "Jl. Customer Street No. 123",
  "id_card_number": "1234567890123456"
}
```

#### Update Customer (Kasir/Admin)
```http
PUT /api/customers/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Doe Updated",
  "phone": "081234567891",
  "email": "john.updated@email.com",
  "address": "Jl. Updated Street No. 456"
}
```

#### Delete Customer (Admin)
```http
DELETE /api/customers/{id}
Authorization: Bearer <token>
```

### Transaction Management

#### Purchase Transactions

##### List Purchase Transactions
```http
GET /api/transactions/purchase?page=1&limit=10&date_from=2024-01-01&date_to=2024-12-31
Authorization: Bearer <token>
```

##### Get Purchase Transaction Details
```http
GET /api/transactions/purchase/{id}
Authorization: Bearer <token>
```

##### Create Purchase Transaction (Kasir/Admin)
```http
POST /api/transactions/purchase
Authorization: Bearer <token>
Content-Type: application/json

{
  "source_type": "customer",
  "source_id": 1,
  "vehicle_id": 1,
  "purchase_price": 8000000,
  "payment_method": "cash",
  "payment_status": "paid",
  "notes": "Pembelian motor bekas dari customer"
}
```

##### Update Purchase Payment Status (Kasir/Admin)
```http
PATCH /api/transactions/purchase/{id}/payment
Authorization: Bearer <token>
Content-Type: application/json

{
  "payment_status": "paid",
  "notes": "Pembayaran lunas"
}
```

#### Sales Transactions

##### List Sales Transactions
```http
GET /api/transactions/sales?page=1&limit=10&date_from=2024-01-01&date_to=2024-12-31
Authorization: Bearer <token>
```

##### Get Sales Transaction Details
```http
GET /api/transactions/sales/{id}
Authorization: Bearer <token>
```

##### Create Sales Transaction (Kasir/Admin)
```http
POST /api/transactions/sales
Authorization: Bearer <token>
Content-Type: application/json

{
  "customer_id": 1,
  "vehicle_id": 1,
  "selling_price": 9500000,
  "payment_method": "cash",
  "payment_status": "paid",
  "down_payment": 9500000,
  "notes": "Penjualan cash"
}
```

##### Update Sales Payment Status (Kasir/Admin)
```http
PATCH /api/transactions/sales/{id}/payment
Authorization: Bearer <token>
Content-Type: application/json

{
  "payment_status": "partial",
  "down_payment": 5000000,
  "remaining_payment": 4500000,
  "notes": "Pembayaran cicilan"
}
```

### Spare Parts Management

#### List Spare Parts
```http
GET /api/spare-parts?page=1&limit=10&active=true
Authorization: Bearer <token>
```

#### Get Spare Part Details
```http
GET /api/spare-parts/{id}
Authorization: Bearer <token>
```

#### Get Spare Part by Code
```http
GET /api/spare-parts/code/{code}
Authorization: Bearer <token>
```

#### Create Spare Part (Kasir/Admin)
```http
POST /api/spare-parts
Authorization: Bearer <token>
Content-Type: application/json

{
  "code": "SP011",
  "name": "Oli Mesin 10W-40",
  "description": "Oli mesin kualitas premium",
  "unit": "liter",
  "purchase_price": 35000,
  "selling_price": 45000,
  "stock_quantity": 50,
  "minimum_stock": 10
}
```

#### Update Spare Part (Kasir/Admin)
```http
PUT /api/spare-parts/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Oli Mesin 10W-40 Premium",
  "selling_price": 50000,
  "minimum_stock": 15
}
```

#### Update Stock (Kasir/Admin)
```http
PATCH /api/spare-parts/{id}/stock
Authorization: Bearer <token>
Content-Type: application/json

{
  "quantity": 10,
  "operation": "add"
}
```

#### Get Low Stock Items
```http
GET /api/spare-parts/low-stock?page=1&limit=10
Authorization: Bearer <token>
```

#### Check Stock Availability
```http
GET /api/spare-parts/{id}/stock-check?quantity=5
Authorization: Bearer <token>
```

#### Bulk Stock Update (Kasir/Admin)
```http
POST /api/spare-parts/bulk-stock-update
Authorization: Bearer <token>
Content-Type: application/json

{
  "updates": [
    {
      "quantity": 5,
      "operation": "subtract",
      "notes": "Used for repair"
    }
  ]
}
```

#### Delete Spare Part (Admin)
```http
DELETE /api/spare-parts/{id}
Authorization: Bearer <token>
```

### Repair System Management

#### List Repair Orders
```http
GET /api/repairs?page=1&limit=10&status=pending&mechanic_id=3
Authorization: Bearer <token>
```

#### Get Repair Order Details
```http
GET /api/repairs/{id}
Authorization: Bearer <token>
```

#### Get Repair Order by Code
```http
GET /api/repairs/code/{code}
Authorization: Bearer <token>
```

#### Create Repair Order (Kasir/Admin)
```http
POST /api/repairs
Authorization: Bearer <token>
Content-Type: application/json

{
  "code": "RPR-20241201-001",
  "vehicle_id": 1,
  "mechanic_id": 3,
  "description": "Ganti oli mesin dan filter udara",
  "estimated_cost": 150000,
  "notes": "Perawatan rutin"
}
```

#### Update Repair Order (Kasir/Admin)
```http
PUT /api/repairs/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "description": "Ganti oli mesin, filter udara, dan tune up",
  "estimated_cost": 200000,
  "notes": "Perawatan lengkap"
}
```

#### Update Repair Progress (Mechanic/Kasir/Admin)
```http
PATCH /api/repairs/{id}/progress
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "completed",
  "actual_cost": 180000,
  "notes": "Perbaikan selesai, semua parts sudah diganti",
  "spare_parts": [
    {
      "spare_part_id": 1,
      "quantity_used": 2
    },
    {
      "spare_part_id": 3,
      "quantity_used": 1
    }
  ]
}
```

#### Add Spare Part to Repair (Mechanic/Kasir/Admin)
```http
POST /api/repairs/{id}/spare-parts
Authorization: Bearer <token>
Content-Type: application/json

{
  "spare_part_id": 1,
  "quantity_used": 2
}
```

#### Remove Spare Part from Repair (Kasir/Admin)
```http
DELETE /api/repairs/{id}/spare-parts/{spare_part_id}
Authorization: Bearer <token>
```

#### Get Repair Spare Parts
```http
GET /api/repairs/{id}/spare-parts
Authorization: Bearer <token>
```

#### Get Repair Statistics
```http
GET /api/repairs/stats?mechanic_id=3&date_from=2024-01-01&date_to=2024-12-31
Authorization: Bearer <token>
```

#### Get Mechanic Workload
```http
GET /api/repairs/mechanic-workload
Authorization: Bearer <token>
```

#### Delete Repair Order (Admin)
```http
DELETE /api/repairs/{id}
Authorization: Bearer <token>
```

### Vehicle Management

#### List Vehicles
```http
GET /api/vehicles?page=1&limit=10&status=available
Authorization: Bearer <token>
```

#### Get Available Vehicles
```http
GET /api/vehicles/available?page=1&limit=10
Authorization: Bearer <token>
```

#### Get Vehicle Details
```http
GET /api/vehicles/{id}
Authorization: Bearer <token>
```

#### Create Vehicle (Kasir/Admin)
```http
POST /api/vehicles
Authorization: Bearer <token>
Content-Type: application/json

{
  "code": "VHC20250801001",
  "brand_id": 1,
  "model": "Beat",
  "year": 2020,
  "color": "Red",
  "engine_capacity": "110cc",
  "fuel_type": "Bensin",
  "transmission_type": "Manual",
  "license_plate": "B1234ABC",
  "odometer": 15000,
  "source_type": "customer",
  "source_id": 1,
  "purchase_price": 8000000,
  "condition_status": "good"
}
```

#### Update Vehicle (Kasir/Admin)
```http
PUT /api/vehicles/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "model": "Beat Updated",
  "year": 2021,
  "color": "Blue"
}
```

#### Set Selling Price (Admin)
```http
PATCH /api/vehicles/{id}/selling-price
Authorization: Bearer <token>
Content-Type: application/json

{
  "selling_price": 9500000
}
```

#### Delete Vehicle (Admin)
```http
DELETE /api/vehicles/{id}
Authorization: Bearer <token>
```

## 🗃️ Database Schema

### Roles
- `admin`: Full access
- `kasir`: Transaction management, vehicle input
- `mekanik`: Repair management

### Vehicle Status
- `available`: Siap dijual
- `in_repair`: Sedang diperbaiki
- `sold`: Sudah terjual
- `reserved`: Reserved untuk customer

### Transaction Flow

1. **Pembelian Kendaraan**
   - Kasir input vehicle dari customer/supplier
   - System calculate HPP = Purchase Price + Repair Cost
   - Vehicle status = available/in_repair

2. **Perbaikan Kendaraan**
   - Admin/Kasir assign ke mekanik
   - Mekanik update progress dan spare parts
   - System update HPP dengan repair cost

3. **Penjualan Kendaraan**
   - Admin set selling price
   - Kasir proses penjualan ke customer
   - System calculate profit = Selling Price - HPP
   - Vehicle status = sold

## 🔧 Configuration

Environment variables dalam `.env`:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=posuser
DB_PASSWORD=pospassword
DB_NAME=pos_showroom
DB_SSLMODE=disable

# JWT
JWT_SECRET=your_super_secret_jwt_key_here

# Server
SERVER_PORT=8080
APP_ENV=development
```

## 📊 Dashboard Features

### Admin Dashboard
- Total revenue & profit
- Vehicle inventory overview
- Transaction summary
- Performance metrics

### Kasir Dashboard
- Available vehicles
- Today's transactions
- Pending payments
- Customer management

### Mekanik Dashboard
- Assigned repairs
- Required spare parts
- Completed work
- Work progress

## 🧪 Testing

Test the API endpoints:

```bash
# Health check
curl http://localhost:8080/health

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# List vehicles (with token)
curl -X GET http://localhost:8080/api/vehicles \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📝 Development Status

### ✅ Completed Features
- [x] JWT Authentication & Authorization
- [x] Role-based access control
- [x] Vehicle CRUD operations
- [x] Customer CRUD operations
- [x] Transaction management (Purchase & Sales)
- [x] Spare Parts inventory management
- [x] Repair system with mechanic assignment
- [x] Repair progress tracking and spare parts usage
- [x] Database setup with PostgreSQL
- [x] Clean architecture implementation
- [x] API validation and error handling
- [x] Vehicle status tracking
- [x] HPP calculation system
- [x] Payment tracking system
- [x] Stock management with low stock alerts
- [x] Repair statistics and reporting

### 🚧 In Progress
- [ ] Dashboard endpoints
- [ ] Invoice generation
- [ ] Daily/monthly closing

### 📋 TODO
- [ ] Suppliers management
- [ ] Vehicle photos management
- [ ] API documentation with Swagger
- [ ] Unit tests
- [ ] Integration tests
- [ ] Docker deployment
- [ ] CI/CD pipeline
- [ ] Performance optimization

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

Untuk pertanyaan atau bantuan, silakan buat issue di repository ini.

---

**Built with ❤️ using Go, Gin, SQLX, and PostgreSQL**