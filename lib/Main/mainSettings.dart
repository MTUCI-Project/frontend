import 'package:flutter/material.dart';

/// Экран настроек
class MainSettings extends StatelessWidget {
  final int partnerId;
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final VoidCallback onLogout;

  const MainSettings({
    super.key,
    required this.partnerId,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? Colors.white : Colors.brown;
    final secondaryTextColor = isDark ? const Color(0xFFB0B0B0) : Colors.brown.shade600;
    final cardBg = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.brown.shade200;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Настройки',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),

            // Уведомления
            _buildSettingSection(
              'Уведомления',
              [
                _buildSettingTile(
                  'Включить уведомления',
                  'Получать напоминания о важных датах',
                  Icons.notifications_rounded,
                  isDark,
                  textColor,
                  secondaryTextColor,
                ),
              ],
              isDark,
              cardBg,
              borderColor,
            ),
            const SizedBox(height: 16),

            // Внешний вид
            _buildSettingSection(
              'Внешний вид',
              [
                _buildThemeToggleTile(
                  isDark,
                  textColor,
                  secondaryTextColor,
                  onThemeChanged,
                ),
              ],
              isDark,
              cardBg,
              borderColor,
            ),
            const SizedBox(height: 16),

            // Выход
            _buildSettingSection(
              'Аккаунт',
              [
                _buildLogoutButton(
                  isDark,
                  textColor,
                  onLogout,
                ),
              ],
              isDark,
              cardBg,
              borderColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children, bool isDark, Color cardBg, Color borderColor) {
    final textColor = isDark ? Colors.white : Colors.brown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, bool isDark, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.brown.shade700 : Colors.brown, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleTile(bool isDark, Color textColor, Color secondaryTextColor, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isDark ? Colors.amber : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Тёмная тема' : 'Светлая тема',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDark ? 'Сейчас активна тёмная тема' : 'Сейчас активна светлая тема',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => onToggle(),
            activeColor: isDark ? Colors.brown.shade700 : Colors.brown,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark, Color textColor, VoidCallback onLogout) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Выход',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
