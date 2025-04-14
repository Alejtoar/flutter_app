import 'package:flutter/material.dart';
import 'package:golo_app/navigation/models/menu_item.dart';
import '../models/main_menu.dart';

class NavigationController extends ChangeNotifier {
  int _mainMenuIndex = 0;
  int? _subMenuIndex;
  MenuItem? _expandedMenu;
  List<MenuItem> get mainMenuItems => MainMenu.items;

  int get currentIndex => _subMenuIndex ?? _mainMenuIndex;
  MenuItem? get expandedMenu => _expandedMenu;
  bool get isSubMenuOpen => _expandedMenu != null;

  List<MenuItem> get currentMenuItems =>
      isSubMenuOpen ? _expandedMenu!.subItems! : MainMenu.items;

  void navigateToMain(int index) {
    _mainMenuIndex = index;
    _subMenuIndex = null;

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
    _subMenuIndex = null;
    notifyListeners();
  }

  int get mainMenuIndex => _mainMenuIndex;
}
