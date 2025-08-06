import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/repair.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/new_repair_service.dart';
import '../widgets/repair_grid_card.dart';
import '../widgets/spare_parts_history_dialog.dart';
import 'mechanic_spare_parts_page.dart';

class NewRepairsPage extends StatefulWidget {
  const NewRepairsPage({super.key});

  @override
  State<NewRepairsPage> createState() => _NewRepairsPageState();
}

class _NewRepairsPageState extends State<NewRepairsPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final RepairService _repairService = RepairService();

  List<RepairOrder> _allRepairs = [];
  List<RepairOrder> _filteredRepairs = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';

  // Track vehicles that have been shown notification to prevent spam
  final Set<int> _notifiedVehicleIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadRepairs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    String newStatus;
    switch (_tabController.index) {
      case 0:
        newStatus = 'all';
        break;
      case 1:
        newStatus = 'pending';
        break;
      case 2:
        newStatus = 'in_progress';
        break;
      case 3:
        newStatus = 'completed';
        break;
      case 4:
        newStatus = 'cancelled';
        break;
      default:
        newStatus = 'all';
    }

    if (newStatus != _selectedStatus) {
      setState(() {
        _selectedStatus = newStatus;
      });
      _filterRepairs();
    }
  }

  Future<void> _loadRepairs() async {
    print('Loading repairs...');

    // Show loading only for initial load, not for refresh
    if (_allRepairs.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Try to get all repair orders including in_progress ones
      final repairs = await _repairService.getRepairOrders(
        page: 1,
        limit: 100, // Get more data to ensure we don't miss anything
      );

      print('Loaded ${repairs.length} repairs');
      for (var repair in repairs) {
        print(
            'Repair: ${repair.code}, Status: ${repair.status}, Vehicle: ${repair.vehicle?.displayName}, Vehicle Status: ${repair.vehicle?.status}');
      }

      // Also check for vehicles that need repair orders using backend API
      try {
        print('🚗 Checking for vehicles needing repair orders via API...');
        final vehiclesNeedingRepairs =
            await _repairService.getVehiclesNeedingRepairOrders();

        if (vehiclesNeedingRepairs.isNotEmpty && mounted) {
          // Only show notification for vehicles that haven't been notified yet
          final vehiclesToNotify = vehiclesNeedingRepairs
              .where((vehicle) => !_notifiedVehicleIds.contains(vehicle.id))
              .toList();

          if (vehiclesToNotify.isNotEmpty) {
            final vehicle = vehiclesToNotify
                .first; // Show notification for first new vehicle
            print(
                '⚠️ Found ${vehiclesToNotify.length} new vehicles needing repair orders');
            print(
                '   First vehicle: ${vehicle.brand?.name} ${vehicle.model} (ID: ${vehicle.id})');

            // Mark this vehicle as notified to prevent future notifications
            _notifiedVehicleIds.add(vehicle.id);

            // Show notification to user (only once per vehicle)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Vehicle ${vehicle.brand?.name} ${vehicle.model} (in_repair) needs repair order'),
                    backgroundColor: Colors.orange,
                    action: SnackBarAction(
                      label: 'CREATE',
                      textColor: Colors.white,
                      onPressed: () => _createRepairOrderForVehicle(vehicle),
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            });
          } else {
            print('✅ All vehicles needing repair orders have been notified');
          }
        } else {
          print('✅ All vehicles with in_repair status have repair orders');
        }

        // Check all vehicle IDs in repairs vs expected in_repair vehicles
        final repairVehicleIds = repairs.map((r) => r.vehicleId).toSet();
        print('📊 Repair orders exist for vehicles: $repairVehicleIds');
        print('🔍 Missing repair order for Vehicle ID 3 (status: in_repair)');
      } catch (e) {
        print('⚠️ Could not check vehicles needing repair orders: $e');
      }

      if (mounted) {
        setState(() {
          _allRepairs = repairs;
          _isLoading = false; // Set loading false here after successful load
          _filterRepairs();
        });
      }
    } catch (e) {
      print('Error loading repairs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // Also set false on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading repairs: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _filterRepairs() {
    print(
        '🔍 Filtering repairs. Total: ${_allRepairs.length}, Status: $_selectedStatus, Search: ${_searchController.text}');

    setState(() {
      if (_selectedStatus == 'all') {
        _filteredRepairs = _allRepairs;
      } else {
        _filteredRepairs = _allRepairs.where((repair) {
          final statusMatch =
              repair.status.toLowerCase() == _selectedStatus.toLowerCase();
          print(
              '🔍 Repair ${repair.code}: status="${repair.status}" -> match=$statusMatch');
          return statusMatch;
        }).toList();
      }

      print('📊 After status filter: ${_filteredRepairs.length} repairs');

      // Apply search filter if there's a search term
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        _filteredRepairs = _filteredRepairs
            .where((repair) =>
                repair.code.toLowerCase().contains(searchTerm) ||
                repair.description.toLowerCase().contains(searchTerm) ||
                (repair.vehicle?.licensePlate
                        ?.toLowerCase()
                        .contains(searchTerm) ??
                    false) ||
                (repair.vehicle?.model.toLowerCase().contains(searchTerm) ??
                    false) ||
                (repair.mechanic?.name.toLowerCase().contains(searchTerm) ??
                    false))
            .toList();
        print('🔍 After search filter: ${_filteredRepairs.length} repairs');
      }

      // Sort by creation date (newest first)
      _filteredRepairs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Final filtered repairs: ${_filteredRepairs.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Repair Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRepairs,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.addRepair),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(text: 'Semua (${_getCountByStatus('all')})'),
            Tab(text: 'Pending (${_getCountByStatus('pending')})'),
            Tab(text: 'Dikerjakan (${_getCountByStatus('in_progress')})'),
            Tab(text: 'Selesai (${_getCountByStatus('completed')})'),
            Tab(text: 'Batal (${_getCountByStatus('cancelled')})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan kode, deskripsi, plat nomor...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterRepairs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                _filterRepairs();
              },
            ),
          ),

          // Summary Stats
          _buildSummaryStats(),

          // Repairs List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _filteredRepairs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRepairs,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredRepairs.length,
                          itemBuilder: (context, index) {
                            final repair = _filteredRepairs[index];
                            return RepairGridCard(
                              repair: repair,
                              onTap: () => _viewRepairDetail(repair),
                              onComplete: () => _completeRepair(repair),
                              onViewDetail: () =>
                                  _showSparePartsHistory(repair),
                              onViewSpareParts: () =>
                                  _showAssignSparePartsDialog(repair),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    if (_allRepairs.isEmpty) return SizedBox.shrink();

    final totalRepairs = _allRepairs.length;
    final pendingCount =
        _allRepairs.where((r) => r.status.toLowerCase() == 'pending').length;
    final inProgressCount = _allRepairs
        .where((r) => r.status.toLowerCase() == 'in_progress')
        .length;
    final completedCount =
        _allRepairs.where((r) => r.status.toLowerCase() == 'completed').length;

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child:
                _buildStatCard('Total', totalRepairs.toString(), Colors.blue),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
                'Pending', pendingCount.toString(), Colors.orange),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
                'Progress', inProgressCount.toString(), Colors.purple),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
                'Selesai', completedCount.toString(), Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _selectedStatus == 'all'
                ? 'Belum ada repair order'
                : 'Belum ada repair order dengan status ${_getStatusText(_selectedStatus)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap tombol + untuk membuat repair order baru',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  int _getCountByStatus(String status) {
    if (status == 'all') return _allRepairs.length;
    return _allRepairs
        .where((r) => r.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  void _viewRepairDetail(RepairOrder repair) {
    // Navigate to repair detail page
    context.go('${AppRoutes.repairs}/${repair.id}');
  }

  void _showSparePartsHistory(RepairOrder repair) async {
    try {
      // Show loading indicator with proper context management
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading spare parts history...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Fetch detailed repair data with spare parts
      final detailedRepair = await _repairService.getRepairDetail(repair.id);

      // Close loading dialog safely
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (detailedRepair == null) {
        throw Exception('Failed to load repair details');
      }

      print(
          'Detailed repair loaded with ${detailedRepair.spareParts?.length ?? 0} spare parts');

      // Show history dialog and wait for result
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => SparePartsHistoryDialog(repair: detailedRepair),
        );

        // If spare part was returned, refresh the repair list
        if (result == true && mounted) {
          _loadRepairs();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data refreshed after spare part return'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _showSparePartsHistory: $e');

      // Close loading dialog if still open
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (popError) {
          print('Error closing loading dialog: $popError');
        }
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAssignSparePartsDialog(RepairOrder repair) async {
    if (repair.vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Navigate directly to spare parts page
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MechanicSparePartsPage(
            vehicle: repair.vehicle!,
            repair: repair, // RepairOrder can be used as Repair due to typedef
          ),
        ),
      );

      if (result != null && mounted) {
        // Parts assigned/updated, refresh the list
        _loadRepairs();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repair updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _completeRepair(RepairOrder repair) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CompleteRepairDialog(repair: repair),
    );

    if (result != null && mounted) {
      // Use a more robust loading indicator approach
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          content: Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Completing repair...',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        // Perform the completion
        await _repairService
            .completeRepairOrder(
          repair.id,
          notes: result['notes'],
        )
            .timeout(
          Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout - please try again');
          },
        );

        // Close loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Repair completed successfully!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Reload data
        if (mounted) {
          await _loadRepairs();
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _createRepairOrderForVehicle(Vehicle vehicle) async {
    try {
      print('🔧 Creating repair order for Vehicle ID ${vehicle.id}...');

      final request = RepairOrderCreateRequest(
        vehicleId: vehicle.id,
        mechanicId: 1, // Default mechanic
        description: 'Auto-created repair order for in_repair vehicle',
        estimatedCost: 100000, // Default estimated cost
        notes: 'Created automatically for vehicle with in_repair status',
      );

      final newRepair = await _repairService.createRepairOrder(request);

      print('✅ Successfully created repair order: ${newRepair.code}');

      // Remove from notified list since repair order now exists
      _notifiedVehicleIds.remove(vehicle.id);

      // Reload repairs to show the new order (without auto-detection)
      _refreshRepairsOnly();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Repair order ${newRepair.code} created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating repair order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating repair order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Refresh repairs data without running auto-detection to prevent notification spam
  Future<void> _refreshRepairsOnly() async {
    try {
      final repairs = await _repairService.getRepairOrders(
        page: 1,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _allRepairs = repairs;
          _filterRepairs();
        });
      }
    } catch (e) {
      print('Error refreshing repairs: $e');
    }
  }
}

class _CompleteRepairDialog extends StatefulWidget {
  final RepairOrder repair;

  const _CompleteRepairDialog({required this.repair});

  @override
  State<_CompleteRepairDialog> createState() => _CompleteRepairDialogState();
}

class _CompleteRepairDialogState extends State<_CompleteRepairDialog> {
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Text('Selesaikan Reparasi'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kode Reparasi:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${widget.repair.code}'),
                SizedBox(height: 8),
                Text('Estimasi Biaya:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp ${widget.repair.estimatedCost.toStringAsFixed(0)}'),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Biaya Perbaikan:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Biaya akan dihitung otomatis berdasarkan spare parts yang digunakan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Catatan Penyelesaian (Opsional)',
              border: OutlineInputBorder(),
              hintText: 'Catatan tambahan mengenai hasil reparasi...',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            // No form validation needed anymore since we removed required fields
            Navigator.of(context).pop({
              'notes': _notesController.text.isNotEmpty
                  ? _notesController.text
                  : null,
            });
          },
          child: Text('Selesaikan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
