import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbap_project/screens/authentication/email_verification.dart';
import 'package:mbap_project/widgets/default_background.dart';
import 'package:mbap_project/providers/theme_provider.dart';
import '../../widgets/password_validation.dart';
import '../../providers/firebase_provider.dart';

// The screen's widget, immutable, points to its state class below
class RegisterScreen extends ConsumerStatefulWidget {
  // Named route for navigation mapping
  static const String routeName = '/register';
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

// Holds the mutable state and UI logic for the registration screen
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Global key to identify and validate the form data
  final _formKey = GlobalKey<FormState>();

  String _name = ''; // Stores the validated full name
  String _email = ''; // Stores the validated email address
  String _password = ''; // Stores the validated password

  // Controls whether the password text is hidden as dots
  bool _obscurePassword = true; // Boolean to toggle password visibility
  bool _obscureConfirmPassword =
      true; // Boolean to toggle confirm password visibility

  // String for tracking password input for strength validation UI
  String _passwordText = '';

  // Local state variable to track the loading status of the submit button
  bool _isRegisterLoading = false;

  @override
  // Builds the registration screen UI
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    return Scaffold(
      body: DefaultBackground(
        // Default background with gradient
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
                // Column layout for the screen's content
                mainAxisAlignment: MainAxisAlignment
                    .center, // Centers the content inside verically
                children: [
                  // --- HEADER SECTION ---
                  // Navigates to the previous screen
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: borderColour, // Creates a circular background for the back button with 5% white opacity
                        shape: BoxShape.circle,
                      ),
                      // Navigates the user back to the previous screen when tapped
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
                      color: blackColour,
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
                          Color.lerp(darkGreyColour, accentColour, 0.3)!, // Mixes 6% accent into the card colour
                          darkGreyColour, // Card background from the active mode
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.school, // School material icon
                      size: 40, // Reduced icon size slightly
                      color:
                          accentColour, // Keep the solid accent color
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

                  // vertical spacing below the title
                  const SizedBox(height: 8),

                  // Application subtitle
                  Text(
                    'Start your journey to smarter studying.',
                    style: TextStyle(
                      color: textSecondaryColour,
                      fontSize: 16,
                    ), // Subtitle with 70% white opacity
                  ),

                  // Vertical spacing before the screen header
                  const SizedBox(height: 24),

                  // Registration screen header text
                  Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColour,
                    ),
                  ),

                  // Vertical spacing before the input form card
                  const SizedBox(height: 24),

                  // --- FORM CARD SECTION ---
                  // Dark card holding the input fields and submit button
                  Container(
                    padding: const EdgeInsets.all(
                      24,
                    ), // Internal padding on all sides of the card
                    decoration: BoxDecoration(
                      color:
                          blackColour, // Sets the base background colour to black
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Rounds the corners of the card
                      border: Border.all(
                        color: borderColour,
                      ), // White Border radius around entire card with 5% opacity
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
                        // Column layout for the form
                        children: [
                          // --- FULL NAME INPUT FIELD ---
                          TextFormField(
                            style: TextStyle(
                              color: textPrimaryColour,
                            ), // Sets the typed text colour to white
                            decoration: InputDecoration(
                              hintText:
                                  'Full Name', // Placeholder text shown when the field is empty
                              hintStyle: TextStyle(
                                color: labelColour,
                              ), // Sets the placeholder text colour to white with 40% opacity
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: textSecondaryColour,
                              ), // Displays a person icon inside the left side of the input field
                              filled:
                                  true, // Enables the background fill colour for the input field
                              fillColor:
                                  blackColour, // Sets the inside colour of the text field to black
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Rounds the input field corners
                                borderSide: BorderSide
                                    .none, // Removes the default underline border
                              ),
                            ),
                            // Checks if the user left the name field blank
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Please enter your name'
                                : null,
                            onSaved: (value) {
                              // Saves the name after validation succeeds
                              _name = value!.trim(); // Removes spaces around the full name
                            },
                          ),

                          // Vertical spacing between input fields
                          const SizedBox(height: 16),

                          // --- EMAIL INPUT FIELD ---
                          TextFormField(
                            style: TextStyle(
                              color: textPrimaryColour,
                            ), // Sets the typed text colour to white
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                              hintStyle: TextStyle(
                                color: labelColour,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: textSecondaryColour,
                              ), // Displays an email icon inside the left side of the input field
                              filled:
                                  true, // Enables the background fill colour for the input field
                              fillColor:
                                  blackColour, // Sets the inside colour of the text field to black
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Rounds the input field corners
                                borderSide: BorderSide
                                    .none, // Removes the default underline border
                              ),
                            ),

                            // Sets the device keyboard for email input (adds the @ symbol)
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              // Check if the email field is empty or not
                              if (value == null || value.isEmpty) {
                                return 'Please enter your account email';
                              }

                              // Regular expression to validate email format
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
                              );

                              // Check if the email format is valid
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email format (e.g. name@example.com)';
                              }

                              return null; // Return null if the input is valid
                            },
                            onSaved: (value) {
                              // Saves the email after validation succeeds
                              _email = value!.trim(); // Removes spaces around the email address
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            obscureText:
                                _obscurePassword, // Hides the text input when true
                            style: TextStyle(
                              color: textPrimaryColour,
                            ), // Sets the typed text colour to white
                            onChanged: (value) {
                              // Updates the local state string every time a key is pressed to feed the strength meter
                              setState(() {
                                _passwordText = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: labelColour,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: textSecondaryColour,
                              ), // Displays a lock icon inside the left side of the input field
                              // Adds an interactive icon to the right side of the input field
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons
                                            .visibility_outlined, // Changes the icon based on whether the password is currently hidden
                                  color: textSecondaryColour,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ), // Flips the boolean state to show or hide the password
                              ),
                              filled:
                                  true, // Enables the background fill colour for the input field
                              fillColor:
                                  blackColour, // Sets the inside colour of the text field to black
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Rounds the input field corners
                                borderSide: BorderSide
                                    .none, // Removes the default underline border
                              ),
                            ),
                            // Ensures the password meets a minimum length requirement
                            validator: (value) =>
                                value == null || value.trim().length < 8
                                ? 'Minimum 8 characters required'
                                : null,
                            onSaved: (value) {
                              // Saves the password exactly as entered, preserving intentional spaces.
                              _password = value!;
                            },
                          ),

                          // Vertical spacing before the strength meter
                          const SizedBox(height: 12),

                          // Password Strength Validation UI Widget
                          // Custom widget that calculates and visually displays password complexity
                          PasswordStrengthMeter(password: _passwordText),

                          // Vertical spacing before the confirm password field
                          const SizedBox(height: 16),

                          // --- CONFIRM PASSWORD INPUT FIELD ---
                          TextFormField(
                            obscureText:
                                _obscureConfirmPassword, // Hides the text input based on its specific boolean state
                            style: TextStyle(
                              color: textPrimaryColour,
                            ), // Sets the typed text colour to white
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              hintStyle: TextStyle(
                                color: labelColour,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: textSecondaryColour,
                              ), // Displays a lock icon inside the left side of the input field
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons
                                            .visibility_outlined, // Changes the icon based on whether the password is currently hidden
                                  color: textSecondaryColour,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ), // Flips the boolean state to show or hide the password
                              ),
                              filled:
                                  true, // Enables the background fill colour for the input field
                              fillColor:
                                  blackColour, // Sets the inside colour of the text field to black
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Rounds the input field corners
                                borderSide: BorderSide
                                    .none, // Removes the default underline border
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password'; // Checks if the field is empty
                              }
                              if (value != _passwordText) {
                                return 'Passwords do not match'; // Checks that both password fields match
                              }
                              return null;
                            },
                          ),

                          // Vertical spacing before the create account button
                          const SizedBox(height: 24),

                          // --- CREATE ACCOUNT BUTTON ---
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  accentColour, // Sets the primary background colour of the button
                              minimumSize: const Size.fromHeight(
                                55,
                              ), // Forces the button to stretch across the full width and be 55 pixels tall
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  28,
                                ), // Applies highly rounded, pill-shaped corners to the button
                              ),
                            ),
                            onPressed: _isRegisterLoading
                                ? null
                                : _handleRegistration, // Disables the button if currently loading, otherwise attaches the logic method
                            // Displays a loading spinner if active, otherwise shows the text and icon row
                            child: _isRegisterLoading
                                ? const SizedBox(
                                    // Sets the size of the loading indicator
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Color.fromARGB(221, 0, 0, 0),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    // Centers the icon and text together horizontally inside the button
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Displays a person icon next to the text
                                      const Icon(
                                        Icons.person,
                                        color: Color.fromARGB(221, 0, 0, 0),
                                        size: 20,
                                      ),

                                      // Horizontal spacing between the icon and text
                                      const SizedBox(width: 8),

                                      // Create account button label
                                      const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Vertical spacing below the login redirect section
                  const SizedBox(height: 24),

                  // --- LOGIN REDIRECT SECTION ---
                  // Arranges the prompt text and the tappable link in a centered horizontal line
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Centers the content inside horizontally
                    children: [
                      // Standard text prompting the user
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: textSecondaryColour,
                        ),
                      ),
                      // Wraps the text to make it respond to user taps
                      GestureDetector(
                        onTap: () {
                          // Closes the registration screen and returns the user to the login screen
                          Navigator.pop(context);
                        },
                        // Styled text that mimics a clickable hyperlink
                        child: Text(
                          "Log in",
                          style: TextStyle(
                            color: accentColour,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration
                                .underline, // Underlines text to look like a tappable link
                            decorationColor: accentColour,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Vertical spacing pushing up from the bottom of the scroll view
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Handles the logic for validating the form and registering the user via Firebase
  Future<void> _handleRegistration() async {
    // Triggers the form validators before proceeding
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!
          .save(); // Triggers the form field onSaved callbacks

      try {
        // Updates the UI state to show the loading spinner on the button
        setState(() => _isRegisterLoading = true);

        // Asks the Firebase service provider to create the user account
        await ref
            .read(firebaseServiceProvider)
            .register(
              _name, // Supplies the saved full name
              _email, // Supplies the saved email address
              _password, // Supplies the saved password
            );

        // Prevents the app from crashing if the user navigates away before the request finishes
        if (!mounted) return;

        // Displays a success notification at the bottom of the screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account successfully created!',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            backgroundColor:
                Colors.green, // Background Colour of floating pill set to green
            behavior: SnackBarBehavior
                .floating, // Detaches the snackbar from the bottom edge to make it look like a floating pill
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // Matches the corner radiuses used elsewhere in the application
            margin: const EdgeInsets.only(
              bottom:
                  20, // Pushes the snackbar up from the bottom of the phone screen
              // Side padding to align with the screen content layout
              left: 24,
              right: 24,
            ),
          ),
        );

        // Navigates to Email Verification Screen
        // Removes history to prevent user from returning to previous page
        Navigator.pushReplacementNamed(
          context,
          EmailVerificationScreen.routeName,
        );
      } catch (e) {
        // Prevents the app from crashing if the user navigates away before the network request finishes
        if (!mounted) return;

        // Catches any errors returned directly by Firebase and displays them to the user
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
            backgroundColor: Colors
                .redAccent, // Background Colour of floating pill set to red
            behavior: SnackBarBehavior
                .floating, // Detaches the snackbar from the bottom edge to make it look like a floating pill
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // Matches the corner radiuses used elsewhere in the application
            margin: const EdgeInsets.only(
              bottom:
                  20, // Pushes the snackbar up from the bottom of the phone screen
              // Side padding to align with the screen content layout
              left: 24,
              right: 24,
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isRegisterLoading = false);
      }
    }
  }
}
