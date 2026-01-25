import 'package:flutter/material.dart';

import '../../features/favorites/favorites_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/wardrobe/wardrobe_screen.dart';
import 'theme/app_colors.dart';

class AppShell extends StatefulWidget {
  final String uid;
  const AppShell({super.key, required this.uid});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(uid: widget.uid),
    const SearchScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
    const WardrobeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      // ✨ TEXT "Style Gemma" CENTERED
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        toolbarHeight: 60,
        centerTitle: true, // ✅ CENTERED
        title: Text(
          'Style Gemma',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.hmBlue, // ✅ SAME BLUE COLOR
            fontFamily: 'IBMPlexSans',
          ),
        ),
      ),

      body: SafeArea(bottom: false, child: _screens[_currentIndex]),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _currentIndex,
              selectedItemColor: AppColors.hmBlue,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: (i) => setState(() => _currentIndex = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: '',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.checkroom_outlined),
                  label: '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
