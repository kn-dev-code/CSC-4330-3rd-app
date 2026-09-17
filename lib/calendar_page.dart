import 'package:flutter/material.dart';

import 'home_page.dart';

enum PlannerView { daily, weekly }

typedef PlannerEvent = ({
  String title,
  String time,
  String? host,
  int hour,
  int day,
  Color color,
});

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    this.plans = const [],
    this.members = const [],
    this.isDark = false,
    this.onThemeToggle,
  });
  final List<Plan> plans;
  final List<TeamMember> members;
  final bool isDark;
  final VoidCallback? onThemeToggle;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  PlannerView _view = PlannerView.daily;
  late DateTime _date;
  List<PlannerEvent> get events => [
    for (var index = 0; index < widget.plans.length; index++)
      (
        title: widget.plans[index].title,
        time: widget.plans[index].time,
        host: _memberName(widget.plans[index].hostId),
        hour: _parseHour(widget.plans[index].time),
        day: _parseDay(widget.plans[index].time, _date.weekday - 1),
        color: const [
          Color(0xFF1F6F5B),
          Color(0xFF3D5A80),
          Color(0xFFB5651D),
          Color(0xFF6B4C9A),
        ][index % 4],
      ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  DateTime get _weekStart => _date.subtract(Duration(days: _date.weekday - 1));

  String? _memberName(String? id) {
    if (id == null) return null;
    for (final member in widget.members) {
      if (member.id == id) return member.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _Header(
              date: _date,
              isDark: widget.isDark,
              onThemeToggle: widget.onThemeToggle,
              onToday: () => setState(() => _date = _onlyDate(DateTime.now())),
            ),
            const SizedBox(height: 22),
            SegmentedButton<PlannerView>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFF1F6F5B),
                selectedForegroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: PlannerView.daily,
                  icon: Icon(Icons.view_day_outlined),
                  label: Text('Daily'),
                ),
                ButtonSegment(
                  value: PlannerView.weekly,
                  icon: Icon(Icons.view_week_outlined),
                  label: Text('Weekly'),
                ),
              ],
              selected: {_view},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _view = value.first),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _view == PlannerView.daily
                  ? _DailySchedule(
                      key: ValueKey('daily-$_date'),
                      date: _date,
                      weekStart: _weekStart,
                      events: events,
                      onSelect: (date) => setState(() => _date = date),
                      onStep: (amount) => setState(
                        () => _date = _date.add(Duration(days: amount)),
                      ),
                    )
                  : _WeeklySchedule(
                      key: ValueKey('weekly-$_weekStart'),
                      weekStart: _weekStart,
                      selectedDate: _date,
                      events: events,
                      onStep: (amount) => setState(
                        () => _date = _date.add(Duration(days: amount)),
                      ),
                      onSelect: (date) => setState(() {
                        _date = date;
                        _view = PlannerView.daily;
                      }),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.date,
    required this.onToday,
    required this.isDark,
    this.onThemeToggle,
  });
  final DateTime date;
  final VoidCallback onToday;
  final bool isDark;
  final VoidCallback? onThemeToggle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendar',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
            ),
            const SizedBox(height: 3),
            Text(
              '${_month(date.month)} ${date.year}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      FilledButton.tonalIcon(
        onPressed: onToday,
        icon: const Icon(Icons.today_rounded),
        label: const Text('Today'),
      ),
      const SizedBox(width: 8),
      IconButton.filledTonal(
        onPressed: onThemeToggle,
        tooltip: isDark ? 'Use light mode' : 'Use dark mode',
        icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      ),
    ],
  );
}

class _DailySchedule extends StatelessWidget {
  const _DailySchedule({
    super.key,
    required this.date,
    required this.weekStart,
    required this.events,
    required this.onSelect,
    required this.onStep,
  });
  final DateTime date;
  final DateTime weekStart;
  final List<PlannerEvent> events;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final index = date.difference(weekStart).inDays;
    final dayEvents = events.where((event) => event.day == index).toList();
    return Column(
      children: [
        _DateNavigator(
          label: '${_weekday(date.weekday)}, ${_month(date.month)} ${date.day}',
          onPrevious: () => onStep(-1),
          onNext: () => onStep(1),
        ),
        const SizedBox(height: 12),
        _DayStrip(date: date, weekStart: weekStart, onSelect: onSelect),
        const SizedBox(height: 18),
        _Banner(
          title: _isToday(date)
              ? 'Today'
              : '${_weekday(date.weekday)}, ${_month(date.month)} ${date.day}',
          subtitle: 'Your schedule at a glance',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          decoration: _panelDecoration(context),
          child: Column(
            children: [
              for (var hour = 8; hour <= 17; hour++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 58,
                      child: Text(
                        _hour(hour),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718078),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 58),
                        padding: const EdgeInsets.only(bottom: 9),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE7E3DA)),
                          ),
                        ),
                        child: Column(
                          children: [
                            for (final event in dayEvents.where(
                              (event) => event.hour == hour,
                            ))
                              _EventCard(event: event),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklySchedule extends StatelessWidget {
  const _WeeklySchedule({
    super.key,
    required this.weekStart,
    required this.selectedDate,
    required this.events,
    required this.onStep,
    required this.onSelect,
  });
  final DateTime weekStart;
  final DateTime selectedDate;
  final List<PlannerEvent> events;
  final ValueChanged<int> onStep;
  final ValueChanged<DateTime> onSelect;
  @override
  Widget build(BuildContext context) {
    final end = weekStart.add(const Duration(days: 6));
    return Column(
      children: [
        _DateNavigator(
          label:
              '${_month(weekStart.month)} ${weekStart.day} – ${_month(end.month)} ${end.day}',
          onPrevious: () => onStep(-7),
          onNext: () => onStep(7),
          weekly: true,
        ),
        const SizedBox(height: 14),
        const _Banner(title: 'This week', subtitle: '3 upcoming events'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _panelDecoration(context),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var day = 0; day < 7; day++)
                  _WeekDay(
                    date: weekStart.add(Duration(days: day)),
                    selected: _sameDay(
                      selectedDate,
                      weekStart.add(Duration(days: day)),
                    ),
                    events: events.where((event) => event.day == day).toList(),
                    onTap: () => onSelect(weekStart.add(Duration(days: day))),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.weekly = false,
  });
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool weekly;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E1D8)),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: weekly ? 'Previous week' : 'Previous day',
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: weekly ? 'Next week' : 'Next day',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.date,
    required this.weekStart,
    required this.onSelect,
  });
  final DateTime date;
  final DateTime weekStart;
  final ValueChanged<DateTime> onSelect;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 7; i++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 5),
            child: _DayButton(
              date: weekStart.add(Duration(days: i)),
              selected: _sameDay(date, weekStart.add(Duration(days: i))),
              onTap: () => onSelect(weekStart.add(Duration(days: i))),
            ),
          ),
        ),
    ],
  );
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.date,
    required this.selected,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? const Color(0xFF1F6F5B)
        : Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              _weekday(date.weekday).substring(0, 1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white70 : const Color(0xFF718078),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.date,
    required this.selected,
    required this.events,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final List<PlannerEvent> events;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 116,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F0EC) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                _weekday(date.weekday).substring(0, 3).toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF66736D),
                ),
              ),
              const SizedBox(height: 7),
              CircleAvatar(
                radius: 18,
                backgroundColor: _isToday(date)
                    ? const Color(0xFF1F6F5B)
                    : const Color(0xFFF0EEE8),
                foregroundColor: _isToday(date)
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                child: Text('${date.day}'),
              ),
              const SizedBox(height: 12),
              for (final event in events)
                _EventCard(event: event, compact: true),
              if (events.isEmpty)
                const SizedBox(
                  height: 88,
                  child: Center(
                    child: Text(
                      'Free',
                      style: TextStyle(fontSize: 12, color: Color(0xFF98A19C)),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.event_available_rounded,
            color: Color(0xFF1F6F5B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer
                      .withValues(alpha: .75),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.compact = false});
  final PlannerEvent event;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 7),
    padding: EdgeInsets.all(compact ? 9 : 11),
    decoration: BoxDecoration(
      color: event.color.withValues(alpha: compact ? .16 : .11),
      border: Border(left: BorderSide(color: event.color, width: 4)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          event.time,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (event.host != null) ...[
          const SizedBox(height: 3),
          Text(
            'Host: ${event.host}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    ),
  );
}

BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFE5E1D8)),
  boxShadow: const [
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
  ],
);
DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
bool _isToday(DateTime date) => _sameDay(date, DateTime.now());
String _hour(int hour) =>
    '${hour > 12 ? hour - 12 : hour} ${hour >= 12 ? 'PM' : 'AM'}';
String _weekday(int day) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][day - 1];
String _month(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

int _parseDay(String value, int fallback) {
  final lower = value.toLowerCase();
  if (lower.contains('today')) return fallback;
  if (lower.contains('tomorrow')) return (fallback + 1) % 7;
  const days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  for (var index = 0; index < days.length; index++) {
    if (lower.contains(days[index])) return index;
  }
  return fallback;
}

int _parseHour(String value) {
  final match = RegExp(
    r'(\d{1,2})(?::\d{2})?\s*(AM|PM)',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return 9;
  var hour = int.parse(match.group(1)!);
  final period = match.group(2)!.toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return hour;
}
