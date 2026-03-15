import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

Widget buildTeamLogo(String? url, {double size = 24}) {
  if (url == null || url == 'N/A') {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.white.withOpacity(0.05),
      child: Icon(Icons.shield, size: size * 0.6, color: Colors.white24),
    );
  }
  return Image.network(
    url,
    width: size,
    height: size,
    headers: const {
      'Referer': 'https://www.goal.com/',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
    fit: BoxFit.contain,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white.withOpacity(0.05),
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
            color: GoalioColors.greenAccent.withOpacity(0.3),
          ),
        ),
      );
    },
    errorBuilder:
        (c, e, s) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white.withOpacity(0.05),
          child: Icon(Icons.shield, size: size * 0.6, color: Colors.white24),
        ),
  );
}
