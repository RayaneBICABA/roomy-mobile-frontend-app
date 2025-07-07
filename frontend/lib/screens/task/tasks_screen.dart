import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../data/models/task_model.dart';
import '../../domain/entities/task.dart' as domain;
import '../../services/task_service.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with TickerProviderStateMixin {
  int _currentIndex = 1; // Tasks is active in bottom nav
  int _selectedTab = 0; // 0 = All, 1 = Pending, 2 = Completed
  bool _showAddTask = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TaskService _taskService = TaskService();

  List<domain.Task> _tasks = [];

  // Add controllers and state for add task modal
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  domain.TaskPriority _selectedPriority = domain.TaskPriority.low;
  DateTime? _selectedDueDate;

  // Add state for editing
  domain.Task? _editingTask;
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editDescriptionController = TextEditingController();
  domain.TaskPriority _editSelectedPriority = domain.TaskPriority.low;
  DateTime? _editSelectedDueDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  Future<void> _loadTasks() async {
    try {
      final tasksData = await _taskService.listGroupTasks();
      setState(() {
        _tasks = tasksData.map((taskJson) => TaskModel.fromJson(taskJson).toEntity()).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _editTitleController.dispose();
    _editDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTaskTabs(),
                          const SizedBox(height: 24),
                          _buildTaskList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showAddTask) _buildAddTaskModal(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => setState(() => _showAddTask = true),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryOrange,
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTabs() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? AppColors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0 ? AppColors.primaryBlue : AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? AppColors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1 ? AppColors.primaryBlue : AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 2 ? AppColors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 2 ? AppColors.primaryBlue : AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    final filteredTasks = _tasks.where((task) {
      if (_selectedTab == 0) {
        return true;
      } else if (_selectedTab == 1) {
        return task.status != domain.TaskStatus.completed;
      } else {
        return task.status == domain.TaskStatus.completed;
      }
    }).toList();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                for (var i = 0; i < filteredTasks.length; i++)
                  _buildTaskCard(filteredTasks[i], i * 200),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(domain.Task task, int delay) {
    Color priorityColor;
    switch (task.priority) {
      case domain.TaskPriority.high:
        priorityColor = AppColors.primaryOrange;
        break;
      case domain.TaskPriority.medium:
        priorityColor = Colors.amber;
        break;
      case domain.TaskPriority.low:
        priorityColor = Colors.green;
        break;
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                              decoration: task.status == domain.TaskStatus.completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: priorityColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            task.priority.toString().split('.').last.capitalize(),
                            style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Task',
                          onPressed: () {
                            setState(() {
                              _editingTask = task;
                              _editTitleController.text = task.title;
                              _editDescriptionController.text = task.description ?? '';
                              _editSelectedPriority = task.priority;
                              _editSelectedDueDate = task.dueDate;
                            });
                            showDialog(
                              context: context,
                              builder: (context) => _buildEditTaskModal(),
                            ).then((_) {
                              setState(() {
                                _editingTask = null;
                              });
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete Task',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Task'),
                                content: const Text('Are you sure you want to delete this task?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _deleteTask(task);
                            }
                          },
                        ),
                      ],
                    ),
                    if ((task.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        task.description!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          decoration: task.status == domain.TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.assignedTo.name,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (task.dueDate.year == DateTime.now().year &&
                                  task.dueDate.month == DateTime.now().month &&
                                  task.dueDate.day == DateTime.now().day)
                              ? "Today"
                              : DateFormat('MM/dd/yyyy').format(task.dueDate),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (task.status != domain.TaskStatus.completed) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await _markTaskDone(task);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: AppColors.primaryBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Mark Complete',
                                style: TextStyle(color: AppColors.primaryBlue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskModal() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showAddTask = false),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Task',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Task title'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Task description (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority'),
                  const SizedBox(height: 8),
                  DropdownButton<domain.TaskPriority>(
                    value: _selectedPriority,
                    items: domain.TaskPriority.values.map((priority) {
                      return DropdownMenuItem<domain.TaskPriority>(
                        value: priority,
                        child: Text(priority.toString().split('.').last.capitalize()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPriority = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Due date'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDueDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedDueDate == null
                            ? 'Select date'
                            : DateFormat('MM/dd/yyyy').format(_selectedDueDate!),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _showAddTask = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.primaryBlue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final title = _titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task title is required')),
                              );
                              return;
                            }
                            await _createTask(title, _descriptionController.text.trim(), _selectedPriority, _selectedDueDate ?? DateTime.now());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save Task',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditTaskModal() {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task title'),
            const SizedBox(height: 8),
            TextField(
              controller: _editTitleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter task title',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Task description (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _editDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter description',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Priority'),
            const SizedBox(height: 8),
            DropdownButton<domain.TaskPriority>(
              value: _editSelectedPriority,
              items: domain.TaskPriority.values.map((priority) {
                return DropdownMenuItem<domain.TaskPriority>(
                  value: priority,
                  child: Text(priority.toString().split('.').last.capitalize()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _editSelectedPriority = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Due date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _editSelectedDueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _editSelectedDueDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _editSelectedDueDate == null
                      ? 'Select date'
                      : DateFormat('MM/dd/yyyy').format(_editSelectedDueDate!),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final title = _editTitleController.text.trim();
            if (title.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task title is required')),
              );
              return;
            }
            if (_editingTask == null) return;
            final updates = {
              'title': title,
              'description': _editDescriptionController.text.trim(),
              'priority': _editSelectedPriority.toString().split('.').last,
              'dueDate': _editSelectedDueDate?.toIso8601String(),
            };
            await _updateTask(_editingTask!, updates);
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                index: 0,
                isSelected: _currentIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.check_circle_outline,
                selectedIcon: Icons.check_circle,
                label: 'Tasks',
                index: 1,
                isSelected: _currentIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.group_outlined,
                selectedIcon: Icons.group,
                label: 'Groups',
                index: 2,
                isSelected: _currentIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.attach_money_outlined,
                selectedIcon: Icons.attach_money,
                label: 'Finances',
                index: 3,
                isSelected: _currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _currentIndex = index;
        });
        _handleNavigation(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primaryBlue : AppColors.primaryBlue.withOpacity(0.4),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : AppColors.primaryBlue.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        // Already on Tasks
        break;
      case 2:
        Navigator.pushNamed(context, '/groups');
        break;
      case 3:
        Navigator.pushNamed(context, '/finances');
        break;
    }
  }

  Future<void> _deleteTask(domain.Task task) async {
    final success = await _taskService.deleteTask(task.id);
    if (success) {
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task')),
      );
    }
  }

  Future<void> _markTaskDone(domain.Task task) async {
    final success = await _taskService.markTaskDone(task.id);
    if (success) {
      setState(() {
        task.completed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task marked as done')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark task as done')),
      );
    }
  }

  Future<void> _createTask(String title, String description, domain.TaskPriority priority, DateTime dueDate) async {
    final success = await _taskService.createTask(title, dueDate, priority.toString().split('.').last);
    if (success) {
      _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task')),
      );
    }
  }

  Future<void> _updateTask(domain.Task task, Map<String, dynamic> updates) async {
    final success = await _taskService.updateTask(task.id, updates);
    if (success) {
      _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task')),
      );
    }
  }
}

// Add this extension for capitalizing strings
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
