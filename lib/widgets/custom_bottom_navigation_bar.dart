import 'package:ichizen/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A customizable and reusable BottomNavigationBar widget.
///
/// This widget provides a standard bottom navigation bar layout
/// with predefined items for Home, Attendance, and Reports.
/// It takes `currentIndex` and an `onTap` callback to manage
/// its state and handle navigation.
class CustomBottomNavigationBar extends StatelessWidget {
  /// The index of the currently selected tab.
  final int currentIndex;

  /// Callback function invoked when a tab is tapped.
  /// The integer parameter `index` represents the index of the tapped tab.
  final Function(int) onTap;

  /// Creates a [CustomBottomNavigationBar].
  ///
  /// [currentIndex] is required and determines which icon is highlighted.
  /// [onTap] is required and is called when a navigation item is tapped.
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.deepPurple, // Color for selected icon/label
      unselectedItemColor: Colors.grey, // Color for unselected icons/labels
      backgroundColor: Colors.white, // Background color of the navigation bar
      type: BottomNavigationBarType
          .fixed, // Ensures all labels are always visible
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time), // Icon for attendance/clock-in
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart), // Icon for reports/statistics
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), // Icon for reports/statistics
          label: 'Profile',
        ),
      ],
    );
  }
}
