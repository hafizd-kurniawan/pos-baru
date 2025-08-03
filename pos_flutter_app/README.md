# POS Showroom Flutter App

Modern Flutter application for POS Showroom management system with beautiful UI/UX design.

## Features

### ✅ Implemented
- **Modern UI Design** with sidebar navigation
- **Authentication System** with JWT support
- **Role-based Dashboard** with real-time metrics
- **Responsive Layout** optimized for desktop/tablet
- **State Management** using BLoC pattern
- **Clean Architecture** with separation of concerns
- **API Integration** ready for backend connection

### 🎨 UI/UX Features
- **Modern Gradient Design** with premium color scheme
- **Sidebar Navigation** (no bottom navigation as requested)
- **Animated Transitions** and smooth interactions
- **Responsive Charts** using FL Chart
- **Loading States** and error handling
- **Professional Typography** using Poppins font
- **Card-based Layout** with proper shadows and spacing

### 📱 Pages Implemented
- **Splash Screen** with animated logo
- **Login Page** with modern design and demo credentials
- **Dashboard** with role-based content and charts
- **Vehicles Management** with grid layout
- **Customers Management** (placeholder)
- **Transactions Management** (placeholder)
- **Spare Parts Management** (placeholder)
- **Repairs Management** (placeholder)
- **Suppliers Management** (placeholder)
- **Users Management** (placeholder)

### 🏗️ Architecture
```
lib/
├── core/
│   ├── constants/     # API endpoints, routes
│   ├── models/        # Domain models
│   ├── network/       # API client and error handling
│   ├── storage/       # Local storage service
│   └── theme/         # App theme and colors
├── features/
│   ├── auth/          # Authentication feature
│   ├── dashboard/     # Dashboard and main layout
│   ├── vehicles/      # Vehicle management
│   ├── customers/     # Customer management
│   ├── transactions/  # Transaction management
│   ├── spare_parts/   # Spare parts management
│   ├── repairs/       # Repair management
│   ├── suppliers/     # Supplier management
│   └── users/         # User management
└── shared/
    ├── services/      # Shared services
    └── widgets/       # Reusable widgets
```

## Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.0.0 or higher)
- Backend server running on `http://localhost:8080`

### Installation

1. **Navigate to Flutter project directory**
```bash
cd pos_flutter_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the application**
```bash
flutter run -d chrome  # For web
flutter run             # For desktop/mobile
```

### Default Login Credentials
- **Username**: `admin`
- **Password**: `admin123`

## API Integration

The app is configured to connect to the backend API at `http://localhost:8080`. Make sure your backend server is running before starting the Flutter app.

### API Endpoints Used
- `POST /api/auth/login` - Authentication
- `GET /api/auth/profile` - User profile
- `GET /api/dashboard` - Dashboard data
- `GET /api/vehicles` - Vehicle list
- And all other endpoints from the backend API

## UI/UX Design

### Color Scheme
- **Primary**: Blue gradient (#2563EB to #1D4ED8)
- **Secondary**: Cyan (#06B6D4)
- **Accent**: Violet (#8B5CF6)
- **Success**: Emerald (#10B981)
- **Warning**: Amber (#F59E0B)
- **Error**: Red (#EF4444)

### Typography
- **Font Family**: Poppins
- **Responsive text sizes** for different screen sizes
- **Proper hierarchy** with bold headings and readable body text

### Layout
- **Sidebar Navigation** with collapsible functionality
- **Modern card design** with subtle shadows
- **Responsive grid layouts** for data display
- **Proper spacing** and visual hierarchy

## Development Progress

### Phase 1: Foundation ✅
- [x] Project setup and architecture
- [x] Authentication system
- [x] Main layout with sidebar
- [x] Theme and styling
- [x] Routing setup

### Phase 2: Core Features 🚧
- [x] Dashboard with charts
- [x] Vehicle management structure
- [ ] Complete vehicle CRUD operations
- [ ] Customer management implementation
- [ ] Transaction management implementation

### Phase 3: Advanced Features 📋
- [ ] Spare parts management
- [ ] Repair system integration
- [ ] Supplier management
- [ ] User administration
- [ ] Reports and analytics

### Phase 4: Enhancements 📋
- [ ] Advanced filtering and search
- [ ] Real-time notifications
- [ ] Export functionality
- [ ] Mobile optimization
- [ ] Offline support

## Contributing

1. Follow Flutter best practices
2. Use BLoC pattern for state management
3. Maintain clean architecture separation
4. Write meaningful commit messages
5. Test all features before committing

## License

This project is part of the POS Showroom system.

---

**Built with ❤️ using Flutter, BLoC, and modern UI/UX principles**