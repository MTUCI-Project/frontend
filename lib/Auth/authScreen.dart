import 'package:flutter/material.dart';
import 'authMain.dart';

/// Экран авторизации с фоном #FAEDCD и кнопками входа.
/// Логику делегирует в переданный [authMain].
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authMain,
    this.onSignedIn, // колбэк на успех, если нужен
    this.onRegisterPressed, // колбэк для открытия экрана регистрации
  });

  final AuthMain authMain;
  final Future<void> Function()? onSignedIn;
  final VoidCallback? onRegisterPressed;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  // Состояние формы email+пароль
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  // Регексы
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!@#\$%\^&\*\-_\.]{8,}$',
  );

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) {
        await widget.onSignedIn?.call();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    await _handleSignIn(() => widget.authMain.signIn(username, password));
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFAEDCD);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            // Контент
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Сердечко над заголовком
                      const Icon(
                        Icons.favorite_rounded,
                        size: 60,
                        color: Colors.brown,
                      ),
                      const SizedBox(height: 12),
                      // Заголовок
                      const Text(
                        'Добро пожаловать',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Форма входа
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Войти по логину',
                          style: TextStyle(
                            color: Colors.brown.shade800,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameCtrl,
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Логин',
                                hintText: 'username',
                                prefixIcon: const Icon(
                                  Icons.alternate_email_rounded,
                                ),
                                filled: true,
                                fillColor: Colors.brown.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Введите логин';
                                }
                                if (text.length < 3 || text.length > 32) {
                                  return 'Логин: от 3 до 32 символов';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Пароль',
                                hintText: 'Минимум 8 символов',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                filled: true,
                                fillColor: Colors.brown.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                final text = value ?? '';
                                if (text.isEmpty) {
                                  return 'Введите пароль';
                                }
                                if (!_passwordRegex.hasMatch(text)) {
                                  return 'Пароль: минимум 8 символов, буква и цифра';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.brown.shade800,
                                  side: BorderSide(
                                    color: Colors.brown.shade400,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.brown.shade50,
                                ),
                                child: const Text(
                                  'Войти',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Кнопка Регистрация (только UI-колбэк)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : widget.onRegisterPressed,
                          child: const Text(
                            'Зарегистрироваться',
                            style: TextStyle(
                              color: Colors.brown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Ошибка
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Лоадер поверх контента
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
