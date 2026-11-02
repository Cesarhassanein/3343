import 'package:flutter/material.dart';
import '../widgets/wadiq_bottom_nav_bar.dart';
import '../widgets/create_modal_sheet.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../reels/presentation/screens/reels_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../more/presentation/screens/more_screen.dart';
import '../../../creation/presentation/screens/create_post_screen.dart';
import '../../../creation/presentation/screens/create_reel_screen.dart';
import '../../../creation/presentation/screens/create_group_channel_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTabIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  void _openCreateSheet() {
    CreateModalSheet.show(
      context,
      onPostTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
      },
      onReelTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateReelScreen()),
        );
      },
      onChannelTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGroupOrChannelScreen(isChannel: true)),
        );
      },
      onGroupTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGroupOrChannelScreen(isChannel: false)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          const FeedScreen(),
          ReelsScreen(isActive: _currentTabIndex == 1),
          const ChatListScreen(),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: WadiqBottomNavBar(
        currentIndex: _currentTabIndex,
        onTabSelected: _onTabSelected,
        onCreatePressed: _openCreateSheet,
      ),
    );
  }
}
