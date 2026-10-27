import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:mbap_project/providers/tags_provider.dart'; // Provides the user's Firestore tag list
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours

// The default dropdown value shared across create and edit modals.
const noTagOption = 'No tag selected'; // Default dropdown option

// Opens a dialog for the user to add or remove tags.
// Returns the tag name to clear from the dropdown when a selected tag is deleted.
Future<String?> showManageTagsDialog({
  required BuildContext context, // Supplies the current screen context
  required WidgetRef ref, // Reads and watches the tags provider
  required String currentSelectedTag, // Tracks which tag is currently selected in the dropdown
}) async {
  // Stores the text entered in the new tag input field.
  final tagController = TextEditingController(); // Controls the tag name input

  // Tracks whether the currently selected tag was deleted inside the dialog.
  String? deletedSelectedTag; // Stores the tag to clear from the dropdown

  // Tracks the feedback message shown below the input field.
  String statusMessage = ''; // Stores the current status text
  bool statusIsError = false; // Tracks whether the status is an error
  bool isAdding = false; // Tracks whether a tag is being created
  String? deletingTag; // Tracks which tag is being deleted

  await showDialog(
    context: context, // Supplies the current screen context
    builder: (dialogContext) => StatefulBuilder(
      // Allows the dialog content to rebuild when tags are added or removed.
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          backgroundColor: darkGreyColour, // Sets the dark grey background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounds the dialog corners
          ),
          title: Row(
            // Arranges the icon and title horizontally.
            children: [
              Icon(
                Icons.label_outlined, // Displays the tag icon
                color: accentColour, // Sets the accent colour
                size: 24, // Sets the icon size
              ),
              const SizedBox(width: 8), // Adds space before the title
              Text(
                'Manage Tags', // Sets the dialog title
                style: TextStyle(
                  color: textPrimaryColour, // Sets the white text colour
                  fontSize: 18, // Sets the title size
                  fontWeight: FontWeight.bold, // Makes the title bold
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite, // Forces the dialog to use full width
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrinks the dialog to fit its content
              children: [
                // --- EXISTING TAGS LIST ---
                // Watches the user's Firestore tag list inside the dialog.
                ref.read(tagsProvider).when(
                  // Builds the tag list after the tags have loaded.
                  data: (tagList) {
                    // Shows a message when the user has no saved tags.
                    if (tagList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12), // Adds vertical spacing
                        child: Text(
                          'No tags yet. Add one below.', // Displays the empty state message
                          style: TextStyle(
                            color: textSecondaryColour, // Sets the muted text colour
                            fontSize: 14, // Sets the message size
                          ),
                        ),
                      );
                    }

                    // Limits the tag list height so the dialog stays scrollable.
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200), // Caps the list height
                      child: ListView.builder(
                        shrinkWrap: true, // Prevents the list from taking infinite height
                        itemCount: tagList.length, // Sets the number of tag rows
                        itemBuilder: (context, index) {
                          final tag = tagList[index]; // Reads the current tag name

                          return ListTile(
                            dense: true, // Reduces the row height
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4), // Tightens the row padding
                            // Displays the tag name.
                            title: Text(
                              tag, // Shows the tag label
                              style: TextStyle(
                                color: textPrimaryColour, // Sets the white text colour
                                fontSize: 14, // Sets the tag text size
                              ),
                            ),
                            // Adds a delete icon at the end of each tag row.
                            trailing: GestureDetector(
                              onTap: () async {
                                // Stops when another delete is already running.
                                if (deletingTag != null) return; // Prevents overlapping delete requests

                                // Shows the loading spinner on this tag's delete icon.
                                setDialogState(() {
                                  deletingTag = tag; // Marks this tag as being deleted
                                });

                                try {
                                  // Removes the tag from Firestore through the tags provider.
                                  await ref.read(tagsProvider.notifier).removeTag(tag); // Deletes the tag from the array

                                  // Marks the deleted tag for clearing in the dropdown.
                                  if (currentSelectedTag == tag) {
                                    deletedSelectedTag = tag; // Signals the caller to reset the dropdown
                                  }

                                  // Clears the spinner and updates the status message.
                                  setDialogState(() {
                                    deletingTag = null; // Removes the loading state
                                    statusMessage = '"$tag" deleted.'; // Shows the deletion feedback
                                    statusIsError = false; // Marks the message as a success
                                  });
                                } catch (_) {
                                  // Clears the spinner and updates the status message with the error.
                                  setDialogState(() {
                                    deletingTag = null; // Removes the loading state
                                    statusMessage = 'Unable to delete the tag.'; // Shows the error feedback
                                    statusIsError = true; // Marks the message as an error
                                  });
                                }
                              },
                              // Shows a spinner while deleting, otherwise shows the remove icon.
                              child: deletingTag == tag
                                  ? SizedBox(
                                      width: 20, // Matches the icon size
                                      height: 20, // Matches the icon size
                                      child: CircularProgressIndicator(
                                        color: Colors.redAccent, // Matches the delete icon colour
                                        strokeWidth: 2, // Keeps the spinner compact
                                      ),
                                    )
                                  : Icon(
                                      Icons.close, // Displays the remove icon
                                      color: Colors.redAccent, // Uses red for the delete action
                                      size: 20, // Sets the icon size
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },

                        // Shows a loading spinner while tags are being fetched.
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12), // Adds vertical spacing
                          child: Center(
                            child: SizedBox(
                              width: 20, // Sets the spinner width
                              height: 20, // Sets the spinner height
                              child: CircularProgressIndicator(strokeWidth: 2), // Keeps the spinner compact
                            ),
                          ),
                        ),

                        // Shows an error message when tags fail to load.
                        error: (_, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12), // Adds vertical spacing
                          child: Text(
                            'Unable to load tags.', // Displays the error message
                            style: TextStyle(color: Colors.redAccent, fontSize: 14), // Sets the error text style
                          ),
                        ),
                      ),

                const SizedBox(height: 12), // Adds space between the list and the input

                // --- ADD TAG INPUT ---
                // Arranges the text field and add button horizontally.
                Row(
                  children: [
                    // Forces the text field to fill the remaining width.
                    Expanded(
                      child: TextField(
                        controller: tagController, // Links the input to the controller
                        style: TextStyle(color: textPrimaryColour), // Sets the input text colour
                        decoration: InputDecoration(
                          hintText: 'New tag name', // Displays the placeholder text
                          hintStyle: TextStyle(color: labelColour), // Sets the hint colour
                          filled: true, // Enables the input background colour
                          fillColor: blackColour, // Sets the black background colour
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, // Adds horizontal padding inside the field
                            vertical: 10, // Adds vertical padding inside the field
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // Rounds the input corners
                            borderSide: BorderSide.none, // Removes the default border line
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8), // Adds space between the field and the button

                    // Saves the entered tag to Firestore.
                    GestureDetector(
                      onTap: () async {
                        // Reads the entered text and removes surrounding spaces.
                        final trimmed = tagController.text.trim(); // Cleans the entered tag name

                        // Stops when the tag name is empty or another add is running.
                        if (trimmed.isEmpty || isAdding) return; // Prevents blank or overlapping requests

                        // Blocks tag names that clash with built-in dropdown and filter options.
                        if (trimmed == noTagOption || trimmed == 'Generated') {
                          setDialogState(() {
                            statusMessage = '"$trimmed" is a reserved name.'; // Warns the user
                            statusIsError = true; // Shows the message in red
                          });
                          return;
                        }

                        // Shows the loading spinner on the add button.
                        setDialogState(() {
                          isAdding = true; // Marks the add button as loading
                        });

                        try {
                          // Saves the new tag to Firestore through the tags provider.
                          await ref.read(tagsProvider.notifier).addTag(trimmed); // Appends the tag to the array

                          // Clears the input field after the tag is saved.
                          tagController.clear(); // Resets the text field

                          // Clears the spinner and updates the status message.
                          setDialogState(() {
                            isAdding = false; // Removes the loading state
                            statusMessage = '"$trimmed" created.'; // Shows the creation feedback
                            statusIsError = false; // Marks the message as a success
                          });
                        } catch (_) {
                          // Clears the spinner and updates the status message with the error.
                          setDialogState(() {
                            isAdding = false; // Removes the loading state
                            statusMessage = 'Unable to create the tag.'; // Shows the error feedback
                            statusIsError = true; // Marks the message as an error
                          });
                        }
                      },
                      child: Container(
                        width: 40, // Sets the button width
                        height: 40, // Sets the button height
                        decoration: BoxDecoration(
                          color: accentColour, // Uses the accent colour for the background
                          borderRadius: BorderRadius.circular(12), // Rounds the button corners
                        ),
                        // Shows a spinner while adding, otherwise shows the add icon.
                        child: Center(
                          child: isAdding
                              ? SizedBox(
                                  width: 20, // Keeps the spinner compact
                                  height: 20, // Keeps the spinner compact
                                  child: CircularProgressIndicator(
                                    color: blackColour, // Matches the icon colour
                                    strokeWidth: 2, // Keeps the spinner compact
                                  ),
                                )
                              : Icon(
                                  Icons.add, // Displays the add icon
                                  color: blackColour, // Sets the icon colour to contrast the background
                                  size: 20, // Sets the icon size
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                // --- STATUS MESSAGE ---
                // Shows feedback text below the input when a tag is created or deleted.
                if (statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12), // Adds space above the status text
                    child: Align(
                      alignment: Alignment.centerLeft, // Aligns the text to the left like input validation
                      child: Text(
                        statusMessage, // Displays the current feedback message
                        style: TextStyle(
                          color: statusIsError
                              ? Colors.redAccent // Red for errors
                              : Colors.greenAccent, // Green for success
                          fontSize: 15, // Matches typical validation text size
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            // Closes the dialog without changing the dropdown selection.
            TextButton(
              onPressed: () {
                // Dismisses the keyboard before closing to release inherited dependencies.
                FocusScope.of(dialogContext).unfocus();
                Navigator.pop(dialogContext); // Returns null
              },
              child: Text(
                'Done', // Sets the close label
                style: TextStyle(
                  color: accentColour, // Sets the accent colour
                  fontWeight: FontWeight.bold, // Makes the label bold
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  // Returns the deleted tag name so the caller can reset the dropdown.
  return deletedSelectedTag; // Null when no selected tag was deleted
}