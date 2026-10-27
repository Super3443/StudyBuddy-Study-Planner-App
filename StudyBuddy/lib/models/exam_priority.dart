// Contains the information entered for one exam
class ExamPriority {
  // Stores the name entered for the exam
  final String name;

  // Stores the date when the exam takes place
  final DateTime examDate;

  // Stores the difficulty as a number from 1 to 10
  final int difficulty;

  // Creates an exam entry using the required values
  const ExamPriority({
    required this.name, // Stores the exam name entered in the form
    required this.examDate, // Stores the selected exam date
    required this.difficulty, // Stores the difficulty slider value
  });

  // Creates a copy with any updated exam values
  ExamPriority copyWith({
    String? name, // Allows the exam name to be replaced
    DateTime? examDate, // Allows the exam date to be replaced
    int? difficulty, // Allows the difficulty to be replaced
  }) {
    // Returns a new exam entry with the selected values
    return ExamPriority(
      name: name ?? this.name, // Keeps the current name when none is supplied
      examDate: examDate ?? this.examDate, // Keeps the current date when none is supplied
      difficulty: difficulty ?? this.difficulty, // Keeps the current difficulty when none is supplied
    );
  }
}
