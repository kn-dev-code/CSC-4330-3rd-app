import 'package:flutter/material.dart';

class TaskItem {
  final String title;
  final bool isCompleted;

  const TaskItem({
    required this.title,
    this.isCompleted = false,
  });

  TaskItem copyWith({String? title, bool? isCompleted}) {
    return TaskItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Plan {
  final String id;
  final String title;
  final String time;
  final IconData icon;
  final List<TaskItem> tasksNeeded;

  const Plan({
    required this.id,
    required this.title,
    required this.time,
    required this.icon,
    this.tasksNeeded = const [],
  });

  bool get isFinished =>
      tasksNeeded.isNotEmpty && tasksNeeded.every((task) => task.isCompleted);

  int get completedTasksCount =>
      tasksNeeded.where((task) => task.isCompleted).length;

  Plan copyWith({
    String? id,
    String? title,
    String? time,
    IconData? icon,
    List<TaskItem>? tasksNeeded,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      tasksNeeded: tasksNeeded ?? this.tasksNeeded,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Plan> _plans = [
    const Plan(
      id: '1',
      title: 'Sprint planning',
      time: 'Today · 2:00 PM',
      icon: Icons.flag_rounded,
      tasksNeeded: [
        TaskItem(title: 'Roadmap deck'),
        TaskItem(title: 'Sprint backlog'),
        TaskItem(title: 'Team capacity sheet'),
      ],
    ),
    const Plan(
      id: '2',
      title: 'Design review',
      time: 'Tomorrow · 10:30 AM',
      icon: Icons.brush_rounded,
      tasksNeeded: [
        TaskItem(title: 'Figma prototypes'),
        TaskItem(title: 'User feedback notes'),
      ],
    ),
    const Plan(
      id: '3',
      title: 'Weekly standup',
      time: 'Friday · 9:00 AM',
      icon: Icons.forum_rounded,
      tasksNeeded: [
        TaskItem(title: 'Status updates'),
        TaskItem(title: 'Blocker list'),
      ],
    ),
  ];

  int get _totalPendingTasks {
    return _plans.fold<int>(
      0,
      (sum, plan) =>
          sum + plan.tasksNeeded.where((task) => !task.isCompleted).length,
    );
  }

  void _addPlan(Plan plan) {
    setState(() {
      _plans.add(plan);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plan "${plan.title}" added'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removePlan(Plan plan) {
    final index = _plans.indexOf(plan);
    if (index == -1) return;

    setState(() {
      _plans.removeAt(index);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plan "${plan.title}" removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _plans.insert(index, plan);
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _reorderPlans(int oldIndex, int newIndex) {
    setState(() {
      final item = _plans.removeAt(oldIndex);
      _plans.insert(newIndex, item);
    });
  }

  void _toggleTask(Plan plan, int taskIndex) {
    final planIndex = _plans.indexOf(plan);
    if (planIndex == -1) return;

    final currentTasks = List<TaskItem>.from(_plans[planIndex].tasksNeeded);
    final currentTask = currentTasks[taskIndex];
    currentTasks[taskIndex] =
        currentTask.copyWith(isCompleted: !currentTask.isCompleted);

    final updatedPlan = _plans[planIndex].copyWith(tasksNeeded: currentTasks);
    final wasFinished = _plans[planIndex].isFinished;

    setState(() {
      _plans[planIndex] = updatedPlan;
    });

    if (!wasFinished && updatedPlan.isFinished) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Plan "${updatedPlan.title}" is finished!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAddPlanDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _AddPlanDialog(onAdd: _addPlan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final mediaQuery = MediaQuery.sizeOf(context);
    final isCompact = mediaQuery.width < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlanDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Plan'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(now: now),
                        const SizedBox(height: 24),
                        Text(
                          _greeting(now),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C2B24),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A shared space to keep the team aligned.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF5C6B64),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _GlanceRow(
                          planCount: _plans.length,
                          taskCount: _totalPendingTasks,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Coming up',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C2B24),
                              ),
                            ),
                            IconButton(
                              onPressed: _showAddPlanDialog,
                              icon:
                                  const Icon(Icons.add_circle_outline_rounded),
                              color: theme.colorScheme.primary,
                              tooltip: 'Add plan',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: _plans.isEmpty
                      ? const SliverToBoxAdapter(child: _EmptyPlansCard())
                      : SliverReorderableList(
                          itemCount: _plans.length,
                          onReorderItem: _reorderPlans,
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              elevation: 6,
                              color: Colors.transparent,
                              shadowColor: Colors.black26,
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            return Padding(
                              key: Key(plan.id),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UpcomingTile(
                                plan: plan,
                                index: index,
                                onRemove: () => _removePlan(plan),
                                onToggleTask: (taskIndex) =>
                                    _toggleTask(plan, taskIndex),
                              ),
                            );
                          },
                        ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    80,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C2B24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _TeamRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning, team';
    if (hour < 17) return 'Good afternoon, team';
    return 'Good evening, team';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        '${_weekday(now.weekday)}, ${now.month}/${now.day}/${now.year}';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_today_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C2B24),
              ),
            ),
            Text(
              dateLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5C6B64),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _weekday(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }
}

class _EmptyPlansCard extends StatelessWidget {
  const _EmptyPlansCard();

  static const _emptyShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _emptyShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 40,
            color: const Color(0xFF5C6B64).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming plans',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2B24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "+ Add Plan" to add your first plan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5C6B64),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlanceRow extends StatelessWidget {
  const _GlanceRow({
    required this.planCount,
    required this.taskCount,
  });

  final int planCount;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            children: [
              _GlanceCard(
                label: 'Plans',
                value: '$planCount',
                hint: 'active',
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GlanceCard(
                      label: 'Tasks',
                      value: '$taskCount',
                      hint: 'pending',
                      icon: Icons.view_week_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _GlanceCard(
                      label: 'Team',
                      value: '4',
                      hint: 'people',
                      icon: Icons.groups_rounded,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _GlanceCard(
                label: 'Plans',
                value: '$planCount',
                hint: 'active',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlanceCard(
                label: 'Tasks',
                value: '$taskCount',
                hint: 'pending',
                icon: Icons.view_week_rounded,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: _GlanceCard(
                label: 'Team',
                value: '4',
                hint: 'people',
                icon: Icons.groups_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlanceCard extends StatelessWidget {
  const _GlanceCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;

  static const _cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5C6B64),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C2B24),
              ),
              children: [
                TextSpan(
                  text: ' $hint',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C6B64),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatefulWidget {
  const _UpcomingTile({
    required this.plan,
    required this.index,
    required this.onRemove,
    required this.onToggleTask,
  });

  final Plan plan;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<int> onToggleTask;

  @override
  State<_UpcomingTile> createState() => _UpcomingTileState();
}

class _UpcomingTileState extends State<_UpcomingTile> {
  bool _isButtonHovered = false;
  bool _isExpanded = false;

  static const _tileShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;
    final hasTasks = plan.tasksNeeded.isNotEmpty;
    final showTasks = _isExpanded || plan.isFinished;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: plan.isFinished ? const Color(0xFFF4FBF7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: plan.isFinished
                ? const Color(0xFF81C784)
                : showTasks
                    ? theme.colorScheme.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: _tileShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: plan.isFinished
                        ? const Color(0xFFE8F5E9)
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    plan.isFinished ? Icons.check_circle_rounded : plan.icon,
                    color: plan.isFinished
                        ? const Color(0xFF2E7D32)
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: plan.isFinished
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF1C2B24),
                                decoration: plan.isFinished
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (plan.isFinished) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Finished',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C6B64),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasTasks && !plan.isFinished) ...[
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isButtonHovered = true),
                    onExit: (_) => setState(() => _isButtonHovered = false),
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: AnimatedScale(
                        scale: _isButtonHovered ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: showTasks
                                ? theme.colorScheme.primary
                                : _isButtonHovered
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.2)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _isButtonHovered
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.checklist_rounded,
                                size: 14,
                                color: showTasks
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${plan.completedTasksCount}/${plan.tasksNeeded.length} tasks',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: showTasks
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: showTasks
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFF5C6B64),
                  tooltip: 'Remove plan',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tasks needed:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C2B24),
                        ),
                      ),
                      if (plan.isFinished)
                        const Text(
                          'All tasks completed! 🎉',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < plan.tasksNeeded.length; i++)
                        _TaskChip(
                          task: plan.tasksNeeded[i],
                          onToggle: () => widget.onToggleTask(i),
                        ),
                    ],
                  ),
                ],
              ),
              crossFadeState: (showTasks && hasTasks)
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({
    required this.task,
    required this.onToggle,
  });

  final TaskItem task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.isCompleted;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFE8F5E9) : const Color(0xFFF0F4F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone ? const Color(0xFF81C784) : const Color(0xFFD3E0DC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDone
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: isDone ? const Color(0xFF2E7D32) : const Color(0xFF5C6B64),
            ),
            const SizedBox(width: 6),
            Text(
              task.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    isDone ? const Color(0xFF2E7D32) : const Color(0xFF1C2B24),
                fontSize: 12,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlanDialog extends StatefulWidget {
  const _AddPlanDialog({required this.onAdd});

  final ValueChanged<Plan> onAdd;

  @override
  State<_AddPlanDialog> createState() => _AddPlanDialogState();
}

class _AddPlanDialogState extends State<_AddPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: 'Today · 3:00 PM');
  final _tasksController = TextEditingController();
  IconData _selectedIcon = Icons.flag_rounded;

  static const _availableIcons = [
    (icon: Icons.flag_rounded, label: 'Planning'),
    (icon: Icons.brush_rounded, label: 'Design'),
    (icon: Icons.forum_rounded, label: 'Meeting'),
    (icon: Icons.code_rounded, label: 'Dev'),
    (icon: Icons.event_note_rounded, label: 'General'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _tasksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final tasksRaw = _tasksController.text.trim();
      final tasksNeeded = tasksRaw.isEmpty
          ? <TaskItem>[]
          : tasksRaw
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((t) => TaskItem(title: t))
              .toList();

      final plan = Plan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        time: _timeController.text.trim(),
        icon: _selectedIcon,
        tasksNeeded: tasksNeeded,
      );
      widget.onAdd(plan);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add New Plan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Plan title',
                  hintText: 'e.g. Code review',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time / Schedule',
                  hintText: 'e.g. Tomorrow · 2:00 PM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tasksController,
                decoration: const InputDecoration(
                  labelText: 'Tasks needed (comma-separated)',
                  hintText: 'e.g. Prepare slides, Review PR, Update docs',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Category Icon',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF5C6B64),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _availableIcons)
                    ChoiceChip(
                      label: Icon(item.icon, size: 18),
                      selected: _selectedIcon == item.icon,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedIcon = item.icon;
                          });
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add Plan'),
        ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow();

  static const members = [
    (name: 'You', color: Color(0xFF1F6F5B)),
    (name: 'Alex', color: Color(0xFF3D5A80)),
    (name: 'Jordan', color: Color(0xFFB5651D)),
    (name: 'Sam', color: Color(0xFF6B4C9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final member in members)
          SizedBox(
            width: 64,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: member.color,
                  child: Text(
                    member.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF1C2B24),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
