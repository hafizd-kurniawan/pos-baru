import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/user.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../widgets/sidebar_widget.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  
  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isCollapsed = false;
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                User? currentUser;
                if (state is AuthAuthenticated) {
                  currentUser = state.user;
                }
                
                return SidebarWidget(
                  isCollapsed: _isCollapsed,
                  currentUser: currentUser,
                  onToggleCollapse: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  onLogout: () {
                    _showLogoutDialog();
                  },
                );
              },
            ),
            
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top App Bar
                  _buildTopAppBar(),
                  
                  // Content Area
                  Expanded(
                    child: Container(
                      color: AppTheme.backgroundColor,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          
          // Toggle Sidebar Button
          IconButton(
            icon: Icon(
              _isCollapsed ? Icons.menu_open : Icons.menu,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
          ),
          
          const SizedBox(width: 16),
          
          // Page Title
          Expanded(
            child: Text(
              _getPageTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          
          // Action Buttons
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppTheme.textSecondary,
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.search),
            color: AppTheme.textSecondary,
            onPressed: () {
              // TODO: Show search
            },
          ),
          
          const SizedBox(width: 8),
          
          // User Menu
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return PopupMenuButton<String>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            state.user.fullName.isNotEmpty 
                                ? state.user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.user.fullName,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              state.user.roleName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Profil'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings_outlined),
                        title: Text('Pengaturan'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout, color: AppTheme.errorColor),
                        title: Text('Keluar', style: TextStyle(color: AppTheme.errorColor)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        // TODO: Show profile
                        break;
                      case 'settings':
                        // TODO: Show settings
                        break;
                      case 'logout':
                        _showLogoutDialog();
                        break;
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  String _getPageTitle() {
    final location = GoRouterState.of(context).fullPath;
    
    switch (location) {
      case '/dashboard':
        return 'Dashboard';
      case '/vehicles':
        return 'Kendaraan';
      case '/customers':
        return 'Customer';
      case '/transactions':
        return 'Transaksi';
      case '/spare-parts':
        return 'Spare Parts';
      case '/repairs':
        return 'Perbaikan';
      case '/suppliers':
        return 'Supplier';
      case '/users':
        return 'Pengguna';
      default:
        if (location?.contains('/vehicles') == true) return 'Kendaraan';
        if (location?.contains('/customers') == true) return 'Customer';
        if (location?.contains('/transactions') == true) return 'Transaksi';
        if (location?.contains('/spare-parts') == true) return 'Spare Parts';
        if (location?.contains('/repairs') == true) return 'Perbaikan';
        if (location?.contains('/suppliers') == true) return 'Supplier';
        if (location?.contains('/users') == true) return 'Pengguna';
        return 'POS Showroom';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}