// Defines the completion choices available in the task filter.
enum TaskCompletionFilter {
  all,
  incomplete,
  completed,
}

// Defines the two ways tasks can be ordered by their starting date.
enum TaskSortOrder {
  earliestFirst,
  latestFirst,
}

// Stores the filter values used when retrieving tasks from Cloud Firestore.
class TaskQuery {
  // Filters the list by one saved priority when a value is selected.
  final int? priority;

  // Filters the list by one saved subject tag when a value is selected.
  final String? tagName;

  // Filters the list by its completion status when it is not set to all.
  final TaskCompletionFilter completionFilter;

  // Filters tasks that start on or after the first selected date.
  final DateTime? startDate;

  // Filters tasks that start before the day after the last selected date.
  final DateTime? endDate;

  // Controls whether Firestore returns the earliest or latest tasks first.
  final TaskSortOrder sortOrder;

  // Creates an immutable set of values for a Firestore task query.
  const TaskQuery({
    this.priority,
    this.tagName,
    this.completionFilter = TaskCompletionFilter.all,
    this.startDate,
    this.endDate,
    this.sortOrder = TaskSortOrder.earliestFirst,
  });

  // Creates a copy after the user applies new filter values.
  TaskQuery copyWith({
    int? priority,
    String? tagName,
    TaskCompletionFilter? completionFilter,
    DateTime? startDate,
    DateTime? endDate,
    TaskSortOrder? sortOrder,
    bool clearPriority = false,
    bool clearTagName = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TaskQuery(
      priority: clearPriority ? null : priority ?? this.priority,
      tagName: clearTagName ? null : tagName ?? this.tagName,
      completionFilter: completionFilter ?? this.completionFilter,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  // Allows Riverpod to recognise equal filter values as the same query.
  bool operator ==(Object other) {
    return other is TaskQuery &&
        other.priority == priority &&
        other.tagName == tagName &&
        other.completionFilter == completionFilter &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.sortOrder == sortOrder;
  }

  @override
  // Keeps equal filter values grouped under the same Riverpod provider key.
  int get hashCode => Object.hash(
        priority,
        tagName,
        completionFilter,
        startDate,
        endDate,
        sortOrder,
      );
}
