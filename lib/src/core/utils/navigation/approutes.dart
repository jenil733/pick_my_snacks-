import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/homescreen.dart';
import 'package:pick_my_snacks/src/presentation/view/login/login_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String homescreen = '/homesceen';
  static final List<GetPage> pages = [
    GetPage(name: login, page: LoginScreen.new),
    GetPage(name: homescreen, page: HomeScreen.new),
  ];
}
