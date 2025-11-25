// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

BoxDecoration appleCard(bool isDark) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF13161C) : Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: isDark ? const Color(0xFF1C1F27) : const Color(0xFFE5E7EB),
    ),
    boxShadow: isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
  );
}
