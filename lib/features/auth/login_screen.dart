import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/slide_button.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../shell/app_flow.dart';
import 'session_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _userFocus.addListener(_refresh);
    _passFocus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    FocusScope.of(context).unfocus();
    final username = _user.text.trim();
    final password = _pass.text;
    if (username.isEmpty) {
      Toast.error('Enter your username');
      return false;
    }
    if (password.isEmpty) {
      Toast.error('Enter your password');
      return false;
    }
    final session = context.read<SessionProvider>();
    try {
      await session.login(username, password);
    } on ApiException catch (e) {
      Toast.error(e.status == 401 ? 'Wrong username or password' : e.or("Couldn't sign in. Try again"));
      return false;
    } catch (_) {
      Toast.error("Couldn't sign in. Try again");
      return false;
    }
    Toast.success('Signed in');
    await AppFlow.enter();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gutter = context.sp(30);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kLightBar,
      child: Scaffold(
        backgroundColor: p.background,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, box) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _Top(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(gutter, context.sp(34), gutter, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _Field(
                                label: 'USERNAME',
                                hint: 'Enter your username',
                                controller: _user,
                                focus: _userFocus,
                                active: _userFocus.hasFocus,
                                action: TextInputAction.next,
                                onSubmitted: (_) => _passFocus.requestFocus(),
                              ),
                              SizedBox(height: context.sp(24)),
                              _Field(
                                label: 'PASSWORD',
                                hint: 'Enter your password',
                                controller: _pass,
                                focus: _passFocus,
                                active: _passFocus.hasFocus,
                                obscure: _hide,
                                action: TextInputAction.done,
                                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                                suffix: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _hide = !_hide),
                                  child: Padding(
                                    padding: EdgeInsets.all(context.sp(6)),
                                    child: Icon(
                                      _hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: context.sp(20),
                                      color: p.muted,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.sp(34)),
                              SlideButton(label: 'Slide to sign in', busyLabel: 'Signing in…', onSubmit: _submit),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(gutter, context.sp(28), gutter, context.bottomInset + context.sp(22)),
                      child: Text(
                        'SABROSO RIDER APP',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: const Color(0xFFB3ADBF), fontSize: context.sp(11), letterSpacing: 2.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Top extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final big = context.sp(30);
    return Container(
      decoration: BoxDecoration(
        gradient: p.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.sp(36))),
      ),
      padding: EdgeInsets.fromLTRB(context.sp(24), context.topInset + context.sp(46), context.sp(24), context.sp(52)),
      child: Column(
        children: <Widget>[
          BrandLogo(height: context.sp(62), maxWidth: context.sp(200)),
          SizedBox(height: context.sp(34)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Good to see',
                  style: TextStyle(color: Colors.white, fontSize: big, fontWeight: FontWeight.w300, height: 1.15),
                ),
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          children: const <InlineSpan>[
                            TextSpan(text: 'you again'),
                            TextSpan(text: '.', style: TextStyle(color: AppColors.amber)),
                          ],
                          style: TextStyle(color: Colors.white, fontSize: big, fontWeight: FontWeight.w700, height: 1.2),
                        ),
                      ),
                      SizedBox(
                        height: context.sp(10),
                        child: CustomPaint(painter: _Underline()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Underline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.01, size.height * 0.7)
      ..cubicTo(size.width * 0.25, size.height * 0.1, size.width * 0.69, size.height * 0.1, size.width * 0.99, size.height * 0.6);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focus,
    required this.active,
    required this.action,
    this.onSubmitted,
    this.obscure = false,
    this.suffix,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focus;
  final bool active;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.accent : p.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(color: color, fontSize: context.sp(11), letterSpacing: 1.8, fontWeight: FontWeight.w500),
          child: Text(label),
        ),
        TextField(
          controller: controller,
          focusNode: focus,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: !obscure,
          textInputAction: action,
          onSubmitted: onSubmitted,
          cursorColor: p.accent,
          style: TextStyle(color: p.text, fontSize: context.sp(15.5), letterSpacing: obscure ? 2.0 : 0.2),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFFB3ADBF), fontSize: context.sp(15), letterSpacing: 0.2),
            contentPadding: EdgeInsets.symmetric(vertical: context.sp(12)),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFDCD6E4))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.accent, width: 1.6)),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFDCD6E4))),
          ),
        ),
      ],
    );
  }
}
