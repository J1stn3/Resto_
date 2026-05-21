import 'package:flutter/material.dart';
import '../utils/currency_format.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.amount, {super.key, this.style, this.bold = false});
  final double amount;
  final TextStyle? style;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPeso(amount),
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
            fontWeight: bold ? FontWeight.bold : null,
          ),
    );
  }
}
