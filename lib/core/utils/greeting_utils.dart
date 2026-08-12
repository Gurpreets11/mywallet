class GreetingUtils {
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    if (hour < 21) {
      return 'Good Evening';
    }

    return 'Good Night';
  }
}
