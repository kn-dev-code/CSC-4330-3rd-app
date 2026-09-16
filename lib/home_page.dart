import 'package:flutter/material.dart';

class Plan {
  final String id;
  final String title;
  final String time;
  final IconData icon;

  const Plan({
    required this.id,
    required this.title,
    required this.time,
    required this.icon,
  });
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
    ),
    const Plan(
      id: '2',
      title: 'Design review',
      time: 'Tomorrow · 10:30 AM',
      icon: Icons.brush_rounded,
    ),
    const Plan(
      id: '3',
      title: 'Weekly standup',
      time: 'Friday · 9:00 AM',
      icon: Icons.forum_rounded,
    ),
  ];

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
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
              children: [
                _Header(now: now),
                const SizedBox(height: 28),
                Text(
                  _greeting(now),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C2B24),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A shared space to keep the team aligned.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF5C6B64),
                  ),
                ),
                const SizedBox(height: 28),
                _GlanceRow(planCount: _plans.length),
                const SizedBox(height: 32),
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
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: theme.colorScheme.primary,
                      tooltip: 'Add plan',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _UpcomingList(
                  plans: _plans,
                  onRemove: _removePlan,
                ),
                const SizedBox(height: 32),
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

class _GlanceRow extends StatelessWidget {
  const _GlanceRow({required this.planCount});

  final int planCount;

  @override
  Widget build(BuildContext context) {
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
            label: 'This week',
            value: '${planCount + 5}',
            hint: 'items',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
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

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({
    required this.plans,
    required this.onRemove,
  });

  final List<Plan> plans;
  final ValueChanged<Plan> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (plans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
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

    return Column(
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          Dismissible(
            key: Key(plans[i].id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete_rounded, color: Colors.red.shade700),
            ),
            onDismissed: (_) => onRemove(plans[i]),
            child: _UpcomingTile(
              plan: plans[i],
              onRemove: () => onRemove(plans[i]),
            ),
          ),
          if (i != plans.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.plan,
    required this.onRemove,
  });

  final Plan plan;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(plan.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C2B24),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan.time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C6B64),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFF5C6B64),
            tooltip: 'Remove plan',
            onPressed: onRemove,
          ),
        ],
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
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final plan = Plan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        time: _timeController.text.trim(),
        icon: _selectedIcon,
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
