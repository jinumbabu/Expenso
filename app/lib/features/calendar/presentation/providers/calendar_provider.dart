import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarSettings {
  final bool showBills;
  final bool showGoals;
  final bool showSalary;
  final bool showTransfers;
  final bool showInvestments;
  final bool showBudget;
  final bool showLoans;
  final bool showSubscriptions;
  final bool showRecurring;
  final bool showImportedData;
  final bool showAiInsights;
  final bool compactMode;
  final bool expandedTimeline;
  final bool animations;
  final String theme; // 'blue', 'cyan', 'purple', 'green'

  const CalendarSettings({
    this.showBills = true,
    this.showGoals = true,
    this.showSalary = true,
    this.showTransfers = true,
    this.showInvestments = true,
    this.showBudget = true,
    this.showLoans = true,
    this.showSubscriptions = true,
    this.showRecurring = true,
    this.showImportedData = true,
    this.showAiInsights = true,
    this.compactMode = false,
    this.expandedTimeline = false,
    this.animations = true,
    this.theme = 'blue',
  });

  CalendarSettings copyWith({
    bool? showBills,
    bool? showGoals,
    bool? showSalary,
    bool? showTransfers,
    bool? showInvestments,
    bool? showBudget,
    bool? showLoans,
    bool? showSubscriptions,
    bool? showRecurring,
    bool? showImportedData,
    bool? showAiInsights,
    bool? compactMode,
    bool? expandedTimeline,
    bool? animations,
    String? theme,
  }) {
    return CalendarSettings(
      showBills: showBills ?? this.showBills,
      showGoals: showGoals ?? this.showGoals,
      showSalary: showSalary ?? this.showSalary,
      showTransfers: showTransfers ?? this.showTransfers,
      showInvestments: showInvestments ?? this.showInvestments,
      showBudget: showBudget ?? this.showBudget,
      showLoans: showLoans ?? this.showLoans,
      showSubscriptions: showSubscriptions ?? this.showSubscriptions,
      showRecurring: showRecurring ?? this.showRecurring,
      showImportedData: showImportedData ?? this.showImportedData,
      showAiInsights: showAiInsights ?? this.showAiInsights,
      compactMode: compactMode ?? this.compactMode,
      expandedTimeline: expandedTimeline ?? this.expandedTimeline,
      animations: animations ?? this.animations,
      theme: theme ?? this.theme,
    );
  }
}

class CalendarState {
  final DateTime selectedDate;
  final String activeFilter;
  final String searchQuery;
  final List<DateTime> favoriteDates;
  final CalendarSettings settings;

  const CalendarState({
    required this.selectedDate,
    this.activeFilter = 'all',
    this.searchQuery = '',
    this.favoriteDates = const [],
    this.settings = const CalendarSettings(),
  });

  CalendarState copyWith({
    DateTime? selectedDate,
    String? activeFilter,
    String? searchQuery,
    List<DateTime>? favoriteDates,
    CalendarSettings? settings,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      favoriteDates: favoriteDates ?? this.favoriteDates,
      settings: settings ?? this.settings,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier()
      : super(CalendarState(selectedDate: DateTime.now()));

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setActiveFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFavoriteDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final currentList = List<DateTime>.from(state.favoriteDates);
    final exists = currentList.any((d) => d.year == normalizedDate.year && d.month == normalizedDate.month && d.day == normalizedDate.day);
    if (exists) {
      currentList.removeWhere((d) => d.year == normalizedDate.year && d.month == normalizedDate.month && d.day == normalizedDate.day);
    } else {
      currentList.add(normalizedDate);
    }
    state = state.copyWith(favoriteDates: currentList);
  }

  void updateSettings(CalendarSettings newSettings) {
    state = state.copyWith(settings: newSettings);
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});
