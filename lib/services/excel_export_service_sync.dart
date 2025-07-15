// lib/services/excel_export_service_sync.dart

//import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:golo_app/services/shopping_list_service.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/helpers/file_saver.dart'; // Tu helper de guardado
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class ExcelExportServiceSync {
  // --- MÉTODO PÚBLICO PRINCIPAL Y ÚNICO ---
  /// Exporta la lista de compras a UN ÚNICO archivo Excel con múltiples hojas.
  ///
  /// [data]: La lista de compras agrupada. Si se quiere separación, debe venir de `getSeparated...`.
  /// [baseFileName]: Nombre base sugerido para el archivo.
  /// [separateByFacturable]: Si es true, las hojas mostrarán secciones separadas.
  Future<void> exportAndSaveShoppingList({
    required BuildContext context,
    required GroupedShoppingListResult data,
    required String baseFileName,
    bool separateByFacturable = false,
  }) async {
    final String operation = "Exportar Excel (Syncfusion)";
    debugPrint("[$operation] Iniciando. BaseName: $baseFileName, Separar Facturable: $separateByFacturable");

    if (data.isEmpty) {
      showAppSnackBar(context, "La lista de compras está vacía.", isError: true);
      return;
    }

    try {
      showAppSnackBar(context, "Generando archivo Excel...");
      final xlsio.Workbook workbook = xlsio.Workbook();

      // --- 1. Hoja Principal (Resumen Completo) ---
      final xlsio.Worksheet resumenSheet = workbook.worksheets[0];
      resumenSheet.name = 'Resumen General';
      _buildMainResumenSheet(
          resumenSheet,
          data,
          separateByFacturable: separateByFacturable,
      );
      debugPrint("[$operation] Hoja Resumen General construida.");

      // --- 2. Hojas Individuales por Proveedor ---
      for (final entry in data.entries) {
        final proveedor = entry.key;
        final items = entry.value;
        String provSheetName = _sanitizeSheetName(proveedor?.nombre ?? 'Sin_Proveedor');

        final xlsio.Worksheet providerSheet = workbook.worksheets.addWithName(provSheetName);
        _buildProviderSpecificSheet(
            providerSheet,
            items,
            separateByFacturable: separateByFacturable,
        );
        debugPrint("[$operation] Hoja para proveedor '${proveedor?.nombre ?? 'N/A'}' construida.");
      }

      // --- 3. Guardar el archivo usando el helper `saveFile` ---
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose(); // Liberar memoria

      final String cleanBaseFileName = _sanitizeFileName(baseFileName);
      final String fileName = "${cleanBaseFileName}_${DateTime.now().toIso8601String().replaceAll(':','-').substring(0,10)}.xlsx";

      await saveFile(bytes, fileName);
      debugPrint("[$operation] Llamada a saveFile completada con nombre: $fileName");
      
      showAppSnackBar(context, "Archivo Excel '$fileName' guardado/descargado.");

    } catch (e, st) {
      debugPrint("[$operation][ERROR] Exportando a Excel: $e\n$st");
      if(context.mounted) showAppSnackBar(context, "Error al exportar a Excel: $e", isError: true);
    }
  }


  // --- MÉTODO PARA CONSTRUIR LA HOJA RESUMEN PRINCIPAL ---
  void _buildMainResumenSheet(
      xlsio.Worksheet sheet,
      GroupedShoppingListResult data,
      { required bool separateByFacturable }
    ) {
    debugPrint("[ExcelBuilder] Construyendo hoja resumen. Separar Facturable: $separateByFacturable");
    final xlsio.Workbook workbook = sheet.workbook;
    // --- Estilos ---
    final xlsio.Style headerStyle = _createHeaderStyle(workbook);
    final xlsio.Style proveedorHeaderStyle = _createSectionHeaderStyle(workbook, backColor: '#E3F2FD', fontColor: '#1565C0');
    final xlsio.Style facturableSectionStyle = _createSectionHeaderStyle(workbook, backColor: '#C6EFCE', fontColor: '#006100');
    final xlsio.Style noFacturableSectionStyle = _createSectionHeaderStyle(workbook, backColor: '#FFCCBC', fontColor: '#C62828');
    final xlsio.Style subtotalStyle = _createTotalStyle(workbook, isBold: true, fontColor: '#1B5E20');
    final xlsio.Style totalStyle = _createTotalStyle(workbook, isBold: true, fontSize: 12, backColor: '#FFF9C4');

    // --- Encabezados ---
    final List<String> headers = ["Proveedor", "Insumo Código", "Insumo Nombre", "Cantidad", "Unidad", "Categoría", "Precio Unit.", "Costo Estimado"];
    for (int col = 1; col <= headers.length; col++) {
      sheet.getRangeByIndex(1, col)..setText(headers[col - 1])..cellStyle = headerStyle;
    }

    int rowIndex = 2;
    double costoTotalGeneral = 0.0;

    for (var entry in data.entries) {
      final proveedor = entry.key;
      final items = entry.value;
      final provNombre = proveedor?.nombre ?? 'Sin Proveedor Asignado';
      double subtotalProveedor = 0.0;
      
      final xlsio.Range provHeaderRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, headers.length);
      provHeaderRange..setText(provNombre)..merge()..cellStyle = proveedorHeaderStyle;
      rowIndex++;
      
      void writeItemRows(List<ShoppingListItem> list) {
        for (var item in list) {
          final row = sheet.getRangeByIndex(rowIndex, 1, rowIndex, headers.length);
          row.cells[0].setText(provNombre);
          row.cells[1].setText(item.insumo.codigo);
          row.cells[2].setText(item.insumo.nombre);
          row.cells[3].setNumber(item.cantidad);
          row.cells[3].numberFormat = '#,##0.00';
          row.cells[4].setText(item.unidad);
          row.cells[5].setText(item.insumo.categorias.join(', '));
          row.cells[6].setNumber(item.insumo.precioUnitario);
          row.cells[6].numberFormat = '\$#,##0.00';
          row.cells[7].setNumber(item.costoItem);
          row.cells[7].numberFormat = '\$#,##0.00';

          subtotalProveedor += item.costoItem;
          rowIndex++;
        }
      }

      if (separateByFacturable) {
        final itemsFact = items.where((i) => i.esFacturable == true).toList();
        final itemsNoFact = items.where((i) => i.esFacturable == false).toList();
        
        if (itemsFact.isNotEmpty) {
           final factHeaderRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, headers.length);
           factHeaderRange..setText('Items Facturables')..merge()..cellStyle = facturableSectionStyle;
           rowIndex++;
           writeItemRows(itemsFact);
        }
         if (itemsNoFact.isNotEmpty) {
           final noFactHeaderRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, headers.length);
           noFactHeaderRange..setText('Items No Facturables')..merge()..cellStyle = noFacturableSectionStyle;
           rowIndex++;
           writeItemRows(itemsNoFact);
        }
      } else {
        writeItemRows(items);
      }
      
      if (subtotalProveedor > 0) {
        sheet.getRangeByIndex(rowIndex, headers.length - 1)..setText('Subtotal Proveedor:')..cellStyle.hAlign = xlsio.HAlignType.right..cellStyle.bold = true;
        sheet.getRangeByIndex(rowIndex, headers.length)..setNumber(subtotalProveedor)..cellStyle = subtotalStyle;
        rowIndex++;
      }
      rowIndex++; // Espacio
      costoTotalGeneral += subtotalProveedor;
    }

    sheet.getRangeByIndex(rowIndex, headers.length - 1)..setText('COSTO TOTAL GENERAL:')..cellStyle = totalStyle;
    sheet.getRangeByIndex(rowIndex, headers.length)..setNumber(costoTotalGeneral)..cellStyle = totalStyle;

    for (int col = 1; col <= headers.length; col++) {
      sheet.autoFitColumn(col);
    }
  }


  // --- MÉTODO PARA CONSTRUIR HOJA ESPECÍFICA DE PROVEEDOR ---
  void _buildProviderSpecificSheet(
      xlsio.Worksheet sheet,
      List<ShoppingListItem> items,
      { required bool separateByFacturable }
    ) {
    final xlsio.Workbook workbook = sheet.workbook;
    final xlsio.Style headerStyle = _createHeaderStyle(workbook, backColor: '#CFD8DC');
    final xlsio.Style facturableSectionStyle = _createSectionHeaderStyle(workbook, backColor: '#C6EFCE', fontColor: '#006100');
    final xlsio.Style noFacturableSectionStyle = _createSectionHeaderStyle(workbook, backColor: '#FFCCBC', fontColor: '#C62828');

    final List<String> headers = ["Insumo Nombre", "Insumo Código", "Cantidad", "Unidad"];

    for (int col = 1; col <= headers.length; col++) {
      sheet.getRangeByIndex(1, col)..setText(headers[col - 1])..cellStyle = headerStyle;
    }
    int rowIndex = 2;

    void writeSimpleItemRows(List<ShoppingListItem> list) {
        for (var item in list) {
          sheet.getRangeByIndex(rowIndex, 1).setText(item.insumo.nombre);
          sheet.getRangeByIndex(rowIndex, 2).setText(item.insumo.codigo);
          sheet.getRangeByIndex(rowIndex, 3)..setNumber(item.cantidad)..numberFormat = '#,##0.00';
          sheet.getRangeByIndex(rowIndex, 4).setText(item.unidad);
          rowIndex++;
        }
    }

    if (separateByFacturable) {
      final itemsFact = items.where((i) => i.esFacturable == true).toList();
      final itemsNoFact = items.where((i) => i.esFacturable == false).toList();
      
      if (itemsFact.isNotEmpty) {
         final factHeaderRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, headers.length);
         factHeaderRange..setText('Items Facturables')..merge()..cellStyle = facturableSectionStyle;
         rowIndex++;
         writeSimpleItemRows(itemsFact);
      }
       if (itemsNoFact.isNotEmpty) {
         final noFactHeaderRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, headers.length);
         noFactHeaderRange..setText('Items No Facturables')..merge()..cellStyle = noFacturableSectionStyle;
         rowIndex++;
         writeSimpleItemRows(itemsNoFact);
      }
    } else {
        writeSimpleItemRows(items);
    }
    
    for (int col = 1; col <= headers.length; col++) {
      sheet.autoFitColumn(col);
    }
  }


  // --- Helpers de Estilo para Syncfusion ---
  xlsio.Style _createHeaderStyle(xlsio.Workbook workbook, {String backColor = '#B0BEC5'}) {
    // Si backColor tiene '#', lo quitamos, si no, lo usamos tal cual
    final cleanColor = backColor.startsWith('#') ? backColor.substring(1) : backColor;
    final styleName = 'HeaderStyle_$cleanColor';
    if(workbook.styles.contains(styleName)) return workbook.styles[styleName]!;
    final style = workbook.styles.add(styleName);
    style.bold = true;
    style.fontSize = 11;
    style.backColor = backColor;
    style.hAlign = xlsio.HAlignType.center;
    style.vAlign = xlsio.VAlignType.center;
    style.borders.all.lineStyle = xlsio.LineStyle.thin;
    return style;
  }

  xlsio.Style _createSectionHeaderStyle(xlsio.Workbook workbook, {required String backColor, required String fontColor}) {
     final cleanBackColor = backColor.startsWith('#') ? backColor.substring(1) : backColor;
     final cleanFontColor = fontColor.startsWith('#') ? fontColor.substring(1) : fontColor;
     final styleName = 'SectionStyle_${cleanBackColor}_$cleanFontColor';
     if(workbook.styles.contains(styleName)) return workbook.styles[styleName]!;
     final style = workbook.styles.add(styleName);
     style.bold = true;
     style.fontSize = 10;
     style.backColor = backColor;
     style.fontColor = fontColor;
     style.hAlign = xlsio.HAlignType.center;
     return style;
  }

   xlsio.Style _createTotalStyle(xlsio.Workbook workbook, {bool isBold = false, double fontSize = 10, String? backColor, String? fontColor}) {
     // --- CORRECCIÓN AQUÍ ---
     final backColorPart = backColor != null && backColor.isNotEmpty ? (backColor.startsWith('#') ? backColor.substring(1) : backColor) : 'no_bg';
     final fontColorPart = fontColor != null && fontColor.isNotEmpty ? (fontColor.startsWith('#') ? fontColor.substring(1) : fontColor) : 'no_fc';
     final styleName = 'TotalStyle_${backColorPart}_$fontColorPart';
     // -------------------------

      if(workbook.styles.contains(styleName)) return workbook.styles[styleName]!;
     final style = workbook.styles.add(styleName);
     style.bold = isBold;
     style.fontSize = fontSize;
     style.numberFormat = '\$#,##0.00;(\$#,##0.00)';
     if (backColor != null) style.backColor = backColor;
     if (fontColor != null) style.fontColor = fontColor;
     return style;
  }

  // --- Helpers de Utilidad ---
  String _sanitizeSheetName(String name) => name.replaceAll(RegExp(r'[\\/*?:\[\]]'), '_').substring(0, name.length > 30 ? 30 : name.length);
  String _sanitizeFileName(String name) => name.replaceAll(RegExp(r'[\\/*?:\[\]]'), '_').replaceAll(' ', '_');
}