import 'package:flutter/material.dart';

/// Aplica el espacio del teclado sin reconstruir el contenido de la hoja.
class LeagueKeyboardInset extends StatelessWidget {
  const LeagueKeyboardInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}
