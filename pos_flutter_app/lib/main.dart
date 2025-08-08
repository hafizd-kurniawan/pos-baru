import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/network/api_client.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/customers/presentation/blocs/customer_bloc.dart';
import 'features/customers/services/customer_service.dart';
import 'features/dashboard/presentation/blocs/dashboard_bloc.dart';
import 'features/repairs/presentation/blocs/mechanic_repair_bloc.dart';
import 'features/repairs/presentation/blocs/repair_bloc.dart';
import 'features/sales/presentation/blocs/sales_bloc.dart';
import 'features/sales/services/sales_service.dart';
import 'features/spare_parts/presentation/blocs/spare_part_bloc.dart';
import 'features/spare_parts/presentation/services/spare_part_service.dart';
import 'features/suppliers/presentation/blocs/supplier_bloc.dart';
import 'features/transactions/presentation/blocs/transaction_bloc.dart';
import 'features/users/presentation/blocs/user_bloc.dart';
import 'features/vehicle_types/presentation/blocs/vehicle_type_bloc.dart';
import 'features/vehicles/presentation/blocs/vehicle_bloc.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/sale_transaction_service.dart';
import 'shared/services/vehicle_type_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.initialize();

  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        Provider<VehicleTypeService>(
          create: (context) => VehicleTypeService(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        Provider<SaleTransactionService>(
          create: (context) => SaleTransactionService(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        Provider<CustomerService>(
          create: (context) => CustomerService(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        Provider<SalesService>(
          create: (context) => SalesService(
            apiClient: context.read<ApiClient>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authService: context.read<AuthService>(),
            ),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              apiClient: context.read<ApiClient>(),
            ),
          ),
          BlocProvider(
            create: (context) => VehicleBloc(
              apiClient: context.read<ApiClient>(),
            ),
          ),
          BlocProvider(
            create: (context) => VehicleTypeBloc(
              vehicleTypeService: context.read<VehicleTypeService>(),
            ),
          ),
          BlocProvider(
            create: (context) => CustomerBloc(
              apiClient: context.read<ApiClient>(),
            ),
          ),
          BlocProvider(
            create: (context) => SalesBloc(
              saleTransactionService: context.read<SaleTransactionService>(),
              apiClient: context.read<ApiClient>(),
            ),
          ),
          BlocProvider(
            create: (context) => TransactionBloc(
              apiClient: context.read<ApiClient>(),
            ),
          ),
          BlocProvider(
            create: (context) => SparePartBloc(
              sparePartService: SparePartService(),
            ),
          ),
          BlocProvider(
            create: (context) => RepairBloc(),
          ),
          BlocProvider(
            create: (context) => MechanicRepairBloc(),
          ),
          BlocProvider(
            create: (context) => SupplierBloc(
              apiClient: context.read<ApiClient>(),
            ),
          ),
          BlocProvider(
            create: (context) => UserBloc(
              apiClient: context.read<ApiClient>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'POS Showroom',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: AppRoutes.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
