import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';

class WadiqBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreatePressed;

  const WadiqBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WadiqColors.obsidianBlack.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: WadiqColors.surfaceBorder, width: 0.8),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 8,
        top: 6,
      ),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 1: Posts / Feed
            _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
              outlineIcon: Icons.home_outlined,
              label: "منشورات",
            ),
            // Tab 2: Reels
            _buildNavItem(
              index: 1,
              icon: Icons.play_arrow_rounded,
              outlineIcon: Icons.play_arrow_outlined,
              label: "الريلز",
            ),
            // Tab 3: Center Action Button (+)
            _buildCenterActionButton(),
            // Tab 4: Telegram / Chats
            _buildNavItem(
              index: 2,
              icon: Icons.chat_bubble_rounded,
              outlineIcon: Icons.chat_bubble_outline_rounded,
              label: "المراسلات",
            ),
            // Tab 5: More
            _buildNavItem(
              index: 3,
              icon: Icons.grid_view_rounded,
              outlineIcon: Icons.grid_view_outlined,
              label: "المزيد",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData outlineIcon,
    required String label,
    int? badgeCount,
  }) {
    final bool isSelected = currentIndex == index;
    final Color itemColor = isSelected ? WadiqColors.primaryAmber : WadiqColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? icon : outlineIcon,
                  size: 24,
                  color: itemColor,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: WadiqColors.primaryAmber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: WadiqTypography.caption.copyWith(
                color: itemColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionButton() {
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onCreatePressed,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: WadiqColors.amberGradient,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: WadiqColors.amberGlow,
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
