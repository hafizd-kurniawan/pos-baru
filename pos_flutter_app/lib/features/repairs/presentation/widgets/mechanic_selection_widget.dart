import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/user.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../users/presentation/blocs/user_bloc.dart';

class MechanicSelectionWidget extends StatefulWidget {
  final Function(User) onMechanicSelected;

  const MechanicSelectionWidget({
    super.key,
    required this.onMechanicSelected,
  });

  @override
  State<MechanicSelectionWidget> createState() =>
      _MechanicSelectionWidgetState();
}

class _MechanicSelectionWidgetState extends State<MechanicSelectionWidget> {
  User? _selectedMechanic;
  List<User> _mechanics = [];

  @override
  void initState() {
    super.initState();
    _loadMechanics();
  }

  void _loadMechanics() {
    // Load all users (we'll filter on the frontend for now)
    context.read<UserBloc>().add(LoadUsers());
  }

  void _selectMechanic(User mechanic) {
    setState(() {
      _selectedMechanic = mechanic;
    });
    widget.onMechanicSelected(mechanic);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Mechanic *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UsersLoaded) {
              setState(() {
                // Filter users to get only mechanics (assuming roleName or roleId indicates mechanic)
                _mechanics = state.users
                    .whereType<User>()
                    .where((user) =>
                        user.roleName.toLowerCase().contains('mechanic'))
                    .toList();
              });
            } else if (state is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UserLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (_mechanics.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.engineering,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tidak ada mechanic tersedia',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadMechanics,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat Ulang'),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _mechanics.map((mechanic) {
                    final isSelected = _selectedMechanic?.id == mechanic.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.engineering,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          mechanic.fullName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mechanic.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            if (mechanic.phone != null)
                              Text(
                                mechanic.phone!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryColor,
                              )
                            : Icon(
                                Icons.radio_button_unchecked,
                                color: Colors.grey[400],
                              ),
                        onTap: () => _selectMechanic(mechanic),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        // Validation Error Display
        if (_selectedMechanic == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Pilih mechanic terlebih dahulu',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),

        // Selected Mechanic Summary
        if (_selectedMechanic != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mechanic yang Ditugaskan:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _selectedMechanic!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedMechanic!.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Mechanic',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
