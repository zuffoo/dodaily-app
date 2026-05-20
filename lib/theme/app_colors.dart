import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bg        = Color(0xFF0A0A0A);
  static const Color surface   = Color(0xFF141414);
  static const Color surfaceHi = Color(0xFF1C1C1C);
  static const Color border    = Color(0xFF242424);
  static const Color borderHi  = Color(0xFF2E2E2E);
  static const Color track     = Color(0xFF202020);

  static const Color text     = Color(0xFFFAFAFA);
  static const Color textDim  = Color(0xFFA0A0A0);
  static const Color textMute = Color(0xFF5A5A5A);

  static const Color accent    = Color(0xFFFF6B1A);
  static const Color accentDim = Color(0x24FF6B1A);

  static const Color priAlta  = Color(0xFFFF5C5C);
  static const Color priMedia = Color(0xFFF5A623);
  static const Color priBaixa = Color(0xFF4ADE80);

  static const Color catTrabalho = Color(0xFF7DA3FF);
  static const Color catEstudo   = Color(0xFFC084FC);
  static const Color catPessoal  = Color(0xFFFF8FAB);
  static const Color catSaude    = Color(0xFF4ADE80);
  static const Color catOutras   = Color(0xFFA0A0A0);

  static Color categoryColor(String name) {
    switch (name) {
      case 'Trabalho': return catTrabalho;
      case 'Estudo':   return catEstudo;
      case 'Pessoal':  return catPessoal;
      case 'Saúde':    return catSaude;
      default:         return catOutras;
    }
  }

  static Color priorityColor(String name) {
    switch (name) {
      case 'Alta':  return priAlta;
      case 'Média': return priMedia;
      case 'Baixa': return priBaixa;
      default:      return priMedia;
    }
  }
}
