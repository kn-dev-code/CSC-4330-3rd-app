import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                const _GlanceRow(),
                const SizedBox(height: 32),
                Text(
                  'Coming up',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C2B24),
                  ),
                ),
                const SizedBox(height: 12),
                const _UpcomingList(),
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
  const _GlanceRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _GlanceCard(
            label: 'Today',
            value: '3',
            hint: 'plans',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _GlanceCard(
            label: 'This week',
            value: '8',
            hint: 'items',
            icon: Icons.view_week_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
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
  const _UpcomingList();

  static const items = [
    (title: 'Sprint planning', time: 'Today · 2:00 PM', icon: Icons.flag_rounded),
    (title: 'Design review', time: 'Tomorrow · 10:30 AM', icon: Icons.brush_rounded),
    (title: 'Weekly standup', time: 'Friday · 9:00 AM', icon: Icons.forum_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _UpcomingTile(
            title: items[i].title,
            time: items[i].time,
            icon: items[i].icon,
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.title,
    required this.time,
    required this.icon,
  });

  final String title;
  final String time;
  final IconData icon;

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
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C2B24),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C6B64),
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
