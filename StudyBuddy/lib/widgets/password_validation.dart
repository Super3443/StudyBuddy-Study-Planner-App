import 'package:flutter/material.dart';
import 'package:mbap_project/providers/theme_provider.dart'; // Core Flutter UI components

// Custom widget that visually indicates password strength based on user input
class PasswordStrengthMeter extends StatelessWidget {
  // The current text typed into the password field
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  // Calculates the integer strength level (0 to 3) based on password complexity
  int _calculateStrength() {
    if (password.isEmpty) return 0; // Returns 0 immediately if the field is empty
    
    // Tracks the total character count
    int len = password.length;
    bool hasNum = RegExp(r".*[0-9].*").hasMatch(password);
    bool hasLetter = RegExp(r".*[A-Za-z].*").hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    // Strong Password: Meets all criteria (length, number, letter, special char)
    if (len >= 8 && hasNum && hasLetter && hasSpecial) {
      return 3; // Returns strength of level 3 to display
    }
    // Moderate Password: At least 8 characters long, includes letters and numbers, but no special characters
    if (len >= 8 && hasNum && hasLetter) {
      return 2; // Returns strength of level 2 to display
    }
    // Weak Password: At least 8 characters long, but meets a single criteria (e.g., only letters, or only numbers)
    if (len >= 8) {
      return 1; // Returns strength of level 1 to display
    }
    
    // 4. Too Short: User has typed something, but it's less than 8 characters
    return 0; 
  }

  // Builds an individual segment of the 3-part strength indicator bar
  Widget _buildStrengthBar(int level, int currentStrength, bool isTyping) {
    // Illuminates the first bar red if the user is typing but hasn't reached 8 characters
    if (isTyping && currentStrength == 0 && level == 1) {
      return Container(
        height: 4, // Thickness of the bar
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 82, 82), // Bright red colour
          borderRadius: BorderRadius.circular(2), // Rounds the edges of the bar
        ),
      );
    }

   // Sets the default inactive track colour to faint white
    Color barColor = textSecondaryColour; 

    // Assigns solid red for weak passwords
    if (currentStrength == 1) {
      barColor = const Color.fromARGB(255, 255, 82, 82);

    // Assigns accent for moderate passwords
    } else if (currentStrength == 2) {
      barColor = const Color.fromARGB(255, 255, 165, 0);

    // Assigns green for strong passwords
    } else if (currentStrength == 3) {
      barColor = const Color.fromARGB(255, 0, 255, 0);
    }

    // Determines if this specific bar segment should be illuminated
    bool isActive = level <= currentStrength;

    // Returns the styled horizontal bar segment
    return Container(
      height: 4,
      decoration: BoxDecoration(
        // Applies the active colour or defaults to the faint inactive colour
        color: isActive ? barColor : borderColour.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  // Builds the visual layout of the strength meter
  Widget build(BuildContext context) {
    int strength = _calculateStrength(); // Evaluates the current password string to get the strength score
    bool isTyping = password.isNotEmpty; // Checks if the user has typed any characters

    String strengthText = 'No password entered'; // Default label shown before any input occurs
    Color textColor = textSecondaryColour; // Default text colour before any input occurs

    // Update the strength text and color based on the calculated strength
    // If password is below 8 characters, show "Too short" in red
    if (isTyping && password.length < 8) { 
      strengthText = 'Too short (< 8 chars)';
      textColor = const Color.fromARGB(255, 255, 82, 82);
    // If password is 8+ characters but weak, show "Weak password" in red
    } else if (strength == 1) { 
      strengthText = 'Weak password';
      textColor = const Color.fromARGB(255, 255, 82, 82);

    // Orange text indicating moderate security
    } else if (strength == 2) {
      strengthText = 'Moderate password';
      textColor = const Color.fromARGB(255, 255, 165, 0);

    // Green text indicating high security
    } else if (strength == 3) {
      strengthText = 'Strong password';
      textColor = const Color.fromARGB(255, 0, 255, 0);
    }

    // Main container arranging the bars and text vertically
    return Column(
      children: [
        // Arranges the three strength bars horizontally
        Row(
          children: [
            Expanded(child: _buildStrengthBar(1, strength, isTyping)), // Stretches each bar equally across the available width
            const SizedBox(width: 4), // Horizontal spacing between the bars
            Expanded(child: _buildStrengthBar(2, strength, isTyping)), // Stretches each bar equally across the available width
            const SizedBox(width: 4), // Horizontal spacing between the bars
            Expanded(child: _buildStrengthBar(3, strength, isTyping)), // Stretches each bar equally across the available width
          ],
        ),

        // Vertical spacing between the bars and the text below
        const SizedBox(height: 8),

        // Arranges the dynamic status text and static requirement text at opposite ends
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Displays the active strength status label
            Text(
              strengthText,
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            // Displays the permanent length requirement reminder
            Text(
              '8+ chars',
              style: TextStyle(
                color: labelColour, 
                fontSize: 12
              ),
            ),
          ],
        ),
      ],
    );
  }
}