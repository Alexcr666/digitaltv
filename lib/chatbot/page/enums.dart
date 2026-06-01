
import 'package:digitaltv/chatbot/color.dart';
import 'package:flutter/material.dart';

enum SalesStage {
  inicial,
  interesado,
  dudoso,
  pendiente,
  confirmado,
  noInteresado,
}

extension SalesStageExt on SalesStage {
  String get label {
    switch (this) {
      case SalesStage.inicial: return 'Inicial';
      case SalesStage.interesado: return 'Interesado';
      case SalesStage.dudoso: return 'Dudoso';
      case SalesStage.pendiente: return 'Pendiente';
      case SalesStage.confirmado: return 'Confirmado';
      case SalesStage.noInteresado: return 'No Interesado';
    }
  }

  Color get color {
    switch (this) {
      case SalesStage.inicial: return WAColors.textMuted;
      case SalesStage.interesado: return WAColors.green;
      case SalesStage.dudoso: return WAColors.warning;
      case SalesStage.pendiente: return WAColors.info;
      case SalesStage.confirmado: return Color(0xFF10B981);
      case SalesStage.noInteresado: return WAColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case SalesStage.inicial: return Icons.fiber_new_rounded;
      case SalesStage.interesado: return Icons.thumb_up_rounded;
      case SalesStage.dudoso: return Icons.help_rounded;
      case SalesStage.pendiente: return Icons.schedule_rounded;
      case SalesStage.confirmado: return Icons.check_circle_rounded;
      case SalesStage.noInteresado: return Icons.thumb_down_rounded;
    }
  }

  static SalesStage fromString(String? s) {
    switch (s) {
      case 'interesado': return SalesStage.interesado;
      case 'dudoso': return SalesStage.dudoso;
      case 'pendiente': return SalesStage.pendiente;
      case 'confirmado': return SalesStage.confirmado;
      case 'noInteresado': return SalesStage.noInteresado;
      default: return SalesStage.inicial;
    }
  }

  String get key {
    switch (this) {
      case SalesStage.inicial: return 'inicial';
      case SalesStage.interesado: return 'interesado';
      case SalesStage.dudoso: return 'dudoso';
      case SalesStage.pendiente: return 'pendiente';
      case SalesStage.confirmado: return 'confirmado';
      case SalesStage.noInteresado: return 'noInteresado';
    }
  }
}

