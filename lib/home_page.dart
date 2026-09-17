import 'package:flutter/material.dart';

import 'top_notification.dart';

class TaskItem {
  final String title;
  final bool isCompleted;
  final String? assigneeId;

  const TaskItem({
    required this.title,
    this.isCompleted = false,
    this.assigneeId,
  });

  TaskItem copyWith({
    String? title,
    bool? isCompleted,
    String? assigneeId,
    bool clearAssignee = false,
  }) {
    return TaskItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      assigneeId: clearAssignee ? null : assigneeId ?? this.assigneeId,
    );
  }
}

class Plan {
  final String id;
  final String title;
  final String time;
  final IconData icon;
  final List<TaskItem> tasksNeeded;
  final String? hostId;
  final List<String> attendeeIds;

  const Plan({
    required this.id,
    required this.title,
    required this.time,
    required this.icon,
    this.tasksNeeded = const [],
    this.hostId,
    this.attendeeIds = const [],
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
    String? hostId,
    List<String>? attendeeIds,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      tasksNeeded: tasksNeeded ?? this.tasksNeeded,
      hostId: hostId ?? this.hostId,
      attendeeIds: attendeeIds ?? this.attendeeIds,
    );
  }
}

class TeamMember {
  final String id;
  final String name;
  final String? role;
  final Color color;

  const TeamMember({
    required this.id,
    required this.name,
    this.role,
    required this.color,
  });
}

enum HomeCategory { events, tasks, team }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.isDark = false,
    this.onThemeToggle,
    this.onPlansChanged,
    this.onMembersChanged,
  });

  final bool isDark;
  final VoidCallback? onThemeToggle;
  final ValueChanged<List<Plan>>? onPlansChanged;
  final ValueChanged<List<TeamMember>>? onMembersChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TeamMember> _members = [];
  HomeCategory _category = HomeCategory.events;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyPlans());
  }

  void _notifyPlans() => widget.onPlansChanged?.call(List.unmodifiable(_plans));
  void _notifyMembers() =>
      widget.onMembersChanged?.call(List.unmodifiable(_members));

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
      _category = HomeCategory.events;
    });
    _notifyPlans();
    TopNotification.show(
      context,
      message: 'Plan "${plan.title}" added',
      icon: Icons.event_available_rounded,
    );
  }

  void _removePlan(Plan plan) {
    final index = _plans.indexOf(plan);
    if (index == -1) return;

    setState(() {
      _plans.removeAt(index);
    });
    _notifyPlans();

    TopNotification.show(
      context,
      message: 'Plan "${plan.title}" removed',
      icon: Icons.delete_outline_rounded,
      duration: const Duration(seconds: 4),
      actionLabel: 'Undo',
      onAction: () {
        setState(() => _plans.insert(index, plan));
        _notifyPlans();
      },
    );
  }

  void _reorderPlans(int oldIndex, int newIndex) {
    setState(() {
      final item = _plans.removeAt(oldIndex);
      _plans.insert(newIndex, item);
    });
    _notifyPlans();
  }

  void _toggleTask(Plan plan, int taskIndex) {
    final planIndex = _plans.indexOf(plan);
    if (planIndex == -1) return;

    final currentTasks = List<TaskItem>.from(_plans[planIndex].tasksNeeded);
    final currentTask = currentTasks[taskIndex];
    currentTasks[taskIndex] = currentTask.copyWith(
      isCompleted: !currentTask.isCompleted,
    );

    final updatedPlan = _plans[planIndex].copyWith(tasksNeeded: currentTasks);
    final wasFinished = _plans[planIndex].isFinished;

    setState(() {
      _plans[planIndex] = updatedPlan;
    });
    _notifyPlans();

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
      builder: (context) => _AddPlanDialog(onAdd: _addPlan, members: _members),
    );
  }

  void _showAddMemberDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _AddMemberDialog(
        onAdd: (name, role) {
          const colors = [
            Color(0xFF287C66),
            Color(0xFF3D5A80),
            Color(0xFFB5651D),
            Color(0xFF6B4C9A),
          ];
          setState(() {
            _members.add(
              TeamMember(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: name,
                role: role,
                color: colors[_members.length % colors.length],
              ),
            );
          });
          _notifyMembers();
          TopNotification.show(
            context,
            message: '$name added to the team',
            icon: Icons.person_add_alt_1_rounded,
          );
        },
      ),
    );
  }

  void _removeMember(TeamMember member) {
    setState(() => _members.removeWhere((item) => item.id == member.id));
    _notifyMembers();
    TopNotification.show(
      context,
      message: '${member.name} removed from the team',
      icon: Icons.person_remove_alt_1_rounded,
    );
  }

  void _assignTask(Plan plan, int taskIndex, String? memberId) {
    final planIndex = _plans.indexOf(plan);
    if (planIndex == -1) return;
    final tasks = List<TaskItem>.from(plan.tasksNeeded);
    tasks[taskIndex] = tasks[taskIndex].copyWith(
      assigneeId: memberId,
      clearAssignee: memberId == null,
    );
    setState(() => _plans[planIndex] = plan.copyWith(tasksNeeded: tasks));
    _notifyPlans();
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
                        _Header(
                          now: now,
                          isDark: widget.isDark,
                          onThemeToggle: widget.onThemeToggle,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _greeting(now),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A shared space to keep the team aligned.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _GlanceRow(
                          planCount: _plans.length,
                          taskCount: _totalPendingTasks,
                          memberCount: _members.length,
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<HomeCategory>(
                          segments: const [
                            ButtonSegment(
                              value: HomeCategory.events,
                              icon: Icon(Icons.event_note_rounded),
                              label: Text('Events'),
                            ),
                            ButtonSegment(
                              value: HomeCategory.tasks,
                              icon: Icon(Icons.checklist_rounded),
                              label: Text('Tasks'),
                            ),
                            ButtonSegment(
                              value: HomeCategory.team,
                              icon: Icon(Icons.groups_rounded),
                              label: Text('Team'),
                            ),
                          ],
                          selected: {_category},
                          showSelectedIcon: false,
                          onSelectionChanged: (value) =>
                              setState(() => _category = value.first),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              switch (_category) {
                                HomeCategory.events => 'Events',
                                HomeCategory.tasks => 'Tasks by event',
                                HomeCategory.team => '',
                              },
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (_category == HomeCategory.events)
                              IconButton(
                                onPressed: _showAddPlanDialog,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
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
                if (_category == HomeCategory.events)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
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
                                  members: _members,
                                  index: index,
                                  onRemove: () => _removePlan(plan),
                                  onToggleTask: (taskIndex) =>
                                      _toggleTask(plan, taskIndex),
                                ),
                              );
                            },
                          ),
                  ),
                if (_category != HomeCategory.events)
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
                          if (_category == HomeCategory.team)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Team',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Text(
                                        '${_members.length} members',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_members.isNotEmpty)
                                  FilledButton.tonalIcon(
                                    onPressed: _showAddMemberDialog,
                                    icon: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                    ),
                                    label: const Text('Add member'),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          if (_category == HomeCategory.team &&
                              _members.isEmpty)
                            _EmptyTeamCard(onAdd: _showAddMemberDialog),
                          if (_category == HomeCategory.team &&
                              _members.isNotEmpty)
                            _TeamRow(
                              members: _members,
                              plans: _plans,
                              onRemove: _removeMember,
                            ),
                          if (_category == HomeCategory.tasks)
                            _TasksOverview(
                              plans: _plans,
                              members: _members,
                              onToggleTask: _toggleTask,
                              onAssignTask: _assignTask,
                            ),
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
  const _Header({required this.now, required this.isDark, this.onThemeToggle});

  final DateTime now;
  final bool isDark;
  final VoidCallback? onThemeToggle;

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Plan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                dateLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onThemeToggle,
          tooltip: isDark ? 'Use light mode' : 'Use dark mode',
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
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
    BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _emptyShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming plans',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "+ Add Plan" to add your first plan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    required this.memberCount,
  });

  final int planCount;
  final int taskCount;
  final int memberCount;

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
                  Expanded(
                    child: _GlanceCard(
                      label: 'Team',
                      value: '$memberCount',
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
            Expanded(
              child: _GlanceCard(
                label: 'Team',
                value: '$memberCount',
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
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: ' $hint',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
    required this.members,
    required this.index,
    required this.onRemove,
    required this.onToggleTask,
  });

  final Plan plan;
  final List<TeamMember> members;
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
    BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;
    final hostName = _memberName(widget.members, plan.hostId);
    final hasTasks = plan.tasksNeeded.isNotEmpty;
    final showTasks = _isExpanded || plan.isFinished;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: plan.isFinished
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
              : theme.colorScheme.surface,
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
                                    : theme.colorScheme.onSurface,
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
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (plan.hostId != null ||
                          plan.attendeeIds.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (hostName != null) 'Host: $hostName',
                            if (plan.attendeeIds.isNotEmpty)
                              '${plan.attendeeIds.length} participant${plan.attendeeIds.length == 1 ? '' : 's'}',
                          ].join(' · '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  )
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
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
                  color: theme.colorScheme.onSurfaceVariant,
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
                          color: theme.colorScheme.onSurface,
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
  const _TaskChip({required this.task, required this.onToggle});

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
          color: isDone
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
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
              color: isDone
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              task.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDone
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
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
  const _AddPlanDialog({required this.onAdd, required this.members});

  final ValueChanged<Plan> onAdd;
  final List<TeamMember> members;

  @override
  State<_AddPlanDialog> createState() => _AddPlanDialogState();
}

class _AddPlanDialogState extends State<_AddPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: 'Today · 3:00 PM');
  final _tasksController = TextEditingController();
  IconData _selectedIcon = Icons.flag_rounded;
  String? _hostId;
  final Set<String> _attendeeIds = {};

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
        hostId: _hostId,
        attendeeIds: _attendeeIds.toList(),
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
              DropdownButtonFormField<String>(
                initialValue: _hostId,
                decoration: const InputDecoration(
                  labelText: 'Event host (optional)',
                  prefixIcon: Icon(Icons.record_voice_over_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final member in widget.members)
                    DropdownMenuItem(
                      value: member.id,
                      child: Text(member.name),
                    ),
                ],
                onChanged: widget.members.isEmpty
                    ? null
                    : (value) => setState(() => _hostId = value),
              ),
              if (widget.members.isEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Add team members first to assign a host.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (widget.members.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Participants (optional)',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final member in widget.members)
                      FilterChip(
                        label: Text(member.name),
                        selected: _attendeeIds.contains(member.id),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _attendeeIds.add(member.id)
                              : _attendeeIds.remove(member.id),
                        ),
                      ),
                  ],
                ),
              ],
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
                  color: theme.colorScheme.onSurfaceVariant,
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
        FilledButton(onPressed: _submit, child: const Text('Add Plan')),
      ],
    );
  }
}

class _EmptyTeamCard extends StatelessWidget {
  const _EmptyTeamCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        Icon(
          Icons.group_add_outlined,
          size: 42,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 10),
        const Text(
          'No team members yet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Add your first member to start assigning work.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add member'),
        ),
      ],
    ),
  );
}

class _TasksOverview extends StatelessWidget {
  const _TasksOverview({
    required this.plans,
    required this.members,
    required this.onToggleTask,
    required this.onAssignTask,
  });
  final List<Plan> plans;
  final List<TeamMember> members;
  final void Function(Plan plan, int taskIndex) onToggleTask;
  final void Function(Plan plan, int taskIndex, String? memberId) onAssignTask;

  @override
  Widget build(BuildContext context) {
    final hasTasks = plans.any((plan) => plan.tasksNeeded.isNotEmpty);
    if (!hasTasks) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No tasks have been added to an event yet.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        for (final plan in plans.where((plan) => plan.tasksNeeded.isNotEmpty))
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(
                plan.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                plan.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${plan.completedTasksCount}/${plan.tasksNeeded.length} complete',
              ),
              children: [
                for (var index = 0; index < plan.tasksNeeded.length; index++)
                  ListTile(
                    leading: Checkbox(
                      value: plan.tasksNeeded[index].isCompleted,
                      onChanged: (_) => onToggleTask(plan, index),
                    ),
                    title: Text(plan.tasksNeeded[index].title),
                    subtitle: Text(
                      _memberName(
                            members,
                            plan.tasksNeeded[index].assigneeId,
                          ) ??
                          'Unassigned',
                    ),
                    trailing: PopupMenuButton<String?>(
                      tooltip: 'Assign task',
                      icon: const Icon(Icons.person_add_alt_rounded),
                      onSelected: (value) => onAssignTask(plan, index, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        for (final member in members)
                          PopupMenuItem(
                            value: member.id,
                            child: Text(member.name),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.members,
    required this.plans,
    required this.onRemove,
  });

  final List<TeamMember> members;
  final List<Plan> plans;
  final ValueChanged<TeamMember> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 520
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final member in members)
              Container(
                width: cardWidth,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: member.color,
                      child: Text(
                        member.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.role ?? 'No role assigned',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_assignmentCount(member.id, plans)} assignments',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (member.id != 'you')
                      IconButton(
                        onPressed: () => onRemove(member),
                        tooltip: 'Remove ${member.name}',
                        icon: const Icon(Icons.close_rounded, size: 19),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.onAdd});
  final void Function(String name, String? role) onAdd;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _role;

  static const roles = [
    'Designer',
    'Developer',
    'Project Manager',
    'Researcher',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onAdd(_nameController.text.trim(), _role);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    icon: const Icon(Icons.person_add_alt_1_rounded),
    title: const Text('Add team member'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter member name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                for (final role in roles)
                  DropdownMenuItem(value: role, child: Text(role)),
              ],
              onChanged: (value) => setState(() => _role = value),
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
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add member'),
      ),
    ],
  );
}

String? _memberName(List<TeamMember> members, String? id) {
  if (id == null) return null;
  for (final member in members) {
    if (member.id == id) return member.name;
  }
  return null;
}

int _assignmentCount(String memberId, List<Plan> plans) {
  var count = 0;
  for (final plan in plans) {
    if (plan.hostId == memberId) count++;
    if (plan.attendeeIds.contains(memberId)) count++;
    count += plan.tasksNeeded
        .where((task) => task.assigneeId == memberId)
        .length;
  }
  return count;
}
