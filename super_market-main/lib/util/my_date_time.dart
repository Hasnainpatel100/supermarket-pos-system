class MyDateTime {
  // MyDateTime.getCurrentDateTimeUtc()
  static String getCurrentDateTimeUtc() {
    return DateTime.now().toUtc().toString();
  }
}
