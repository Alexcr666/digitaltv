// lib/utils/permission_label.dart

import 'package:digitaltv/auth/auth.dart';
import 'package:flutter/material.dart';

extension AppPermissionLabel on AppPermission {
  String get label => switch (this) {
    AppPermission.companiesView     => '👁 Ver empresas',
    AppPermission.companiesCreate   => '➕ Crear empresas',
    AppPermission.companiesEdit     => '✏️ Editar empresas',
    AppPermission.companiesDelete   => '🗑 Eliminar empresas',
    AppPermission.usersView         => '👥 Ver usuarios',
    AppPermission.usersCreate       => '➕ Crear usuarios',
    AppPermission.usersEdit         => '✏️ Editar usuarios',
    AppPermission.usersDelete       => '🗑 Eliminar usuarios',
    AppPermission.rolesView         => '🛡 Ver roles',
    AppPermission.rolesCreate       => '➕ Crear roles',
    AppPermission.rolesEdit         => '✏️ Editar roles',
    AppPermission.rolesDelete       => '🗑 Eliminar roles',
    AppPermission.notificationsSend => '🔔 Enviar notificaciones',
    AppPermission.settingsEdit      => '⚙️ Editar configuración',  // ← agregado
    AppPermission.reportsView       => '📊 Ver reportes',
    AppPermission.dashboardGlobal   => '🌐 Dashboard global',      // ← agregado
    AppPermission.dashboardCompany  => '🏠 Ver panel empresa',
  };

  String get description => switch (this) {
    AppPermission.companiesView     => 'Puede ver la lista de empresas registradas',
    AppPermission.companiesCreate   => 'Puede registrar nuevas empresas en el sistema',
    AppPermission.companiesEdit     => 'Puede modificar datos de empresas existentes',
    AppPermission.companiesDelete   => 'Puede eliminar o desactivar empresas',
    AppPermission.usersView         => 'Puede ver la lista de usuarios del sistema',
    AppPermission.usersCreate       => 'Puede crear nuevas cuentas de usuario',
    AppPermission.usersEdit         => 'Puede modificar datos y roles de usuarios',
    AppPermission.usersDelete       => 'Puede eliminar o desactivar usuarios',
    AppPermission.rolesView         => 'Puede ver los roles y sus permisos',
    AppPermission.rolesCreate       => 'Puede crear nuevos roles personalizados',
    AppPermission.rolesEdit         => 'Puede modificar permisos de roles existentes',
    AppPermission.rolesDelete       => 'Puede eliminar roles del sistema',
    AppPermission.notificationsSend => 'Puede enviar notificaciones a usuarios',
    AppPermission.settingsEdit      => 'Puede modificar la configuración del sistema',
    AppPermission.reportsView       => 'Puede ver reportes y analíticas',
    AppPermission.dashboardGlobal   => 'Acceso al dashboard global del sistema',
    AppPermission.dashboardCompany  => 'Acceso al panel de control de la empresa',
  };
}


extension AppPermissionExtension on AppPermission {
  String get label => switch (this) {
    AppPermission.companiesView   => 'Ver empresas',
    AppPermission.companiesCreate => 'Crear empresas',
    AppPermission.companiesEdit   => 'Editar empresas',
    AppPermission.companiesDelete => 'Eliminar empresas',
    AppPermission.usersView       => 'Ver usuarios',
    AppPermission.usersCreate     => 'Crear usuarios',
    AppPermission.usersEdit       => 'Editar usuarios',
    AppPermission.usersDelete     => 'Eliminar usuarios',
    AppPermission.rolesView       => 'Ver roles',
    AppPermission.rolesCreate     => 'Crear roles',
    AppPermission.rolesEdit       => 'Editar roles',
    AppPermission.rolesDelete     => 'Eliminar roles',
    AppPermission.notificationsSend => 'Enviar notificaciones',
    AppPermission.settingsEdit    => 'Editar configuración',
    AppPermission.reportsView     => 'Ver reportes',
    AppPermission.dashboardGlobal => 'Dashboard global',
    AppPermission.dashboardCompany => 'Dashboard empresa',
  };
}


extension AppRoleExtension on AppRole {
  Color get color => switch (this) {
    AppRole.superAdmin   => const Color(0xFFEF4444),
    AppRole.companyAdmin => const Color(0xFF6366F1),
    AppRole.manager      => const Color(0xFF38BDF8),
    AppRole.editor       => const Color(0xFF22C55E),
    AppRole.user         => const Color(0xFFF59E0B),
  };

  String get description => switch (this) {
    AppRole.superAdmin   => 'Control total del sistema',
    AppRole.companyAdmin => 'Gestiona usuarios y dispositivos',
    AppRole.manager      => 'Supervisa equipos y contenido',
    AppRole.editor       => 'Crea y edita contenido',
    AppRole.user         => 'Acceso básico al sistema',
  };
}

// =============================================================================
// 1. DOMAIN MODELS
// =============================================================================
enum AppRole {
  superAdmin('super_admin'),
  companyAdmin('company_admin'),
  manager('manager'),
  editor('editor'),
  user('user');

  final String value;
  const AppRole(this.value);

  static AppRole fromString(String s) =>
      AppRole.values.firstWhere((r) => r.value == s, orElse: () => AppRole.user);

  String get displayName => switch (this) {
        AppRole.superAdmin   => 'Super Admin',
        AppRole.companyAdmin => 'Admin Empresa',
        AppRole.manager      => 'Manager',
        AppRole.editor       => 'Editor',
        AppRole.user         => 'Usuario',
      };
}
enum AppPermission {
  // Empresas (solo superAdmin)
  companiesView('companies.view'),
  companiesCreate('companies.create'),
  companiesEdit('companies.edit'),
  companiesDelete('companies.delete'),

  // Usuarios
  usersView('users.view'),
  usersCreate('users.create'),
  usersEdit('users.edit'),
  usersDelete('users.delete'),

  // Roles
  rolesView('roles.view'),
  rolesCreate('roles.create'),
  rolesEdit('roles.edit'),
  rolesDelete('roles.delete'),

  // Notificaciones
  notificationsSend('notifications.send'),

  // Configuración
  settingsEdit('settings.edit'),

  // Reportes / Analytics
  reportsView('reports.view'),

  // Dashboard global (solo superAdmin)
  dashboardGlobal('dashboard.global'),

  // Dashboard empresa
  dashboardCompany('dashboard.company');

  final String value;
  const AppPermission(this.value);

  static AppPermission? fromString(String s) {
    try {
      return AppPermission.values.firstWhere((p) => p.value == s);
    } catch (_) {
      return null;
    }
  }
}