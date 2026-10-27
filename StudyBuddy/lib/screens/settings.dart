import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbap_project/providers/theme_provider.dart';
import 'package:mbap_project/providers/firebase_provider.dart';
import 'package:mbap_project/providers/biometric_provider.dart';
import 'package:mbap_project/providers/ai_access_provider.dart'; // Reads the current AI plan
import 'package:mbap_project/screens/ai_plan_selection.dart'; // Opens the plan selection screen

// The screen's widget, immutable, points to its state class below
class SettingsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// Holds the mutable state and UI logic for the Settings screen
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local state variable to track the loading status of the logout button
  bool _isLoggingOut = false;
  bool _biometricEnabled = false; // Tracks whether biometric login is on
  bool _biometricSupported = false; // Tracks whether the device supports biometrics

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting(); // Loads the saved biometric preference
  }

  // Loads the current biometric setting from Firestore
  Future<void> _loadBiometricSetting() async {
    final biometric = ref.read(biometricProvider); // Reads the biometric provider
    final supported = await biometric.isDeviceSupported(); // Checks device support

    final user = ref.read(authStateProvider).value; // Reads the current user

    if (user != null) {
      final enabled = await biometric.isEnabled(user.uid); // Checks Firestore setting
      if (mounted) {
        setState(() {
          _biometricSupported = supported; // Stores the device support result
          _biometricEnabled = enabled; // Stores the saved preference
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value; // Watches the current user
    final accessState = ref.watch(aiAccessProvider); // Watches the AI access state

    // Reads the active colour scheme and brightness mode for the theme selector.
    ref.watch(themeProvider); // Rebuilds when the theme changes
    final themeNotifier = ref.read(themeProvider.notifier); // Reads the theme notifier
    final currentScheme = themeNotifier.currentScheme; // Gets the active colour scheme
    final currentMode = themeNotifier.currentMode; // Gets the active brightness mode

    // For checking if the app is currently loading the logout process
    return Scaffold(
      body: SafeArea( // Prevents UI elements from overlapping with device status bars
        child: Column( // Column layout for the screen's content
          crossAxisAlignment: CrossAxisAlignment.start, // Aligns all child elements to the left edge of the screen
          children: [
            // --- HEADER SECTION ---
            // Arranges the back button and title horizontally
            Row(
              children: [
                // Navigates the user back to the previous screen when tapped
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textPrimaryColour), // Back arrow icon
                  onPressed: () => Navigator.pop(context), // Pops the current screen
                ),
                // Screen title
                Text(
                  'Settings', // Sets the screen title
                  style: TextStyle( // Styles the screen title
                    fontSize: 26, // Sets the title size
                    fontWeight: FontWeight.bold, // Makes the title bold
                    color: textPrimaryColour, // Sets the title colour
                  ),
                ),
              ],
            ),

            // --- DIVIDER ---
            Row(
              children: [
                // Forces the divider to span the entire horizontal space
                Expanded(
                  child: Divider(color: dividerColour), // Horizontal line separating the header from the content
                ),
              ],
            ),

            // --- SETTINGS CONTENT ---
            // Forces the content area to fill the remaining vertical space
            Expanded(
              child: Padding( // Padding on all sides
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24), // Sets the padding values
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Aligns content to the left
                  children: [
                    // Section label for account details
                    Text(
                      'ACCOUNT', // Sets the section label
                      style: TextStyle( // Styles the section label
                        color: labelColour, // Sets the label colour
                        fontSize: 13, // Sets the label size
                        fontWeight: FontWeight.w600, // Makes the label semi-bold
                        letterSpacing: 2.0, // Adds spacing between letters
                      ),
                    ),

                    // Vertical spacing before the user email section
                    const SizedBox(height: 12),

                    // Card for the user's email address
                    Container(
                      // Internal padding for the email card
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration( // Styles the email card
                        color: darkGreyColour, // Sets the card background colour
                        borderRadius: BorderRadius.circular(12), // Rounds the card corners
                        border: Border.all(color: borderColour), // Sets the card border
                      ),
                      // Arranges the email icon and text horizontally
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, color: accentColour, size: 20), // Email icon
                          const SizedBox(width: 12), // Adds space between the icon and text
                          // Fetches and displays the current user's email from Firebase
                          Text(
                            currentUser?.email ?? '', // Displays the email or empty string
                            style: TextStyle( // Styles the email text
                              color: textSecondaryColour, // Sets the text colour
                              fontSize: 15, // Sets the text size
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- SECURITY SECTION ---
                    const SizedBox(height: 24), // Adds vertical spacing

                    Text(
                      'SECURITY', // Sets the section label
                      style: TextStyle( // Styles the section label
                        color: labelColour, // Sets the label colour
                        fontSize: 13, // Sets the label size
                        fontWeight: FontWeight.w600, // Makes the label semi-bold
                        letterSpacing: 2.0, // Adds spacing between letters
                      ),
                    ),

                    const SizedBox(height: 12), // Adds vertical spacing

                    // Biometric verification toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Sets the internal padding
                      decoration: BoxDecoration( // Styles the biometric card
                        color: darkGreyColour, // Sets the card background colour
                        borderRadius: BorderRadius.circular(12), // Rounds the card corners
                        border: Border.all(color: borderColour), // Sets the card border
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint, color: accentColour, size: 20), // Fingerprint icon
                          const SizedBox(width: 12), // Adds space between the icon and text
                          Expanded(
                            child: Text(
                              'Fingerprint Verification', // Sets the toggle label
                              style: TextStyle( // Styles the toggle label
                                color: textSecondaryColour, // Sets the text colour
                                fontSize: 15, // Sets the text size
                              ),
                            ),
                          ),
                          Switch( // Biometric toggle switch
                            value: _biometricEnabled, // Sets the switch state
                            onChanged: _biometricSupported // Enables the switch only if device supports biometrics
                                ? (value) async {
                                    final user = ref.read(authStateProvider).value; // Reads the current user
                                    if (user == null) return; // Stops if no user is logged in
                                    // Captures the messenger before the async gap.
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await ref.read(biometricProvider).setEnabled(user.uid, value); // Saves the preference
                                      if (!mounted) return; // Stops if the screen was closed during the save
                                      setState(() => _biometricEnabled = value); // Updates the local state
                                    } catch (_) {
                                      if (!mounted) return; // Stops if the screen was closed during the error
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Unable to update biometric setting.', style: TextStyle(color: textPrimaryColour)),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                                        ),
                                      );
                                    }
                                  }
                                : null, // Disables the switch when unsupported
                            activeThumbColor: accentColour, // Sets the active thumb colour
                          ),
                        ],
                      ),
                    ),

                    // --- AI PLAN SECTION ---
                    const SizedBox(height: 24), // Adds vertical spacing

                    // Section label for AI plan details.
                    Text(
                      'AI PLAN', // Sets the section label
                      style: TextStyle( // Styles the section label
                        color: labelColour, // Sets the label colour
                        fontSize: 13, // Sets the label size
                        fontWeight: FontWeight.w600, // Makes the label semi-bold
                        letterSpacing: 2.0, // Adds spacing between letters
                      ),
                    ),

                    const SizedBox(height: 12), // Adds vertical spacing

                    // Card showing the active plan and upgrade option.
                    Container(
                      padding: const EdgeInsets.symmetric( // Sets the internal padding
                        horizontal: 16, // Horizontal padding
                        vertical: 14, // Vertical padding
                      ),
                      decoration: BoxDecoration( // Styles the AI plan card
                        color: darkGreyColour, // Sets the card background colour
                        borderRadius: BorderRadius.circular(12), // Rounds the card corners
                        border: Border.all( // Sets the card border
                          color: borderColour, // Sets the border colour
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon( // AI plan icon
                            Icons.auto_awesome, // Sets the sparkle icon
                            color: accentColour, // Sets the icon colour
                            size: 20, // Sets the icon size
                          ),
                          const SizedBox(width: 12), // Adds space between the icon and text
                          Expanded(
                            child: Text(
                              accessState.tierDisplayName, // Displays the current tier name
                              style: TextStyle( // Styles the tier text
                                color: textSecondaryColour, // Sets the text colour
                                fontSize: 15, // Sets the text size
                              ),
                            ),
                          ),
                          // Shows the upgrade button or max tier message.
                          if (accessState.proTier == 'premium') // Checks for the highest tier
                            Text(
                              'Max tier', // Displays the max tier label
                              style: TextStyle( // Styles the max tier label
                                color: labelColour, // Sets the text colour
                                fontSize: 15, // Sets the text size
                              ),
                            )
                          else
                            GestureDetector( // Wraps the upgrade label with a tap handler
                              onTap: () async {
                                // Opens the plan selection screen.
                                await Navigator.pushNamed( // Navigates to the plan selection
                                  context, // Uses the current context
                                  AiPlanSelectionScreen.routeName, // Sets the route
                                );

                                // Stops if the settings screen was removed.
                                if (!mounted) return;

                                // Reloads the access state to show the updated tier.
                                ref.read(aiAccessProvider.notifier).loadAccess();
                              },
                              child: Text(
                                'Upgrade', // Displays the upgrade label
                                style: TextStyle( // Styles the upgrade label
                                  color: accentColour, // Sets the accent colour
                                  fontSize: 14, // Sets the text size
                                  fontWeight: FontWeight.w600, // Makes the text semi-bold
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // --- THEME SECTION ---
                    const SizedBox(height: 24), // Adds vertical spacing

                    // Section label for theme selection.
                    Text(
                      'THEME', // Sets the section label
                      style: TextStyle( // Styles the section label
                        color: labelColour, // Sets the label colour
                        fontSize: 13, // Sets the label size
                        fontWeight: FontWeight.w600, // Makes the label semi-bold
                        letterSpacing: 2.0, // Adds spacing between letters
                      ),
                    ),

                    const SizedBox(height: 12), // Adds vertical spacing

                    // Theme container holding mode toggle and colour circles.
                    Container(
                      padding: const EdgeInsets.symmetric( // Sets the internal padding
                        horizontal: 16, // Horizontal padding
                        vertical: 14, // Vertical padding
                      ),
                      decoration: BoxDecoration( // Styles the theme card
                        color: darkGreyColour, // Sets the card background colour
                        borderRadius: BorderRadius.circular(12), // Rounds the card corners
                        border: Border.all( // Sets the card border
                          color: borderColour, // Sets the border colour
                        ),
                      ),
                      child: Column( // Stacks the mode toggle and colour circles vertically
                        children: [
                          // --- BRIGHTNESS MODE TOGGLE ---
                          // Two side-by-side buttons for Light and Dark mode.
                          Row(
                            children: AppBrightnessMode.values.map((mode) { // Loops through each mode
                              final isSelected = currentMode == mode; // Checks whether this mode is active

                              return Expanded( // Forces equal width for both buttons
                                child: GestureDetector( // Wraps the button with a tap handler
                                  onTap: () { // Switches to the tapped mode
                                    ref
                                        .read(themeProvider.notifier) // Reads the theme notifier
                                        .setMode(mode); // Sets the new brightness mode
                                  },
                                  child: Container( // The mode button container
                                    padding: const EdgeInsets.symmetric( // Sets the button padding
                                      vertical: 10, // Vertical padding
                                    ),
                                    margin: const EdgeInsets.symmetric( // Sets the button margin
                                      horizontal: 4, // Horizontal margin between buttons
                                    ),
                                    decoration: BoxDecoration( // Styles the mode button
                                      color: isSelected // Sets the background colour
                                          ? accentColour.withValues(alpha: 0.15) // Faded accent when selected
                                          : Colors.transparent, // Transparent when unselected
                                      borderRadius: BorderRadius.circular(10), // Rounds the button corners
                                      border: Border.all( // Sets the button border
                                        color: isSelected // Sets the border colour
                                            ? accentColour // Accent border when selected
                                            : borderColour, // Faint border when unselected
                                      ),
                                    ),
                                    child: Row( // Arranges the icon and label horizontally
                                      mainAxisAlignment: MainAxisAlignment.center, // Centres the content
                                      children: [
                                        Icon( // Mode icon
                                          mode == AppBrightnessMode.light // Picks the icon based on mode
                                              ? Icons.light_mode // Sun icon for light mode
                                              : Icons.dark_mode, // Moon icon for dark mode
                                          size: 18, // Sets the icon size
                                          color: isSelected // Sets the icon colour
                                              ? accentColour // Accent when selected
                                              : textSecondaryColour, // Faded when unselected
                                        ),
                                        const SizedBox(width: 6), // Adds space between icon and label
                                        Text(
                                          modeDisplayName(mode), // Displays "Light" or "Dark"
                                          style: TextStyle( // Styles the mode label
                                            color: isSelected // Sets the text colour
                                                ? accentColour // Accent when selected
                                                : textSecondaryColour, // Faded when unselected
                                            fontWeight: isSelected // Sets the text weight
                                                ? FontWeight.w600 // Semi-bold when selected
                                                : FontWeight.normal, // Normal when unselected
                                            fontSize: 15, // Sets the text size
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(), // Converts the map iterable to a list
                          ),

                          const SizedBox(height: 16), // Adds space between mode toggle and colour circles

                          // --- COLOUR SCHEME SELECTOR ---
                          // Preview circles for each accent colour scheme.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distributes circles evenly
                            children: AppColourScheme.values.map((scheme) { // Loops through each scheme
                              // Checks whether this circle matches the active scheme.
                              final isSelected = currentScheme == scheme;

                              return GestureDetector( // Wraps the circle with a tap handler
                                // Switches to the tapped colour scheme.
                                onTap: () {
                                  ref
                                      .read(themeProvider.notifier) // Reads the theme notifier
                                      .setScheme(scheme); // Sets the new colour scheme
                                },
                                child: Column( // Stacks the circle and label vertically
                                  children: [
                                    // Displays the scheme's accent colour in a circle.
                                    Container(
                                      width: 44, // Sets the circle width
                                      height: 44, // Sets the circle height
                                      decoration: BoxDecoration( // Styles the colour circle
                                        color: schemePreviewColour(scheme), // Sets the circle fill colour
                                        shape: BoxShape.circle, // Makes the container circular
                                        border: isSelected // Sets the circle border
                                            ? Border.all( // Thick border when selected
                                                color: textPrimaryColour, // Primary text colour border
                                                width: 2.5, // Sets the border width
                                              )
                                            : Border.all( // Thin border when unselected
                                                color: borderColour, // Faint border colour
                                              ),
                                      ),
                                      // Shows a tick inside the active scheme.
                                      child: isSelected
                                          ? Icon( // Tick icon
                                              Icons.check, // Sets the check icon
                                              color: textPrimaryColour, // Sets the tick colour
                                              size: 20, // Sets the tick size
                                            )
                                          : null, // No icon when unselected
                                    ),
                                    const SizedBox(height: 6), // Adds space between the circle and label
                                    // Displays the scheme name below the circle.
                                    Text(
                                      schemeDisplayName(scheme), // Shows "Peach", "Ocean", etc.
                                      style: TextStyle( // Styles the scheme label
                                        color: isSelected // Sets the text colour
                                            ? textPrimaryColour // Primary when selected
                                            : unselectedNavColour, // Faded when unselected
                                        fontSize: 13, // Sets the text size
                                        fontWeight: isSelected // Sets the text weight
                                            ? FontWeight.w600 // Semi-bold when selected
                                            : FontWeight.normal, // Normal when unselected
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(), // Converts the map iterable to a list
                          ),
                        ],
                      ),
                    ),

                    // Pushes the logout button to the absolute bottom of the screen
                    const Spacer(),

                    // --- LOGOUT BUTTON ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreyColour, // Sets the button background colour
                        minimumSize: const Size.fromHeight(55), // Forces the button to stretch across the full width and be 55 pixels tall
                        shape: RoundedRectangleBorder( // Rounds the button corners
                          borderRadius: BorderRadius.circular(12), // Sets the corner radius
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.4)), // Sets the red border
                        ),
                        elevation: 0, // Removes the button shadow
                      ),
                      onPressed: _isLoggingOut ? null : _confirmLogout, // Confirms before logging out
                      child: _isLoggingOut // Displays a loading spinner if active, otherwise shows the text and icon row
                          ? const SizedBox(
                              // Constrains the size of the loading indicator
                              height: 20, // Sets the spinner height
                              width: 20, // Sets the spinner width
                              child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2), // Red loading spinner
                            )
                          : const Row(
                            // Centres the icon and text together inside the button horizontally
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, color: Colors.red, size: 20), // Logout icon
                                SizedBox(width: 8), // Adds space between icon and text
                                Text('Log Out', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600)), // Logout label
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Displays a confirmation before logging out
  Future<void> _confirmLogout() async {
    // Waits for the selected dialog action
    final confirmed = await showDialog<bool>(
      context: context, // Supplies the current screen context
      builder: (dialogContext) => AlertDialog( // Creates the logout dialog
        backgroundColor: darkGreyColour, // Sets the card background colour
        shape: RoundedRectangleBorder( // Sets the dialog shape
          borderRadius: BorderRadius.circular(16), // Rounds the dialog corners
        ),
        title: Row( // Arranges the icon and title horizontally
          children: [
            const Icon( // Displays the logout icon
              Icons.logout, // Sets the logout icon
              color: Colors.redAccent, // Sets the red colour
              size: 24, // Sets the icon size
            ),
            const SizedBox(width: 8), // Adds space before the title
            Text( // Displays the dialog title
              'Log Out?', // Sets the dialog title
              style: TextStyle( // Styles the dialog title
                color: textPrimaryColour, // Sets the primary text colour
                fontSize: 18, // Sets the title size
                fontWeight: FontWeight.bold, // Makes the title bold
              ),
            ),
          ],
        ),
        content: Text( // Displays the confirmation message
          'Are you sure you want to log out of your account?', // Sets the confirmation message
          style: TextStyle( // Styles the confirmation message
            color: textSecondaryColour, // Sets the secondary text colour
            fontSize: 14, // Sets the message size
          ),
        ),
        actions: [
          TextButton( // Creates the cancel button
            onPressed: () => Navigator.pop( // Closes the logout dialog
              dialogContext, // Uses the dialog context
              false, // Returns the cancelled result
            ),
            child: Text( // Displays the cancel label
              'Cancel', // Sets the cancel label
              style: TextStyle( // Styles the cancel label
                color: accentColour, // Sets the accent colour
              ),
            ),
          ),
          TextButton( // Creates the logout button
            onPressed: () => Navigator.pop( // Closes the logout dialog
              dialogContext, // Uses the dialog context
              true, // Returns the confirmed result
            ),
            child: const Text( // Displays the logout label
              'Log Out', // Sets the logout label
              style: TextStyle( // Styles the logout label
                color: Colors.redAccent, // Sets the red colour
                fontWeight: FontWeight.bold, // Makes the label bold
              ),
            ),
          ),
        ],
      ),
    );

    // Stops when the action is cancelled or the screen closes
    if (confirmed != true || !mounted) return;

    // Starts the confirmed logout process
    await _handleLogout();
  }

  // Handles the logic for logging out the user via Firebase
  Future<void> _handleLogout() async {
    // Updates the UI state to show the loading spinner
    setState(() => _isLoggingOut = true);

    try {
      await ref.read(firebaseServiceProvider).logout(); // Asks the Firebase service provider to end the user session

      // Prevents crashes if the user leaves the screen during the network wait
      if (!mounted) return;

      // Clears the navigation history and sends the user back to the first screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      // Ensures the loading spinner is turned off regardless of success or failure
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }
}