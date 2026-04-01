import 'package:flutter/material.dart';

/// Used so [HomePage] refreshes when a route (e.g. wake alignment) is popped.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
