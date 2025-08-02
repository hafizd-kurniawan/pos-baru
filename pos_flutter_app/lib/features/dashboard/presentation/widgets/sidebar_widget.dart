import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/user.dart';

class SidebarWidget extends StatelessWidget {
  final bool isCollapsed;
  final User? currentUser;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;
  
  const SidebarWidget({
    super.key,
    required this.isCollapsed,
    this.currentUser,
    required this.onToggleCollapse,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).fullPath;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 70 : 280,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  title: 'Dashboard',
                  route: AppRoutes.dashboard,
                  isSelected: currentLocation == AppRoutes.dashboard,
                  context: context,
                ),
                
                _buildNavItem(
                  icon: Icons.directions_car_outlined,
                  selectedIcon: Icons.directions_car,
                  title: 'Kendaraan',
                  route: AppRoutes.vehicles,
                  isSelected: currentLocation?.startsWith('/vehicles') == true,
                  context: context,
                ),
                
                _buildNavItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  title: 'Customer',
                  route: AppRoutes.customers,
                  isSelected: currentLocation?.startsWith('/customers') == true,
                  context: context,
                ),
                
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  title: 'Transaksi',
                  route: AppRoutes.transactions,
                  isSelected: currentLocation?.startsWith('/transactions') == true,
                  context: context,
                ),
                
                _buildNavItem(
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2,
                  title: 'Spare Parts',
                  route: AppRoutes.spareParts,
                  isSelected: currentLocation?.startsWith('/spare-parts') == true,
                  context: context,
                ),
                
                _buildNavItem(
                  icon: Icons.build_outlined,
                  selectedIcon: Icons.build,
                  title: 'Perbaikan',
                  route: AppRoutes.repairs,
                  isSelected: currentLocation?.startsWith('/repairs') == true,
                  context: context,
                ),
                
                _buildNavItem(
                  icon: Icons.business_outlined,
                  selectedIcon: Icons.business,
                  title: 'Supplier',
                  route: AppRoutes.suppliers,
                  isSelected: currentLocation?.startsWith('/suppliers') == true,
                  context: context,
                ),
                
                // Admin-only section
                if (currentUser?.roleName == 'admin') ...[
                  const SizedBox(height: 16),
                  if (!isCollapsed) _buildSectionTitle('Administrasi'),
                  
                  _buildNavItem(
                    icon: Icons.admin_panel_settings_outlined,
                    selectedIcon: Icons.admin_panel_settings,
                    title: 'Pengguna',
                    route: AppRoutes.users,
                    isSelected: currentLocation?.startsWith('/users') == true,
                    context: context,
                  ),
                ],
              ],
            ),
          ),
          
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.sidebarHover.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'POS Showroom',
                    style: TextStyle(
                      color: AppTheme.sidebarText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Management System',
                    style: TextStyle(
                      color: AppTheme.sidebarIcon,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String route,
    required bool isSelected,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.sidebarSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.sidebarIcon,
                  size: 22,
                ),
                
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.sidebarText,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.sidebarIcon,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.sidebarHover.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (currentUser != null && !isCollapsed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sidebarHover.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      currentUser!.fullName.isNotEmpty 
                          ? currentUser!.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser!.fullName,
                          style: TextStyle(
                            color: AppTheme.sidebarText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser!.roleName,
                          style: TextStyle(
                            color: AppTheme.sidebarIcon,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      size: 16,
                      color: AppTheme.errorColor,
                    ),
                    onPressed: onLogout,
                    tooltip: 'Keluar',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Collapse Toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleCollapse,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Icon(
                  isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
                  color: AppTheme.sidebarIcon,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}