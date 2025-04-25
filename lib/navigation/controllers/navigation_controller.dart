import 'package:flutter/material.dart';
import 'package:golo_app/navigation/models/menu_item.dart';
import '../models/main_menu.dart';

class NavigationController extends ChangeNotifier {
  int _mainMenuIndex = 0;
  int _subMenuIndex = 0;
  MenuItem? _expandedMenu;

  List<MenuItem> get mainMenuItems => MainMenu.items;
  List<MenuItem> get currentSubMenuItems => _expandedMenu?.subItems ?? [];

  int get mainMenuIndex => _mainMenuIndex;
  int get subMenuIndex => _subMenuIndex;
  bool get isSubMenuOpen => _expandedMenu != null;

  void navigateToMain(int index) {
    final isValidIndex = index >= 0 && index < MainMenu.items.length;
    if (!isValidIndex) return;

    _mainMenuIndex = index;
    _subMenuIndex = 0;

    if (MainMenu.items[index].subItems != null) {
      _expandedMenu = MainMenu.items[index];
    } else {
      _expandedMenu = null;
    }

    notifyListeners();
  }

  void navigateToSub(int index) {
    _subMenuIndex = index;
    notifyListeners();
  }

  void backToMain() {
    _expandedMenu = null;
    _subMenuIndex = 0;
    notifyListeners();
  }

  /// Navegación inteligente para botón atrás
  void back() {
    if (isSubMenuOpen && _subMenuIndex == 0) {
      // Si está en el primer submenú, volver a Home
      _mainMenuIndex = 0;
      _subMenuIndex = 0;
      _expandedMenu = null;
      notifyListeners();
    } else if (isSubMenuOpen) {
      // Si está en otro submenú, volver al primero
      _subMenuIndex = 0;
      notifyListeners();
    }
    // Si ya está en Home, no hace nada
  }

  /// Navega siempre a Home (Dashboard)
  void goHome() {
    _mainMenuIndex = 0;
    _subMenuIndex = 0;
    _expandedMenu = null;
    notifyListeners();
  }

  // Nuevo: Verificar si el ítem principal tiene pantalla asociada
  bool get hasMainScreen {
    if (!isSubMenuOpen) return true;
    return _expandedMenu?.subItems == null;
  }

  List<MenuItem> get currentMenuItems =>
      isSubMenuOpen ? _expandedMenu!.subItems! : MainMenu.items;
}
