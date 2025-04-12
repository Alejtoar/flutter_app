
import 'package:golo_app/viewmodels/base/base_viewmodel.dart';

class MainViewModel extends BaseViewModel {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void changeTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
