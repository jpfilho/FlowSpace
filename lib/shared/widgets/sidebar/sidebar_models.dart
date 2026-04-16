import 'package:flutter/material.dart';

class SidebarNavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;

  const SidebarNavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });

  SidebarNavItem copyWith({int? badge}) => SidebarNavItem(
        route: route,
        icon: icon,
        activeIcon: activeIcon,
        label: label,
        badge: badge ?? this.badge,
      );
}
