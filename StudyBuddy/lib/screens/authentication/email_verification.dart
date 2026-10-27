import 'dart:async';
import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:mbap_project/widgets/default_background.dart';
import 'package:mbap_project/providers/firebase_provider.dart';
import 'package:mbap_project/providers/theme_provider.dart';

// The screen's widget, immutable, points to its state class below
class EmailVerificationScreen extends ConsumerStatefulWidget {
  // Named route for navigation mapping
  static const String routeName = '/email-verification';
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

// Holds the mutable state and UI logic for the email verification screen
class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  // Timer variables to manage the countdown and resend button cooldown
  Timer? _timer;
  int _expirySeconds = 300; // 5 minutes countdown
  int _resendSeconds = 30; // 30 seconds cooldown before user can click resend again
  bool _canResend = false; // Controls if the resend button is clickable

  // Local state variable to track the loading status of the resend button
  bool _isResending = false;



  @override
  void initState() {
    super.initState();
    
    // Sends the first verification email as soon as the screen opens
    _sendInitialVerificationEmail();
    
    // Starts the main timer clock to handle all countdowns
    _startMasterTimer();
  }

  // Sets up a timer that ticks every second to manage the countdown and resend button cooldown
  void _startMasterTimer() {
    // This timer ticks exactly once every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Stops the timer from running if the user leaves the screen
      if (!mounted) return;

      bool expiryReachedThisTick = false;

      setState(() {
        // Decreases the five-minute display timer
        if (_expirySeconds > 0) {
          _expirySeconds--;

          if (_expirySeconds == 0) {
            _canResend = true;
            expiryReachedThisTick = true;
          }
        }

        // Decreases the 30-second resend button cooldown
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
        }
      });

      // Displays the message once when the timer first reaches zero
      if (expiryReachedThisTick) {
        _showMessage(
          'Verification timer ended. Tap Resend Email for a new link.',
          Colors.orange,
        );
      }

      // Background Auto-Check. Ask Firebase every 3 seconds to check if verified
      if (timer.tick % 3 == 0) {
        await _checkEmailVerified();
      }
    });
  }

  // Helper function to turn "300" seconds into "05:00" format to display on the screen
  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Critical: Kills the timer when the screen closes to prevent memory leaks
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    // Gets the current user to display their actual email address on the screen
    final currentUser = ref.watch(authStateProvider).value;
    return Scaffold(
      // Sets the custom gradient background for the screen
      body: DefaultBackground( // Default background with gradient
        child: SafeArea( // SafeArea prevents UI elements from overlapping with device notches and status bars
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),// Centers all child widgets horizontally within the column
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pushes the top content down 45 pixels from the safe area boundary
                const SizedBox(height: 45),

                // --- HEADER SECTION ---
                Container(
                  padding: const EdgeInsets.all(16), // Internal padding between the icon and the container border
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 0, 0).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_email_read_outlined, size: 48, color: accentColour),
                ),
                const SizedBox(height: 24),
                
                // Main title text
                Text(
                  'Verify your email',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryColour),
                ),
                const SizedBox(height: 12),
                
                // Dynamic text showing the user's specific email address with highlighted styling
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    // Default style for the surrounding text, using 70% opacity white
                    style: TextStyle(color: textSecondaryColour, fontSize: 18, height: 1.5),
                    children: [
                      const TextSpan(text: "We've sent a verification link to\n"),
                      TextSpan(
                        text: currentUser?.email ?? "your email address", // Inserts the current user's email or a fallback string
                        style: TextStyle(color: accentColour, fontWeight: FontWeight.bold), // Highlights the email address in the primary accent colour
                      ),
                      const TextSpan(text: ". Please\ncheck your inbox."),
                    ],
                  ),
                ),

                // Vertical spacing before the timer card
                const SizedBox(height: 32),

                // --- TIMER CARD SECTION ---
                // Dark card holding the countdown visuals
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: darkGreyColour,
                    borderRadius: BorderRadius.circular(16), // Rounds the corners of the card
                    border: Border.all(color: borderColour), // Adds a faint white outline to separate the card from the background
                    gradient: LinearGradient(
                      begin: Alignment.topRight, // From the top right corner
                      end: Alignment.bottomLeft, // To the bottom left corner
                      colors: [
                        Color.lerp(darkGreyColour, accentColour, 0.2)!, // Mixes 6% accent into the card colour
                        darkGreyColour, // Card background from the active mode
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // The large circular timer ring
                      Container(
                        // Fixed dimensions to ensure the circle remains perfectly round
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Draws the solid accent border ring around the timer
                          border: Border.all(color: accentColour, width: 8),
                        ),
                        child: Column(
                          // Centers the text vertically inside the circle
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Displays the active countdown time
                            Text(
                              _formatTime(_expirySeconds),
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColour,
                              ),
                            ),

                            // Vertical spacing between the time and the "REMAINING" label
                            const SizedBox(height: 4),

                            // The "REMAINING" label below the countdown timer
                            Text(
                              'REMAINING',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.5, // Adds extra spacing between letters
                                color: accentColour.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vertical spacing between the ring and the pill indicator
                      const SizedBox(height: 32),
                      
                      // The Pill Indicator below the timer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Internal padding to shape the pill (16 horizontal, 8 vertical)
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3), // Semi-transparent black background
                          borderRadius: BorderRadius.circular(20), // High border radius to create the pill shape
                          border: Border.all(color: borderColour),
                        ),
                        child: Row(
                          // Shrinks the row to exactly fit the icon and text
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: accentColour), // Horizontal spacing between the icon and text
                            const SizedBox(width: 8),
                            Text(
                              'Link expires in 5 mins',
                              style: TextStyle(color: textSecondaryColour, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vertical spacing between the timer card and the bottom action section
                const SizedBox(height: 50),

                // --- BOTTOM ACTION SECTION ---
                Text(
                  "Didn't receive the email?",
                  style: TextStyle(color: textSecondaryColour, fontSize: 16, letterSpacing: 1),
                ),

                // Vertical spacing above the button
                const SizedBox(height: 16),
                
                // Resend email button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColour, // Fades the button background when it is locked/disabled
                    disabledBackgroundColor: accentColour.withValues(alpha: 0.3), // Fades out when resend button is locked
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28), // Highly rounded corners for a modern button style
                    ),
                  ),
                  // Enables the button only after the cooldown and while no request is running
                  onPressed: (_canResend && !_isResending)
                    ? _resendVerificationEmail
                    : null,
                                  
                  // Displays the loading spinner if active, otherwise shows the dynamic text and icon
                  child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(221, 0, 0, 0),
                          strokeWidth: 2,
                        ),
                      )
                      
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Centers the content inside horizontally
                      children: [
                        // Dynamic text that changes based on the button lock state
                        Text(
                          _canResend ? 'Resend Email' : 'Resend in ${_resendSeconds}s',
                          style: TextStyle(
                            color: _canResend ? Colors.black87 : textSecondaryColour,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Horizontal spacing between text and icon
                        const SizedBox(width: 8),
                        
                        Icon(
                          Icons.send, 
                          color: _canResend ? Colors.black87 : textSecondaryColour, 
                          size: 20
                        ),
                      ],
                    ),
                  ),
                  // Vertical spacing from the bottom edge of the screen
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Displays a floating SnackBar using the same design for all feedback
    void _showMessage(String message, Color backgroundColour) {

      // Prevents context access after the screen has been removed
      if (!mounted) return;

      // Gets the nearest ScaffoldMessenger for displaying feedback
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar() // Removes existing feedback before displaying the latest message
        ..showSnackBar( // Displays the success or error message
          SnackBar(
            // Displays the message passed into this helper method
            content: Text(
              message,
              style: TextStyle(color: textPrimaryColour),
            ),
            backgroundColor: backgroundColour, // Uses green for success or red for failure
            behavior: SnackBarBehavior.floating, // Displays the SnackBar as a floating notification

            // Matches the rounded styling used across the application
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), 
            ),

            // Adds spacing around the floating notification
            margin: const EdgeInsets.only(
              bottom: 20,
              left: 24,
              right: 24,
            ),
          ),
        );
    }

    // Sends the first verification email when the screen opens
    Future<void> _sendInitialVerificationEmail() async {
      try {
        // Gets the Firebase service through Riverpod
        final firebaseService = ref.read(firebaseServiceProvider);

        // Waits for Firebase to complete the email request
        await firebaseService.sendEmailVerification();
      } catch (error) {
        // Stops UI updates if the screen was closed during the request
        if (!mounted) return;

        // Removes the normal cooldown so the user can retry immediately
        setState(() {
          _canResend = true;
          _resendSeconds = 0;
        });

        // Converts the caught error into a user-friendly message
        final message = 'Unable to send the verification email. Please try again.';

        // Displays the failure using the standard red SnackBar
        _showMessage(message, Colors.redAccent);
      }
    }

    // Checks the account and resends the verification email
    Future<void> _resendVerificationEmail() async {
      // Shows the loading indicator and prevents repeated button presses
      setState(() => _isResending = true);

      try {
        // Gets the Firebase service through Riverpod
        final firebaseService = ref.read(firebaseServiceProvider);

        // Reloads the account before sending another email
        final isVerified = await firebaseService.checkEmailVerified();

        // Stops UI updates if the screen was closed during the request
        if (!mounted) return;

        // Handles an account that was verified outside the application
        if (isVerified) {
          _showMessage(
            'Your email is already verified!',
            Colors.green,
          );

          ref.invalidate(authStateProvider);
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }

        // Requests a new verification email through FirebaseService
        // Any authentication error is handled by the catch block below
        await firebaseService.sendEmailVerification();

        // Stops UI updates if the screen was closed during the request
        if (!mounted) return;

        // Restarts both timers only after Firebase accepts the request
        setState(() {
          _canResend = false; // Locks the Resend button during the cooldown
          _resendSeconds = 30; // Restarts the 30-second Resend button cooldown
          _expirySeconds = 300; // Restarts the five-minute display timer
        });

        // Confirms that Firebase accepted the resend request
        _showMessage(
          'Verification email sent successfully!',
          Colors.green,
        );
      } catch (error) {
        // Converts Firebase and unexpected errors into a safe message
        final message = 'Unable to resend the verification email. Please try again.';

        // Displays the failure without restarting the timers
        _showMessage(message, Colors.redAccent);
      } finally {
        // Runs after success, failure, or an early return
        if (mounted) {
          setState(() => _isResending = false); // Hides the loading indicator and re-enables the button
        }
      }
    }

  // Checks the user's verification status automatically in the background
  Future<void> _checkEmailVerified() async {
    try {
      // Gets the Firebase service through Riverpod
      final firebaseService =
          ref.read(firebaseServiceProvider);

      // Reloads the current Firebase user and checks their latest status
      final isVerified =
          await firebaseService.checkEmailVerified();

      // Stops UI and navigation updates if the screen was closed
      if (!mounted) return;

      // Stops here when the user has not verified their email
      // The periodic timer will check the account again later
      if (!isVerified) return;

      // Stops future automatic checks after verification succeeds
       _timer?.cancel();

      _showMessage(
        'Email verified successfully! Logging in',
        Colors.green,
      );

      // Refreshes the auth provider so it picks up the updated emailVerified value.
      ref.invalidate(authStateProvider);

      // Returns to the root route where the auth routing re-evaluates.
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (_) {
      // Ignores temporary network failures during the background check
      // The periodic timer will automatically try again in three seconds
    }
  }
}