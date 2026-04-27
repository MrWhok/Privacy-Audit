import 'package:flutter/material.dart';

class RiskBadge extends StatelessWidget {
  final String risk;
  const RiskBadge(this.risk, {super.key});

  Color _bg() {
    switch (risk) {
      case 'Critical': return const Color(0xFFFCEBEB);
      case 'High':     return const Color(0xFFFAEEDA);
      case 'Medium':   return const Color(0xFFE6F1FB);
      default:         return const Color(0xFFEAF3DE);
    }
  }

  Color _fg() {
    switch (risk) {
      case 'Critical': return const Color(0xFF791F1F);
      case 'High':     return const Color(0xFF633806);
      case 'Medium':   return const Color(0xFF0C447C);
      default:         return const Color(0xFF27500A);
    }
  }

  Color dotColor() {
    switch (risk) {
      case 'Critical': return const Color(0xFFE24B4A);
      case 'High':     return const Color(0xFFEF9F27);
      case 'Medium':   return const Color(0xFF378ADD);
      default:         return const Color(0xFF639922);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        risk,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _fg()),
      ),
    );
  }
}
