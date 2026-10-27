import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management
import 'package:flutter_riverpod/legacy.dart'; // StateNotifierProvider support
import 'package:mbap_project/services/theme_service.dart'; // Reads and writes saved settings

// ── Colour Scheme Enum ──

// Lists every selectable colour scheme in the app.
enum AppColourScheme {
  peach, // Warm orange tones (default)
  ocean, // Cool blue tones
  forest, // Nature green tones
  royal, // Rich purple tones
}

// ── Brightness Mode Enum ──

// Lists the two brightness modes for the app.
enum AppBrightnessMode {
  light, // Light backgrounds with dark text
  dark, // Dark backgrounds with light text (default)
}

// ── Accent Palette ──

// Holds the three accent colours that define one colour scheme.
// These remain the same regardless of brightness mode.
class _AccentPalette {
  final Color accent; // Primary accent for text, icons, buttons
  final Color highlight; // Bright colour for FAB, selected nav items, sliders
  final Color deepAccent; // Dark version of the accent for button foregrounds

  const _AccentPalette({
    required this.accent, // Sets the accent colour
    required this.highlight, // Sets the highlight colour
    required this.deepAccent, // Sets the deep accent colour
  });
}

// ── Accent Palette Definitions ──

// Maps each scheme to its three accent colours.
const _accentPalettes = <AppColourScheme, _AccentPalette>{
  // Warm orange tones matching the original app design.
  AppColourScheme.peach: _AccentPalette(
    accent: Color.fromARGB(255, 255, 158, 110), // Light peach accent
    highlight: Color.fromARGB(255, 255, 109, 0), // Vibrant orange highlight
    deepAccent: Color.fromARGB(255, 87, 32, 0), // Dark brown for button text
  ),

  // Cool blue tones for an ocean-inspired look.
  AppColourScheme.ocean: _AccentPalette(
    accent: Color.fromARGB(255, 144, 205, 255), // Light blue accent
    highlight: Color.fromARGB(255, 66, 165, 245), // Medium blue highlight
    deepAccent: Color.fromARGB(255, 13, 71, 161), // Dark blue for button text
  ),

  // Natural green tones for a calming feel.
  AppColourScheme.forest: _AccentPalette(
    accent: Color.fromARGB(255, 111, 210, 113), // Light green accent
    highlight: Color.fromARGB(255, 68, 196, 75), // Medium green highlight
    deepAccent: Color.fromARGB(255, 29, 103, 34), // Dark green for button text
  ),

  // Rich purple tones for a premium feel.
  AppColourScheme.royal: _AccentPalette(
    accent: Color.fromARGB(255, 198, 107, 214), // Light purple accent
    highlight: Color.fromARGB(255, 171, 71, 188), // Medium purple highlight
    deepAccent: Color.fromARGB(255, 74, 20, 140), // Dark purple for button text
  ),
};

// ── Global Colour Variables ──
// Mutable top-level colours that update when the active scheme or mode changes.
// Every screen references these by name so they must remain top-level.

// Accent globals (change with colour scheme)
Color accentColour = _accentPalettes[AppColourScheme.peach]!.accent; // Primary accent colour
Color highlightColour = _accentPalettes[AppColourScheme.peach]!.highlight; // Highlight colour
Color deepAccentColour = _accentPalettes[AppColourScheme.peach]!.deepAccent; // Deep accent colour

// Base globals (change with brightness mode)
Color darkGreyColour = const Color.fromARGB(255, 30, 30, 30); // Card and container backgrounds
Color blackColour = const Color.fromARGB(255, 18, 18, 18); // Scaffold and input backgrounds

// Text and UI globals (change with brightness mode)
Color textPrimaryColour = Colors.white; // Headings, icons, primary text
Color textSecondaryColour = const Color(0xCCFFFFFF); // Body text at roughly 80% opacity
Color labelColour = const Color(0x66FFFFFF); // Section labels and hints at roughly 40% opacity
Color dividerColour = const Color(0x0FFFFFFF); // Divider lines at roughly 6% opacity
Color borderColour = const Color(0x0DFFFFFF); // Card borders at roughly 5% opacity
Color unselectedNavColour = const Color(0x80FFFFFF); // Unselected nav items at roughly 50% opacity

// ── Display Helpers ──

// Returns a user-facing label for the given scheme.
String schemeDisplayName(AppColourScheme scheme) {
  switch (scheme) {
    case AppColourScheme.peach:
      return 'Peach'; // Peach scheme label
    case AppColourScheme.ocean:
      return 'Ocean'; // Ocean scheme label
    case AppColourScheme.forest:
      return 'Forest'; // Forest scheme label
    case AppColourScheme.royal:
      return 'Royal'; // Royal scheme label
  }
}

// Returns the accent colour for the scheme selector preview circles.
Color schemePreviewColour(AppColourScheme scheme) {
  return _accentPalettes[scheme]!.accent; // Grabs the accent from the palette map
}

// Returns a user-facing label for the given brightness mode.
String modeDisplayName(AppBrightnessMode mode) {
  switch (mode) {
    case AppBrightnessMode.light:
      return 'Light'; // Light mode label
    case AppBrightnessMode.dark:
      return 'Dark'; // Dark mode label
  }
}

// ── Comprehensive Theme Builder ──

// Builds a fully customised ThemeData for the given colour scheme and brightness mode.
// Customises 14 widget-level themes beyond the base colour scheme.
ThemeData buildAppTheme(AppColourScheme scheme, AppBrightnessMode mode) {
  final a = _accentPalettes[scheme]!; // Retrieves the accent palette for the chosen scheme
  final isDark = mode == AppBrightnessMode.dark; // Checks whether dark mode is active

  // Base colours derived from brightness mode
  final cardColour = isDark // Card background colour
      ? const Color.fromARGB(255, 30, 30, 30) // Dark grey for dark mode
      : Colors.white; // White for light mode
  final surfaceColour = isDark // Scaffold background colour
      ? const Color.fromARGB(255, 18, 18, 18) // Near-black for dark mode
      : const Color(0xFFF2F2F7); // Light grey for light mode
  final textPrimary = isDark // Primary text colour
      ? Colors.white // White text for dark mode
      : const Color(0xFF1A1A1A); // Near-black text for light mode
  final textSecondary = isDark // Secondary text colour
      ? Colors.white.withValues(alpha: 0.8) // Faded white for dark mode
      : const Color(0xFF1A1A1A).withValues(alpha: 0.65); // Faded black for light mode
  final textFaint = isDark // Faint text for hints and labels
      ? Colors.white.withValues(alpha: 0.4) // Very faded white for dark mode
      : const Color(0xFF1A1A1A).withValues(alpha: 0.4); // Very faded black for light mode
  final borderFaint = isDark // Border colour for outlined buttons
      ? Colors.white.withValues(alpha: 0.15) // Subtle white border for dark mode
      : Colors.black.withValues(alpha: 0.12); // Subtle black border for light mode
  final divider = isDark // Divider line colour
      ? Colors.white.withValues(alpha: 0.06) // Near-invisible white for dark mode
      : Colors.black.withValues(alpha: 0.08); // Near-invisible black for light mode
  final unselectedNav = isDark // Unselected navigation item colour
      ? Colors.white.withValues(alpha: 0.5) // Half-opacity white for dark mode
      : Colors.black.withValues(alpha: 0.45); // Half-opacity black for light mode

  // Picks the correct Material colour scheme constructor based on mode
  final colorScheme = isDark
      ? ColorScheme.dark( // Dark colour scheme base
          primary: a.accent, // Sets the primary accent colour
          secondary: a.highlight, // Sets the secondary highlight colour
          surface: cardColour, // Sets the card surface colour
          onPrimary: a.deepAccent, // Sets the text colour on primary backgrounds
          onSecondary: Colors.white, // Sets the text colour on secondary backgrounds
          onSurface: textPrimary, // Sets the text colour on surfaces
        )
      : ColorScheme.light( // Light colour scheme base
          primary: a.accent, // Sets the primary accent colour
          secondary: a.highlight, // Sets the secondary highlight colour
          surface: cardColour, // Sets the card surface colour
          onPrimary: a.deepAccent, // Sets the text colour on primary backgrounds
          onSecondary: const Color(0xFF1A1A1A), // Sets the text colour on secondary backgrounds
          onSurface: textPrimary, // Sets the text colour on surfaces
        );

  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light, // Sets the overall brightness
    useMaterial3: true, // Enables Material 3 design
    scaffoldBackgroundColor: surfaceColour, // Sets the scaffold background

    // Core colour scheme used by Material widgets throughout the app.
    colorScheme: colorScheme,

    // Heading and body text styles applied across the app.
    textTheme: TextTheme(
      headlineLarge: TextStyle( // Large heading style
        color: textPrimary, // Sets the heading colour
        fontWeight: FontWeight.bold, // Makes the heading bold
        fontSize: 26, // Sets the heading size
      ),
      headlineMedium: TextStyle( // Medium heading style
        color: textPrimary, // Sets the heading colour
        fontWeight: FontWeight.bold, // Makes the heading bold
        fontSize: 22, // Sets the heading size
      ),
      bodyLarge: TextStyle( // Large body text style
        color: textSecondary, // Sets the body text colour
        fontSize: 16, // Sets the body text size
      ),
      bodyMedium: TextStyle( // Medium body text style
        color: textSecondary, // Sets the body text colour
        fontSize: 14, // Sets the body text size
      ),
      labelLarge: TextStyle( // Large label style
        color: a.accent, // Sets the label colour to the accent
        fontWeight: FontWeight.w600, // Makes the label semi-bold
        fontSize: 14, // Sets the label size
      ),
    ),

    // Filled button styling with rounded pill shape.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: a.accent, // Sets the button background to the accent
        foregroundColor: a.deepAccent, // Sets the button text to the deep accent
        shape: RoundedRectangleBorder( // Rounds the button corners
          borderRadius: BorderRadius.circular(28), // Sets the corner radius
        ),
        elevation: 0, // Removes the button shadow
      ),
    ),

    // Bordered button styling matching the elevated buttons.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textSecondary, // Sets the button text colour
        side: BorderSide(color: borderFaint), // Sets the border colour
        shape: RoundedRectangleBorder( // Rounds the button corners
          borderRadius: BorderRadius.circular(28), // Sets the corner radius
        ),
      ),
    ),

    // Text field and dropdown input decoration.
    inputDecorationTheme: InputDecorationTheme(
      filled: true, // Fills the input background
      fillColor: surfaceColour, // Sets the input background colour
      hintStyle: TextStyle(color: textFaint), // Sets the hint text colour
      border: OutlineInputBorder( // Rounds the input corners
        borderRadius: BorderRadius.circular(12), // Sets the corner radius
        borderSide: BorderSide.none, // Removes the border line
      ),
    ),

    // Card container styling.
    cardTheme: CardThemeData(
      color: cardColour, // Sets the card background colour
      shape: RoundedRectangleBorder( // Rounds the card corners
        borderRadius: BorderRadius.circular(12), // Sets the corner radius
      ),
      elevation: 0, // Removes the card shadow
    ),

    // Bottom navigation bar colours and selected item styling.
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardColour, // Sets the navigation bar background
      selectedItemColor: a.highlight, // Sets the selected item colour
      unselectedItemColor: unselectedNav, // Sets the unselected item colour
      type: BottomNavigationBarType.fixed, // Keeps all items visible
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold), // Makes the selected label bold
    ),

    // Alert dialog window styling.
    dialogTheme: DialogThemeData(
      backgroundColor: cardColour, // Sets the dialog background colour
      shape: RoundedRectangleBorder( // Rounds the dialog corners
        borderRadius: BorderRadius.circular(16), // Sets the corner radius
      ),
    ),

    // Floating snackbar notification styling.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating, // Makes the snackbar float
      shape: RoundedRectangleBorder( // Rounds the snackbar corners
        borderRadius: BorderRadius.circular(12), // Sets the corner radius
      ),
    ),

    // Horizontal divider line colour.
    dividerTheme: DividerThemeData(
      color: divider, // Sets the divider colour
    ),

    // Toggle switch thumb and track colours.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) { // Resolves the thumb colour
        if (states.contains(WidgetState.selected)) return a.accent; // Sets the accent when selected
        return null; // Uses the default when unselected
      }),
      trackColor: WidgetStateProperty.resolveWith((states) { // Resolves the track colour
        if (states.contains(WidgetState.selected)) { // Checks whether the switch is on
          return a.accent.withValues(alpha: 0.3); // Sets a faded accent track
        }
        return null; // Uses the default when unselected
      }),
    ),

    // Default icon colour when not set explicitly.
    iconTheme: IconThemeData(
      color: textSecondary, // Sets the default icon colour
    ),

    // Floating action button styling.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: a.highlight, // Sets the FAB background to the highlight
      foregroundColor: Colors.white, // Sets the FAB icon colour to white
    ),

    // Dropdown menu background colour.
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(surfaceColour), // Sets the dropdown background
      ),
    ),
  );
}

// ── Providers ──

// Provides a single ThemeService instance for reading and writing saved settings.
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService(); // Creates the theme service
});

// Provides the current ThemeData to the MaterialApp and rebuilds when changed.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  final service = ref.read(themeServiceProvider); // Reads the theme service
  return ThemeNotifier(service); // Creates the theme notifier
});

// ── Theme Notifier ──

// Manages the active colour scheme and brightness mode, updates global colours,
// and delegates persistence to ThemeService. Follows the Provider → Service architecture.
class ThemeNotifier extends StateNotifier<ThemeData> {
  final ThemeService service; // Delegates reading and writing to the service
  AppColourScheme _scheme; // Stores the currently active colour scheme
  AppBrightnessMode _mode; // Stores the currently active brightness mode

  // Starts with Dark + Peach defaults and loads saved settings from storage.
  ThemeNotifier(this.service)
      : _scheme = AppColourScheme.peach, // Sets the default colour scheme
        _mode = AppBrightnessMode.dark, // Sets the default brightness mode
        super(buildAppTheme(AppColourScheme.peach, AppBrightnessMode.dark)) {
    _applyGlobalColours(); // Initialises the global colour variables
    loadTheme(); // Reads the saved settings from SharedPreferences
  }

  // Returns the currently active colour scheme for the settings selector.
  AppColourScheme get currentScheme => _scheme;

  // Returns the currently active brightness mode for the settings selector.
  AppBrightnessMode get currentMode => _mode;

  // Reads saved settings from device storage and applies them.
  Future<void> loadTheme() async {
    final savedScheme = await service.getTheme(); // Reads the saved colour scheme
    final savedMode = await service.getBrightnessMode(); // Reads the saved brightness mode

    // Keeps the default Peach scheme when nothing has been saved yet.
    if (savedScheme != null) {
      _scheme = AppColourScheme.values.firstWhere( // Finds the matching scheme
        (s) => s.name == savedScheme, // Compares the scheme name
        orElse: () => AppColourScheme.peach, // Falls back to Peach
      );
    }

    // Keeps the default Dark mode when nothing has been saved yet.
    if (savedMode != null) {
      _mode = AppBrightnessMode.values.firstWhere( // Finds the matching mode
        (m) => m.name == savedMode, // Compares the mode name
        orElse: () => AppBrightnessMode.dark, // Falls back to Dark
      );
    }

    _applyGlobalColours(); // Updates the global colour variables
    state = buildAppTheme(_scheme, _mode); // Rebuilds the ThemeData
  }

  // Switches to a new colour scheme, rebuilds the theme and saves the choice.
  Future<void> setScheme(AppColourScheme scheme) async {
    _scheme = scheme; // Stores the new scheme
    _applyGlobalColours(); // Updates the global colour variables
    state = buildAppTheme(_scheme, _mode); // Rebuilds the ThemeData
    await service.setTheme(scheme.name); // Persists the selection
  }

  // Switches to a new brightness mode, rebuilds the theme and saves the choice.
  Future<void> setMode(AppBrightnessMode mode) async {
    _mode = mode; // Stores the new mode
    _applyGlobalColours(); // Updates the global colour variables
    state = buildAppTheme(_scheme, _mode); // Rebuilds the ThemeData
    await service.setBrightnessMode(mode.name); // Persists the selection
  }

  // Overwrites all global colour variables with the current scheme and mode.
  void _applyGlobalColours() {
    final a = _accentPalettes[_scheme]!; // Retrieves the accent palette
    final isDark = _mode == AppBrightnessMode.dark; // Checks whether dark mode is active

    // Accent colours (from colour scheme)
    accentColour = a.accent; // Updates the accent global
    highlightColour = a.highlight; // Updates the highlight global
    deepAccentColour = a.deepAccent; // Updates the deep accent global

    // Base colours (from brightness mode)
    darkGreyColour = isDark // Updates the card background global
        ? const Color.fromARGB(255, 30, 30, 30) // Dark grey for dark mode
        : Colors.white; // White for light mode
    blackColour = isDark // Updates the scaffold background global
        ? const Color.fromARGB(255, 18, 18, 18) // Near-black for dark mode
        : const Color(0xFFF2F2F7); // Light grey for light mode

    // Text and UI colours (from brightness mode)
    textPrimaryColour = isDark // Updates the primary text global
        ? Colors.white // White text for dark mode
        : const Color(0xFF1A1A1A); // Near-black text for light mode
    textSecondaryColour = isDark // Updates the secondary text global
        ? Colors.white.withValues(alpha: 0.8) // Faded white for dark mode
        : const Color(0xFF1A1A1A).withValues(alpha: 0.65); // Faded black for light mode
    labelColour = isDark // Updates the label text global
        ? Colors.white.withValues(alpha: 0.4) // Very faded white for dark mode
        : const Color(0xFF1A1A1A).withValues(alpha: 0.4); // Very faded black for light mode
    dividerColour = isDark // Updates the divider colour global
        ? Colors.white.withValues(alpha: 0.06) // Near-invisible white for dark mode
        : Colors.black.withValues(alpha: 0.08); // Near-invisible black for light mode
    borderColour = isDark // Updates the border colour global
        ? Colors.white.withValues(alpha: 0.05) // Subtle white for dark mode
        : Colors.black.withValues(alpha: 0.08); // Subtle black for light mode
    unselectedNavColour = isDark // Updates the unselected nav colour global
        ? Colors.white.withValues(alpha: 0.5) // Half-opacity white for dark mode
        : Colors.black.withValues(alpha: 0.45); // Half-opacity black for light mode
  }
}