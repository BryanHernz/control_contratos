class UserViewKeys {
  static const String dashboard = 'dashboard';
  static const String workers = 'workers';
  static const String attendance = 'attendance';
  static const String users = 'users';
  static const String settings = 'settings';

  static const List<String> all = [
    dashboard,
    workers,
    attendance,
    users,
    settings,
  ];
}

class UserActionKeys {
  static const String manageUsers = 'manageUsers';

  /// Editar las plantillas de contrato, finiquito y demas documentos.
  ///
  /// Va aparte de la vista de Ajustes a proposito: agregar una comuna y
  /// reescribir una clausula de un contrato laboral no son el mismo riesgo.
  static const String manageTemplates = 'manageTemplates';

  static const List<String> all = [
    manageUsers,
    manageTemplates,
  ];
}

class UserAccess {
  UserAccess({
    required this.active,
    required this.views,
    required this.actions,
  });

  final bool active;
  final Map<String, bool> views;
  final Map<String, bool> actions;

  bool canView(String key) => views[key] ?? false;
  bool canAction(String key) => actions[key] ?? false;

  /// Permisos de un documento que no declara los suyos.
  ///
  /// Todo en `false` a proposito. Antes esto devolvia las cinco vistas en
  /// `true` y `manageUsers` tambien, asi que un documento de `Usuarios` sin el
  /// campo `permissions` no significaba "sin permisos" sino "con todos": un
  /// campo ausente concedia acceso total en vez de negarlo.
  ///
  /// Las reglas de Firestore (`firestore.rules`) fallan cerrado; esto tiene
  /// que decir lo mismo o la app pinta pantallas que el servidor luego niega.
  static Map<String, bool> defaultViews() {
    return {
      UserViewKeys.dashboard: false,
      UserViewKeys.workers: false,
      UserViewKeys.attendance: false,
      UserViewKeys.users: false,
      UserViewKeys.settings: false,
    };
  }

  static Map<String, bool> defaultActions() {
    return {
      UserActionKeys.manageUsers: false,
      UserActionKeys.manageTemplates: false,
    };
  }

  static bool _toBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    return fallback;
  }

  static UserAccess fromUserData(Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};
    final defaultsViews = defaultViews();
    final defaultsActions = defaultActions();

    final permissions = map['permissions'];
    final viewsRaw = permissions is Map ? permissions['views'] : null;
    final actionsRaw = permissions is Map ? permissions['actions'] : null;

    final views = <String, bool>{};
    for (final key in UserViewKeys.all) {
      views[key] = _toBool(
        viewsRaw is Map ? viewsRaw[key] : null,
        defaultsViews[key] ?? false,
      );
    }

    final actions = <String, bool>{};
    for (final key in UserActionKeys.all) {
      actions[key] = _toBool(
        actionsRaw is Map ? actionsRaw[key] : null,
        defaultsActions[key] ?? false,
      );
    }

    // Sin campo `activo` no entra. Caia a `true`, asi que una ficha a la que
    // nadie le escribio el campo quedaba habilitada.
    final active = _toBool(map['activo'], false);
    return UserAccess(active: active, views: views, actions: actions);
  }

  Map<String, dynamic> permissionsPayload() {
    return {
      'views': views,
      'actions': actions,
    };
  }
}

const Map<String, String> userViewLabels = {
  UserViewKeys.dashboard: 'Dashboard',
  UserViewKeys.workers: 'Trabajadores',
  UserViewKeys.attendance: 'Asistencia',
  UserViewKeys.users: 'Usuarios',
  UserViewKeys.settings: 'Ajustes',
};

const Map<String, String> userActionLabels = {
  UserActionKeys.manageUsers: 'Gestionar usuarios',
  UserActionKeys.manageTemplates: 'Editar plantillas de documentos',
};
