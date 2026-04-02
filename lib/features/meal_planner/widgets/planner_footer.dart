import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../recipes/models/recipe_model.dart';
import '../view_models/meal_planner_view_model.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class RecipeDragPayload {
  const RecipeDragPayload({
    required this.recipe,
    required this.missingIngredients,
  });

  final Recipe recipe;
  final List<String> missingIngredients;
}

class PlannerFooter extends StatelessWidget {
  const PlannerFooter({
    super.key,
    required this.currentIndex,
    this.showBottomNav = true,
  });

  final int currentIndex;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    final Widget calendarBar = const _WeeklyScheduleBar();

    if (!showBottomNav) {
      return SafeArea(top: false, child: calendarBar);
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          calendarBar,
          BottomNavBar(currentIndex: currentIndex),
        ],
      ),
    );
  }
}

class _WeeklyScheduleBar extends StatelessWidget {
  const _WeeklyScheduleBar();

  @override
  Widget build(BuildContext context) {
    final MealPlannerViewModel viewModel = context
        .watch<MealPlannerViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(top: BorderSide(color: Color(0x1A000000))),
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => viewModel.showPreviousWeek(),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Tuần trước',
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  _weekLabel(viewModel.visibleWeekStart),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: () => viewModel.showNextWeek(),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Tuần sau',
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: viewModel.visibleWeekDates
                  .map(
                    (DateTime date) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _WeekDayTile(
                        date: date,
                        selected: _sameDay(date, viewModel.selectedDate),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _weekLabel(DateTime start) {
    final DateTime end = start.add(const Duration(days: 6));
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} - '
        '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
  }
}

class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({required this.date, required this.selected});

  final DateTime date;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final MealPlannerViewModel viewModel = context.read<MealPlannerViewModel>();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DragTarget<RecipeDragPayload>(
      onWillAcceptWithDetails: (DragTargetDetails<RecipeDragPayload> details) {
        viewModel.selectDate(date);
        return true;
      },
      onAcceptWithDetails: (DragTargetDetails<RecipeDragPayload> details) async {
        final bool added = await viewModel.addRecipeToDate(
          date,
          details.data.recipe,
          missingIngredients: details.data.missingIngredients,
        );
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added
                  ? 'Đã thêm món ăn ${details.data.recipe.title} vào ngày ${_formatFullDate(date)} thành công'
                  : 'Món ăn này đã có trong ngày ${_formatFullDate(date)}.',
            ),
          ),
        );
      },
      builder:
          (
            BuildContext context,
            List<RecipeDragPayload?> candidateData,
            List<dynamic> rejectedData,
          ) {
            final bool active = candidateData.isNotEmpty;
            final Color background = active
                ? colorScheme.primaryContainer
                : selected
                ? colorScheme.primary.withAlpha(31)
                : colorScheme.surfaceContainerHighest;

            return InkWell(
              onTap: () => viewModel.selectDate(date),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 66,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? colorScheme.primary : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _weekdayShort(date.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDayMonth(date),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  static String _weekdayShort(int weekday) {
    const List<String> weekdays = <String>[
      'CN',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
    ];
    return weekdays[weekday % 7];
  }

  static String _formatDayMonth(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  static String _formatFullDate(DateTime date) {
    const List<String> weekdays = <String>[
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];

    final String weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
