import 'package:flutter/material.dart';
import 'package:nymphette/ui/auth/login.dart';
import 'package:nymphette/ui/dashboard/admin_dashboard.dart';
import 'route_names.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    RouteNames.login: (context) => const LoginScreen(),
    RouteNames.dashboard: (context) => const AdminDashboard(),
  };
}
