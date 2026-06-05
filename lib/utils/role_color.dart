// lib/utils/role_color.dart

import 'package:digitaltv/utils/permission_label.dart';
import 'package:flutter/material.dart';
import 'package:digitaltv/auth/auth.dart';

extension AppRoleColor on AppRole {
  Color get color => switch (this) {
        AppRole.superAdmin => const Color(0xFFEF4444),
        AppRole.companyAdmin => const Color(0xFF6366F1),
        AppRole.manager => const Color(0xFF38BDF8),
        AppRole.editor => const Color(0xFF22C55E),
        AppRole.user => const Color(0xFFF59E0B),
      };

  String get description => switch (this) {
        AppRole.superAdmin => 'Control total del sistema',
        AppRole.companyAdmin => 'Gestiona usuarios y dispositivos',
        AppRole.manager => 'Supervisa equipos y contenido',
        AppRole.editor => 'Crea y edita contenido',
        AppRole.user => 'Acceso básico al sistema',
      };
}
