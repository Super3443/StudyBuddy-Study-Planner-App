import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import 'package:mbap_project/models/app_user.dart';
import '../models/study_task.dart';
import '../models/task_query.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Listens to sign-in and sign-out changes
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.authStateChanges();
});

// Provides real-time task updates for the signed-in account.
final tasksProvider = StreamProvider<List<StudyTask>>((ref) {
  // Gets the Firebase service that handles Firestore operations.
  final firebaseService = ref.watch(firebaseServiceProvider);

  // Gets the currently signed-in account from the authentication provider.
  final user = ref.watch(authStateProvider).value;

  // Returns an empty list when no account is signed in.
  if (user == null) {
    return Stream.value(<StudyTask>[]);
  }

  // Listens for task changes belonging to the signed-in account.
  return firebaseService.getTasks(user.uid);
});

// Provides one filtered task request when the screen opens or filters apply.
final filteredTasksProvider = FutureProvider.autoDispose
  .family<List<StudyTask>, TaskQuery>((ref, taskQuery) async {
    // Gets the Firebase service that handles Firestore operations.
    final firebaseService = ref.watch(firebaseServiceProvider);

    // Gets the currently signed-in account from the authentication provider.
    final user = ref.watch(authStateProvider).value;

    // Returns an empty list when the account is no longer signed in.
    if (user == null) {
      return <StudyTask>[];
    }

    // Re-evaluates whenever the real-time task stream emits a change.
    ref.watch(tasksProvider);

    // Fetches the user's tasks from Firestore and applies the selected filters locally.
    return firebaseService.getFilteredTasks(
      userId: user.uid,
      taskQuery: taskQuery,
    );
  });