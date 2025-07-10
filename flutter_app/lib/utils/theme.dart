import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFF1E3A8A); // Azul profundo
  static const Color secondaryColor = Color(0xFF3B82F6); // Azul claro
  static const Color accentColor = Color(0xFF10B981); // Verde éxito
  static const Color errorColor = Color(0xFFEF4444); // Rojo error
  static const Color warningColor = Color(0xFFF59E0B); // Amarillo advertencia
  static const Color infoColor = Color(0xFF06B6D4); // Cyan información
  
  // Colores de fondo
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // Colores de texto
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color textDisabledColor = Color(0xFF9CA3AF);
  
  // Colores de bordes
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
      
      // Esquema de colores
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        onError: Colors.white,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Roboto',
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // Campos de entrada
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          color: textDisabledColor,
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: errorColor,
          fontSize: 12,
        ),
      ),

      // Tarjetas


      // Divisores
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Tipografía
      textTheme: const TextTheme(
        // Títulos grandes
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        
        // Títulos
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        
        // Cuerpo de texto
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondaryColor,
          fontFamily: 'Roboto',
        ),
        
        // Etiquetas
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          fontFamily: 'Roboto',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          fontFamily: 'Roboto',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          fontFamily: 'Roboto',
        ),
      ),

      // Barra de navegación inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Indicador de progreso
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: borderColor,
        circularTrackColor: borderColor,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Métodos de utilidad para colores
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETADA':
      case 'SUCCESS':
        return accentColor;
      case 'PENDIENTE':
      case 'WARNING':
        return warningColor;
      case 'FALLIDA':
      case 'CANCELADA':
      case 'ERROR':
        return errorColor;
      case 'INFO':
        return infoColor;
      default:
        return textSecondaryColor;
    }
  }

  static Color getTransactionColor(bool isOutgoing) {
    return isOutgoing ? errorColor : accentColor;
  }
}

// Extensiones para facilitar el uso
extension ColorExtensions on Color {
  Color get withLightOpacity => withOpacity(0.1);
  Color get withMediumOpacity => withOpacity(0.5);
  Color get withHighOpacity => withOpacity(0.8);
}

extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
