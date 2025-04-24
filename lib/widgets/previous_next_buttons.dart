import 'package:flutter/material.dart';

class PreviousNextButton extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isFirstPage;
  final bool isLastPage;

  const PreviousNextButton({
    super.key,
    required this.onPrevious,
    required this.onNext,
    this.isFirstPage = false,
    this.isLastPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirstPage)
          _HoverButton(
            label: 'PREV',
            icon: Icons.keyboard_double_arrow_left,
            color: Colors.red,
            onPressed: onPrevious!,
          )
        else
          const SizedBox(width: 100), // spacer kecil

        if (!isLastPage)
          _HoverButton(
            label: 'NEXT',
            icon: Icons.keyboard_double_arrow_right,
            color: Colors.blue,
            onPressed: onNext!,
          )
        else
          const SizedBox(width: 100),
      ],
    );
  }
}

class _HoverButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _HoverButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform:
            _isHovered ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: 20), // ikon lebih kecil
          label: Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            elevation: _isHovered ? 8 : 2,
            shadowColor: widget.color.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
