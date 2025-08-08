import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../blocs/mechanic_repair_bloc.dart';
import '../services/mechanic_repair_service.dart';
import '../widgets/enhanced_repair_card.dart';
import '../widgets/repair_status_card.dart';

class MechanicRepairsPage extends StatefulWidget {
  const MechanicRepairsPage({super.key});

  @override
  State<MechanicRepairsPage> createState() => _MechanicRepairsPageState();
}

class _MechanicRepairsPageState extends State<MechanicRepairsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRepairs();
    _scrollController.addListener(_onScroll);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = _getStatusFromIndex(_tabController.index);
        });
        _loadRepairs(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _getStatusFromIndex(int index) {
    switch (index) {
      case 0:
        return null; // All
      case 1:
        return 'pending';
      case 2:
        return 'in_progress';
      case 3:
        return 'completed';
      default:
        return null;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreRepairs();
    }
  }

  Future<void> _loadRepairs({bool refresh = false}) async {
    context.read<MechanicRepairBloc>().add(
          LoadMechanicRepairs(
            status: _selectedStatus,
            refresh: refresh,
          ),
        );
  }

  Future<void> _loadMoreRepairs() async {
    final state = context.read<MechanicRepairBloc>().state;
    if (state is MechanicRepairsLoaded && state.hasMore) {
      context.read<MechanicRepairBloc>().add(
            LoadMechanicRepairs(
              status: _selectedStatus,
              page: state.currentPage + 1,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Repair Mekanik',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadRepairs(refresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pending'),
            Tab(text: 'Dikerjakan'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: BlocListener<MechanicRepairBloc, MechanicRepairState>(
        listener: (context, state) {
          if (state is MechanicRepairError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MechanicRepairOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Status Overview Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: BlocBuilder<MechanicRepairBloc, MechanicRepairState>(
                builder: (context, state) {
                  if (state is MechanicRepairsLoaded) {
                    return _buildStatusOverview(state.repairs);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Repairs List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRepairsList(),
                  _buildRepairsList(),
                  _buildRepairsList(),
                  _buildRepairsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverview(List<RepairWithItems> repairs) {
    final pendingCount =
        repairs.where((r) => r.repair.status == 'pending').length;
    final inProgressCount =
        repairs.where((r) => r.repair.status == 'in_progress').length;
    final completedCount =
        repairs.where((r) => r.repair.status == 'completed').length;

    return Row(
      children: [
        Expanded(
          child: RepairStatusCard(
            title: 'Pending',
            count: pendingCount,
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RepairStatusCard(
            title: 'Progress',
            count: inProgressCount,
            icon: Icons.build,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RepairStatusCard(
            title: 'Selesai',
            count: completedCount,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildRepairsList() {
    return BlocBuilder<MechanicRepairBloc, MechanicRepairState>(
      builder: (context, state) {
        if (state is MechanicRepairLoading &&
            (state is! MechanicRepairsLoaded)) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is MechanicRepairError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _loadRepairs(refresh: true),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (state is MechanicRepairsLoaded) {
          final filteredRepairs = _selectedStatus == null
              ? state.repairs
              : state.repairs
                  .where((r) => r.repair.status == _selectedStatus)
                  .toList();

          if (filteredRepairs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak Ada Perbaikan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada perbaikan yang perlu dikerjakan',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadRepairs(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredRepairs.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= filteredRepairs.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final repairWithItems = filteredRepairs[index];
                return EnhancedRepairCard(
                  repairWithItems: repairWithItems,
                  onTap: () =>
                      _navigateToRepairDetail(repairWithItems.repair.id),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _navigateToRepairDetail(int repairId) {
    context.go('/mechanic-repairs/$repairId');
  }
}
