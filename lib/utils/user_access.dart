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

  static const List<String> all = [
    manageUsers,
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

  static Map<String, bool> defaultViews() {
    return {
      UserViewKeys.dashboard: true,
      UserViewKeys.workers: true,
      UserViewKeys.attendance: true,
      UserViewKeys.users: true,
      UserViewKeys.settings: true,
    };
  }

  static Map<String, bool> defaultActions() {
    return {
      UserActionKeys.manageUsers: true,
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

    final active = _toBool(map['activo'], true);
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
};
