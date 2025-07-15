import 'dart:io';
import 'package:file_selector/file_selector.dart';

Future<void> saveFile(List<int> bytes, String fileName) async {
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: [
      XTypeGroup(label: 'Excel', extensions: ['xlsx']),
    ],
  );

  if (location != null) {
    final file = File(location.path);
    await file.writeAsBytes(bytes, flush: true);
  }
}