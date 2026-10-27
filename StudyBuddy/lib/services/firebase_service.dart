import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbap_project/models/app_user.dart';
import '../models/generated_task.dart';
import '../models/study_task.dart';
import '../models/task_query.dart';

// To handle Firebase account authentication logic
class FirebaseService {
  // Function to get the currently authenticated user
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Provides updates when the user signs in or signs out
  Stream<AppUser?> authStateChanges() {
    return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
      // Returns null when no account is signed in.
      if (user == null) return null;

      // Creates the user document with default values when it does not exist yet.
      await ensureUserDocument();

      // Social login providers (Google, GitHub) don't require separate email verification.
      final isSocialLogin = user.providerData.any(
        (info) => info.providerId == 'google.com' || info.providerId == 'github.com',
      );

      return AppUser(
        uid: user.uid, // Passes the Firebase account ID
        email: user.email, // Passes the account email address
        displayName: user.displayName, // Passes the account display name
        emailVerified: user.emailVerified || isSocialLogin, // Skips verification for social logins
      );
    });
  }

  // Function to handle Google Sign in
  Future<UserCredential?> signInWithGoogle() async {
    // Start sign-in flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      clientId:
          '332994068371-6o7mt9qst4s1hlm69j65lin7i613dqvq.apps.googleusercontent.com',
    ).signIn();

    // User cancelled login
    if (googleUser == null) return null;

    // Get authentication details
    final googleAuth = await googleUser.authentication;

    // Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  // Function to handle Github Sign in
  Future<UserCredential?> signInWithGitHub() async {
    try {
      // Creates the GitHub authentication provider
      final githubProvider = GithubAuthProvider();

      // Opens GitHub in a popup when the app is running in a web browser
      if (kIsWeb) {
        return await FirebaseAuth.instance.signInWithPopup(githubProvider);
      }

      // Opens GitHub's OAuth login flow in a webview/browser
      return await FirebaseAuth.instance.signInWithProvider(githubProvider);
    } on FirebaseAuthException catch (e) {
      // Handles a GitHub browser flow that was cancelled normally
      if (e.code == 'web-context-cancelled' ||
          e.code == 'web-context-canceled' ||
          e.code == 'popup-closed-by-user') {
        throw Exception('GitHub Sign-In was cancelled.');
      }

      // Handles a previous browser sign-in operation that is still active
      if (e.code == 'web-context-already-presented') {
        throw Exception(
            'A GitHub Sign-In window is already active. Return to it or restart the app.');
      }

      // Catches any other Firebase errors
      throw Exception('GitHub Sign-In failed. Please try again later');
    }
  }

  // Function to create a new user with Firebase
  Future<void> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Creates the user account with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Updates the newly created user's profile with their Full Name
      await userCredential.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      // Translates the Firebase error into a plain exception for the screen
      throw Exception(e.message ?? 'Account not successfully created.');
    }
  }

  // Logs in an existing user with email and password
  Future<UserCredential> login(String email, String password) async {
    try {
      // Authenticates the user with Firebase
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, // Supplies the saved email address
        password: password, // Supplies the saved password
      );
    } on FirebaseAuthException catch (e) {
      // Translates the Firebase error into a readable message for the screen
      throw Exception(e.message ?? 'Login failed. Please try again.');
    }
  }

  // Function to log out the current user
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // Function to send an email verification link to the user's email address
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    if (user.emailVerified) return;

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Unable to send the verification email.');
    }
  }

  // Reloads the current user from Firebase and returns whether their email is verified
  Future<bool> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  // Creates the user document with default values when it does not already exist.
  // Called after every successful sign-in to guarantee the document is present.
  Future<void> ensureUserDocument() async {
    // Gets the account that just signed in.
    final user = FirebaseAuth.instance.currentUser;

    // Stops because the document must belong to a signed-in account.
    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    // Opens the expected user document using the Firebase account ID.
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Reads the document to check whether it already exists.
    final snapshot = await userRef.get();

    // Skips creation when the document was already set up by a previous sign-in.
    if (snapshot.exists) return;

    // Creates the document with every field set to its default value.
    await userRef.set({
      'user_id': user.uid, // Stores the Firebase user ID
      'biometric_enabled': false, // Disables fingerprint login until the user enables it
      'pro_tier': 'free', // Starts the account on the free plan
      'daily_generation_count': 0, // Tracks the number of AI generations used today
      'last_generation_date': null, // Stores the date of the most recent AI generation
      'nets_transaction_ref': null, // Stores the NETS payment reference when purchased
      'pro_purchased_at': null, // Stores when the Pro upgrade was purchased
      'has_seen_onboarding': false, // Tracks whether the user has completed the onboarding walkthrough
    });
  }

  // Sends a password reset email to the supplied address
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Requests a password reset link from Firebase
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Translates the Firebase error into a readable message for the screen
      throw Exception(e.message ?? 'Unable to send the reset link. Please try again.');
    }
  }

  // Returns the active plan tier for the signed-in account.
  Future<String> getProTier() async {
    // Gets the account currently signed in to Firebase.
    final user = FirebaseAuth.instance.currentUser;

    // Stops because AI access must belong to a signed-in account.
    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    // Retrieves the account document using the Firebase user ID.
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Reads the saved tier, falling back to free for older accounts.
    final tier = userDocument.data()?['pro_tier'] as String?;

    // Returns free when the field is missing or contains an unknown value.
    if (tier == 'standard' || tier == 'premium') return tier!;
    return 'free';
  }

  // Returns the daily generation count and date for the signed-in account.
  Future<Map<String, dynamic>> getDailyGenerationData() async {
    // Gets the account currently signed in to Firebase.
    final user = FirebaseAuth.instance.currentUser;

    // Stops because generation history must belong to a signed-in account.
    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    // Retrieves the account document using the Firebase user ID.
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Reads the saved daily generation count.
    final count = userDocument.data()?['daily_generation_count'] as int? ?? 0;

    // Reads the saved generation date timestamp.
    final dateTimestamp =
        userDocument.data()?['last_generation_date'] as Timestamp?;

    // Returns the count and converted date for the provider to use.
    return {
      'count': count,
      'date': dateTimestamp?.toDate(),
    };
  }

  // Records a completed generation and updates the daily counter.
  Future<Map<String, dynamic>> recordGeneration() async {
    // Gets the account that completed the schedule generation.
    final user = FirebaseAuth.instance.currentUser;

    // Stops because generation history must belong to a signed-in account.
    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    // Retrieves the current daily count and date from Firestore.
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Reads the saved count and date for today's reset check.
    final savedCount =
        userDocument.data()?['daily_generation_count'] as int? ?? 0;
    final savedTimestamp =
        userDocument.data()?['last_generation_date'] as Timestamp?;
    final savedDate = savedTimestamp?.toDate();

    // Checks whether the saved date matches today's calendar date.
    final now = DateTime.now();
    final isToday = savedDate != null &&
        savedDate.toLocal().year == now.year &&
        savedDate.toLocal().month == now.month &&
        savedDate.toLocal().day == now.day;

    // Increments the counter when the saved date is today, otherwise resets to one.
    final newCount = isToday ? savedCount + 1 : 1;

    // Updates the daily generation fields on the existing user document.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'daily_generation_count': newCount, // Stores the updated daily count
      'last_generation_date': Timestamp.fromDate(now), // Stores today's date
    });

    // Returns the updated values for the provider to store locally.
    return {
      'count': newCount,
      'date': now,
    };
  }

  // Grants AI Pro after NETS confirms a successful payment.
  Future<void> grantAiProAccess({
    required String transactionReference,
    required String tier,
  }) async {
    // Gets the account that completed the payment.
    final user = FirebaseAuth.instance.currentUser;

    // Stops because the purchase must belong to a signed-in account.
    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    // Updates only the Pro access fields on the existing user document.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'pro_tier': tier, // Stores the purchased plan tier
      'nets_transaction_ref':
          transactionReference, // Stores the successful NETS reference
      'pro_purchased_at': Timestamp.fromDate(
        DateTime.now(),
      ), // Stores when the purchase completed
    });
  }

  // Retrieves a single task document from Firestore by its document ID.
  Future<StudyTask?> getTaskById(String taskId) async {
    // Reads the task document using its unique Firestore ID.
    final document = await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .get();

    // Returns null when the document does not exist.
    if (!document.exists) return null;

    // Converts the Firestore document into a StudyTask object.
    return StudyTask.fromMap(document.id, {
      ...document.data()!, // Spreads all Firestore fields into the map
      'start_date': (document.data()!['start_date'] as Timestamp?)?.toDate(), // Converts the start timestamp
      'end_date': (document.data()!['end_date'] as Timestamp?)?.toDate(), // Converts the end timestamp
    });
  }

  // Listens for unfiltered tasks belonging to the signed-in account.
  Stream<List<StudyTask>> getTasks(String userId) {
    return FirebaseFirestore.instance
        // Opens the tasks collection without the advanced sort query.
        .collection('tasks')

        // Only retrieves tasks belonging to the signed-in account.
        .where('user_id', isEqualTo: userId)

        // Keeps the Dashboard and Schedule screens updated in real time.
        .snapshots()
        
        // Converts every Firestore document into a StudyTask object.
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((document) => StudyTask.fromMap(document.id, {
                // Spreads all the original Firestore fields into the new map.
                ...document.data(),

                // Converts the Firestore Timestamp into a DateTime before the model sees it.
                // This keeps all Firestore-specific type handling inside the service layer.
                'start_date': (document.data()['start_date'] as Timestamp?)?.toDate(),
                'end_date': (document.data()['end_date'] as Timestamp?)?.toDate(),
              }))
              .toList();

          // Sorts the shared screen tasks without requiring a Firestore index.
          tasks.sort((firstTask, secondTask) {
            return firstTask.startDate.compareTo(secondTask.startDate);
          });

          // Sends the sorted task list to Dashboard and Schedule.
          return tasks;
        });
  }

  // Fetches all tasks for the signed-in account and applies the selected filters locally.
  Future<List<StudyTask>> getFilteredTasks({
    required String userId,
    required TaskQuery taskQuery,
  }) async {
    // Retrieves every task belonging to the signed-in account.
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('user_id', isEqualTo: userId)
        .get();

    // Converts every Firestore document into a StudyTask object.
    List<StudyTask> tasks = snapshot.docs
        .map((document) => StudyTask.fromMap(document.id, {
              // Spreads all the original Firestore fields into the new map.
              ...document.data(),

              // Converts the Firestore Timestamp into a DateTime before the model sees it.
              'start_date': (document.data()['start_date'] as Timestamp?)?.toDate(),
              'end_date': (document.data()['end_date'] as Timestamp?)?.toDate(),
            }))
        .toList();

    // Filters by the selected completion status.
    if (taskQuery.completionFilter != TaskCompletionFilter.all) {
      tasks = tasks
          .where((task) =>
              task.isCompleted ==
              (taskQuery.completionFilter == TaskCompletionFilter.completed))
          .toList();
    }

    // Filters by the selected subject tag.
    if (taskQuery.tagName != null) {
      tasks = tasks.where((task) => task.tagName == taskQuery.tagName).toList();
    }

    // Filters by the selected priority level.
    if (taskQuery.priority != null) {
      tasks = tasks.where((task) => task.priority == taskQuery.priority).toList();
    }

    // Filters tasks that start on or after the first selected date.
    if (taskQuery.startDate != null) {
      tasks = tasks
          .where((task) =>
              task.startDate.isAfter(taskQuery.startDate!) ||
              task.startDate.isAtSameMomentAs(taskQuery.startDate!))
          .toList();
    }

    // Filters tasks that start before the day after the last selected date.
    if (taskQuery.endDate != null) {
      tasks = tasks
          .where((task) => task.startDate.isBefore(taskQuery.endDate!))
          .toList();
    }

    // Sorts the filtered results by the selected date order.
    if (taskQuery.sortOrder == TaskSortOrder.latestFirst) {
      tasks.sort((a, b) => b.startDate.compareTo(a.startDate));
    } else {
      tasks.sort((a, b) => a.startDate.compareTo(b.startDate));
    }

    return tasks;
  }

  // Function to save a new task into Firebase and return its document ID.
  Future<String> createTask({
    // The title entered in the task form.
    required String title,

    // The chosen starting date and time.
    required DateTime startDate,

    // The chosen ending date and time.
    required DateTime endDate,

    // Priority uses 1 for Low, 2 for Medium and 3 for High.
    required int priority,

    // Selecting a tag is optional, so this value can be null.
    String? tagName,
  }) async {
    // Gets the account that is currently signed in to Firebase.
    final user = FirebaseAuth.instance.currentUser;

    // Stops the operation if there is no signed-in account.
    // Every task must be connected to an account.
    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    // Adds a new document to the tasks collection.
    // Firestore automatically creates a unique document ID.
    final docRef = await FirebaseFirestore.instance.collection('tasks').add({
      // Saves the Firebase UID so the task can be retrieved for this account.
      'user_id': user.uid,

      // Removes unnecessary spaces before and after the title.
      'title': title.trim(),

      // Converts DateTime into the Timestamp format used by Firestore.
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),

      // Saves the selected priority as a number.
      'priority': priority,

      // A newly created task starts as incomplete.
      'is_completed': false,

      // Saves the selected tag or null when no tag was selected.
      'tag_name': tagName,
    });

    // Returns the Firestore document ID for scheduling the notification.
    return docRef.id;
  }

  // Saves every accepted generated task as one complete Firestore operation.
  // Returns the document IDs so notifications can be scheduled for each task.
  Future<List<String>> createGeneratedTasks(List<GeneratedTask> generatedTasks) async {
    // Gets the account that will own all generated task documents.
    final user = FirebaseAuth.instance.currentUser;

    // Stops because every saved task must belong to a signed-in account.
    if (user == null) {
      throw Exception('No signed-in user was found.');
    }

    // Stops before creating an empty Firestore batch.
    if (generatedTasks.isEmpty) {
      throw ArgumentError('No generated tasks were supplied.');
    }

    // Creates one batch so all generated tasks save together.
    final batch = FirebaseFirestore.instance.batch();

    // Stores each document reference so the IDs can be returned after the commit.
    final docRefs = <DocumentReference>[];

    // Adds one new task document to the batch for every accepted task.
    for (final generatedTask in generatedTasks) {
      // Creates a new document reference with an automatic Firestore ID.
      final taskDocument = FirebaseFirestore.instance.collection('tasks').doc();

      // Keeps the reference so its ID can be returned after the batch saves.
      docRefs.add(taskDocument);

      // Adds the generated task fields to the pending batch operation.
      batch.set(taskDocument, {
        'user_id': user.uid, // Connects the task to the signed-in account
        'title': generatedTask.title.trim(), // Removes spaces around the title
        'start_date': Timestamp.fromDate(
          generatedTask.startDate,
        ), // Stores the starting date and time
        'end_date': Timestamp.fromDate(
          generatedTask.endDate,
        ), // Stores the ending date and time
        'priority':
            generatedTask.priority, // Stores Low, Medium or High as a number
        'is_completed': false, // Starts every generated task as incomplete
        'tag_name': generatedTask.tagName, // Stores the Generated filter tag
      });
    }

    // Sends every pending task document to Firestore together.
    await batch.commit();

    // Returns the document IDs in the same order as the generated tasks.
    return docRefs.map((ref) => ref.id).toList();
  }

  // Function to update the editable fields of an existing task.
  Future<void> updateTask({
    // The unique ID of the task document that needs to be updated.
    required String taskId,

    // The latest title entered in the Edit Task form.
    required String title,

    // The latest starting date and time.
    required DateTime startDate,

    // The latest ending date and time.
    required DateTime endDate,

    // The latest selected priority.
    required int priority,

    // The latest selected tag, or null when the tag was removed.
    String? tagName,
  }) async {
    // Opens the matching task document and updates only these fields.
    // Other fields, such as user_id and is_completed, remain unchanged.
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      // Removes unnecessary spaces before saving the updated title.
      'title': title.trim(),

      // Converts both DateTime values into Firestore Timestamps.
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),

      // Replaces the old priority with the newly selected priority.
      'priority': priority,

      // Replaces the old tag or stores null when no tag is selected.
      'tag_name': tagName,
    });
  }

  // Function to update only the completion status of a task.
  Future<void> updateTaskCompletion({
    // The unique ID of the task document that needs to be changed.
    required String taskId,

    // True means completed and false means not completed.
    required bool isCompleted,
  }) async {
    // Opens the matching document and updates only is_completed.
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'is_completed': isCompleted,
    });
  }

  // Function to delete one task based of unique Firestore document ID.
  Future<void> deleteTask(String taskId) async {
    // Opens the matching task document and removes it from Firestore.
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  // --- TAG MANAGEMENT METHODS ---

  // Retrieves the signed-in user's tag list from the tags collection.
  Future<List<String>> getUserTags() async {
    // Gets the currently signed-in account.
    final user = FirebaseAuth.instance.currentUser; // Reads the active Firebase user

    // Stops when no account is signed in.
    if (user == null) return <String>[]; // Returns an empty list without a user

    // Queries the tags collection for the document belonging to this user.
    final snapshot = await FirebaseFirestore.instance
        .collection('tags') // Opens the tags collection
        .where('user_id', isEqualTo: user.uid) // Filters by the signed-in user
        .limit(1) // Each user has at most one tag document
        .get(); // Executes the Firestore query

    // Returns an empty list when the user has no tag document yet.
    if (snapshot.docs.isEmpty) return <String>[]; // No tag document found

    // Reads the tags array from the user's tag document.
    final data = snapshot.docs.first.data(); // Gets the document fields

    // Casts the stored array into a typed string list.
    final tags = List<String>.from(
      data['tags'] ?? <String>[], // Falls back to an empty list when the field is missing
    );

    return tags; // Returns the user's saved tag list
  }

  // Adds a new tag to the signed-in user's tag document.
  Future<void> addUserTag(String tagName) async {
    // Gets the currently signed-in account.
    final user = FirebaseAuth.instance.currentUser; // Reads the active Firebase user

    // Stops when no account is signed in.
    if (user == null) throw Exception('No signed-in user was found.'); // Prevents saving without a user

    // Queries the tags collection for the document belonging to this user.
    final snapshot = await FirebaseFirestore.instance
        .collection('tags') // Opens the tags collection
        .where('user_id', isEqualTo: user.uid) // Filters by the signed-in user
        .limit(1) // Each user has at most one tag document
        .get(); // Executes the Firestore query

    if (snapshot.docs.isEmpty) {
      // Creates a new tag document when the user has none yet.
      await FirebaseFirestore.instance.collection('tags').add({
        'user_id': user.uid, // Links the document to the signed-in user
        'tags': [tagName], // Starts the array with the first tag
      });
    } else {
      // Adds the tag to the existing document without duplicating it.
      await snapshot.docs.first.reference.update({
        'tags': FieldValue.arrayUnion([tagName]), // Appends the tag only if it is not already present
      });
    }
  }

  // Removes a tag from the signed-in user's tag document.
  Future<void> removeUserTag(String tagName) async {
    // Gets the currently signed-in account.
    final user = FirebaseAuth.instance.currentUser; // Reads the active Firebase user

    // Stops when no account is signed in.
    if (user == null) throw Exception('No signed-in user was found.'); // Prevents deleting without a user

    // Queries the tags collection for the document belonging to this user.
    final snapshot = await FirebaseFirestore.instance
        .collection('tags') // Opens the tags collection
        .where('user_id', isEqualTo: user.uid) // Filters by the signed-in user
        .limit(1) // Each user has at most one tag document
        .get(); // Executes the Firestore query

    // Stops when there is no tag document to update.
    if (snapshot.docs.isEmpty) return; // Nothing to remove

    // Removes the tag from the existing array.
    await snapshot.docs.first.reference.update({
      'tags': FieldValue.arrayRemove([tagName]), // Removes the matching tag from the array
    });
  }

  // Checks whether the signed-in user has completed the onboarding walkthrough.
  Future<bool> hasSeenOnboarding() async {
    // Gets the currently signed-in account.
    final user = FirebaseAuth.instance.currentUser; // Reads the active Firebase user

    // Returns true when no account is signed in to skip onboarding.
    if (user == null) return true; // Prevents showing onboarding without a user

    // Reads the user's document from the users collection.
    final doc = await FirebaseFirestore.instance
        .collection('users') // Opens the users collection
        .doc(user.uid) // Selects the signed-in user's document
        .get(); // Fetches the document data

    // Returns true when the document is missing to avoid blocking login.
    if (!doc.exists) return true; // Skips onboarding when the document is not found

    // Reads the onboarding flag from the user's document.
    return doc.data()?['has_seen_onboarding'] ?? false; // Defaults to false for existing users without the field
  }

  // Marks the signed-in user as having completed the onboarding walkthrough.
  Future<void> completeOnboarding() async {
    // Gets the currently signed-in account.
    final user = FirebaseAuth.instance.currentUser; // Reads the active Firebase user

    // Stops when no account is signed in.
    if (user == null) return; // Prevents updating without a user

    // Updates the onboarding flag in the user's document.
    await FirebaseFirestore.instance
        .collection('users') // Opens the users collection
        .doc(user.uid) // Selects the signed-in user's document
        .update({'has_seen_onboarding': true}); // Marks onboarding as completed
  }
}
