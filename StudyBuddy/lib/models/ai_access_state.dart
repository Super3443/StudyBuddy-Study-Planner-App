// Stores the current AI access details for the signed-in account.
class AiAccessState {
  final String proTier; // Stores the active plan: 'free', 'standard', or 'premium'
  final int dailyGenerationCount; // Tracks how many generations were used today
  final DateTime? lastGenerationDate; // Stores the date of the most recent generation
  final String status; // Tracks loading, ready or error states
  final String? message; // Stores an access-related error message

  // Creates the initial free access state before Firestore is checked.
  const AiAccessState({
    this.proTier = 'free', // Starts on the free plan
    this.dailyGenerationCount = 0, // Starts with no generations recorded
    this.lastGenerationDate, // Starts without a saved generation date
    this.status = 'idle', // Waits until the provider loads the account
    this.message, // Starts without an error message
  });

  // Returns the maximum daily generations allowed by the active plan.
  int get dailyLimit {
    switch (proTier) {
      case 'premium':
        return -1; // Allows unlimited generations
      case 'standard':
        return 25; // Allows twenty-five generations per day
      default:
        return 1; // Allows one free generation per day
    }
  }

  // Checks whether the last recorded generation happened today.
  bool get _hasGeneratedToday {
    if (lastGenerationDate == null) return false;

    // Converts the saved time into the device's local time zone.
    final savedDate = lastGenerationDate!.toLocal();

    // Gets the current date in the device's local time zone.
    final currentDate = DateTime.now();

    // Matches the calendar year, month and day without comparing the time.
    return savedDate.year == currentDate.year &&
        savedDate.month == currentDate.month &&
        savedDate.day == currentDate.day;
  }

  // Returns the number of generations already used today.
  int get _usedToday => _hasGeneratedToday ? dailyGenerationCount : 0;

  // Returns how many generations remain for the current day.
  int get remainingGenerations {
    // Returns a sentinel value when the plan has no daily cap.
    if (dailyLimit == -1) return -1;

    // Subtracts today's usage from the plan's daily limit.
    return (dailyLimit - _usedToday).clamp(0, dailyLimit);
  }

  // Allows generation only after access loads and the daily limit permits it.
  bool get canGenerateSchedule {
    if (status != 'ready') return false;

    // Premium accounts always have unlimited access.
    if (proTier == 'premium') return true;

    // Free and standard accounts must have remaining generations.
    return remainingGenerations > 0;
  }

  // Returns a display-friendly name for the active plan.
  String get tierDisplayName {
    switch (proTier) {
      case 'premium':
        return 'Premium';
      case 'standard':
        return 'Standard';
      default:
        return 'Free';
    }
  }

  // Creates an updated access state while preserving unchanged values.
  AiAccessState copyWith({
    String? proTier,
    int? dailyGenerationCount,
    DateTime? lastGenerationDate,
    String? status,
    String? message,
    bool clearMessage = false,
  }) {
    // Returns a new immutable state for Riverpod to publish.
    return AiAccessState(
      proTier: proTier ?? this.proTier, // Keeps the current plan when omitted
      dailyGenerationCount: dailyGenerationCount ??
          this.dailyGenerationCount, // Keeps the current count
      lastGenerationDate: lastGenerationDate ??
          this.lastGenerationDate, // Keeps the current generation date
      status: status ?? this.status, // Keeps the current loading status
      message: clearMessage
          ? null
          : message ?? this.message, // Clears or preserves the current message
    );
  }
}