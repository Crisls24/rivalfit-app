import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

/// Entrada de codigo OTP: 6 cajas con avance/retroceso automatico, teclado
/// numerico, paste multiposicion y validacion automatica al completar.
///
/// El padre controla dos cosas:
/// - [isVerifying]: bloquea la entrada y muestra un progreso fino.
/// - [errorText]: al pasar de null a string, la fila hace shake, se limpia y
///   el foco vuelve a la primera caja.
class OtpCodeInput extends StatefulWidget {
  final int length;
  final bool isVerifying;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpCodeInput({
    super.key,
    this.length = 6,
    this.isVerifying = false,
    this.errorText,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput>
    with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final AnimationController _shakeController;
  bool _bulk = false;

  int get _length => widget.length;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: -1,
      upperBound: 1,
      value: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant OtpCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText == null && widget.errorText != null) {
      _shakeAndReset();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _shakeAndReset() {
    // _bulk evita que los onChanged disparados por el clear hagan setState
    // durante el build (didUpdateWidget).
    _bulk = true;
    for (final c in _controllers) {
      c.clear();
    }
    _bulk = false;
    _shakeController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _focusNodes.first.requestFocus();
    });
  }

  void _onChanged(int index, String value) {
    if (_bulk) return;

    if (value.length > 1) {
      // Paste de varios digitos: se reparten desde la caja en curso.
      _bulk = true;
      final digits = value.characters.toList();
      final insert = digits.take(_length - index).toList();
      for (var k = 0; k < insert.length; k++) {
        _controllers[index + k].text = insert[k];
      }
      _bulk = false;
      final end = index + insert.length;
      if (end >= _length) {
        _complete();
      } else {
        _focusNodes[end].requestFocus();
      }
      return;
    }

    if (value.isEmpty) {
      setState(() {});
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }

    // Un solo digito (normaliza a 1 char por si el autocompletado coloco mas).
    _controllers[index].text = value[value.length - 1];
    setState(() {});
    if (index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _complete();
    }
  }

  void _complete() {
    final code = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(code);
    if (code.length == _length && !widget.isVerifying) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.errorText != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final boxWidth =
            (constraints.maxWidth - gap * (_length - 1)) / _length;

        return AnimatedBuilder(
          animation: _shakeController,
          builder: (context, _) {
            final dx = _shakeController.value * 6.0;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    _OtpBox(
                      width: boxWidth,
                      height: 56,
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      isFocused: _focusNodes[i].hasFocus,
                      isError: isError,
                      readOnly: widget.isVerifying,
                      onChanged: (v) => _onChanged(i, v),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OtpBox extends StatelessWidget {
  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isError;
  final bool readOnly;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isError,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isError
        ? AppColors.danger
        : (isFocused ? AppColors.primary : AppColors.inputBorder);

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isFocused ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            readOnly: readOnly,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            cursorColor: AppColors.primary,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}