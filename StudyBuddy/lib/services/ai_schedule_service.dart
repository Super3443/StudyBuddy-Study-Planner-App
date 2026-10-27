import 'dart:async'; // Provides TimeoutException for slow network requests
import 'dart:convert'; // Converts Dart maps and Groq JSON strings
import 'package:http/http.dart' as http; // Sends HTTP requests to the Groq API
import 'package:mbap_project/models/exam_priority.dart'; // Contains the entered exam details
import 'package:mbap_project/models/generated_task.dart'; // Contains temporary generated task details
import 'package:mbap_project/models/study_task.dart'; // Contains existing Firestore task details

// Describes an AI schedule problem using a message that can be shown in the app.
class AiScheduleException implements Exception {
  final String message; // Stores the readable error message

  // Creates an exception with the reason why schedule generation failed.
  const AiScheduleException(this.message);

  @override
  String toString() => message; // Returns only the readable message
}

// Sends exam information to Groq and checks the returned study schedule
class AiScheduleService {
  // Stores the Groq chat completions address
  static final Uri _endpoint = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions', // Groq schedule request address
  );

  // Stores the Groq model used for schedule generation
  static const String _model = 'openai/gpt-oss-120b'; // Groq model identifier

  // Stores the Groq API key used
  static const String _apiKey = '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';

  // Sets the maximum number of generated tasks
  static const int _maximumTaskCount = 30; // Internal response safety limit

  // Sets the required break between generated tasks
  static const Duration _generatedTaskGap = Duration(
    minutes: 15, // Keeps at least 15 minutes between generated tasks
  );

  // Sets the maximum time allowed for each request
  static const Duration _requestTimeout = Duration(
    seconds: 60, // Allows enough time for the model to prepare a full schedule
  );

  // Generates a temporary schedule without saving or changing Firestore tasks.
  Future<List<GeneratedTask>> generateSchedule({
    required List<ExamPriority> exams, // Exams that need revision tasks
    required List<StudyTask> existingTasks, // Saved times that must remain free
    // Accepts a fixed time when one is supplied
    DateTime? requestTime,
  }) async {
    // Uses one timestamp for every time check
    final currentTime = (requestTime ?? DateTime.now()).toLocal();

    // Stops before the request when no API key was supplied to the app.
    if (_apiKey.trim().isEmpty) {
      throw const AiScheduleException(
        'The Groq API key is missing. Run the app with GROQ_API_KEY.', // Explains how to supply the missing key
      );
    }

    // Checks the exam inputs before sending the request
    _validateExams(
      exams: exams, // Passes every entered exam into the validation method
      currentTime: currentTime, // Prevents schedules for exams that have passed
    );

    // Builds the request body with the schedule schema
    final requestBody = _buildRequestBody(
      exams: exams, // Includes exam names, dates and full difficulty values
      existingTasks: existingTasks, // Includes occupied Firestore time periods
      currentTime: currentTime, // Tells Groq the earliest valid starting time
    );

    try {
      // Sends the schedule request and waits for Groq's structured response.
      final response = await http
          .post(
            _endpoint, // Sends the request to the Groq chat endpoint
            headers: {
              'Authorization':
                  'Bearer $_apiKey', // Authenticates the Groq request
              'Content-Type':
                  'application/json', // Identifies the encoded request body
            },
            body: jsonEncode(
              requestBody,
            ), // Converts the Dart map into JSON text
          )
          .timeout(
            _requestTimeout,
          ); // Cancels requests that exceed the time limit

      // Converts non-success responses into a useful message for the screen.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiScheduleException(
          _readGroqError(
            statusCode:
                response.statusCode, // Helps identify common API failures
            responseBody:
                response.body, // Reads Groq's error details when available
          ),
        );
      }

      // Extracts the JSON string stored in the first Groq response choice.
      final scheduleJson = _readScheduleContent(response.body);

      // Converts and checks every returned task before the app displays it.
      return _parseAndValidateSchedule(
        scheduleJson:
            scheduleJson, // Contains the model's structured task result
        exams: exams, // Provides the valid exam names and deadlines
        existingTasks: existingTasks, // Provides occupied time periods
        currentTime:
            currentTime, // Prevents tasks from starting before the request
      );
    } on TimeoutException {
      // Uses a clear message when the request exceeds the allowed waiting time.
      throw const AiScheduleException(
        'AI took too long to generate the schedule. Please try again.', // Suggests a safe retry
      );
    } on http.ClientException {
      // Uses a clear message when the device cannot reach the Groq service.
      throw const AiScheduleException(
        'The schedule could not connect to AI. Check your internet connection.', // Explains the likely network issue
      );
    } on FormatException {
      // Handles malformed response JSON or invalid date-time text safely.
      throw const AiScheduleException(
        'AI returned an invalid schedule. Please generate it again.', // Keeps raw parsing errors away from the screen
      );
    }
  }

  // Checks that every entered exam can be used to build a future schedule.
  void _validateExams({
    required List<ExamPriority> exams, // Exam entries supplied by the AI screen
    required DateTime currentTime, // Time when schedule generation started
  }) {
    // A schedule cannot be generated without at least one exam.
    if (exams.isEmpty) {
      throw const AiScheduleException(
        'Add at least one exam before generating a schedule.', // Guides the next action
      );
    }

    // Tracks lower-case names so repeated exam names can be rejected.
    final examNames = <String>{}; // Stores each unique normalised exam name

    // Checks each exam before it is included in the Groq prompt.
    for (final exam in exams) {
      // Removes surrounding spaces before checking the visible exam name.
      final examName = exam.name.trim(); // Uses the same name sent to Groq

      // Prevents an unnamed exam from reaching the model.
      if (examName.isEmpty) {
        throw const AiScheduleException(
          'Every exam needs a name before generating a schedule.', // Identifies the missing value
        );
      }

      // Keeps the difficulty on the full scale selected by the user.
      if (exam.difficulty < 1 || exam.difficulty > 10) {
        throw AiScheduleException(
          '$examName must have a difficulty from 1 to 10.', // Identifies the invalid exam entry
        );
      }

      // Prevents Groq from scheduling revision after the exam has started.
      if (!exam.examDate.isAfter(currentTime)) {
        throw AiScheduleException(
          '$examName must have a future exam date.', // Identifies the expired exam entry
        );
      }

      // Uses lower-case text so capitalisation cannot hide a duplicate name.
      final normalisedName = examName
          .toLowerCase(); // Creates a stable comparison value

      // Avoids ambiguous task-to-exam matching in the returned schedule.
      if (!examNames.add(normalisedName)) {
        throw AiScheduleException(
          'Each exam needs a different name. $examName was added more than once.', // Explains the duplicate
        );
      }
    }
  }

  // Creates the Groq request body and its strict JSON output rules.
  Map<String, dynamic> _buildRequestBody({
    required List<ExamPriority> exams, // Validated exam inputs
    required List<StudyTask> existingTasks, // Existing occupied task times
    required DateTime currentTime, // Earliest time a generated task may start
  }) {
    // Converts every exam into plain JSON-friendly values for the prompt.
    final examData = exams.map((exam) {
      return {
        'name': exam.name.trim(), // Sends the exact exam name shown in the app
        'exam_date': exam.examDate.toIso8601String(), // Sends the exam deadline
        'difficulty':
            exam.difficulty, // Sends the complete 1 to 10 difficulty value
      };
    }).toList(); // Finishes the JSON list of exams

    // Converts existing tasks into occupied periods without changing them.
    final occupiedTimes = existingTasks.map((task) {
      return {
        'start_date': task.startDate
            .toLocal()
            .toIso8601String(), // Sends the occupied start time
        'end_date': task.endDate
            .toLocal()
            .toIso8601String(), // Sends the occupied end time
      };
    }).toList(); // Finishes the JSON list of occupied periods

    // Stores the scheduling rules sent to the model
    const systemInstructions =
        'Create a practical study schedule from the supplied exams. '
        'Use the full difficulty value from 1 to 10 when deciding how many '
        'tasks each exam needs, how long they should last, and how important '
        'they are. Choose priority 1, 2, or 3 separately for every task. '
         'Include the exact related exam name inside every task title. '
         'Schedule at least one task for every exam. Tasks may occur at any '
         'time of day, including later today. Never place a task in the past, '
         'on or after its exam date, or over an occupied time. Generated tasks '
         'must not overlap and need a gap of at least 15 minutes. Spread tasks '
         'across the available time before each exam instead of placing all '
         'tasks within the first few days. For an exam more than 14 days away, '
         'create at least two tasks, with at least one task before the final '
         'seven days and at least one task during the final seven days. Use '
         'higher difficulty values to create more frequent or longer revision '
         'tasks while keeping the complete response below 30 tasks. Return '
         'only the structured response.';

    // Combines the changing scheduling data into one readable user message.
    final userInstructions = jsonEncode({
      'current_local_time': currentTime
          .toIso8601String(), // Anchors all future time checks
      'exams': examData, // Supplies names, deadlines and difficulty values
      'occupied_times': occupiedTimes, // Supplies unavailable Firestore periods
    });

    // Returns the OpenAI-compatible request format accepted by Groq.
    return {
      'model': _model, // Sets the Groq model
      'temperature': 0.2, // Reduces variation between generated schedules
      'messages': [
        {
          'role': 'system', // Gives the model its fixed scheduling behaviour
          'content': systemInstructions, // Supplies every scheduling rule
        },
        {
          'role': 'user', // Supplies data that changes for each generation
          'content': userInstructions, // Includes exams and occupied times
        },
      ],
      'response_format': {
        'type': 'json_schema', // Requests schema-constrained JSON output
        'json_schema': {
          'name': 'study_schedule', // Gives the response schema a stable name
          'strict': true, // Requires the response to follow every schema field
          'schema': {
            'type': 'object', // Wraps all generated tasks in one JSON object
            'properties': {
              'tasks': {
                'type': 'array', // Returns the complete schedule as a list
                'items': {
                  'type': 'object', // Describes one generated study task
                  'properties': {
                    'exam_name': {
                      'type': 'string', // Identifies the task's related exam
                    },
                    'title': {
                      'type': 'string', // Supplies the normal task card title
                    },
                    'start_date': {
                      'type': 'string', // Supplies an ISO 8601 starting time
                    },
                    'end_date': {
                      'type': 'string', // Supplies an ISO 8601 ending time
                    },
                    'priority': {
                      'type':
                          'integer', // Uses the existing numeric task priority
                      'enum': [
                        1,
                        2,
                        3,
                      ], // Restricts priority to Low, Medium or High
                    },
                  },
                  'required': [
                    'exam_name', // Requires a reliable task-to-exam link
                    'title', // Requires visible task card text
                    'start_date', // Requires the task's starting time
                    'end_date', // Requires the task's ending time
                    'priority', // Requires the numeric task priority
                  ],
                  'additionalProperties':
                      false, // Rejects unexpected task fields
                },
              },
            },
            'required': ['tasks'], // Requires the schedule task list
            'additionalProperties':
                false, // Rejects unexpected top-level fields
          },
        },
      },
    };
  }

  // Reads the structured schedule string from Groq's response wrapper.
  String _readScheduleContent(String responseBody) {
    // Converts the outer Groq response into a Dart map.
    final decodedResponse = jsonDecode(
      responseBody,
    ); // Parses the response JSON text

    // Rejects a response that does not contain the expected top-level object.
    if (decodedResponse is! Map<String, dynamic>) {
      throw const FormatException('The AI response was not an object.');
    }

    // Reads the list that normally contains one generated response choice.
    final choices =
        decodedResponse['choices']; // Retrieves the AI choices field

    // Rejects a successful response that contains no model choice.
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('The AI response contained no choices.');
    }

    // Reads the first response choice because the request only asks for one.
    final firstChoice = choices.first; // Retrieves the first generated choice

    // Rejects a choice that is not represented as a JSON object.
    if (firstChoice is! Map<String, dynamic>) {
      throw const FormatException('The AI choice was not an object.');
    }

    // Reads the assistant message stored inside the selected choice.
    final message = firstChoice['message']; // Retrieves the response message

    // Rejects a choice that does not contain the expected message object.
    if (message is! Map<String, dynamic>) {
      throw const FormatException('The AI response contained no message.');
    }

    // Reads the strict JSON text produced by the selected Groq model.
    final content = message['content']; // Retrieves the generated schedule text

    // Rejects missing or blank content before trying to decode it.
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('The AI response contained no schedule.');
    }

    return content; // Passes the structured JSON text to local validation
  }

  // Converts the structured result and verifies every scheduling rule locally.
  List<GeneratedTask> _parseAndValidateSchedule({
    required String scheduleJson, // Strict JSON text returned by Groq
    required List<ExamPriority> exams, // Valid exam names and dates
    required List<StudyTask> existingTasks, // Occupied Firestore task periods
    required DateTime currentTime, // Earliest allowed task start time
  }) {
    // Converts the structured schedule text into a Dart object.
    final decodedSchedule = jsonDecode(
      scheduleJson,
    ); // Parses the inner JSON response

    // Rejects a result that does not match the schema's outer object.
    if (decodedSchedule is! Map<String, dynamic>) {
      throw const FormatException('The generated schedule was not an object.');
    }

    // Reads the generated task list from the schema's required field.
    final taskData =
        decodedSchedule['tasks']; // Retrieves the structured tasks list

    // Rejects a missing, empty or unexpectedly large schedule.
    if (taskData is! List ||
        taskData.isEmpty ||
        taskData.length > _maximumTaskCount) {
      throw const AiScheduleException(
        'AI did not return a usable number of study tasks. Please try again.', // Covers empty and oversized plans
      );
    }

    // Maps normalised exam names back to the original validated exam entries.
    final examsByName = {
      for (final exam in exams)
        exam.name.trim().toLowerCase():
            exam, // Creates one reliable lookup per exam
    };

    // Tracks which exams received at least one generated revision task.
    final scheduledExamNames =
        <String>{}; // Stores normalised matched exam names

    // Groups validated tasks under their related exam names
    final generatedTasksByExam =
        <String, List<GeneratedTask>>{}; // Stores tasks for each exam

    // Stores validated task objects before sorting and gap checks.
    final generatedTasks =
        <GeneratedTask>[]; // Starts the temporary schedule list

    // Validates and converts every structured task returned by Groq.
    for (final taskValue in taskData) {
      // Rejects a task that is not represented as a JSON object.
      if (taskValue is! Map<String, dynamic>) {
        throw const FormatException('A generated task was not an object.');
      }

      // Reads and normalises the exam link returned for this task.
      final examNameValue =
          taskValue['exam_name']; // Retrieves the related exam name

      // Rejects an exam link with an unexpected value type.
      if (examNameValue is! String) {
        throw const FormatException('A generated task had no exam name.');
      }

      // Uses lower-case text to match the input regardless of capitalisation.
      final normalisedExamName = examNameValue.trim().toLowerCase();

      // Finds the original exam so its exact name and deadline can be checked.
      final exam =
          examsByName[normalisedExamName]; // Matches this task to one exam

      // Rejects tasks invented for an exam the user did not enter.
      if (exam == null) {
        throw const AiScheduleException(
          'AI created a task for an unknown exam. Please generate the schedule again.', // Rejects invented exam data
        );
      }

      // Converts the task fields into a GeneratedTask object
      final generatedTask = GeneratedTask.fromJson(taskValue);

      // Prevents blank task titles from reaching the preview.
      if (generatedTask.title.trim().isEmpty) {
        throw const AiScheduleException(
          'AI created a task without a title. Please generate the schedule again.', // Rejects unusable card text
        );
      }

      // Ensures the visible title clearly identifies its related exam.
      if (!generatedTask.title.toLowerCase().contains(normalisedExamName)) {
        throw AiScheduleException(
          'A generated task title did not include ${exam.name}. Please try again.', // Identifies the mismatched title
        );
      }

      // Prevents tasks from starting before schedule generation began.
      if (generatedTask.startDate.isBefore(currentTime)) {
        throw const AiScheduleException(
          'AI created a task in the past. Please generate the schedule again.', // Rejects expired start times
        );
      }

      // Ensures each task starts before its ending time
      if (!generatedTask.endDate.isAfter(generatedTask.startDate)) {
        throw const AiScheduleException(
          'AI created a task with an invalid time range. Please try again.', // Rejects zero or negative durations
        );
      }

      // Keeps every revision task strictly before its related exam date.
      if (!generatedTask.endDate.isBefore(exam.examDate)) {
        throw AiScheduleException(
          'A generated task for ${exam.name} was not before the exam.', // Identifies the missed deadline
        );
      }

      // Checks that the priority remains between 1 and 3
      if (generatedTask.priority < 1 || generatedTask.priority > 3) {
        throw const AiScheduleException(
          'AI created a task with an invalid priority. Please try again.', // Protects the normal task schema
        );
      }

      // Prevents the new task from using time occupied by any saved task.
      final overlapsExistingTask = existingTasks.any((existingTask) {
        return _periodsOverlap(
          firstStart:
              generatedTask.startDate, // Uses the generated starting time
          firstEnd: generatedTask.endDate, // Uses the generated ending time
          secondStart: existingTask.startDate, // Uses the saved starting time
          secondEnd: existingTask.endDate, // Uses the saved ending time
        );
      });

      // Rejects the complete response when one generated task has a conflict.
      if (overlapsExistingTask) {
        throw const AiScheduleException(
          'AI created a task that overlaps an existing task. Please try again.', // Protects saved task times
        );
      }

      // Records that the related exam received at least one study task.
      scheduledExamNames.add(normalisedExamName); // Marks this exam as covered

      // Creates the exam task list when it does not exist
      generatedTasksByExam.putIfAbsent(
        normalisedExamName, // Uses the normalised exam name as the key
        () => <GeneratedTask>[], // Creates an empty task list
      );

      // Adds the task to its related exam list
      generatedTasksByExam[normalisedExamName]!.add(
        generatedTask, // Stores the validated generated task
      );

      // Adds the fully validated task to the temporary plan.
      generatedTasks.add(generatedTask); // Keeps the task out of Firestore
    }

    // Makes sure the model did not leave any entered exam without revision.
    if (scheduledExamNames.length != exams.length) {
      throw const AiScheduleException(
        'AI did not create a study task for every exam. Please try again.', // Rejects an incomplete exam plan
      );
    }

    // Sorts the tasks so preview cards and gap checks use date order.
    generatedTasks.sort((firstTask, secondTask) {
      return firstTask.startDate.compareTo(
        secondTask.startDate,
      ); // Orders earliest to latest
    });

    // Checks that longer schedules cover the available revision period
    _validateTaskDistribution(
      exams: exams, // Supplies every entered exam
      generatedTasksByExam: generatedTasksByExam, // Supplies tasks for each exam
      currentTime: currentTime, // Supplies the schedule starting time
    );

    // Compares neighbouring tasks after sorting to enforce the required break.
    for (var index = 1; index < generatedTasks.length; index++) {
      // Reads the task immediately before the current sorted task.
      final previousTask = generatedTasks[index - 1]; // Earlier generated task

      // Reads the current task being checked against its earlier neighbour.
      final currentTask = generatedTasks[index]; // Later generated task

      // Measures the free time between the earlier end and later start.
      final gap = currentTask.startDate.difference(previousTask.endDate);

      // Rejects overlaps and breaks shorter than 15 minutes
      if (gap < _generatedTaskGap) {
        throw const AiScheduleException(
          'Generated tasks need at least 15 minutes between them. Please try again.', // Enforces rest time
        );
      }
    }

    return generatedTasks; // Returns only the fully validated temporary plan
  }

  // Checks that longer schedules are spread before the exam
  void _validateTaskDistribution({
    required List<ExamPriority> exams, // Exams included in the schedule
    required Map<String, List<GeneratedTask>>
    generatedTasksByExam, // Generated tasks grouped by exam
    required DateTime currentTime, // Time when generation started
  }) {
    // Checks the task distribution for every exam
    for (final exam in exams) {
      // Measures the available revision time before the exam
      final availableTime = exam.examDate.difference(
        currentTime, // Uses the current time as the starting point
      );

      // Keeps the normal rules when fewer than 14 days remain
      if (availableTime <= const Duration(days: 14)) continue;

      // Creates the key used to find this exam's generated tasks
      final normalisedExamName = exam.name.trim().toLowerCase();

      // Reads every task created for this exam
      final examTasks = generatedTasksByExam[normalisedExamName] ??
          <GeneratedTask>[]; // Uses an empty list when no tasks exist

      // Requires more than one task for a longer revision period
      if (examTasks.length < 2) {
        throw AiScheduleException(
          '${exam.name} needs tasks spread across the time before the exam. Please generate the schedule again.', // Explains the missing distribution
        );
      }

      // Finds the start of the final revision week
      final finalWeekStart = exam.examDate.subtract(
        const Duration(days: 7), // Moves seven days before the exam
      );

      // Checks for revision before the final week
      final hasEarlierTask = examTasks.any(
        (task) => task.startDate.isBefore(finalWeekStart), // Finds an earlier task
      );

      // Checks for revision during the final week
      final hasFinalWeekTask = examTasks.any(
        (task) =>
            !task.startDate.isBefore(finalWeekStart) &&
            task.endDate.isBefore(exam.examDate), // Finds a final week task
      );

      // Rejects schedules clustered into only one part of the period
      if (!hasEarlierTask || !hasFinalWeekTask) {
        throw AiScheduleException(
          '${exam.name} needs earlier revision and revision during the final week. Please generate the schedule again.', // Explains the required spread
        );
      }
    }
  }

  // Checks whether two time periods occupy any of the same time.
  bool _periodsOverlap({
    required DateTime firstStart, // Start of the first time period
    required DateTime firstEnd, // End of the first time period
    required DateTime secondStart, // Start of the second time period
    required DateTime secondEnd, // End of the second time period
  }) {
    // Allows one task to start exactly when another task ends.
    return firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);
  }

  // Converts Groq error responses into short messages suitable for the screen.
  String _readGroqError({
    required int statusCode, // HTTP status returned by Groq
    required String responseBody, // JSON error body returned by Groq
  }) {
    // Gives missing or rejected API keys a direct configuration message.
    if (statusCode == 401 || statusCode == 403) {
      return 'The Groq API key was rejected. Check the GROQ_API_KEY value.';
    }

    // Identifies a temporary rate limit without exposing the raw response.
    if (statusCode == 429) {
      return 'AI is receiving too many requests. Please wait and try again.';
    }

    try {
      // Converts Groq's error body into a Dart object when valid JSON is present.
      final decodedError = jsonDecode(
        responseBody,
      ); // Parses the API error response

      // Reads the normal Groq error wrapper when it is available.
      if (decodedError is Map<String, dynamic>) {
        final errorData =
            decodedError['error']; // Retrieves the nested error field

        // Reads the message stored inside the nested Groq error object.
        if (errorData is Map<String, dynamic>) {
          final message =
              errorData['message']; // Retrieves Groq's readable reason

          // Returns the API message only when it contains useful text.
          if (message is String && message.trim().isNotEmpty) {
            return 'AI could not generate the schedule: ${message.trim()}';
          }
        }
      }
    } on FormatException {
      // Falls through to the standard message when the error body is not JSON.
    }

    // Handles every remaining unsuccessful status with a consistent message.
    return 'AI could not generate the schedule. Please try again.';
  }
}
