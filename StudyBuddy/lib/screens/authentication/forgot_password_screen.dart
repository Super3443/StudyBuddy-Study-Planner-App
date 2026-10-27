import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbap_project/providers/firebase_provider.dart';
import 'package:mbap_project/widgets/default_background.dart';
import 'package:mbap_project/providers/theme_provider.dart';

// The screen's widget, immutable, points to its state class below
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  // Named route for navigation mapping
  static const String routeName = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

// Holds the mutable state and UI logic for the forgot password screen
class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  // Global key to identify and validate the form data
  final _formKey = GlobalKey<FormState>();

  String _email = ''; // Stores the validated email address

  // Local state variable to track the loading status of the submit button
  bool _isSendResetLinkLoading = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    return Scaffold(
      // The main body of the forgot password screen
      body: DefaultBackground(
        // Default gradient background
        child: SafeArea(
          // Prevents UI elements from overlapping with device status bars and notches
          child: Center(
            // Centers the entire scrollable column horizontally and vertically
            child: SingleChildScrollView(
              // Allows the screen to scroll if the keyboard covers the input fields
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
              ), // Padding on the left and right edges of the screen
              child: Column(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Centers the content inside verically
                children: [
                  // --- HEADER SECTION ---
                  // Navigates to the previous screen
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      // Creates a circular background for the back button with 5% white opacity
                      decoration: BoxDecoration(
                        color: borderColour,
                        shape: BoxShape.circle,
                      ),
                      // Navigates the user back to the login screen when tapped
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: textPrimaryColour),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),

                  // Vertical spacing below the back button
                  const SizedBox(height: 12),

                  // Container wrapping the school icon
                  Container(
                    padding: const EdgeInsets.all(
                      12,
                    ), // Internal padding around the icon
                    decoration: BoxDecoration(
                      color: darkGreyColour,
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Rounds the corners of the container
                      border: Border.all(
                        color: borderColour,
                      ), // Adds a subtle 5% opacity white border
                      // Applies a diagonal gradient from top-right to bottom-left
                      gradient: LinearGradient(
                        begin: Alignment.topRight, // From the top right corner
                        end: Alignment.bottomLeft, // To the bottom left corner
                        colors: [
                          Color.lerp(darkGreyColour, accentColour, 0.2)!, // Mixes 6% accent into the card colour
                          darkGreyColour, // Card background from the active mode
                        ],
                      ),
                    ),
                    // Displays the primary school icon
                    child: Icon(
                      Icons.school, // School material icon
                      size:
                          40, // Reduced icon size slightly to account for the new shape's layout
                      color:
                          accentColour, // Keep the solid accent accent color
                    ),
                  ),

                  // Vertical spacing below the icon
                  const SizedBox(height: 12),

                  // Main application title
                  Text(
                    'StudyBuddy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: accentColour,
                    ),
                  ),

                  // Vertical spacing below the title
                  const SizedBox(height: 8),

                  // Application subtitle with 70% white opacity
                  Text(
                    'Start your journey to smarter studying.',
                    style: TextStyle(
                      color: textSecondaryColour,
                      fontSize: 16,
                    ),
                  ),

                  // Vertical spacing before the screen header
                  const SizedBox(height: 32),

                  // Forgot Password screen header text
                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColour,
                    ),
                  ),

                  // Vertical spacing before the input form
                  const SizedBox(height: 24),

                  // --- FORM CARD SECTION ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: darkGreyColour,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColour,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topRight, // From the top right corner
                        end: Alignment.bottomLeft, // To the bottom left corner
                        colors: [
                          Color.lerp(darkGreyColour, accentColour, 0.2)!, // Mixes 6% accent into the card colour
                          darkGreyColour, // Card background from the active mode
                        ],
                      ),
                    ),
                    child: Form(
                      // Assigns the global key to this form to allow validation triggering
                      key: _formKey,
                      child: Column(
                        children: [
                          // EMAIL INPUT
                          TextFormField(
                            style: TextStyle(color: textPrimaryColour),
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                              hintStyle: TextStyle(
                                color: labelColour,
                              ),
                              // Displays an email icon inside the left side of the input field
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: textSecondaryColour,
                              ),
                              filled: true,
                              fillColor:
                                  blackColour, // Sets the inside colour of the text field to pitch black
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                // Removes the default underline border
                                borderSide: BorderSide.none,
                              ),
                            ),
                            // Optimises the device keyboard for email input (adds the @ symbol)
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              // Check if the email field is empty
                              if (value == null || value.isEmpty) {
                                return 'Please enter your account email';
                              }

                              // Regular expression to validate email format
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
                              );

                              // Returns an error string if the typed text does not match the email pattern
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email format (e.g. name@example.com)';
                              }

                              return null; // Return null if the input is valid
                            },
                            onSaved: (value) {
                              // Saves the email after validation succeeds
                              _email = value!
                                  .trim(); // Removes spaces around the email address
                            },
                          ),

                          // Vertical spacing between the input field and the button
                          const SizedBox(height: 24),

                          // SEND LINK BUTTON
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColour,
                              minimumSize: const Size.fromHeight(
                                55,
                              ), // Forces the button to stretch across the full width and be 55 pixels tall
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  28,
                                ), // Applies highly rounded, pill-shaped corners to the button
                              ),
                            ),
                            // Disables the button if currently loading, otherwise attaches the logic method
                            // Displays a loading spinner if active, otherwise shows the text and icon
                            onPressed: _isSendResetLinkLoading
                                ? null
                                : _handlePasswordReset,
                            child: _isSendResetLinkLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Color.fromARGB(221, 0, 0, 0),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Centers the content inside horizontally
                                    children: [
                                      const Text(
                                        'Send Email Link',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ), // Horizontal spacing between the text and the send icon
                                      const Icon(
                                        Icons.send,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Vertical spacing pushing up from the bottom of the screen
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Handles the logic for sending a password reset email via Firebase
  Future<void> _handlePasswordReset() async {
    // Triggers the form validators before proceeding
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!
          .save(); // Triggers the email field onSaved callback

      // Updates the UI state to show the loading spinner on the button
      setState(() => _isSendResetLinkLoading = true);
      try {
        // Asks the Firebase service provider to send the reset email
        await ref
            .read(firebaseServiceProvider)
            .sendPasswordResetEmail(
              _email, // Supplies the saved email address
            );

        // Prevents the app from crashing if the user navigates away before the network request finishes
        if (!mounted) return;

        // Success Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recovery link sent! Please check your inbox.',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior
                .floating, // Detaches the snackbar from the bottom edge to make it look like a floating pill
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // Matches the corner radiuses used in the app
            margin: const EdgeInsets.only(
              bottom:
                  20, // Pushes the snackbar up from the bottom of the phone screen
              left: 24,
              right: 24,
            ),
          ),
        );

        // Pop the user cleanly back to the Login screen
        Navigator.pop(context);
      } catch (e) {
        // Guard against the user leaving the page during the wait
        if (!mounted) return;

        // Displays the actual Firebase error reason to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''), // Strips the Exception prefix
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior
                .floating, // Detaches the snackbar from the bottom edge to make it look like a floating pill
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // Matches the corner radiuses used in the app
            margin: const EdgeInsets.only(
              bottom:
                  20, // Pushes the snackbar up from the bottom of the phone screen
              left: 24,
              right: 24,
            ),
          ),
        );
      } finally {
        // Ensures the loading spinner is turned off
        if (mounted) setState(() => _isSendResetLinkLoading = false);
      }
    }
  }
}
