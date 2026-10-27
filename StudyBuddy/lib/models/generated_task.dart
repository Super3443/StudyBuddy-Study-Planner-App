// Contains the information for one generated study task
class GeneratedTask {
  // Stores the title displayed on the task card
  final String title;

  // Stores the date and time when the task begins
  final DateTime startDate;

  // Stores the date and time when the task ends
  final DateTime endDate;

  // Stores 1 for Low, 2 for Medium or 3 for High priority
  final int priority;

  // Stores the tag displayed on the task card
  final String tagName;

  // Creates a generated task using the required values
  const GeneratedTask({
    required this.title, // Stores the title shown on the task card
    required this.startDate, // Stores when the study task begins
    required this.endDate, // Stores when the study task finishes
    required this.priority, // Stores the selected task priority
    required this.tagName, // Stores Generated as the task tag
  });

  // Converts one JSON task into a GeneratedTask object
  static GeneratedTask fromJson(Map<String, dynamic> json) {
    // Returns the converted generated task
    return GeneratedTask(
      title: json['title'] as String, // Reads the generated task title
      startDate: DateTime.parse(
        json['start_date'] as String,
      ).toLocal(), // Converts the start date text into local time
      endDate: DateTime.parse(
        json['end_date'] as String,
      ).toLocal(), // Converts the end date text into local time
      priority: (json['priority'] as num)
          .toInt(), // Converts the priority into a whole number
      tagName:
          'Generated', // Sets Generated as the task tag
    );
  }
}
