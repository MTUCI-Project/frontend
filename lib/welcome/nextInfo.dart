import 'package:flutter/material.dart';

/// Экран с предложением заполнить информацию о партнере
class NextInfo extends StatelessWidget {
  final VoidCallback onContinuePressed;

  const NextInfo({
    super.key,
    required this.onContinuePressed,
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
                          Icons.person_add_rounded,
                          size: 80,
                          color: Colors.brown,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Давайте заполним информацию о вашем партнёре',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Это поможет вам лучше узнать своего партнера и создать персональную коллекцию его предпочтений, интересов и важных моментов.',
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

                  // Кнопка "Продолжить" внизу
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinuePressed,
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
                        'Продолжить',
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
