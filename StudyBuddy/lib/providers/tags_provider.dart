import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:flutter_riverpod/legacy.dart'; // Provides StateNotifier support
import 'package:mbap_project/providers/firebase_provider.dart'; // Reads the Firebase service and auth state

// Holds the current tag list and loading status for the signed-in user.
class TagsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Ref ref; // Stores the Riverpod reference for accessing other providers

  // Starts with a loading state and receives the provider reference.
  TagsNotifier(this.ref) : super(const AsyncLoading()) {
    // Loads the user's tags from Firestore when the notifier is first created.
    loadTags(); // Fetches the initial tag list
  }

  // Fetches the signed-in user's tag list from Firestore.
  Future<void> loadTags() async {
    // Shows that the tag list is being retrieved.
    state = const AsyncLoading(); // Displays a loading state

    // Converts a successful result or thrown error into Riverpod state.
    state = await AsyncValue.guard(() async {
      // Gets the Firebase service that handles Firestore operations.
      final firebaseService = ref.read(firebaseServiceProvider); // Reads the service provider

      // Retrieves the tag list from the tags collection.
      return await firebaseService.getUserTags(); // Returns the user's saved tags
    });
  }

  // Adds a new tag and refreshes the local list.
  Future<void> addTag(String tagName) async {
    // Gets the Firebase service that handles Firestore operations.
    final firebaseService = ref.read(firebaseServiceProvider); // Reads the service provider

    // Saves the new tag to the tags collection in Firestore.
    await firebaseService.addUserTag(tagName); // Appends the tag to the array

    // Reloads the tag list so the dropdown shows the new tag.
    await loadTags(); // Refreshes the local state from Firestore
  }

  // Removes a tag and refreshes the local list.
  Future<void> removeTag(String tagName) async {
    // Gets the Firebase service that handles Firestore operations.
    final firebaseService = ref.read(firebaseServiceProvider); // Reads the service provider

    // Removes the tag from the tags collection in Firestore.
    await firebaseService.removeUserTag(tagName); // Removes the tag from the array

    // Reloads the tag list so the dropdown reflects the removal.
    await loadTags(); // Refreshes the local state from Firestore
  }
}

// Exposes the tag list and its actions throughout the app.
final tagsProvider = StateNotifierProvider<TagsNotifier, AsyncValue<List<String>>>((ref) {
  // Recreates the tag state whenever the signed-in account changes.
  ref.watch(authStateProvider); // Resets the tags on sign-out or account switch

  // Creates the notifier which loads tags from Firestore immediately.
  return TagsNotifier(ref); // Returns the configured notifier to Riverpod
});