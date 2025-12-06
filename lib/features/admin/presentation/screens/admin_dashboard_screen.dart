import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/dependency_injection.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminCubit>()..loadDashboardData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/settings');
              },
            ),
          ],
        ),
        body: BlocBuilder<AdminCubit, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AdminError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AdminCubit>().loadDashboardData();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is AdminLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<AdminCubit>().loadDashboardData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Courses',
                              value: state.courses.length.toString(),
                              icon: Icons.school,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: 'Pending Orders',
                              value: state.pendingOrdersCount.toString(),
                              icon: Icons.pending,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Orders',
                              value: state.orders.length.toString(),
                              icon: Icons.shopping_cart,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: 'Revenue',
                              value: '\$${state.totalRevenue.toStringAsFixed(2)}',
                              icon: Icons.attach_money,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Add Course Button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/add-course');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Course'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/manage-orders');
                              },
                              icon: const Icon(Icons.list_alt),
                              label: const Text('Manage Orders'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pending Orders Section
                      Text(
                        'Pending Orders',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...state.orders
                          .where((order) => order.status == 'pending')
                          .map((order) => Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.shopping_bag),
                                  ),
                                  title: Text(order.courseTitle),
                                  subtitle: Text(
                                    '${order.userEmail}\n\$${order.coursePrice.toStringAsFixed(2)}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () async {
                                      await context.read<AdminCubit>().approveOrder(order.id);
                                      if (context.mounted) {
                                        context.read<AdminCubit>().loadDashboardData();
                                      }
                                    },
                                  ),
                                  isThreeLine: true,
                                ),
                              ))
                          .toList(),
                      if (state.orders.where((order) => order.status == 'pending').isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No pending orders'),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // All Courses Section
                      Text(
                        'All Courses',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...state.courses.map((course) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.video_library, size: 32),
                              ),
                              title: Text(course.title),
                              subtitle: Text(
                                '\$${course.price.toStringAsFixed(2)} • ${course.lessonsCount} lessons',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.list, color: Colors.purple),
                                    onPressed: () {
                                      context.push('/manage-lessons', extra: course);
                                    },
                                    tooltip: 'Manage Lessons',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      context.push('/edit-course', extra: course);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text('Delete Course'),
                                          content: Text('Are you sure you want to delete "${course.title}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await context.read<AdminCubit>().deleteCourse(course.id);
                                                if (dialogContext.mounted) {
                                                  Navigator.pop(dialogContext);
                                                }
                                                if (context.mounted) {
                                                  context.read<AdminCubit>().loadDashboardData();
                                                }
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )),
                      if (state.courses.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No courses yet'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
