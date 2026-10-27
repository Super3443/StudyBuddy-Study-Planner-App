import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/exam_priority.dart';
import '../models/generated_task.dart';
import '../models/study_task.dart';
import '../services/ai_schedule_service.dart';
import '../services/firebase_service.dart';
import 'ai_access_provider.dart';
import 'firebase_provider.dart';

// Provides the service used to request generated schedules from Groq.
final aiScheduleServiceProvider = Provider<AiScheduleService>((ref) {
  return AiScheduleService(); // Creates the schedule service when first needed
});

// Holds the loading state and temporary tasks for the generated schedule.
class AiScheduleNotifier
    extends StateNotifier<AsyncValue<List<GeneratedTask>>> {
  final AiScheduleService aiScheduleService; // Sends requests to Groq
  final FirebaseService firebaseService; // Saves accepted tasks to Firestore
  final AiAccessNotifier aiAccessNotifier; // Manages free and Pro AI access
  final Future<List<StudyTask>> Function()
  loadExistingTasks; // Retrieves saved tasks before generation

  // Starts with an empty schedule and receives its required services.
  AiScheduleNotifier({
    required this.aiScheduleService, // Provides the schedule generation methods
    required this.firebaseService, // Provides the Firestore saving methods
    required this.aiAccessNotifier, // Provides the current AI access actions
    required this.loadExistingTasks, // Provides the latest saved task list
  }) : super(
         const AsyncData(
           <GeneratedTask>[], // Keeps the initial schedule preview empty
         ),
       );

  // Generates a temporary schedule using the entered exams and saved tasks.
  Future<void> generateSchedule(List<ExamPriority> exams) async {
    state = const AsyncLoading(); // Shows that schedule generation has started

    // Converts a successful result or thrown error into Riverpod state.
    state = await AsyncValue.guard(() async {
      // Reads the latest access state inside the protected request.
      final accessState = aiAccessNotifier.state;

      // Stops generation until the account access details have loaded.
      if (accessState.status != 'ready') {
        throw const AiScheduleException(
          'Your AI access could not be checked. Please try again.',
        );
      }

      // Stops another free request after today's allowance has been used.
      if (!accessState.canGenerateSchedule) {
        throw const AiScheduleException(
          'Today\'s free schedule has already been used.',
        );
      }

      // Reads the latest saved tasks to protect their occupied time periods.
      final existingTasks = await loadExistingTasks();

      // Requests and validates the generated schedule through the service.
      final generatedTasks = await aiScheduleService.generateSchedule(
        exams: exams, // Sends the exams entered on the AI screen
        existingTasks: existingTasks, // Sends saved tasks as occupied times
      );

      // Records the generation only after a valid schedule was returned.
      await aiAccessNotifier.recordGeneration();

      // Keeps the generated tasks in memory until the user accepts them.
      return generatedTasks;
    });
  }

  // Saves the accepted preview through FirebaseService as one batch.
  // Returns the document IDs paired with the generated tasks for notification scheduling.
  Future<Map<String, GeneratedTask>> saveSchedule() async {
    // Reads the generated tasks currently shown in the preview.
    final generatedTasks = state.value;

    // Stops when there is no generated schedule ready to save.
    if (generatedTasks == null || generatedTasks.isEmpty) {
      throw const AiScheduleException(
        'There is no generated schedule to save.',
      );
    }

    // Saves all accepted tasks and receives their Firestore document IDs.
    final docIds = await firebaseService.createGeneratedTasks(generatedTasks);

    // Pairs each document ID with its generated task for notification scheduling.
    final savedTasks = <String, GeneratedTask>{};
    for (int i = 0; i < docIds.length; i++) {
      savedTasks[docIds[i]] = generatedTasks[i];
    }

    // Clears the preview only after every task was saved successfully.
    state = const AsyncData(<GeneratedTask>[]);

    // Returns the paired data so the screen can schedule notifications.
    return savedTasks;
  }

  // Removes the current preview without changing any saved tasks.
  void discardSchedule() {
    state = const AsyncData(
      <GeneratedTask>[], // Replaces the generated preview with an empty list
    );
  }
}

// Exposes the generated schedule state and its actions throughout the app.
final aiScheduleProvider = StateNotifierProvider<AiScheduleNotifier, AsyncValue<List<GeneratedTask>>>((ref,
    ) {
      // Recreates the schedule state whenever the signed-in account changes.
      ref.watch(authStateProvider);

      // Gets the service that requests and validates generated schedules.
      final aiScheduleService = ref.read(aiScheduleServiceProvider);

      // Gets the service that saves accepted schedules to Firestore.
      final firebaseService = ref.read(firebaseServiceProvider);

      // Gets the notifier that manages free and Pro generation access.
      final aiAccessNotifier = ref.read(aiAccessProvider.notifier);

      // Creates the schedule notifier with all of its required dependencies.
      return AiScheduleNotifier(
        aiScheduleService: aiScheduleService, // Supplies the Groq service
        firebaseService: firebaseService, // Supplies the Firebase service
        aiAccessNotifier: aiAccessNotifier, // Supplies the AI access actions
        loadExistingTasks: () => ref.read(
          tasksProvider.future, // Retrieves the latest saved tasks when needed
        ),
      );
    });