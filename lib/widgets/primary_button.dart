import "package:flutter/material.dart";

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool expanded;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
