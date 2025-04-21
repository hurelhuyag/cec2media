
import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';

List<Route> routeStack = [];
String routeStackFirstName = "Home";

class AppNavigatorObserver extends RouteObserver {

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    routeStack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    routeStack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    routeStack.remove(route);
  }

  @override
  void didReplace({ Route<dynamic>? newRoute, Route<dynamic>? oldRoute }) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final index = routeStack.indexOf(oldRoute!);
    routeStack[index] = newRoute!;
  }
}

BreadCrumbItem breadCrumbItem(int index, Route route, BuildContext context) {
  return BreadCrumbItem(
    content: GestureDetector(
      onTap: () {
        Navigator.popUntil(context, (r) => r == route);
      },
      child: Text(
        index == 0 ? routeStackFirstName : route.settings.name.toString(),
      ),
    ),
  );
}

class NavPath extends StatelessWidget {
  const NavPath({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Route> currentRouteStack = routeStack.toList();
    return BreadCrumb.builder(
      overflow: ScrollableOverflow(),
      itemCount: currentRouteStack.length,
      builder: (index) => breadCrumbItem(
        index,
        currentRouteStack[index],
        context,
      ),
      divider: const Icon(
        Icons.chevron_right,
        color: Colors.blue,
      ),
    );
  }
}
