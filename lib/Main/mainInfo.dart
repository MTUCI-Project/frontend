import 'package:flutter/material.dart';
import '../Api/apiService.dart';

/// Экран информации о партнёре
class MainInfo extends StatefulWidget {
  final int partnerId;
  final String partnerName;
  final bool isDarkMode;

  const MainInfo({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.isDarkMode,
  });

  @override
  State<MainInfo> createState() => _MainInfoState();
}

class _MainInfoState extends State<MainInfo> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.brown;
    final secondaryTextColor = isDark
        ? const Color(0xFFB0B0B0)
        : Colors.brown.shade600;
    final cardBg = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.brown.shade200;
    final avatarBg = isDark ? Colors.brown.shade900 : Colors.brown.shade200;
    final avatarIcon = isDark ? Colors.brown.shade600 : Colors.brown.shade400;

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.instance.partnerAnswers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.brown.shade700 : Colors.brown,
              ),
            );
          }

          final answers = snapshot.data ?? {};
          final partner =
              answers['partner.basic'] as Map<String, dynamic>? ?? {};
          final hobbies = (answers['partner.hobbies'] as List<dynamic>? ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: avatarBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: avatarIcon,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        partner['name'] as String? ?? widget.partnerName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/userInfo1'),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Редактировать информацию'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Основная информация
                _buildSection(
                  'Основная информация',
                  [
                    _buildInfoTile(
                      'Имя',
                      partner['name'] as String? ?? 'Не указано',
                      isDark,
                    ),
                    _buildInfoTile(
                      'Пол',
                      partner['gender'] as String? ?? 'Не указано',
                      isDark,
                    ),
                    _buildInfoTile(
                      'Дата рождения',
                      partner['birthDate'] as String? ?? 'Не указано',
                      isDark,
                    ),
                  ],
                  isDark,
                  cardBg,
                  borderColor,
                  textColor,
                  secondaryTextColor,
                ),
                const SizedBox(height: 24),

                // Хобби и увлечения
                _buildSection(
                  'Хобби и увлечения',
                  [
                    if (hobbies.isEmpty)
                      _buildInfoTile('Хобби', 'Не указано', isDark),
                    ...hobbies.map((item) {
                      final hobby = item as Map<String, dynamic>;
                      return _buildInfoTile(
                        hobby['hobby'] as String? ?? 'Хобби',
                        hobby['description'] as String? ?? '',
                        isDark,
                      );
                    }),
                  ],
                  isDark,
                  cardBg,
                  borderColor,
                  textColor,
                  secondaryTextColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> children,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
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
          padding: const EdgeInsets.all(12),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.brown;
    final secondaryTextColor = isDark
        ? const Color(0xFFB0B0B0)
        : Colors.brown.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
