class OnboardingModel {
  String age = "";
  String country = "";
  String status = "";
  List<String> interests = [];
  List<String> goals = [];

  // ADD THIS FUNCTION:
  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'country': country,
      'status': status,
      'interests': interests,
      'goals': goals,
      'hasCompletedOnboarding': true,
    };
  }
}
