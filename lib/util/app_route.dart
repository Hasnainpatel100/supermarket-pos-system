import 'package:get/get.dart';

import '../screens/home/activity_home.dart';
import '../screens/login/activity_login.dart';
import '../screens/sample/activity_main.dart';
import '../screens/sample/binding_sample.dart';
import '../screens/splash/activity_splash.dart';
import '../screens/user/activity_user.dart';

class AppRoute {
  // AppRoute.user
  static const splash = "/";
  static const sample = "/sample";
  static const home = "/home";
  static const login = "/login";
  static const user = "/user";

  static final pages = <GetPage>[
    GetPage(name: splash, page: () => ActivitySplash()),

    GetPage(
      name: sample,
      page: () => const ActivitySample(),
      binding: BindingSample(),
    ),

    GetPage(name: home, page: () => const ActivityHome()),
    GetPage(name: login, page: () => const ActivityLogin()),
    GetPage(name: user, page: () =>const ActivityUser()),
  ];
}
