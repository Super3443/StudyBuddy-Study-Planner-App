import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbap_project/firebase_options.dart';
import 'package:mbap_project/providers/firebase_provider.dart';
import 'package:mbap_project/providers/theme_provider.dart';
import 'package:mbap_project/screens/authentication/login.dart';
import 'package:mbap_project/screens/dashboard.dart';
import 'package:mbap_project/screens/view_all_tasks.dart';
import 'package:mbap_project/screens/ai_assistant.dart';
import 'package:mbap_project/screens/schedule.dart';
import 'package:mbap_project/widgets/add_task_modal.dart';
import 'package:mbap_project/widgets/biometric_check.dart';
import 'package:mbap_project/widgets/floating_create_task.dart';
import 'package:mbap_project/screens/settings.dart';
import 'package:mbap_project/screens/authentication/registration.dart';
import 'package:mbap_project/screens/authentication/forgot_password_screen.dart';
import 'package:mbap_project/screens/authentication/email_verification.dart';
import 'package:mbap_project/providers/notification_provider.dart';
import 'package:mbap_project/screens/ai_plan_selection.dart';
import 'package:mbap_project/screens/introduction.dart';

void main() async {
  // Ensures Flutter framework is fully initialised before running native code (like Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialises Firebase using the generated platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Wraps the app in a ProviderScope to enable Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

// Sets up the material app and the initial screen
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

// Builds the material app and handles authentication routing.
class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialises the notification plugin once when the app starts.
    ref.read(notificationProvider).initialise();
  }

  // Caches the onboarding check so it only runs once per session.
  Future<bool>? _onboardingFuture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyBuddy', // App title, used in task switcher
      debugShowCheckedModeBanner:
          false, // Clears the red debug banner to view the app properly
      // --- THEME SETTINGS ---
      theme: ref.watch(themeProvider),

      // --- AUTHENTICATION STATE ROUTING ---
      // Listens to the Firebase auth state stream to determine the initial screen
      home: ref
          .watch(authStateProvider)
          .when(
            // Routes to MainScreen if user is logged in, otherwise routes to LoginScreen
            data: (user) {
              // Shows the login screen when no account is signed in.
              if (user == null) {
                _onboardingFuture = null; // Clears the cached result on sign-out
                return const LoginScreen();
              }

              // Routes unverified accounts to the email verification screen.
              if (!user.emailVerified) return const EmailVerificationScreen();

              // Checks whether the user has completed the onboarding walkthrough.
              // Caches the Future so theme changes don't re-fire the Firestore read.
              _onboardingFuture ??= ref.read(firebaseServiceProvider).hasSeenOnboarding();
              return FutureBuilder<bool>(
                future: _onboardingFuture,
                builder: (context, snapshot) {
                  // Shows an error message when Firestore cannot read the onboarding flag.
                  if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Text(
                          'Something went wrong. Please restart the app.',
                          style: TextStyle(color: textPrimaryColour),
                        ),
                      ),
                    );
                  }

                  // Shows a loading spinner while Firestore checks the onboarding flag.
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Opens the main screen when onboarding was already completed.
                  if (snapshot.data == true) return const BiometricGate();

                  // Shows the onboarding walkthrough for first-time users.
                  return OnboardingScreen(
                    onComplete: () async {
                      // Marks onboarding as completed in Firestore.
                      await ref.read(firebaseServiceProvider).completeOnboarding(); // Saves the flag

                      // Clears the onboarding screenshots from memory.
                      imageCache.clear(); // Removes all cached images
                      imageCache.clearLiveImages(); // Removes images still being displayed

                      _onboardingFuture = null; // Clears the cached Future so the next build re-checks
                      ref.invalidate(authStateProvider); // Triggers the routing to re-evaluate
                    },
                  );
                },
              );
            },

            // Displays a loading spinner while checking authentication status
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),

            // Displays an error message if the authentication stream fails
            error: (err, stack) => const Scaffold(
              body: Center(child: Text('Something went wrong')),
            ),
          ),

      // --- NAMED ROUTES ---
      // Maps route strings to their respective screen widgets for clean navigation
      routes: {
        SettingsScreen.routeName: (_) => const SettingsScreen(), // Routes to the Settings screen
        ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(), // Routes to the Forgot Password screen
        RegisterScreen.routeName: (_) => const RegisterScreen(), // Routes to the Registration screen
        EmailVerificationScreen.routeName: (_) => const EmailVerificationScreen(), // Routes to the Email Verification screen
        AiPlanSelectionScreen.routeName: (_) => const AiPlanSelectionScreen(), // Routes to the AI plan selection screen
      },
    );
  }
}

// The main screen container that manages bottom tab navigation and layout
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

// Holds the selected navigation tab and rebuilds the displayed screen
class _MainScreenState extends ConsumerState<MainScreen> {
  static const int _homeIndex = 0; // Stores the Home navigation index
  static const int _tasksIndex = 1; // Stores the Tasks navigation index
  static const int _addTaskIndex = 2; // Stores the centre button spacer index
  static const int _aiIndex = 3; // Stores the AI navigation index
  static const int _scheduleIndex = 4; // Stores the Schedule navigation index

  int _selectedIndex = _homeIndex; // Starts with the Home tab selected

  // Changes the selected tab and rebuilds the main screen
  void _selectTab(int index) {
    // Keeps the centre spacer from becoming a selected screen
    if (index == _addTaskIndex) return;

    setState(() {
      _selectedIndex = index; // Stores the selected navigation item index
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds the navigation bar when the colour scheme changes.
    ref.watch(themeProvider);
    
    // Array of tab screens
    final List<Widget> screens = [
      DashboardScreen(
        onOpenTasks: () => _selectTab(_tasksIndex), // Opens the Tasks tab
        onOpenAI: () => _selectTab(_aiIndex), // Opens the AI tab
      ),
      const AllTasksScreen(), // Displays all saved tasks
      const SizedBox.shrink(), // Reserves the centre navigation position
      // Opens Schedule after saving a plan
      AIScreen(onOpenSchedule: () => _selectTab(_scheduleIndex)),
      const ScheduleScreen(), // Displays tasks on the calendar
    ];

    return Scaffold(
      // Displays the screen that matches the selected navigation item
      body: screens[_selectedIndex],

      // --- BOTTOM NAVIGATION BAR ---
      // Docks the floating action button into the notch of the bottom navigation bar
      // Custom floating action button for adding new tasks
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: NavAddTask(
        onPressed: () {
          // Triggers the bottom sheet modal to slide up
          showModalBottomSheet(
            context: context,
            // Allows the modal to move up when the on-screen keyboard appears
            isScrollControlled: true,
            // Removes the default white background so custom rounded corners and gradient show properly
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              // Dynamically adds padding to the bottom equal to the keyboard height
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const CreateTaskModal(),
            ),
          );
        },
      ),

      // Raises the built-in navigation bar above the bottom edge
      bottomNavigationBar: ColoredBox(
        color: darkGreyColour, // Fills the spacing with the navigation colour
          child: BottomNavigationBar(
            // Keeps all five navigation positions visible
            type: BottomNavigationBarType.fixed,
            // Sets the navigation bar background colour
            backgroundColor: darkGreyColour,
            // Highlights the selected navigation item
            selectedItemColor: highlightColour,
            // Fades the unselected navigation items
            unselectedItemColor: unselectedNavColour,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, // Makes the selected label bold
            ),
            // Highlights the currently selected item
            currentIndex: _selectedIndex,
            // Changes the displayed screen when an item is tapped
            onTap: _selectTab,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home), // Sets the Home icon
                label: 'Home', // Sets the Home label
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined), // Sets the Tasks icon
                label: 'Tasks', // Sets the Tasks label
              ),
              BottomNavigationBarItem(
                icon: SizedBox(
                  width: 24, // Reserves the standard icon width
                  height: 24, // Reserves the standard icon height
                ),
                label: '', // Leaves space beneath the Add Task button
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology_outlined), // Sets the AI icon
                label: 'AI', // Sets the AI label
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.calendar_today_outlined,
                ), // Sets the Schedule icon
                label: 'Schedule', // Sets the Schedule label
              ),
            ],
          ),
        ),
      );
  }
}


