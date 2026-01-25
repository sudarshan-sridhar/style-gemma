import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/auth_screen.dart';
import '../features/profile/body_image.dart';
import '../features/wardrobe/wardrobe_item.dart';
import 'app_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }

        return FutureBuilder<void>(
          future: _initUser(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return AppShell(uid: user.uid);
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Auth error'))),
    );
  }

  Future<void> _initUser(String uid) async {
    // Wardrobe Hive (UI cache)
    if (!Hive.isBoxOpen('wardrobe_guest')) {
      await Hive.openBox<WardrobeItem>('wardrobe_guest');
    }
    if (!Hive.isBoxOpen('wardrobe_$uid')) {
      await Hive.openBox<WardrobeItem>('wardrobe_$uid');
    }

    // Body images (UI cache)
    if (!Hive.isBoxOpen('body_$uid')) {
      await Hive.openBox<BodyImage>('body_$uid');
    }

    // ✅ Firestore is the source of truth
    // ✅ Hive is just a UI cache
  }
}
