// Holds the signed-in account details without depending on Firebase types.
// The service converts Firebase's User into this class before the rest of the app sees it.
class AppUser {
  // The unique Firebase account ID used to link tasks to their owner.
  final String uid;

  // The account email address shown on the settings screen.
  final String? email;

  // The full name shown on the dashboard greeting.
  final String? displayName;

  // Tracks whether the account's email has been verified.
  final bool emailVerified;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false, // Defaults to unverified
  });
}