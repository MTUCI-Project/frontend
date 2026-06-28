import 'package:flutter/material.dart';

/// Начальный экран приложения с описанием
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStartPressed;

  const WelcomeScreen({
    super.key,
    required this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFAEDCD);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 40),
                  
                  // Иконка и содержимое
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 80,
                          color: Colors.brown,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Помните всё',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Вы здесь, чтобы помнить всё о своей второй половинке, не так ли? '
                          'Желаете помнить даты особенных дней, помнить о её любимых цветах '
                          'или же о его любимых музыкальных группах? Хотите в любой момент '
                          'найти информацию о её любимом напитке и внезапно порадовать её? '
                          'Или вы совсем забыли какой покемон ему нравится? '
                          'Тогда мы вам в этом поможем!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.brown,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Кнопка "Начать" внизу
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStartPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Начать',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
