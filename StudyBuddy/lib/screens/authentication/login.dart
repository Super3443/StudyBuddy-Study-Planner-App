import 'package:flutter/material.dart';
import 'package:mbap_project/screens/authentication/registration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbap_project/providers/theme_provider.dart';
import '../../providers/firebase_provider.dart';
import 'forgot_password_screen.dart';
import '../../widgets/default_background.dart';

// The screen's widget, immutable, points to its state class below
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

// Holds the mutable state and UI logic for the login screen
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  String _email = ''; // Stores the validated email address
  String _password = ''; // Stores the validated password

  // Local state variables to track the loading status of each individual button
  bool _isLoggingIn = false;
  bool _isGoogleLoading = false;
  bool _isGitHubLoading = false;

  bool _obscurePassword =
      true; // Controls whether the password text is hidden as dots

  @override
  // Main build method for the login screen, structured with a gradient background, header, form card, and footer link
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    return Scaffold(
      // The main body of the login screen
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
                      ), // Creates a circular background for the back button with 5% white opacity
                      gradient: LinearGradient(
                        begin: Alignment.topRight, // From the top right corner
                        end: Alignment.bottomLeft, // To the bottom left corner
                        colors: [
                          Color.lerp(darkGreyColour, accentColour, 0.2)!, // Mixes 6% accent into the card colour
                          darkGreyColour, // Card background from the active mode
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.school, // Material School Icon
                      size:
                          40, // Reduced icon size slightly to account for the new shape's layout
                      color:
                          accentColour, // Keep the solid accent color
                    ),
                  ),

                  // Vertical spacing before the Main title
                  const SizedBox(height: 16),

                  // Main application title
                  Text(
                    'StudyBuddy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          accentColour, // Keep the solid accent color for the app name
                    ),
                  ),

                  // Vertical spacing before the subtitle
                  const SizedBox(height: 8),

                  // Application subtitle
                  Text(
                    'Continue your journey to smarter studying.',
                    style: TextStyle(
                      color: textSecondaryColour,
                      fontSize: 16,
                    ), // Subtitle with 70% white opacity
                  ),

                  // Vertical spacing below the subtitle
                  const SizedBox(height: 32),

                  // Login screen header text
                  Text(
                    'Login your account',
                    style: TextStyle(
                      // Larger and bolder, white text for the form header
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColour,
                    ),
                  ),

                  // Vertical spacing before the Form Card
                  const SizedBox(height: 24),

                  // --- FORM CARD SECTION ---
                  // Dark card holding the input fields and submit button
                  Container(
                    padding: const EdgeInsets.all(
                      24,
                    ), // Internal padding on all sides of the card
                    decoration: BoxDecoration(
                      color: darkGreyColour, // Sets the base background colour
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Rounds the corners of the card
                      border: Border.all(
                        color: borderColour,
                      ), // White border around entire card with 5% opacity
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
                            autofillHints: const [
                              AutofillHints.email,
                            ], // Lets the device suggest saved emails
                            keyboardType: TextInputType
                                .emailAddress, // Sets the device keyboard for email input (adds the @ symbol)
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

                          // Verticle spacing before the password input field
                          const SizedBox(height: 16),

                          // --- PASSWORD INPUT FIELD ---
                          TextFormField(
                            obscureText:
                                _obscurePassword, // Hides the password text into dots
                            style: TextStyle(
                              color: textPrimaryColour,
                            ), // Sets the typed text colour to white
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
                            // Checks if the field was left blank
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter your password'
                                : null,
                            onSaved: (value) {
                              // Saves the password after validation succeeds
                              _password = value!; // Saves the password exactly as entered
                            },
                          ),

                          // Vertical spacing before the forgot password link
                          const SizedBox(height: 16),

                          // --- FORGOT PASSWORD LINK ---
                          Align(
                            alignment: Alignment
                                .centerRight, // Pushes the link to the right edge of the card
                            child: GestureDetector(
                              onTap: () {
                                // Navigates to the forgot password screen when tapped
                                Navigator.pushNamed(
                                  context,
                                  ForgotPasswordScreen.routeName,
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: accentColour,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Vertical spacing before the login button
                          const SizedBox(height: 24),

                          // LOGIN BUTTON
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
                            onPressed: _isLoggingIn
                                ? null
                                : _handleLogin, // Disables the button if currently loading, otherwise attaches the logic method
                            // Displays a loading spinner if active, otherwise shows the text and icon row
                            child: _isLoggingIn
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Color.fromARGB(221, 0, 0, 0),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    // Centers the text and icon together horizontally inside the button
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Login Account',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Color.fromARGB(221, 0, 0, 0),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Vertical spacing before the "OR" seperator
                  const SizedBox(height: 24),

                  // --- "OR" DIVIDER ---
                  // Separates the standard login form from the third-party sign-in options
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: dividerColour,
                        ),
                      ), // Fills remaining space on the right with a 2% opacity line
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ), // Spacing either side of the "OR" text
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: unselectedNavColour,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: dividerColour,
                        ),
                      ), // Fills remaining space on the right with a 2% opacity line
                    ],
                  ),

                  // Vertical spacing before the Google Sign in button
                  const SizedBox(height: 16),

                  // --- GOOGLE SIGN-IN BUTTON (Advanced Authentication Method) ---
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        55,
                      ), // Stretches the button across the full width, 55 pixels tall
                      side: BorderSide(
                        color: borderColour,
                      ), // White outline around the button with 2% opacity
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ), // Fully rounded pill shape
                      backgroundColor: darkGreyColour,
                    ),
                    onPressed: _isGoogleLoading
                        ? null
                        : _handleGoogleSignIn, // Disables the button while the sign-in request is loading
                    // Displays a loading spinner if active, otherwise shows the icon and text row
                    child: _isGoogleLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: textPrimaryColour,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Centers the content inside horizontally
                            children: [
                              Image.asset(
                                'images/google_icon.png',
                                height: 20,
                              ), // Google logo asset
                              // Horizontal spacing between the icon and text
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: textPrimaryColour,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Spacing between the Google and Github login buttons
                  const SizedBox(height: 12),

                  // --- GITHUB SIGN-IN BUTTON (Advanced Authentication Method) ---
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        55,
                      ), // Stretches the button across the full width, 55 pixels tall
                      side: BorderSide(
                        color: borderColour,
                      ), // White outline around the button with 2% opacity
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ), // Rounded pill shape
                      backgroundColor: darkGreyColour,
                    ),
                    onPressed: _isGitHubLoading
                        ? null
                        : _handleGitHubSignIn, // Disables the button while the sign-in request is loading
                    // Displays a loading spinner if active, otherwise shows the icon and text row
                    child: _isGitHubLoading
                        ? SizedBox(
                            // Constrains the size of the loading indicator
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: textPrimaryColour,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Centers the content inside horizontally
                            children: [
                              Image.asset(
                                'images/github_icon.png',
                                height: 20,
                                color: textPrimaryColour, // Tints the icon to match the current mode
                              ), // GitHub logo asset
                              // Horizontal spacing between the icon and text
                              const SizedBox(width: 12),
                              Text(
                                'Continue with GitHub',
                                style: TextStyle(
                                  color: textPrimaryColour,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Vertical spacing before Create account link
                  // Arranges the text and the tappable link in a centred horizontal line
                  const SizedBox(height: 24),

                  // --- CREATE ACCOUNT LINK ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Centers the content inside horizontally
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: textSecondaryColour,
                        ),
                      ),
                      // Wraps the text to make it respond to user taps
                      GestureDetector(
                        onTap: () async {
                          // Wait for user to navigate away and return
                          await Navigator.pushNamed(
                            context,
                            RegisterScreen.routeName,
                          );
                          // Reset form errors and input fields completely upon return
                          if (mounted) {
                            _formKey.currentState?.reset();
                            _email = ''; // Clears the saved email value
                            _password = ''; // Clears the saved password value
                          }
                        },
                        // Styled text that looks like a clickable link
                        child: Text(
                          "Create one",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Handles the logic for validating the form and logging the user in via Firebase
  Future<void> _handleLogin() async {
    // Triggers the form validators before proceeding
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!
          .save(); // Triggers the form field onSaved callbacks

      // Updates the UI state to show the loading spinner on the button
      setState(() => _isLoggingIn = true);
      try {
        // Asks the Firebase service provider to authenticate the user
        await ref
            .read(firebaseServiceProvider)
            .login(
              _email, // Supplies the saved email address
              _password, // Supplies the saved password
            );

        // Prevents the app from crashing if the user navigates away before the request finishes
        if (!mounted) return;

        // If login is successful, show a success message and navigate to the main screen
        // Navigation to the main screen is handled automatically by authStateProvider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login Successful!',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            backgroundColor:
                Colors.green, // Background colour of floating pill set to green
            behavior: SnackBarBehavior
                .floating, // Turns the bar into a floating pill container
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // Matches card corner radiuses
            margin: const EdgeInsets.only(
              bottom:
                  20, // Pushes the snackbar up from the bottom of the phone screen
              left: 24,
              right: 24,
            ),
          ),
        );
      } catch (e) {
        // Prevents the app from crashing if the user navigates away before the request finishes
        if (!mounted) return;

        // Displays the actual Firebase error reason to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''), // Strips the Exception prefix
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
            backgroundColor: Colors
                .redAccent, // Background colour of floating pill set to red
            behavior: SnackBarBehavior
                .floating, // Turns the bar into a floating pill container
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // Matches card corner radiuses
            margin: const EdgeInsets.only(
              bottom:
                  20, // Pushes the snackbar up from the bottom of the phone screen
              left: 24,
              right: 24,
            ),
          ),
        );
      } finally {
        // Always clears the loading spinner, whether login succeeded or failed
        if (mounted) setState(() => _isLoggingIn = false);
      }
    }
  }

  // Handles the logic for signing in with a Google account via Firebase
  Future<void> _handleGoogleSignIn() async {
    // Updates the UI state to show the loading spinner on the button
    setState(() => _isGoogleLoading = true);
    try {
      // Asks the Firebase service provider to run the Google sign-in flow
      final result = await ref.read(firebaseServiceProvider).signInWithGoogle();

      // User cancelled the Google sign-in popup
      if (result == null) return;

      // Prevents the app from crashing if the user navigates away before the request finishes
      if (!mounted) return;

      // If login is successful, show a success message and navigate to the main screen
      // Navigation to the main screen is handled automatically by authStateProvider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In Successful!',
            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
          backgroundColor:
              Colors.green, // Background colour of floating pill set to green
          behavior: SnackBarBehavior
              .floating, // Turns the bar into a floating pill container
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Matches card corner radiuses
          margin: const EdgeInsets.only(
            bottom:
                10, // Pushes the snackbar up from the bottom of the phone screen
            left: 24,
            right: 24,
          ),
        ),
      );
    } catch (error) {
      // Prevents the app from crashing if the user navigates away before the request finishes
      if (!mounted) return;

      // Catches any errors returned directly by Firebase and displays them to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In failed. Please try again later',
          ),
          backgroundColor:
              Colors.redAccent, // Background colour of floating pill set to red
          behavior: SnackBarBehavior
              .floating, // Turns the bar into a floating pill container
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Matches card corner radiuses
          margin: const EdgeInsets.only(
            bottom:
                10, // Pushes the snackbar up from the bottom of the phone screen
            left: 24,
            right: 24,
          ),
        ),
      );
    } finally {
      // Always clears the loading spinner, whether sign-in succeeded or failed
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // Handles the logic for signing in with a GitHub account via Firebase
  Future<void> _handleGitHubSignIn() async {
    // Updates the UI state to show the loading spinner on the button
    setState(() => _isGitHubLoading = true);
    try {
      // Asks the Firebase service provider to run the GitHub sign-in flow
      final result = await ref.read(firebaseServiceProvider).signInWithGitHub();

      // User cancelled the GitHub sign-in
      if (result == null) return;

      // Prevents the app from crashing if the user navigates away before the request finishes
      if (!mounted) return;

      // If login is successful, show a success message and navigate to the main screen
      // Navigation to the main screen is handled automatically by authStateProvider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GitHub Sign-In Successful!',
            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
          backgroundColor:
              Colors.green, // Background colour of floating pill set to green
          behavior: SnackBarBehavior
              .floating, // Turns the bar into a floating pill container
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Matches card corner radiuses
          margin: const EdgeInsets.only(
            bottom:
                10, // Pushes the snackbar up from the bottom of the phone screen
            left: 24,
            right: 24,
          ),
        ),
      );
    } catch (error) {
      // Stops if the login screen was removed while GitHub Sign-In was running
      if (!mounted) return;

      // Gets the messenger used to manage SnackBars on the login screen
      final messenger = ScaffoldMessenger.of(context);

      // Removes any previous message before displaying the latest error
      messenger.hideCurrentSnackBar();

      // Displays the error message from the service
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.black),
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 10, left: 24, right: 24),
        ),
      );
    } finally {
      // Always clears the loading spinner, whether sign-in succeeded or failed
      if (mounted) setState(() => _isGitHubLoading = false);
    }
  }
}
