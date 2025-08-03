import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/customers/presentation/pages/add_customer_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/main_layout.dart';
import '../../features/repairs/presentation/pages/repairs_page.dart';
import '../../features/spare_parts/presentation/pages/spare_parts_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/vehicle_types/presentation/pages/vehicle_types_page.dart';
import '../../features/vehicles/presentation/pages/add_vehicle_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_edit_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';
import '../storage/storage_service.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static const String addVehicle = '/vehicles/add';
  static const String vehicleTypes = '/vehicle-types';
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
      final isLoggedIn = await StorageService.hasToken();
      final isGoingToLogin = state.matchedLocation == login;
      final isGoingToSplash = state.matchedLocation == splash;

      // If not logged in and not going to login or splash, redirect to login
      if (!isLoggedIn && !isGoingToLogin && !isGoingToSplash) {
        return login;
      }

      // If logged in and going to login or splash, redirect to dashboard
      if (isLoggedIn && (isGoingToLogin || isGoingToSplash)) {
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
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return VehicleEditPage(vehicleId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: vehicleTypes,
            builder: (context, state) => const VehicleTypesPage(),
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
          ),
          GoRoute(
            path: repairs,
            builder: (context, state) => const RepairsPage(),
          ),
          GoRoute(
            path: suppliers,
            builder: (context, state) => const SuppliersPage(),
          ),
          GoRoute(
            path: users,
            builder: (context, state) => const UsersPage(),
          ),
        ],
      ),
    ],
  );
}
