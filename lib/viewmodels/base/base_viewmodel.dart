import 'package:flutter/foundation.dart';

enum ViewState { idle, busy, error }

abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _state == ViewState.busy;

  void setState(ViewState newState, {String? error}) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
