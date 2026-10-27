import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:introduction_screen/introduction_screen.dart'; // Onboarding page view library
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours

// Displays a first-launch walkthrough explaining the app's main features.
class OnboardingScreen extends StatelessWidget {
  // Callback that runs when the user finishes or skips the onboarding.
  final VoidCallback onComplete; // Returns to the main screen after onboarding

  const OnboardingScreen({super.key, required this.onComplete});

  // Builds a single onboarding page with a screenshot, title, and description.
  PageViewModel _buildPage({
    required String title, // Sets the page heading
    required String body, // Sets the page description
    required String imagePath, // Points to the screenshot asset
  }) {
    return PageViewModel(
      title: title, // Displays the page heading
      body: body, // Displays the page description
      image: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Rounds the screenshot corners
          child: Image.asset(
            imagePath, // Loads the screenshot from the assets folder
            height: 420, // Increases the screenshot height
            fit: BoxFit.contain, // Keeps the screenshot proportions
            cacheHeight: 840, // Decodes at 2x display height to save memory
          ),
        ),
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(
          color: textPrimaryColour, // Sets the white heading colour
          fontSize: 24, // Sets the heading size
          fontWeight: FontWeight.bold, // Makes the heading bold
        ),
        bodyTextStyle: TextStyle(
          color: textSecondaryColour, // Sets the muted description colour
          fontSize: 15, // Sets the description size
          height: 1.5, // Adds line spacing for readability
        ),
        pageColor: blackColour, // Sets the dark page background
        imageFlex: 4, // Gives the image 3x more space than the text area
        bodyFlex: 1, // Gives the text area less space, pushing it down
        imagePadding: const EdgeInsets.only(top: 100), // Pushes the image down from the top
        bodyPadding: const EdgeInsets.symmetric(horizontal: 24), // Adds space around the description
        titlePadding: const EdgeInsets.only(top: 24, bottom: 12), // Adds space around the heading
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      // Sets the background colour for the entire onboarding screen.
      globalBackgroundColor: blackColour, // Matches the main app background

      // Builds the list of onboarding pages.
      pages: [
        // --- PAGE 1: WELCOME ---
        _buildPage(
          title: 'Welcome to StudyBuddy',
          body: 'Your personal study companion. Track tasks, generate AI study plans, and stay on top of your schedule.',
          imagePath: 'images/onboarding_1.png', // Dashboard screenshot
        ),

        // --- PAGE 2: CREATE TASKS ---
        _buildPage(
          title: 'Create Study Tasks',
          body: 'Add tasks with dates, times, priorities, and custom tags. Stay organised with everything in one place.',
          imagePath: 'images/onboarding_2.png', // Create task modal screenshot
        ),

        // --- PAGE 3: MANAGE TASKS ---
        _buildPage(
          title: 'Manage Your Tasks',
          body: 'View, edit, and filter your tasks. Mark them complete and track your daily progress.',
          imagePath: 'images/onboarding_3.png', // View all tasks screenshot
        ),

        // --- PAGE 4: AI STUDY PLANS ---
        _buildPage(
          title: 'AI-Powered Schedules',
          body: 'Enter your exams and let the AI generate an optimal study plan tailored to your priorities.',
          imagePath: 'images/onboarding_4.png', // AI screen screenshot
        ),

        // --- PAGE 5: CALENDAR & ANALYTICS ---
        _buildPage(
          title: 'Track Your Progress',
          body: 'View your tasks on the calendar and analyse your study habits with detailed charts.',
          imagePath: 'images/onboarding_5.png', // Calendar screen screenshot
        ),
      ],

      // --- NAVIGATION CONTROLS ---

      // Shows a Skip button on every page except the last.
      showSkipButton: true, // Displays the skip option

      // Displays the Skip button text.
      skip: Text(
        'Skip', // Sets the skip label
        style: TextStyle(
          color: textSecondaryColour, // Sets the muted text colour
          fontSize: 16, // Sets the label size
        ),
      ),

      // Displays the Next button text.
      next: Icon(
        Icons.arrow_forward_rounded, // Sets the next arrow icon
        color: accentColour, // Sets the accent colour
        size: 24, // Sets the icon size
      ),

      // Displays the Done button on the final page.
      done: Text(
        'Get Started', // Sets the done label
        style: TextStyle(
          color: accentColour, // Sets the accent colour
          fontSize: 16, // Sets the label size
          fontWeight: FontWeight.bold, // Makes the label bold
        ),
      ),

      // Runs the callback when the user taps Done on the last page.
      onDone: onComplete, // Completes the onboarding flow

      // Runs the callback when the user taps Skip on any page.
      onSkip: onComplete, // Completes the onboarding flow early

      // Styles the page indicator dots at the bottom.
      dotsDecorator: DotsDecorator(
        size: const Size(8, 8), // Sets the inactive dot size
        activeSize: const Size(22, 8), // Stretches the active dot wider
        activeColor: accentColour, // Sets the active dot colour
        color: textSecondaryColour.withValues(alpha: 0.3), // Sets the inactive dot colour
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Rounds the active dot corners
        ),
      ),
    );
  }
}