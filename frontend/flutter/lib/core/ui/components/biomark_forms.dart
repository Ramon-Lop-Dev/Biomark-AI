// Biblioteca de Elementos de Formulario (Form Controls) de Biomark AI
// Diseñados conforme a WCAG 2.1 AA/AAA, Syne/Poppins y accesibilidad táctil (>=48dp)
import 'package:flutter/material.dart';
import '../../../biomark_brand.dart';
import '../../design/app_themecontroller.dart';

/// Campo de Texto Universal Biomark
class BiomarkTextField extends StatelessWidget {
  const BiomarkTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixWidget,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.helperText,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = AppThemeController.instance.isHighContrast;

    final fillColor = isHighContrast
        ? Colors.white
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));
    final borderColor = isHighContrast
        ? Colors.black
        : (isDark ? Colors.white12 : const Color(0xFFCBD5E1));
    final focusedBorderColor = isHighContrast ? Colors.black : BiomarkColors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            helperText: helperText,
            helperStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  )
                : null,
            suffixIcon: suffixWidget,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: isHighContrast ? 2.0 : 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo de Contraseña con Toggle de Visibilidad
class BiomarkPasswordField extends StatefulWidget {
  const BiomarkPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText = '••••••••',
    this.validator,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  State<BiomarkPasswordField> createState() => _BiomarkPasswordFieldState();
}

class _BiomarkPasswordFieldState extends State<BiomarkPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return BiomarkTextField(
      label: widget.label,
      controller: widget.controller,
      hintText: widget.hintText,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      suffixWidget: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white60
              : const Color(0xFF64748B),
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
        tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
      ),
    );
  }
}

/// Selector Desplegable Estilizado (Dropdown)
class BiomarkDropdownField<T> extends StatelessWidget {
  const BiomarkDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.hintText,
    this.validator,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;
  final String? hintText;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Selector de Chips Múltiples para Síntomas o Alertas
class BiomarkMultiSelectChips extends StatelessWidget {
  const BiomarkMultiSelectChips({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onChanged,
  });

  final List<String> options;
  final List<String> selectedOptions;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            final updated = List<String>.from(selectedOptions);
            if (selected) {
              updated.add(option);
            } else {
              updated.remove(option);
            }
            onChanged(updated);
          },
          selectedColor: BiomarkColors.green.withValues(alpha: 0.2),
          checkmarkColor: BiomarkColors.green,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? BiomarkColors.green
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF334155)),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? BiomarkColors.green : Colors.transparent,
              width: 1.2,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Control Deslizante de Escala de Dolor / Intensidad (0 a 10)
class BiomarkPainScaleSlider extends StatelessWidget {
  const BiomarkPainScaleSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  String get _painDescription {
    if (value <= 0) return 'Sin dolor / Normal';
    if (value <= 3) return 'Leve (molestia soportable)';
    if (value <= 6) return 'Moderado (interfiere con actividades)';
    if (value <= 8) return 'Severo (dificulta el movimiento)';
    return 'Incapacitante / Emergencia';
  }

  Color get _sliderColor {
    if (value <= 3) return BiomarkColors.green;
    if (value <= 6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Intensidad del Síntoma o Dolor:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _sliderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${value.round()} / 10',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _sliderColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _sliderColor,
            thumbColor: _sliderColor,
            overlayColor: _sliderColor.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
        Center(
          child: Text(
            _painDescription,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
