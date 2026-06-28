import 'package:flutter/material.dart';

/// Простой полноэкранный экран-загрузчик.
/// Ничего не знает о вашем роутинге/теме.
/// Можно использовать как переходное окно между экранами/приложениями.
///
/// Примеры использования (в вашем коде, не здесь):
/// Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoaderScreen()));
/// Navigator.of(context).pop(); // чтобы закрыть, когда загрузка завершится.
class LoaderScreen extends StatelessWidget {
  const LoaderScreen({
    super.key,
    this.message,
    this.backgroundColor,
    this.spinnerColor,
    this.logo,
    this.blockBack = true,
  });

  /// Необязательное сообщение под индикатором.
  final String? message;

  /// Цвет фона. Если не задан, используется тёмный полупрозрачный поверх темы.
  final Color? backgroundColor;

  /// Цвет спиннера.
  final Color? spinnerColor;

  /// Необязательный логотип/иконка над индикатором.
  final Widget? logo;

  /// Блокировать кнопку "назад" (Android) и свайп-назад (iOS).
  final bool blockBack;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.black.withOpacity(0.85);
    final progressColor = spinnerColor ?? Colors.white;

    Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logo != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: logo!,
              ),
            ],
            Semantics(
              label: 'Загрузка',
              child: SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Небольшая анимация появления.
    content = AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 200),
      child: content,
    );

    // По умолчанию блокируем "назад", чтобы это было именно переходное окно.
    Widget page = Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
          ],
        ),
      ),
    );

    if (blockBack) {
      page = WillPopScope(
        onWillPop: () async => false,
        child: page,
      );
    }

    return page;
  }
}
