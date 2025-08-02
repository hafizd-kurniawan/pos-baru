import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/storage_service.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/main_layout.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/pages/add_vehicle_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/customers/presentation/pages/add_customer_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/spare_parts/presentation/pages/spare_parts_page.dart';
import '../../features/spare_parts/presentation/pages/spare_part_detail_page.dart';
import '../../features/spare_parts/presentation/pages/add_spare_part_page.dart';
import '../../features/repairs/presentation/pages/repairs_page.dart';
import '../../features/repairs/presentation/pages/repair_detail_page.dart';
import '../../features/repairs/presentation/pages/add_repair_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/suppliers/presentation/pages/supplier_detail_page.dart';
import '../../features/suppliers/presentation/pages/add_supplier_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/users/presentation/pages/user_detail_page.dart';
import '../../features/users/presentation/pages/add_user_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static const String addVehicle = '/vehicles/add';
  static const String customers = '/customers';
  static const String customerDetail = '/customers/:id';
  static const String addCustomer = '/customers/add';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String spareParts = '/spare-parts';
  static const String sparePartDetail = '/spare-parts/:id';
  static const String addSparePart = '/spare-parts/add';
  static const String repairs = '/repairs';
  static const String repairDetail = '/repairs/:id';
  static const String addRepair = '/repairs/add';
  static const String suppliers = '/suppliers';
  static const String supplierDetail = '/suppliers/:id';
  static const String addSupplier = '/suppliers/add';
  static const String users = '/users';
  static const String userDetail = '/users/:id';
  static const String addUser = '/users/add';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    redirect: (context, state) async {
      final hasToken = await StorageService.hasToken();
      final isLoginRoute = state.fullPath == login;
      final isSplashRoute = state.fullPath == splash;

      // If no token and not on login/splash, redirect to login
      if (!hasToken && !isLoginRoute && !isSplashRoute) {
        return login;
      }

      // If has token and on login, redirect to dashboard
      if (hasToken && isLoginRoute) {
        return dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: vehicles,
            builder: (context, state) => const VehiclesPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddVehiclePage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return VehicleDetailPage(vehicleId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: customers,
            builder: (context, state) => const CustomersPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddCustomerPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CustomerDetailPage(customerId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: transactions,
            builder: (context, state) => const TransactionsPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddTransactionPage(),
              ),
            ],
          ),
          GoRoute(
            path: spareParts,
            builder: (context, state) => const SparePartsPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddSparePartPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return SparePartDetailPage(sparePartId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: repairs,
            builder: (context, state) => const RepairsPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddRepairPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return RepairDetailPage(repairId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: suppliers,
            builder: (context, state) => const SuppliersPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddSupplierPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return SupplierDetailPage(supplierId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: users,
            builder: (context, state) => const UsersPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddUserPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return UserDetailPage(userId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}