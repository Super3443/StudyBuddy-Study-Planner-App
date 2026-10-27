// Contains all the information for each study task.
// Using a class makes the task data easier to pass between providers and the app's screens.
class StudyTask {
  // Firestore automatically gives each task document a unique ID.
  final String taskId;

  // Stores the Firebase UID of the user who owns this task.
  final String userId;

  // The name or description entered for the task.
  final String title;

  // The date and time when the task is planned to begin.
  final DateTime startDate;

  // The date and time when the task is planned to finish.
  final DateTime endDate;

  // Priority is stored as a number: 1 for Low, 2 for Medium and 3 for High.
  final int priority;

  // Keeps track of whether the user has completed the task.
  final bool isCompleted;

  // A tag is optional, so this value can be null when no tag was selected.
  final String? tagName;

  // Creates a StudyTask object using the values supplied by the app.
  const StudyTask({
    required this.taskId, // Stores the Firestore document ID
    required this.userId, // Stores the task owner's Firebase UID
    required this.title, // Stores the task title
    required this.startDate, // Stores when the task begins
    required this.endDate, // Stores when the task ends
    required this.priority, // Stores the task priority
    required this.isCompleted, // Stores the task completion status
    this.tagName, // Stores the optional task tag
  });

  // Converts a plain map of task fields into a StudyTask object.
  // The service handles all Firestore-specific conversions (like Timestamp to DateTime)
  // before passing the data here, keeping this model free from Firestore dependencies.
  static StudyTask fromMap(String id, Map<String, dynamic> data) {
    return StudyTask(
      // The document ID is passed in separately from the field data.
      taskId: id,

      // Default values prevent a missing field from crashing the app.
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',

      // The service already converted Firestore Timestamps into DateTime values,
      // so these fields arrive as DateTime objects ready to use.
      startDate: data['start_date'] ?? DateTime.now(),
      endDate: data['end_date'] ?? DateTime.now(),

      // Firestore may return a number as an int or double, so toInt()
      // makes sure the priority always matches the field type above.
      priority: (data['priority'] as num?)?.toInt() ?? 1,
      isCompleted: data['is_completed'] ?? false,

      // No default is needed because tasks are allowed to have no tag.
      tagName: data['tag_name'],
    );
  }
}