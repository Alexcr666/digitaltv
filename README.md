# VIEWIX — Plataforma de Gestión Digital Empresarial

<div align="center">

![Version](https://img.shields.io/badge/versión-1.0.0-00c8c8?style=for-the-badge)
![Estado](https://img.shields.io/badge/estado-en%20producción-22C55E?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-Web%203.x-02569B?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Functions-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)

**Plataforma SaaS multi-tenant para gestión de señalización digital y comunicación empresarial vía WhatsApp con IA.**

*Desarrollado por [WebSourcing](https://websourcing.com) · Autor: Alex Cabarcas · Junio 2026*

</div>

---

## Tabla de Contenido

1. [Descripción General](#1-descripción-general)
2. [Características Principales](#2-características-principales)
3. [Arquitectura del Sistema](#3-arquitectura-del-sistema)
4. [Stack Tecnológico](#4-stack-tecnológico)
5. [Estructura del Proyecto](#5-estructura-del-proyecto)
6. [Modelos de Datos](#6-modelos-de-datos)
7. [Base de Datos — Firestore](#7-base-de-datos--firestore)
8. [Autenticación y Sesión](#8-autenticación-y-sesión)
9. [Autorización y Permisos](#9-autorización-y-permisos)
10. [Módulos Funcionales](#10-módulos-funcionales)
11. [Módulo WhatsApp Chatbot](#11-módulo-whatsapp-chatbot)
12. [Módulo Digital Viewix](#12-módulo-digital-viewix)
13. [Gestión de Estado — Riverpod](#13-gestión-de-estado--riverpod)
14. [Servicios](#14-servicios)
15. [Sistema de Enrutamiento](#15-sistema-de-enrutamiento)
16. [Seguridad](#16-seguridad)
17. [Manejo de Errores](#17-manejo-de-errores)
18. [Despliegue](#18-despliegue)
19. [Mantenimiento y Guía de Desarrollo](#19-mantenimiento-y-guía-de-desarrollo)
20. [Troubleshooting](#20-troubleshooting)
21. [Decisiones Arquitectónicas](#21-decisiones-arquitectónicas)
22. [Riesgos y Recomendaciones Futuras](#22-riesgos-y-recomendaciones-futuras)
23. [Glosario Técnico](#23-glosario-técnico)

---

## 1. Descripción General

**VIEWIX** es una plataforma SaaS multi-tenant desarrollada con Flutter Web y Firebase que unifica la gestión de señalización digital corporativa y la atención al cliente vía WhatsApp Business con inteligencia artificial.

### Problema que Resuelve

| Problema | Descripción |
|---|---|
| Fragmentación digital | Gestión dispersa de dispositivos de señalización en múltiples ubicaciones |
| Sin control centralizado | Ausencia de panel único para contenidos multimedia en pantallas corporativas |
| Comunicación desintegrada | Falta de integración entre WhatsApp Business y CRM de ventas |
| Administración compleja | Dificultad para gestionar usuarios con diferentes accesos en entornos multi-empresa |
| Sin analítica unificada | Inexistencia de herramientas para medir rendimiento de campañas y conversaciones |

### Beneficios Clave

| Beneficio | Descripción | Impacto |
|---|---|---|
| Centralización | Panel único para todos los activos digitales | 🔴 Alto |
| Multi-tenant | Soporte multi-empresa con aislamiento de datos | 🔴 Alto |
| IA Integrada | Chatbot WhatsApp con GPT-4o para atención 24/7 | 🔴 Alto |
| Tiempo real | Actualizaciones en vivo con Firestore streams | 🟡 Medio |
| Escalabilidad | Arquitectura serverless que crece según demanda | 🔴 Alto |
| Seguridad | Roles y permisos granulares a nivel de ruta y UI | 🔴 Alto |

---

## 2. Características Principales

### Módulo Core — Gestión Empresarial
- ✅ Autenticación completa: login, registro, recuperación de contraseña con Firebase Auth
- ✅ Gestión multi-empresa con administrador dedicado por empresa
- ✅ Sistema de roles y permisos granular (5 roles, 15+ permisos)
- ✅ Dashboard adaptado por rol con métricas en tiempo real
- ✅ Sistema de notificaciones push en tiempo real (info, éxito, alerta, error, sistema)
- ✅ Perfil de usuario con foto, datos personales y cambio de contraseña

### Módulo Digital Viewix — Señalización
- ✅ Gestión de dispositivos físicos de señalización digital
- ✅ Creación y administración de playlists de contenido
- ✅ Programación horaria de contenidos
- ✅ Biblioteca multimedia centralizada
- ✅ Editor visual de pantallas

### Módulo WhatsApp Chatbot
- ✅ Bots de IA con GPT-4o, GPT-4 y GPT-3.5-turbo configurables
- ✅ Conversaciones en tiempo real con polling automático (5 segundos)
- ✅ Modo IA / Modo Humano con activación por palabras clave
- ✅ Pipeline de ventas con tablero Kanban drag-and-drop (6 etapas)
- ✅ Analytics y métricas de conversaciones
- ✅ Integración OAuth 2.0 con Facebook Business API

---

## 3. Arquitectura del Sistema

VIEWIX implementa una **arquitectura en capas (Layered Architecture)** combinada con el **patrón Repository** para acceso a datos. La capa de presentación usa el patrón **BLoC/Riverpod** para gestión de estado reactivo. El módulo de autenticación aplica **Clean Architecture** con separación explícita entre entidades, casos de uso y repositorios.

```
┌─────────────────────────────────────────────────────────────┐
│              CAPA DE PRESENTACIÓN (Flutter Web)             │
│         Screens · Pages · Widgets · Dialogs · Forms         │
│    GoRouter (Navegación Declarativa) · MaterialApp.router    │
└─────────────────────┬───────────────────────────────────────┘
                      │  Riverpod Providers
┌─────────────────────▼───────────────────────────────────────┐
│              CAPA DE LÓGICA DE NEGOCIO                      │
│   Use Cases · StateNotifiers · AsyncNotifiers               │
│   RouteGuard · PermissionGuard                              │
└─────────────────────┬───────────────────────────────────────┘
                      │  Repository Pattern
┌─────────────────────▼───────────────────────────────────────┐
│                    CAPA DE DATOS                            │
│   FirebaseService · FirestoreDeviceRepository               │
│   FirestoreContentRepository · WAService                    │
└─────────────────────┬───────────────────────────────────────┘
                      │  SDK Firebase / HTTP
┌─────────────────────▼───────────────────────────────────────┐
│                INFRAESTRUCTURA EXTERNA                      │
│  Firestore (NoSQL) · Firebase Auth · Cloud Storage          │
│  Cloud Functions · WhatsApp Business API · OpenAI GPT-4o    │
└─────────────────────────────────────────────────────────────┘
```

### Flujo de Datos

El flujo es **unidireccional**:

```
Usuario → Widget → Provider → Service/Repository → Firebase/API
                                                         │
Widget se reconstruye ← Provider actualiza ◄─────────────┘
```

Los Streams de Firestore permiten actualizaciones en tiempo real sin polling manual.

### Patrones de Diseño Aplicados

| Patrón | Ubicación | Propósito |
|---|---|---|
| Repository Pattern | `lib/repositories/`, `lib/firestore/` | Abstrae acceso a datos y facilita testing |
| Provider Pattern | `lib/provider/app_providers.dart` | Inyección de dependencias y estado global |
| Observer (Streams) | `FirebaseService`, Firestore Repos | Actualización reactiva en tiempo real |
| Factory Method | `fromFirestore()` en todos los modelos | Construcción de objetos desde documentos Firestore |
| Sealed Classes | `Result`, `Success`, `Failure` | Manejo tipado y seguro de errores |
| Guard Pattern | `PermissionGuard`, `RouteGuard` | Protección declarativa de rutas y widgets |
| Singleton | `FirebaseService`, `FirebaseFirestore.instance` | Instancia única de servicios Firebase |
| Strategy Pattern | `kDefaultRolePermissions` Map | Asignación de permisos por estrategia de rol |

---

## 4. Stack Tecnológico

### Stack Principal

| Tecnología | Versión | Propósito | Criticidad |
|---|---|---|---|
| Flutter Web | 3.x | Framework UI multiplataforma principal | 🔴 CRÍTICA |
| Dart | 3.x | Lenguaje de programación | 🔴 CRÍTICA |
| Firebase Core | Latest | SDK base de Firebase | 🔴 CRÍTICA |
| Firebase Auth | Latest | Autenticación y gestión de sesión | 🔴 CRÍTICA |
| Cloud Firestore | Latest | Base de datos NoSQL en tiempo real | 🔴 CRÍTICA |
| Flutter Riverpod | 2.x | Gestión de estado reactivo | 🔴 CRÍTICA |
| GoRouter | 14.x | Enrutamiento declarativo SPA | 🔴 CRÍTICA |
| Firebase Storage | Latest | Almacenamiento de archivos y fotos | 🟠 ALTA |
| http | Latest | Peticiones HTTP para API WhatsApp | 🟠 ALTA |
| Cloud Functions | Latest | Lógica serverless (emails, triggers) | 🟡 MEDIA |
| fl_chart | Latest | Gráficas de líneas y barras | 🟡 MEDIA |
| image_picker | Latest | Selección de imágenes del sistema | 🟡 MEDIA |
| intl | Latest | Internacionalización y formato de fechas | 🟡 MEDIA |
| dartz | Latest | Either/Option para manejo funcional de errores | 🟡 MEDIA |
| equatable | Latest | Comparación por valor en entidades | 🟡 MEDIA |
| qr_flutter | Latest | Generación de códigos QR | 🟢 BAJA |
| flutter_animate | Latest | Animaciones declarativas | 🟢 BAJA |

### Servicios Externos e Integraciones

| Servicio | URL / SDK | Función |
|---|---|---|
| WhatsApp Business API | `gettranscribeai.onrender.com` | Envío/recepción de mensajes WA y gestión de bots |
| OpenAI GPT-4o | `api.openai.com` (vía backend) | Respuestas automáticas de IA en chatbot |
| Facebook Graph API | `graph.facebook.com v19.0` | OAuth para conectar números WA Business |
| Firebase Console | `console.firebase.google.com` | Administración del proyecto Firebase |

---

## 5. Estructura del Proyecto

```
lib/
├── main.dart                    # Entry point, inicialización Firebase, ProviderScope
├── logo.dart                    # Widget AppLogo corporativo
├── config/
│   └── app_config.dart          # Constantes globales (superAdminEmail, etc.)
│
├── auth/
│   ├── auth.dart                # Modelos: AppUser, Company, AppNotification,
│   │                            #   RoleDefinition, Result<T>
│   ├── authSystem.dart          # UI: Login, Register, Profile, Roles, Users,
│   │                            #   Companies, Dashboard Shells, Router
│   ├── firebaseService.dart     # FirebaseService: Auth, Firestore, Storage, Functions
│   └── listUser.dart            # Componente auxiliar de listado de usuarios
│
├── chatbot/
│   ├── chatbot.dart             # Página principal WhatsappChatbotPage + views
│   ├── color.dart               # WAColors — paleta del módulo chatbot
│   ├── models/
│   │   └── waConversations.dart # WAChatbot, WAConversation, WAMessage
│   ├── page/
│   │   ├── analitics.dart       # AnalyticsView (embudo, usuarios, trazabilidad)
│   │   ├── config.dart          # ConfigView — configuración de bot
│   │   ├── enums.dart           # SalesStage enum con extensión de color/icono
│   │   ├── globalAnalytics.dart # GlobalAnalyticsView multi-bot
│   │   ├── kanva.dart           # KanbanView, KanbanCard, columnas drag-drop
│   │   ├── page.dart            # DashboardView, BotCard, BotListTile, StatCard
│   │   └── widget.dart          # Componentes reutilizables: WACard, PageHeader,
│   │                            #   MessageBubble, StatusBadge, FormField...
│   └── service/
│       └── service.dart         # WAService: cliente HTTP para API WhatsApp
│
├── entities/
│   └── entities.dart            # UserEntity, DeviceEntity, ContentEntity,
│                                #   GroupEntity, AssignmentEntity
│
├── firestore/
│   └── firestore.dart           # FirestoreDeviceRepo, FirestoreAssignmentRepo,
│                                #   FirestoreContentRepo
│
├── model/
│   └── models.dart              # Modelos Firestore: DeviceModel, ContentModel...
│
├── notification/                # Sistema de notificaciones push y overlay
│
├── provider/
│   └── app_providers.dart       # Todos los providers Riverpod globales del sistema
│
├── repositories/                # Contratos abstractos, tipos de fallo y casos de uso
│
├── route/
│   ├── mainshell.dart           # MainShell layout (sidebar legacy)
│   ├── route.dart               # Router secundario (legacy)
│   ├── route_guards.dart        # RouteGuard estático separado
│   └── shellprovider.dart       # Providers: onlineDevices, RegisterDeviceUseCase
│
├── ui/
│   ├── auth/
│   │   └── auth.dart            # AuthScreen (pantalla de autenticación legacy)
│   ├── dashboard.dart           # DashboardScreen, AnalyticsScreen
│   └── panel/
│       ├── panel.dart           # DevicesScreen, PlaylistsScreen
│       ├── panel2.dart          # MediaLibraryScreen, ScreenEditorScreen
│       ├── panel3.dart          # SchedulesScreen, ProgrammingScreen
│       ├── playlist2.dart       # PlaylistsListScreen, PlaylistViewerDialog
│       ├── programing.dart      # Pantalla de programación de contenidos
│       └── device_portal_screen.dart  # Portal de dispositivos físicos
│
└── utils/
    └── permission_label.dart    # AppRole enum, AppPermission enum con extensiones
```

### Responsabilidades por Módulo

| Módulo / Carpeta | Responsabilidad Principal | Tipo |
|---|---|---|
| `auth/` | Modelos de dominio, UI de autenticación, servicio Firebase central, router | Core |
| `chatbot/` | Módulo completo de WhatsApp chatbot: UI, modelos, servicio HTTP, analytics, Kanban | Feature |
| `entities/` | Entidades de dominio puras (sin dependencia de Firebase) para Viewix | Domain |
| `firestore/` | Implementaciones concretas de repositorios contra Firestore | Infrastructure |
| `model/` | Modelos de datos con serialización/deserialización Firestore | Data |
| `notification/` | Sistema de notificaciones push y overlay de notificaciones | Feature |
| `provider/` | Todos los providers Riverpod globales del sistema | State |
| `repositories/` | Contratos abstractos, tipos de fallo y casos de uso | Domain |
| `route/` | Configuración de router, shell layouts y guards de navegación | Navigation |
| `ui/` | Pantallas secundarias y componentes de Viewix | Presentation |
| `utils/` | Enumeraciones de roles/permisos con extensiones de helper | Utils |

---

## 6. Modelos de Datos

### 6.1 · AppUser

Modelo central que representa a un usuario autenticado. Soporta el patrón `copyWith` para inmutabilidad parcial.

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `uid` | String | ✅ | ID único de Firebase Auth |
| `name` | String | ✅ | Nombre completo del usuario |
| `email` | String | ✅ | Correo electrónico (único) |
| `phone` | String | ❌ | Teléfono de contacto |
| `photoUrl` | String? | ❌ | URL de foto de perfil en Storage |
| `address` | String | ❌ | Dirección física del usuario |
| `roles` | List | ✅ | Lista de roles asignados |
| `permissions` | List | ✅ | Permisos explícitos del usuario |
| `status` | String | ✅ | Estado: `active` \| `suspended` \| `inactive` |
| `companyId` | String? | ❌ | ID de empresa (null = Super Admin) |
| `createdAt` | DateTime | ✅ | Timestamp de creación |
| `updatedAt` | DateTime | ✅ | Timestamp de última actualización |
| `lastLogin` | DateTime? | ❌ | Timestamp del último inicio de sesión |

**Métodos relevantes:**
- `isActive` → `bool`: Retorna `true` si `status == "active"`
- `isSuperAdmin` → `bool`: True si contiene `AppRole.superAdmin`
- `isCompanyAdmin` → `bool`: True si contiene `AppRole.companyAdmin`
- `hasPermission(AppPermission)` → `bool`: Super Admin siempre retorna true
- `hasAnyPermission(List)` → `bool`: Verifica si posee al menos uno de los permisos
- `copyWith(...)` → `AppUser`: Crea copia inmutable con campos modificados

### 6.2 · Company

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `id` | String | ✅ | ID del documento Firestore |
| `name` | String | ✅ | Nombre comercial de la empresa |
| `legalName` | String | ✅ | Razón social / Nombre legal |
| `email` | String | ✅ | Email corporativo principal |
| `phone` | String | ❌ | Teléfono de contacto empresarial |
| `address` | String | ❌ | Dirección física de la empresa |
| `logoUrl` | String? | ❌ | URL del logo en Storage |
| `status` | String | ✅ | Estado: `active` \| `suspended` \| `inactive` |
| `createdAt` | DateTime | ✅ | Fecha de creación |
| `updatedAt` | DateTime | ✅ | Fecha de última modificación |

### 6.3 · AppNotification

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | ID del documento Firestore |
| `userId` | String | ID del usuario destinatario |
| `title` | String | Título de la notificación |
| `body` | String | Cuerpo / mensaje de la notificación |
| `type` | NotificationType | Enum: `info` \| `success` \| `warning` \| `error` \| `system` |
| `read` | bool | Estado de lectura (false = no leída) |
| `createdAt` | DateTime | Timestamp de creación |
| `metadata` | Map | Datos adicionales arbitrarios |

### 6.4 · RoleDefinition

Modelo para roles personalizados creados por empresas o el Super Admin.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | ID del documento |
| `name` | String | Identificador interno único (snake_case) |
| `displayName` | String | Nombre legible para UI |
| `description` | String | Descripción del propósito del rol |
| `permissions` | List | Permisos asignados al rol |
| `companyId` | String? | `null` = rol global; `id` = rol de empresa específica |
| `createdAt` | DateTime | Timestamp de creación |

### 6.5 · WAChatbot

Modelo del chatbot de WhatsApp. Se almacena en el backend externo (no en Firestore) y se sincroniza vía HTTP REST desde `WAService`.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | ID único del bot en backend externo |
| `name` | String | Nombre del bot |
| `phoneNumber` | String | Número WA asociado (+57...) |
| `phoneNumberId` | String | Phone Number ID de Meta Business |
| `accessToken` | String | Token de acceso de Meta API |
| `systemPrompt` | String | Prompt del sistema para la IA |
| `aiModel` | String | Modelo OpenAI: `gpt-4o-mini` \| `gpt-4o` \| `gpt-3.5-turbo` |
| `temperature` | double | Temperatura de IA (0.0 - 1.0) |
| `maxTokens` | int | Máximo de tokens por respuesta |
| `contextMessages` | int | Número de mensajes de contexto a incluir |
| `isActive` | bool | Estado activo/inactivo de la IA |
| `humanKeywords` | List | Palabras que activan derivación a humano |

---

## 7. Base de Datos — Firestore

El sistema usa **Firebase Cloud Firestore** como base de datos NoSQL orientada a documentos con sincronización en tiempo real. Todas las colecciones siguen el patrón de documentos planos con referencias por ID (desnormalización).

### Colecciones Principales

| Colección | Descripción | Relaciones | Acceso |
|---|---|---|---|
| `users` | Perfiles de usuarios del sistema | `companyId → companies` | Auth + Admin |
| `companies` | Empresas registradas | `← users.companyId` | Super Admin |
| `roles` | Roles personalizados por empresa | `companyId → companies` | Company Admin |
| `notifications` | Notificaciones de usuarios | `userId → users` | Por usuario |
| `devices` | Dispositivos de señalización digital | `groupId → groups` | Company Admin |
| `content` | Contenidos multimedia | `ownerId → users` | Company Admin |
| `assignments` | Asignaciones contenido-dispositivo | `contentId`, `tvId`, `groupId` | Company Admin |

### Esquema: `users/{uid}`

```
users/{uid}
  uid: String               // = Firebase Auth UID
  name: String
  email: String
  phone: String
  photoUrl: String?
  address: String
  roles: Array<String>      // ["companyAdmin", "manager"]
  permissions: Array<String>// ["usersView", "rolesView", ...]
  status: String            // "active" | "suspended" | "inactive"
  companyId: String?        // null si es Super Admin
  createdAt: Timestamp
  updatedAt: Timestamp
  lastLogin: Timestamp?
```

### Esquema: `notifications/{notifId}`

```
notifications/{notifId}
  userId: String
  companyId: String?        // opcional para filtros
  title: String
  body: String
  type: String              // "info"|"success"|"warning"|"error"|"system"
  read: Boolean
  createdAt: Timestamp
  metadata: Map             // datos adicionales arbitrarios
```

### Esquema: `devices/{deviceId}`

```
devices/{deviceId}
  name: String
  uniqueDeviceId: String    // ID hardware único
  status: String            // "online"|"offline"|"warning"
  groupId: String?
  groupName: String?
  currentContentId: String?
  lastSeen: Timestamp
  metadata: {
    ipAddress: String?
    androidVersion: String?
    appVersion: String?
    resolution: String?
  }
  createdAt: Timestamp
```

### Reglas de Acceso (Firestore Security Rules)

```javascript
rules_version = "2";
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: solo el propio user o admin puede leer/escribir
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid
        || get(/databases/$(database)/documents/users/$(request.auth.uid))
           .data.roles.hasAny(["superAdmin","companyAdmin"]);
    }
    // Companies: solo superAdmin puede escribir
    match /companies/{companyId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid))
        .data.roles.hasAny(["superAdmin"]);
    }
    // Notifications: usuario solo ve las suyas
    match /notifications/{notifId} {
      allow read, write: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

> ⚠️ **Importante:** Las reglas anteriores son un ejemplo base. Se deben configurar las reglas completas en Firebase Console antes de ir a producción. Ver [checklist de producción](#checklist-de-producción).

---

## 8. Autenticación y Sesión

El sistema usa **Firebase Authentication** con proveedores de email/contraseña. La gestión de sesión es automática mediante el stream `authStateChanges()` que notifica al router GoRouter para redirigir al usuario correctamente.

### Flujo de Login

| Paso | Acción | Componente | Resultado |
|---|---|---|---|
| 1 | Usuario ingresa email y contraseña | `LoginPage` | Formulario validado |
| 2 | Se llama a `_submit()` | `LoginPage` | Validación local de campos |
| 3 | `firebaseService.signIn(email, password)` | `FirebaseService` | Llamada a Firebase Auth |
| 4 | Firebase Auth devuelve `UserCredential` | Firebase | Sesión creada en Firebase |
| 5 | Se carga `AppUser` desde Firestore | `FirebaseService.signIn()` | Verificación de cuenta activa |
| 6 | Se verifica empresa activa (si aplica) | `FirebaseService.signIn()` | Empresa verificada |
| 7 | Se actualiza `lastLogin` en Firestore | `FirebaseService` | Timestamp actualizado |
| 8 | `authStateProvider` actualiza stream | Riverpod Provider | Estado global actualizado |
| 9 | GoRouter redirige según rol | `routerProvider redirect` | `superDashboard` o `dashboard` |

### Creación de Usuarios por Administrador

Los Company Admins pueden crear usuarios usando `createUserAsAdmin()`. Este método utiliza una **aplicación Firebase secundaria** (`secondary app`) para crear el usuario en Authentication sin afectar la sesión del administrador actual:

```dart
// Patrón: Firebase Secondary App para crear usuarios
final secondaryApp = await Firebase.initializeApp(
  name: "secondary_${timestamp}",
  options: Firebase.app().options
);
final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
final cred = await secondaryAuth.createUserWithEmailAndPassword(...);
// Crear perfil en Firestore
await _users.doc(cred.user!.uid).set(appUser.toFirestore());
await secondaryAuth.signOut();
await secondaryApp.delete(); // IMPORTANTE: limpiar app secundaria
```

### Super Admin Seed

El método `seedSuperAdmin()` de `FirebaseService` se ejecuta al inicializar la app. Verifica si existe el Super Admin en Firestore; si no existe, lo crea en Auth y Firestore. Las credenciales se definen en `app_config.dart`.

> ⚠️ **Seguridad:** Para producción, se debe mover el Super Admin seed a variables de entorno o Firebase Remote Config.

---

## 9. Autorización y Permisos

### 9.1 · Roles del Sistema (AppRole)

| Rol | Valor en BD | Alcance | Descripción |
|---|---|---|---|
| **Super Admin** | `superAdmin` | Global | Control total del sistema. Accede a todas las empresas, usuarios y configuración global |
| **Company Admin** | `companyAdmin` | Empresa | Administra usuarios, dispositivos y contenidos de su empresa |
| **Manager** | `manager` | Empresa | Supervisa equipos, puede ver usuarios y enviar notificaciones |
| **Editor** | `editor` | Empresa | Crea y edita contenidos. Solo puede ver usuarios y roles |
| **User** | `user` | Empresa | Acceso básico al dashboard de empresa. Sin capacidad de gestión |

### 9.2 · Permisos del Sistema (AppPermission)

| Permiso | Descripción |
|---|---|
| `companiesView` | Ver lista de empresas |
| `companiesCreate` | Crear nuevas empresas |
| `companiesEdit` | Modificar datos de empresas |
| `companiesDelete` | Eliminar/desactivar empresas |
| `usersView` | Ver listado de usuarios |
| `usersCreate` | Crear nuevas cuentas de usuario |
| `usersEdit` | Editar datos y roles de usuarios |
| `usersDelete` | Eliminar/desactivar usuarios |
| `rolesView` | Ver roles y permisos configurados |
| `rolesCreate` | Crear roles personalizados |
| `rolesEdit` | Modificar permisos de roles |
| `rolesDelete` | Eliminar roles del sistema |
| `notificationsSend` | Enviar notificaciones a usuarios |
| `reportsView` | Ver reportes y analíticas |
| `dashboardCompany` | Acceder al dashboard de empresa |

### 9.3 · Matriz de Permisos por Rol

| Permiso | Super Admin | Company Admin | Manager | Editor | User |
|---|:---:|:---:|:---:|:---:|:---:|
| `usersView` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `usersCreate` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `usersEdit` | ✅ | ✅ | ✅ | ❌ | ❌ |
| `usersDelete` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `rolesView` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `rolesCreate` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `rolesEdit` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `rolesDelete` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `notificationsSend` | ✅ | ✅ | ✅ | ❌ | ❌ |
| `reportsView` | ✅ | ✅ | ✅ | ❌ | ❌ |
| `dashboardCompany` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Todas las empresas | ✅ | ❌ | ❌ | ❌ | ❌ |

### 9.4 · PermissionGuard Widget

Envuelve contenido que requiere permisos específicos. Si el usuario no tiene el permiso, muestra "Acceso Denegado" o un widget `fallback` personalizable:

```dart
PermissionGuard(
  permission: AppPermission.usersCreate,
  child: ElevatedButton(
    onPressed: _createUser,
    child: Text("Crear Usuario"),
  ),
  fallback: Text("Sin permisos"), // opcional
)
```

### 9.5 · RouteGuard

El `RouteGuard` estático (`route_guards.dart`) evalúa cada navegación y redirige según estado de autenticación y rol:

- **Rutas públicas** → sin restricción
- **Rutas privadas** → requiere autenticación
- **Rutas super-admin** → solo `superAdmin`
- **Rutas con permiso** → verifica `hasPermission()`

---

## 10. Módulos Funcionales

### 10.1 · Dashboard

El dashboard varía según el rol:

- **Dashboard Normal:** Tarjetas de estadísticas (dispositivos, usuarios activos, uptime, latencia)
- **Super Dashboard:** Total/activas/suspendidas empresas, total/activos usuarios, acciones rápidas
- **Acciones rápidas:** Nueva empresa, ver usuarios, gestionar roles, notificaciones
- **Listas inline:** Top 6 empresas y top 5 usuarios recientes

### 10.2 · Gestión de Usuarios

Pantalla `UsersManagementPage` con vista tabla (desktop) y lista (mobile) responsive:

- 🔍 Búsqueda en tiempo real por nombre o email
- 🏷️ Filtro por rol mediante chips
- ➕ Crear usuario con formulario inline
- ✏️ Editar nombre, teléfono, dirección y roles
- 🔒 Bloquear/Activar (cambio de `status`)
- 🗑️ Eliminar con confirmación dialog

> Los Company Admins solo ven usuarios de su empresa; el Super Admin ve todos.

### 10.3 · Gestión de Empresas

Solo accesible por el **Super Admin**. Permite crear empresas con administrador principal, editar datos corporativos, activar/suspender y eliminar. Cada empresa creada genera automáticamente un usuario `Company Admin`.

### 10.4 · Gestión de Roles

`RolesManagementPage` con tres pestañas:
1. **Roles del Sistema** — solo lectura, roles predefinidos
2. **Roles Personalizados** — Solo Super Admin, CRUD completo
3. **Usuarios y Roles** — asignación de roles a usuarios específicos

### 10.5 · Sistema de Notificaciones

| Tipo | Color | Uso |
|---|---|---|
| `info` | Azul (#38BDF8) | Información general del sistema |
| `success` | Verde (#22C55E) | Operaciones completadas exitosamente |
| `warning` | Ámbar (#F59E0B) | Advertencias que requieren atención |
| `error` | Rojo (#EF4444) | Errores críticos del sistema |
| `system` | Primario (#45c4c4) | Notificaciones del propio sistema |

Las notificaciones no leídas muestran badge contador en el TopBar.

### 10.6 · Perfil de Usuario

- **AvatarCard:** Foto de perfil con edición vía `image_picker` (máx 512x512px)
- **InfoCard:** Edición de nombre, teléfono y dirección (email no editable)
- **SecurityCard:** Cambio de contraseña con re-autenticación previa
- **RolesCard:** Vista de roles y permisos activos (solo lectura)
- **CompanyBanner:** Muestra la empresa asociada del usuario

---

## 11. Módulo WhatsApp Chatbot

Módulo completo de gestión de chatbots con IA. Se comunica con un backend Node.js externo alojado en Render.com vía API REST.

### Arquitectura del Módulo

```
WhatsappChatbotPage
├── DashboardView        // Resumen de bots y métricas
├── BotsList             // Lista/CRUD de bots
├── BotDetailView        // Detalle bot: QR, config, estadísticas
├── ChatView             // Conversaciones en tiempo real
├── StatsView            // Estadísticas del bot con gráficas
├── ConfigView           // Configuración completa del bot
├── AnalyticsView        // Embudo, usuarios, trazabilidad IA
├── GlobalAnalyticsView  // Analytics de todos los bots
├── KanbanView           // Pipeline de ventas drag-and-drop
└── ConnectionView       // Estado de conexión Facebook/WhatsApp
```

### Proceso de Conexión con WhatsApp Business

1. **OAuth Facebook** — Se abre popup con scope `whatsapp_business_management`
2. **Intercambio de código** — El código OAuth se envía al backend para obtener el access token
3. **Selección de número** — Se listan los números WA disponibles de la cuenta Business
4. **Creación del bot** — Se crea el bot con el número seleccionado y nombre definido
5. **Webhook activo** — El backend escucha mensajes entrantes vía webhook de Meta

### Kanban de Ventas

Tablero drag-and-drop con 6 etapas:

| Etapa | Key | Color | Descripción |
|---|---|---|---|
| Inicial | `inicial` | Gris | Nuevo contacto sin clasificar |
| Interesado | `interesado` | Verde | Mostró interés en el producto/servicio |
| Dudoso | `dudoso` | Ámbar | Tiene dudas o requiere más información |
| Pendiente | `pendiente` | Azul | En espera de respuesta o seguimiento |
| Confirmado | `confirmado` | Verde oscuro | Venta cerrada o confirmada |
| No Interesado | `noInteresado` | Rojo | Contacto descartado |

### Endpoints de la API WhatsApp (WAService)

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/wa/chatbots/{userId}` | Obtiene todos los bots del usuario |
| POST | `/api/wa/chatbots` | Crea un nuevo bot |
| PATCH | `/api/wa/chatbots/{userId}/{botId}` | Actualiza configuración del bot |
| DELETE | `/api/wa/chatbots/{userId}/{botId}` | Elimina un bot |
| POST | `/api/wa/chatbots/{userId}/{botId}/toggle-ai` | Activa/desactiva IA del bot |
| GET | `/api/wa/chatbots/{userId}/{botId}/summary` | Resumen de métricas del bot |
| GET | `/api/wa/chatbots/{userId}/{botId}/stats` | Estadísticas detalladas del bot |
| GET | `/api/wa/chatbots/{userId}/{botId}/conversations` | Lista de conversaciones |
| GET | `/api/wa/conversations/{convId}/messages` | Mensajes de una conversación |
| POST | `/api/wa/conversations/{convId}/send` | Envía mensaje como agente |
| POST | `/api/wa/conversations/{convId}/human-control` | Activa/desactiva modo humano |
| GET | `/api/wa/dashboard/{userId}` | Dashboard global del usuario |
| POST | `/api/wa/facebook/exchange-token` | Intercambia código OAuth por access token |

---

## 12. Módulo Digital Viewix

| Funcionalidad | Descripción |
|---|---|
| **Dispositivos** | Registro, monitoreo y control de dispositivos de señalización física |
| **Playlists** | Creación y administración de listas de reproducción de contenido |
| **Programación** | Asignación horaria de contenidos a dispositivos o grupos |
| **Media Library** | Biblioteca centralizada de archivos multimedia |
| **Editor** | Editor visual de pantallas con drag-and-drop |

Los dispositivos se identifican por `uniqueDeviceId` (ID hardware) y reportan su estado (`online` / `offline` / `warning`) con `lastSeen` para monitoreo en tiempo real.

---

## 13. Gestión de Estado — Riverpod

El sistema usa **Flutter Riverpod v2**. Los providers se declaran globalmente en `lib/provider/app_providers.dart`. Se prefiere `StreamProvider` para datos en tiempo real de Firestore.

### Providers Globales

| Provider | Tipo | Descripción | Fuente de datos |
|---|---|---|---|
| `authStateProvider` | StreamProvider | Estado de autenticación Firebase | Firebase Auth |
| `currentUserProvider` | StreamProvider | Perfil completo del usuario actual | Firestore /users |
| `routerProvider` | Provider | Instancia del router con redirecciones | Static |
| `firebaseServiceProvider` | Provider | Singleton del servicio Firebase | Static |
| `currentCompanyProvider` | StreamProvider | Empresa del usuario actual | Firestore /companies |
| `companiesProvider` | StreamProvider> | Todas las empresas (Super Admin) | Firestore /companies |
| `allUsersProvider` | StreamProvider> | Todos los usuarios del sistema | Firestore /users |
| `rolesProvider` | StreamProvider> | Roles personalizados | Firestore /roles |
| `notificationsProvider` | StreamProvider.family | Notificaciones de un usuario | Firestore /notifications |
| `unreadCountProvider` | StreamProvider.family | Contador de notificaciones no leídas | Firestore /notifications |
| `permissionCheckerProvider` | Provider.family | Verifica un permiso del usuario actual | currentUserProvider |
| `savedPlaylistsProvider` | Provider> | Playlists guardadas localmente | Estado local |
| `onlineDevicesCountProvider` | StreamProvider | Conteo de dispositivos online | Firestore /devices |

### Ejemplo de StreamProvider con Riverpod

```dart
// Provider que escucha la empresa del usuario en tiempo real
final currentCompanyProvider = StreamProvider<Company?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  // Super Admin no tiene empresa asociada
  if (user == null || user.isSuperAdmin || user.companyId == null) {
    return Stream.value(null);
  }
  // Stream reactivo de Firestore
  return FirebaseFirestore.instance
    .collection("companies")
    .doc(user.companyId)
    .snapshots()
    .map((doc) => doc.exists ? Company.fromFirestore(doc) : null);
});
```

---

## 14. Servicios

### 14.1 · FirebaseService

Clase central que encapsula **TODAS** las operaciones con Firebase. Es un singleton accesible vía `firebaseServiceProvider`. Implementa el patrón `Result` para manejo de errores tipado.

#### Métodos de Autenticación y Usuarios

| Método | Parámetros | Retorno | Descripción |
|---|---|---|---|
| `signIn()` | email, password | Result | Login + verificación de empresa activa |
| `register()` | name, email, password, role, companyId? | Result | Registro + perfil Firestore |
| `signOut()` | — | Future | Cierra sesión Firebase |
| `sendPasswordReset()` | email | Result | Email de recuperación |
| `reauthenticate()` | email, password | Result | Re-auth para operaciones sensibles |
| `changePassword()` | newPassword | Result | Cambio de contraseña |
| `createUserAsAdmin()` | name, email, password, role, companyId? | Result | Crea usuario con app secundaria |
| `updateProfile()` | uid, name?, phone?, address?, photoUrl? | Result | Actualiza perfil |
| `uploadProfilePhoto()` | uid, bytes, filename | Result | Sube foto a Storage |

#### Métodos de Empresas

| Método | Parámetros | Retorno | Descripción |
|---|---|---|---|
| `createCompany()` | name, legalName, email, phone, address, adminName, adminEmail, adminPassword | Result | Crea empresa + admin con Firebase secundario |
| `updateCompany()` | company: Company | Result | Actualiza datos de empresa |
| `deleteCompany()` | companyId: String | Result | Soft delete (status=inactive) |
| `updateCompanyStatus()` | companyId, status | Result | Activa/suspende empresa |
| `companiesStream()` | — | Stream> | Stream de todas las empresas ordenadas |

#### Métodos de Notificaciones

| Método | Descripción |
|---|---|
| `createNotification(notification)` | Crea notificación para un usuario |
| `markNotificationRead(notifId)` | Marca notificación como leída |
| `markAllNotificationsRead(userId)` | Marca todas como leídas (batch write) |
| `deleteNotification(notifId)` | Elimina notificación |
| `notificationsStream(userId)` | Stream de notificaciones del usuario (últimas 50, ordenadas) |
| `unreadCountStream(userId)` | Stream del conteo de notificaciones no leídas |

### 14.2 · Patrón Result

```dart
// Sealed class para manejo tipado de resultados
sealed class Result<T> { const Result(); }
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}
class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, [this.error]);
}

// Uso con pattern matching:
switch (result) {
  case Success(:final value): handleSuccess(value);
  case Failure(:final message): setState(() => _error = message);
}
```

---

## 15. Sistema de Enrutamiento

El enrutamiento principal está en `routerProvider` (`authSystem.dart`). Usa **GoRouter** con dos ShellRoutes y una función `redirect()` que evalúa autenticación y roles en cada cambio de ruta.

### Rutas Registradas

| Ruta | Widget | Tipo | Acceso |
|---|---|---|---|
| `/login` | LoginPage | Pública | Todos |
| `/register` | RegisterPage | Pública | Todos |
| `/forgot-password` | ForgotPasswordPage | Pública | Todos |
| `/portal` | DevicePortalScreen | Pública | Dispositivos físicos |
| `/view/:id` | _ViewPlaylistScreen | Pública | Todos (link público) |
| `/dashboard` | DashboardScreen | Shell Normal | Usuarios autenticados |
| `/devices` | DevicesScreen | Shell Normal | Company Admin+ |
| `/content` | PlaylistsScreen | Shell Normal | Company Admin+ |
| `/schedules` | ProgrammingScreen | Shell Normal | Company Admin+ |
| `/media` | MediaLibraryScreen | Shell Normal | Company Admin+ |
| `/editor` | ScreenEditorScreen | Shell Normal | Company Admin+ |
| `/notifications` | NotificationsPage | Shell Normal | Todos autenticados |
| `/notifications2` | NotificationsPage22 | Shell Normal | notificationsSend |
| `/users` | UsersManagementPage | Shell Normal | usersView + Company Admin |
| `/roles` | RolesManagementPage | Shell Normal | rolesView + Company Admin |
| `/profile` | ProfilePage | Shell Normal | Todos autenticados |
| `/wa/dashboard` | WhatsappChatbotPage | Shell Normal | Todos autenticados |
| `/wa/bots` | WhatsappChatbotPage | Shell Normal | Todos autenticados |
| `/wa/chat` | WhatsappChatbotPage | Shell Normal | Todos autenticados |
| `/wa/analytics` | WhatsappChatbotPage | Shell Normal | Todos autenticados |
| `/wa/kanban` | WhatsappChatbotPage | Shell Normal | Todos autenticados |
| `/super-dashboard` | _SuperDashboardHome | Shell Super | Solo Super Admin |
| `/companies` | CompaniesPage | Shell Super | Solo Super Admin |
| `/super/users` | UsersManagementPage | Shell Super | Solo Super Admin |
| `/super/roles` | RolesManagementPage | Shell Super | Solo Super Admin |
| `/company/:companyId` | _CompanyDetailPage | Shell Super | Solo Super Admin |

---

## 16. Seguridad

### Controles de Seguridad Implementados

| Control | Implementación | Nivel |
|---|---|---|
| Autenticación | Firebase Auth con email/password. Tokens JWT gestionados por Firebase SDK | 🔴 ALTO |
| Autorización por Ruta | GoRouter `redirect()` verifica rol/permiso antes de navegar | 🔴 ALTO |
| Autorización en UI | `PermissionGuard` oculta/muestra funciones según permisos | 🟡 MEDIO |
| Autorización en BD | Firestore Security Rules | 🔴 ALTO |
| Aislamiento Multi-tenant | `companyId` en AppUser filtra datos solo de la empresa correspondiente | 🔴 ALTO |
| Soft Delete | `status=inactive/suspended` en lugar de eliminación física | 🟡 MEDIO |
| Re-autenticación | Cambio de contraseña requiere re-auth con contraseña actual | 🔴 ALTO |
| Firebase secundario | Creación de usuarios sin afectar sesión del admin actual | 🔴 ALTO |
| Tokens OAuth | Access tokens de Facebook/Meta almacenados en backend externo | 🔴 ALTO |
| Validación de formularios | Validadores en todos los TextFormField antes de enviar a Firebase | 🟡 MEDIO |

### OWASP Top 10 — Estado de Mitigación

| OWASP Risk | Estado | Mitigación Aplicada |
|---|---|---|
| A01 Broken Access Control | ⚠️ PARCIAL | PermissionGuard + RouteGuard. Falta completar Firestore Rules |
| A02 Cryptographic Failures | ✅ GESTIONADO | Firebase Auth gestiona hashing/tokens. HTTPS obligatorio |
| A03 Injection | ✅ GESTIONADO | Firestore SDK parametrizado previene inyección NoSQL |
| A05 Security Misconfiguration | 🔴 RIESGO | Credenciales super admin en código. Requiere acción inmediata |
| A07 Auth and Session Failures | ✅ GESTIONADO | Tokens JWT de Firebase con expiración automática |
| A09 Security Logging | ❌ PENDIENTE | No hay sistema de auditoría/logs de accesos |

---

## 17. Manejo de Errores

El sistema implementa dos estrategias: `Result` (sealed class) para operaciones de `FirebaseService`, y `Either` de `dartz` para los repositorios del módulo.

### Tipos de Failure

| Clase | Uso | Descripción |
|---|---|---|
| `AuthFailure` | Firebase Auth errors | Errores de autenticación (credenciales inválidas, cuenta desactivada) |
| `NetworkFailure` | Conectividad | Sin conexión a internet o timeout |
| `FirestoreFailure` | Operaciones Firestore | Errores de lectura/escritura en base de datos |
| `PermissionFailure` | Autorización | Permisos insuficientes para la operación |
| `NotFoundFailure` | Recursos | Documento o recurso no encontrado |
| `UnknownFailure` | General | Errores no clasificados |

### Mensajes de Error de Firebase Auth (en Español)

| Código Firebase | Mensaje en Español |
|---|---|
| `user-not-found` | No existe una cuenta con ese email. |
| `wrong-password` | Contraseña incorrecta. |
| `email-already-in-use` | Este email ya está registrado. |
| `weak-password` | La contraseña debe tener al menos 6 caracteres. |
| `invalid-email` | El formato del email no es válido. |
| `too-many-requests` | Demasiados intentos. Intenta más tarde. |
| `user-disabled` | Esta cuenta ha sido desactivada. |
| `invalid-credential` | Credenciales inválidas. |
| `network-request-failed` | Error de conexión. Verifica tu internet. |
| `requires-recent-login` | Debes iniciar sesión nuevamente. |

---

## 18. Despliegue

### Build Flutter Web

```bash
# 1. Verificar Flutter instalado y canal stable
flutter doctor
flutter channel stable
flutter upgrade

# 2. Obtener dependencias
flutter pub get

# 3. Build de producción (optimizado)
flutter build web --release --web-renderer canvaskit

# El output se genera en: build/web/
# Archivos principales: index.html, main.dart.js, assets/, flutter_service_worker.js
```

### Despliegue en Firebase Hosting

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login y seleccionar proyecto
firebase login
firebase use --add  # seleccionar proyecto

# Configurar firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}

# Desplegar
firebase deploy --only hosting
```

### Variables de Entorno y Configuración

La configuración de Firebase se gestiona en `lib/firebase_options.dart` (generado por FlutterFire CLI). Las constantes sensibles están en `lib/config/app_config.dart`:

```bash
# Generar configuración Firebase (primera vez)
dart pub global activate flutterfire_cli
flutterfire configure
# Esto genera: lib/firebase_options.dart
```

```dart
// lib/config/app_config.dart
abstract class AppConfig {
  static const superAdminEmail = String.fromEnvironment(
    "SUPER_ADMIN_EMAIL",
    defaultValue: "admin@empresa.com"  // CAMBIAR en producción
  );
  static const superAdminPassword = String.fromEnvironment(
    "SUPER_ADMIN_PASS",
    defaultValue: ""
  );
}
```

### Checklist de Producción

- [ ] ⚙️ Configurar Firestore Security Rules completas en Firebase Console
- [ ] 🔐 Mover credenciales super admin a variables de entorno o Firebase Remote Config
- [ ] 🔒 Habilitar HTTPS en Firebase Hosting (automático)
- [ ] 🌐 Configurar dominio personalizado en Firebase Hosting
- [ ] 💰 Configurar alertas de facturación en Firebase Console
- [ ] 📊 Revisar índices de Firestore para consultas de producción
- [ ] 🛡️ Configurar Firebase App Check para proteger APIs
- [ ] 💾 Habilitar Cloud Firestore backups automáticos
- [ ] 📋 Revisar Firebase Functions logs y errores
- [ ] 📱 Configurar webhook de Meta (WhatsApp Business) en producción

---

## 19. Mantenimiento y Guía de Desarrollo

### Cómo Agregar un Nuevo Módulo

```
1. Crear carpeta del módulo:
   lib/[nombre_modulo]/
   ├── model/
   ├── service/
   ├── provider/
   └── ui/

2. Definir el modelo:
   Clase Dart con fromFirestore(), toFirestore() y copyWith()

3. Crear el servicio:
   Métodos CRUD en FirebaseService o clase dedicada

4. Registrar providers:
   Agregar StreamProvider/Provider en lib/provider/app_providers.dart

5. Crear la pantalla:
   ConsumerWidget o ConsumerStatefulWidget en lib/ui/ o lib/[modulo]/

6. Registrar la ruta:
   Agregar GoRoute en routerProvider (authSystem.dart)

7. Agregar al sidebar:
   Añadir _NavItemData en _buildNavItems() con el ícono y ruta

8. Configurar permisos (si aplica):
   Agregar en AppPermission enum y kDefaultRolePermissions
```

### Convenciones de Código

| Convención | Descripción |
|---|---|
| Nombres de archivos | `snake_case.dart` — ej: `auth.dart`, `firebase_service.dart` |
| Nombres de clases | `PascalCase` — ej: `AppUser`, `FirebaseService`, `LoginPage` |
| Nombres privados | Prefijo `_` para clases/widgets privados — ej: `_T`, `_Sidebar` |
| Constantes de tema | Clase `abstract _T` con `static const` para colores y radios |
| Modelos | `fromFirestore(DocumentSnapshot)` + `toFirestore()` en todos los modelos |
| Errores | `Result` con `Success`/`Failure` para operaciones async de Firebase |
| Estado | `ConsumerWidget` / `ConsumerStatefulWidget` para acceso a providers |
| Widgets privados | Prefijo `_` para widgets no expuestos al exterior del archivo |

---

## 20. Troubleshooting

| Problema | Causa Probable | Solución |
|---|---|---|
| Login redirige a superDashboard con usuario normal | `isSuperAdmin` checkeado antes de cargar perfil | Verificar delay en `currentUserProvider` y flujo de `redirect()` |
| App secundaria Firebase no se elimina | Error al crear usuario admin | Verificar bloque `try/finally` en `createUserAsAdmin()`. `secondaryApp.delete()` debe estar en `finally` |
| Notificaciones no aparecen en tiempo real | Índice de Firestore faltante | Crear índice compuesto en `notifications`: `userId ASC` + `read ASC` + `createdAt DESC` |
| Router redirecciona en bucle | `_AuthRouteNotifier` dispara múltiples notificaciones | Verificar que `authStateProvider` no lance eventos duplicados. Revisar `isLoading` en `redirect()` |
| Foto de perfil no se actualiza en UI | Provider no se refresca post-upload | Verificar que `updateProfile()` con `photoUrl` actualice Firestore y el stream lo propague |
| Flutter build web falla con CanvasKit | Assets de CanvasKit no disponibles | Usar `--web-renderer html` en entornos con limitaciones de CORS |
| WAService retorna error 404 | Backend en Render.com en modo sleep | Plan gratuito de Render duerme tras 15min. Usar plan pago o implementar keep-alive |
| KanbanView no persiste etapas | `stageMap` es estado local en `_KanbanViewState` | Implementar persistencia en Firestore o backend para estado del Kanban por conversación |
| Empresa no carga en sidebar | `companyId` es null o empresa inactiva | Verificar `status` de empresa. El provider retorna `null` si empresa no está `active` |
| Cloud Functions no ejecuta | Región incorrecta o permisos | Verificar región en `FirebaseFunctions.instance` y permisos IAM en Firebase Console |

---

## 21. Decisiones Arquitectónicas

### ADR-001: Flutter Web sobre React/Angular
**Decisión:** Usar Flutter Web como framework de UI principal.  
**Razón:** Reutilización de código nativo móvil futuro, tipado fuerte con Dart, y experiencia del equipo.  
**Consecuencias:** Mayor tamaño de bundle inicial, pero mejor rendimiento en runtime y coherencia UI.

### ADR-002: Riverpod sobre Provider/BLoC
**Decisión:** Usar Riverpod v2 para gestión de estado.  
**Razón:** Compile-safe, sin necesidad de `BuildContext`, mejor soporte para `Stream` de Firestore.  
**Consecuencias:** Curva de aprendizaje, pero mejor testabilidad y separación de concerns.

### ADR-003: Firestore Desnormalizado
**Decisión:** Documentos planos con referencias por ID en lugar de subcolecciones.  
**Razón:** Simplicidad en queries y compatibilidad con Firestore Security Rules a nivel documento.  
**Consecuencias:** Algunos datos duplicados, pero lecturas más eficientes y reglas más simples.

### ADR-004: Backend Externo para WhatsApp
**Decisión:** Node.js en Render.com para el módulo WhatsApp en lugar de Cloud Functions.  
**Razón:** Flexibilidad para webhooks en tiempo real, manejo de long-running connections y compatibilidad con la API de Meta.  
**Consecuencias:** Dependencia de servicio externo con riesgo de cold starts en plan gratuito.

### ADR-005: Firebase Secondary App para crear usuarios
**Decisión:** Usar `Firebase.initializeApp()` secundario para `createUserAsAdmin()`.  
**Razón:** Firebase Auth cambia la sesión activa al crear una nueva cuenta, lo que cerraría la sesión del administrador.  
**Consecuencias:** Overhead de inicialización de app secundaria, pero operación transparente para el admin.

---

## 22. Riesgos y Recomendaciones Futuras

### Riesgos Identificados

| Riesgo | Severidad | Descripción | Mitigación |
|---|---|---|---|
| Credenciales en código | 🔴 CRÍTICO | Super Admin seed con credenciales hardcoded en `app_config.dart` | Migrar a Firebase Remote Config o variables de entorno |
| Firestore Rules incompletas | 🔴 ALTO | Las reglas de Firestore no están completamente configuradas | Implementar reglas completas antes de producción |
| Backend en plan gratuito | 🟡 MEDIO | Render.com duerme tras 15 minutos de inactividad | Migrar a plan pago o implementar keep-alive |
| Sin logging de auditoría | 🟡 MEDIO | No hay registro de acciones de usuarios (OWASP A09) | Implementar sistema de audit logs en Firestore |
| KanbanView sin persistencia | 🟢 BAJO | El estado del Kanban no se persiste entre sesiones | Implementar persistencia en Firestore |

### Recomendaciones Futuras

1. **Seguridad:** Completar Firestore Security Rules y migrar credenciales a variables de entorno
2. **Auditoría:** Implementar sistema de logs de actividad por usuario y empresa
3. **Testing:** Agregar pruebas unitarias para repositorios y providers con Riverpod
4. **Performance:** Implementar paginación en listas de usuarios y dispositivos (actualmente sin límite)
5. **Offline:** Habilitar persistencia offline de Firestore para dispositivos de señalización
6. **CI/CD:** Configurar pipeline con GitHub Actions para build y deploy automático en Firebase Hosting
7. **App Check:** Habilitar Firebase App Check para proteger las APIs contra abuso
8. **Internacionalización:** Expandir soporte multi-idioma usando el paquete `intl` ya instalado
9. **Kanban:** Implementar persistencia del estado del Kanban en backend/Firestore
10. **Monitoreo:** Integrar Firebase Crashlytics y Performance Monitoring

---

## 23. Glosario Técnico

| Término | Definición |
|---|---|
| `AppUser` | Modelo de usuario con roles, permisos y datos de perfil |
| `AppRole` | Enumeración de roles: `superAdmin`, `companyAdmin`, `manager`, `editor`, `user` |
| `AppPermission` | Enumeración granular de permisos de acceso a funcionalidades |
| `Company` | Modelo de empresa cliente con datos corporativos y estado |
| `ConsumerWidget` | Widget de Riverpod que puede leer providers reactivos del árbol |
| `Firestore` | Base de datos NoSQL en tiempo real de Firebase, orientada a documentos |
| `FirebaseService` | Servicio singleton central que encapsula todas las operaciones de Firebase |
| `Flutter Web` | Compilación de aplicación Flutter para navegadores web vía WebAssembly/JS |
| `GoRouter` | Librería de enrutamiento declarativo para Flutter con soporte de deep links |
| `Multi-tenant` | Arquitectura donde múltiples organizaciones comparten la misma plataforma con datos aislados |
| `PermissionGuard` | Widget que condiciona la visibilidad de UI según permisos del usuario |
| `Result` | Sealed class para manejo tipado de operaciones que pueden fallar |
| `RouteGuard` | Lógica estática que evalúa si una ruta es accesible según el usuario actual |
| `Riverpod` | Framework de gestión de estado para Flutter, sucesor de Provider |
| `Secondary App` | Instancia secundaria de Firebase para crear usuarios sin afectar la sesión actual |
| `ShellRoute` | Ruta de GoRouter que envuelve rutas hijas con un layout compartido (sidebar) |
| `Soft Delete` | Eliminación lógica: cambiar `status` a `inactive` sin borrar el documento |
| `StreamProvider` | Provider de Riverpod que expone un Stream reactivo (ej: cambios de Firestore) |
| `Super Admin` | Rol con acceso total al sistema, gestión de todas las empresas y usuarios |
| `WAChatbot` | Modelo del chatbot de WhatsApp con configuración de IA y conexión Meta |
| `WAService` | Servicio HTTP que consume la API REST del backend de WhatsApp chatbot |
| `WebAssembly` | Formato binario de bajo nivel que permite ejecutar código nativo en navegadores |
| `Kanban` | Metodología visual de gestión de flujo de trabajo con columnas representando etapas |
| `OAuth 2.0` | Protocolo de autorización para obtener acceso delegado a recursos de terceros |
| `GPT-4o` | Modelo de lenguaje multimodal de OpenAI usado para respuestas automáticas en chatbot |

---

<div align="center">

---

**VIEWIX v1.0.0** · Documentación Técnica

Desarrollado por [WebSourcing](https://websourcing.com) · © 2026 · Confidencial

*Flutter Web · Firebase · Dart · GPT-4o*

</div>
# viewix
