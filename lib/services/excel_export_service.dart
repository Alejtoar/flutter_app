// services/excel_export_service.dart

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/services/shopping_list_service.dart'; // Para typedefs y ShoppingListItem
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Servicio encargado de exportar listas de compras a archivos Excel.
///
/// Este servicio proporciona funcionalidades para:
/// - Exportar listas de compras a archivos Excel con múltiples hojas
/// - Compartir los archivos generados a través de la interfaz de compartir nativa
/// - Filtrar y organizar los datos por proveedor y tipo de facturación
/// - Personalizar el formato y estilo de las hojas de cálculo generadas
///
/// Ejemplo de uso:
/// ```dart
/// final exportService = ExcelExportService();
/// await exportService.exportSingleExcelWithMultipleSheets(
///   context: context,
///   data: groupedData,
///   baseFileName: 'Lista de Compras',
///   separateFacturableInResumen: true,
///   separateFacturableInProviderSheets: true,
/// );
/// ```
class ExcelExportService {
  /// Exporta la lista de compras a un archivo Excel con múltiples hojas.
  ///
  /// Este método es el punto de entrada principal para exportar listas de compras
  /// a Excel, con opciones para organizar los datos en diferentes hojas y formatos.
  ///
  /// Parámetros:
  /// - [context]: Contexto de Flutter para mostrar mensajes al usuario.
  /// - [data]: Mapa que contiene la lista de compras agrupada por proveedor.
  ///   Debe ser del tipo `GroupedShoppingListResult` (Proveedor? -> List<ShoppingListItem>).
  /// - [baseFileName]: Nombre base sugerido para el archivo. Se limpiará de caracteres no válidos.
  /// - [separateFacturableInResumen]: Si es `true`, la hoja de resumen general separará
  ///   los ítems facturables de los no facturables en secciones diferentes.
  /// - [separateFacturableInProviderSheets]: Si es `true`, las hojas individuales de cada
  ///   proveedor separarán los ítems facturables de los no facturables.
  ///
  /// Retorna:
  /// - `true` si la exportación fue exitosa.
  /// - `false` si ocurrió un error o el usuario canceló la operación.
  ///
  /// Lanza:
  /// - `Exception` si ocurre un error durante la generación del archivo.
  ///
  /// Requiere:
  /// - Que los objetos `ShoppingListItem` en [data] tengan el campo `esFacturable`
  ///   cuando se usen los parámetros de separación por facturabilidad.
  ///
  /// Ejemplo:
  /// ```dart
  /// final result = await excelExportService.exportSingleExcelWithMultipleSheets(
  ///   context: context,
  ///   data: shoppingListData,
  ///   baseFileName: 'Lista de Compras ${evento.nombre}',
  ///   separateFacturableInResumen: true,
  ///   separateFacturableInProviderSheets: true,
  /// );
  /// ```
  Future<bool> exportSingleExcelWithMultipleSheets({
    required BuildContext context,
    required GroupedShoppingListResult data,
    required String baseFileName,
    bool separateFacturableInResumen = false,
    bool separateFacturableInProviderSheets = false,
  }) async {
    final String operation = "Exportar Excel con Múltiples Hojas";
    debugPrint("[$operation] Iniciando. BaseName: $baseFileName, SepararResumen: $separateFacturableInResumen, SepararProv: $separateFacturableInProviderSheets");

    if (data.isEmpty) {
      _showSnackBar(context, "La lista de compras está vacía.", isError: true);
      return false;
    }
    final String cleanBaseFileName = baseFileName
        .replaceAll(RegExp(r'[\\/*?:\[\]]'), '_')
        .replaceAll('__', '_')
        .substring(0, (baseFileName.length > 30 ? 30 : baseFileName.length));

    try {
      var excel = Excel.createExcel();

      // --- 1. Hoja Principal (Resumen Completo) ---
      String resumenSheetName = "Resumen_General";
      if (excel.sheets.containsKey("Sheet1")) { // La hoja por defecto
         excel.rename("Sheet1", resumenSheetName);
      } else {
         excel.updateCell(resumenSheetName, CellIndex.indexByString("A1"), TextCellValue(""));
      }
      Sheet resumenSheetObject = excel[resumenSheetName];
      _buildMainExcelSheetContent(
          resumenSheetObject,
          data,
          separateByFacturable: separateFacturableInResumen, // Usar el flag correspondiente
      );
      debugPrint("[$operation] Hoja Resumen General construida.");


      // --- 2. Hojas Individuales por Proveedor ---
      for (var entry in data.entries) {
        final proveedor = entry.key;
        final items = entry.value;
        String provSheetName = proveedor?.nombre ?? "Sin_Proveedor";
        provSheetName = provSheetName.replaceAll(RegExp(r'[\\/*?:\[\]]'), '_').replaceAll(' ', '_');
        provSheetName = provSheetName.substring(0, (provSheetName.length > 30 ? 30 : provSheetName.length));

        // Evitar conflicto si el proveedor se llama igual que la hoja resumen
        if (provSheetName.toLowerCase() == resumenSheetName.toLowerCase()) {
            provSheetName = "${provSheetName}_Detalle";
        }
        // Verificar si ya existe (poco probable si limpiamos nombres)
        if (excel.sheets.containsKey(provSheetName)) {
            int count = 2;
            String originalName = provSheetName;
            while(excel.sheets.containsKey(provSheetName)){
                provSheetName = "${originalName}_$count";
                count++;
            }
        }

        Sheet providerSheetObject = excel[provSheetName];
        _buildProviderSpecificSheetContent(
            providerSheetObject,
            proveedor,
            items,
            separateByFacturable: separateFacturableInProviderSheets, // Usar el flag correspondiente
        );
        debugPrint("[$operation] Hoja para proveedor '${proveedor?.nombre ?? 'N/A'}' construida.");
      }

      // Guardar el archivo único usando FilePicker
      var fileBytes = excel.save(fileName: "temp_excel.xlsx"); // Nombre temporal en memoria
      if (fileBytes != null) {
        String suggestedFileName = '${cleanBaseFileName}_${DateTime.now().toIso8601String().replaceAll(':','-').substring(0,10)}.xlsx';
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar Lista de Compras como Excel',
          fileName: suggestedFileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputPath != null) {
          if (!outputPath.toLowerCase().endsWith('.xlsx')) outputPath += '.xlsx';
          final File file = File(outputPath);
          await file.writeAsBytes(fileBytes, flush: true);
          debugPrint("[$operation] Archivo Excel guardado en: $outputPath");
          _showSnackBar(context, "Archivo Excel guardado en: $outputPath", isError: false);
          return true;
        } else {
          debugPrint("[$operation] Guardado de archivo cancelado por el usuario.");
          return false;
        }
      } else {
        debugPrint("[$operation] Falla al obtener bytes del archivo Excel.");
        _showSnackBar(context, "Error interno al generar el archivo Excel.", isError: true);
        return false;
      }
    } catch (e, st) {
      debugPrint("[$operation][ERROR] Exportando a Excel: $e\n$st");
      if(context.mounted) _showSnackBar(context, "Error al exportar a Excel: $e", isError: true);
      return false;
    }
  }


  // --- MÉTODO PARA CONSTRUIR LA HOJA PRINCIPAL (RESUMEN COMPLETO) ---
  // (La implementación anterior con la corrección para 'separateByFacturable' estaba bien)
  void _buildMainExcelSheetContent(
      Sheet sheetObject,
      GroupedShoppingListResult data,
      { required bool separateByFacturable }
    ) {
    // Estilos (Usar ExcelColor.fromHexString para colores)
    CellStyle headerStyle = CellStyle(bold: true, fontSize: 11, backgroundColorHex: ExcelColor.fromHexString("#B0BEC5"), horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
    CellStyle proveedorHeaderStyle = CellStyle(bold: true, fontSize: 12, fontColorHex: ExcelColor.fromHexString("#1565C0"), backgroundColorHex: ExcelColor.fromHexString("#E3F2FD"));
    CellStyle facturableSectionStyle = CellStyle(bold: true, fontSize: 10, backgroundColorHex: ExcelColor.fromHexString("#C8E6C9")); // Verde claro
    CellStyle noFacturableSectionStyle = CellStyle(bold: true, fontSize: 10, backgroundColorHex: ExcelColor.fromHexString("#FFCCBC")); // Naranja claro
    CellStyle subtotalStyle = CellStyle(bold: true, numberFormat: NumFormat.standard_0, fontColorHex: ExcelColor.fromHexString("#1B5E20"));
    CellStyle totalStyle = CellStyle(bold: true, fontSize: 12, numberFormat: NumFormat.standard_0, backgroundColorHex: ExcelColor.fromHexString("#FFF9C4"));
    CellStyle numberCellStyle = CellStyle(numberFormat: NumFormat.standard_0);
    CellStyle currencyCellStyle = CellStyle(numberFormat: NumFormat.standard_0);


    List<String> headers = ["Insumo Código", "Insumo Nombre", "Cantidad", "Unidad", "Categoría", "Precio Unit.", "Costo Estimado"];
    if (separateByFacturable) headers.add("Tipo Facturación");

    for(int i=0; i< headers.length; i++){
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
    }

    int rowIndex = 1;
    double costoTotalGeneralExcel = 0.0;

    data.forEach((proveedor, items) {
      final provNombre = proveedor?.nombre ?? 'Sin Proveedor Asignado';
      double subtotalProveedorGeneral = 0.0;

      var provCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      provCell.value = TextCellValue(provNombre);
      provCell.cellStyle = proveedorHeaderStyle;
      sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex), customValue: TextCellValue(provNombre));
      rowIndex++;

      void writeItemRow(ShoppingListItem item, String? tipoFacturableStr) {
          List<CellValue> rowData = [
             TextCellValue(item.insumo.codigo), TextCellValue(item.insumo.nombre),
             DoubleCellValue(item.cantidad), TextCellValue(item.unidad),
             TextCellValue(item.insumo.categorias.join(', ')), // Asumiendo que insumo.categoria es String
             DoubleCellValue(item.insumo.precioUnitario), DoubleCellValue(item.costoItem),
          ];
          if (separateByFacturable) rowData.add(TextCellValue(tipoFacturableStr ?? "N/A"));
          
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).cellStyle = numberCellStyle;
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).cellStyle = currencyCellStyle;
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).cellStyle = currencyCellStyle;
          if (separateByFacturable) sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).cellStyle = CellStyle(fontColorHex: (tipoFacturableStr == "Facturable" ? ExcelColor.green : ExcelColor.red));


          sheetObject.insertRowIterables(rowData, rowIndex); // Corrección aquí
          rowIndex++;
      }

      if (separateByFacturable) {
          List<ShoppingListItem> itemsFacturables = items.where((item) => item.esFacturable == true).toList();
          if (itemsFacturables.isNotEmpty) {
             var factHeaderCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
             factHeaderCell.value = TextCellValue("Items Facturables"); factHeaderCell.cellStyle = facturableSectionStyle;
             sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex), customValue: TextCellValue("Items Facturables"));
             rowIndex++;
             for (var item in itemsFacturables) { writeItemRow(item, "Facturable"); subtotalProveedorGeneral += item.costoItem; }
          }
          List<ShoppingListItem> itemsNoFacturables = items.where((item) => item.esFacturable == false).toList();
          if (itemsNoFacturables.isNotEmpty) {
             var noFactHeaderCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
             noFactHeaderCell.value = TextCellValue("Items No Facturables"); noFactHeaderCell.cellStyle = noFacturableSectionStyle;
             sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex), customValue: TextCellValue("Items No Facturables"));
             rowIndex++;
             for (var item in itemsNoFacturables) { writeItemRow(item, "No Facturable"); subtotalProveedorGeneral += item.costoItem; }
          }
          List<ShoppingListItem> itemsCombinados = items.where((item) => item.esFacturable == null).toList();
           if (itemsCombinados.isNotEmpty) {
              rowIndex++; // Espacio o subtitulo
              for (var item in itemsCombinados) { writeItemRow(item, "Combinado"); subtotalProveedorGeneral += item.costoItem; }
           }
      } else {
         for (var item in items) { writeItemRow(item, null); subtotalProveedorGeneral += item.costoItem; }
      }

      if (subtotalProveedorGeneral > 0) {
          var subtotalLabelCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: headers.length - 2, rowIndex: rowIndex));
          subtotalLabelCell.value = TextCellValue("Subtotal Proveedor:");
          subtotalLabelCell.cellStyle = CellStyle(bold:true, horizontalAlign: HorizontalAlign.Right);
          var subtotalValueCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex));
          subtotalValueCell.value = DoubleCellValue(subtotalProveedorGeneral);
          subtotalValueCell.cellStyle = subtotalStyle;
          rowIndex++;
      }
      rowIndex++;
      costoTotalGeneralExcel += subtotalProveedorGeneral;
    });

    if(data.isNotEmpty){ // Solo mostrar total general si hay datos
      rowIndex++;
      var totalLabelCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: headers.length - 2, rowIndex: rowIndex));
      totalLabelCell.value = TextCellValue("COSTO TOTAL GENERAL:");
      totalLabelCell.cellStyle = CellStyle(bold:true, horizontalAlign: HorizontalAlign.Right);
      var totalValueCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex));
      totalValueCell.value = DoubleCellValue(costoTotalGeneralExcel);
      totalValueCell.cellStyle = totalStyle;
    }
  }

  // --- MÉTODO PARA CONSTRUIR HOJA ESPECÍFICA DE PROVEEDOR (CON SEPARACIÓN FACTURABLE OPCIONAL) ---
  void _buildProviderSpecificSheetContent(
      Sheet sheetObject,
      Proveedor? proveedor,
      List<ShoppingListItem> items,
      { required bool separateByFacturable } // Flag para separar en esta hoja
    ) {
    CellStyle headerStyle = CellStyle(bold: true, fontSize: 11, backgroundColorHex: ExcelColor.grey, horizontalAlign: HorizontalAlign.Center);
    CellStyle numberCellStyle = CellStyle(numberFormat: NumFormat.standard_0);
    CellStyle facturableHeaderStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.lightGreen);
    CellStyle noFacturableHeaderStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.orange);

    List<String> headers = ["Insumo Nombre", "Insumo Código", "Cantidad", "Unidad"];
    if (separateByFacturable) headers.add("Tipo Facturación");

    for(int i=0; i< headers.length; i++){
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
    }

    int rowIndex = 1;

    void writeSimpleItemRow(ShoppingListItem item, String? tipoFacturableStr) {
      List<CellValue> rowData = [
        TextCellValue(item.insumo.nombre), TextCellValue(item.insumo.codigo),
        DoubleCellValue(item.cantidad), TextCellValue(item.unidad),
      ];
      if (separateByFacturable) rowData.add(TextCellValue(tipoFacturableStr ?? "N/A"));
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).cellStyle = numberCellStyle;
      sheetObject.insertRowIterables(rowData, rowIndex);
      rowIndex++;
    }

    if (separateByFacturable) {
        List<ShoppingListItem> itemsFacturables = items.where((item) => item.esFacturable == true).toList();
        if (itemsFacturables.isNotEmpty) {
           var factHeaderCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
           factHeaderCell.value = TextCellValue("Items Facturables"); factHeaderCell.cellStyle = facturableHeaderStyle;
           sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex), customValue: TextCellValue("Items Facturables"));
           rowIndex++;
           for (var item in itemsFacturables) { writeSimpleItemRow(item, "Facturable"); }
        }
        List<ShoppingListItem> itemsNoFacturables = items.where((item) => item.esFacturable == false).toList();
        if (itemsNoFacturables.isNotEmpty) {
           var noFactHeaderCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
           noFactHeaderCell.value = TextCellValue("Items No Facturables"); noFactHeaderCell.cellStyle = noFacturableHeaderStyle;
           sheetObject.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex), customValue: TextCellValue("Items No Facturables"));
           rowIndex++;
           for (var item in itemsNoFacturables) { writeSimpleItemRow(item, "No Facturable"); }
        }
         List<ShoppingListItem> itemsCombinados = items.where((item) => item.esFacturable == null).toList();
         if (itemsCombinados.isNotEmpty) {
            rowIndex++;
            for (var item in itemsCombinados) { writeSimpleItemRow(item, "Combinado");}
         }
    } else {
        for (var item in items) { writeSimpleItemRow(item, null); }
    }
  }


  /// Exporta y comparte la lista de compras a través de la interfaz de compartir del dispositivo.
  ///
  /// Este método permite exportar la lista de compras y compartirla directamente
  /// a través de las opciones de compartir del sistema operativo (correo, mensajes, etc.).
  ///
  /// Parámetros:
  /// - [context]: Contexto de Flutter para mostrar mensajes al usuario.
  /// - [data]: Mapa que contiene la lista de compras agrupada por proveedor.
  /// - [baseFileName]: Nombre base sugerido para el archivo. Se limpiará de caracteres no válidos.
  /// - [separateFilesByProvider]: Si es `true`, genera un archivo Excel por cada proveedor.
  ///   Si es `false`, genera un solo archivo con múltiples hojas.
  /// - [separateByFacturable]: Si es `true`, separa los ítems facturables de los no facturables
  ///   en hojas o archivos diferentes según corresponda.
  ///
  /// Retorna:
  /// - `true` si la exportación y compartición fue exitosa.
  /// - `false` si ocurrió un error o el usuario canceló la operación.
  ///
  /// Lanza:
  /// - `Exception` si ocurre un error durante la generación del archivo.
  ///
  /// Ejemplo:
  /// ```dart
  /// await excelExportService.shareShoppingList(
  ///   context: context,
  ///   data: shoppingListData,
  ///   baseFileName: 'Lista de Compras ${evento.nombre}',
  ///   separateFilesByProvider: false,
  ///   separateByFacturable: true,
  /// );
  /// ```
  Future<bool> shareShoppingList({
    required BuildContext context,
    required GroupedShoppingListResult data,
    required String baseFileName,
    bool separateFilesByProvider = false,
    bool separateByFacturable = false,
  }) async {
    debugPrint(
      "ExcelExportService: Iniciando exportación. Separar Proveedor: $separateFilesByProvider, Separar Facturable: $separateByFacturable",
    );

    if (data.isEmpty) {
      _showSnackBar(context, "La lista de compras está vacía.", isError: true);
      return false;
    }

    // Limpiar nombre base del archivo
    final String cleanBaseFileName = baseFileName
        .replaceAll(RegExp(r'[\\/*?:\[\]]'), '_')
        .replaceAll('__', '_')
        .substring(0, (baseFileName.length > 30 ? 30 : baseFileName.length));

    try {
      if (separateFilesByProvider) {
        // --- Exportar Múltiples Archivos (Uno por proveedor) ---
        List<XFile> filesToShare = [];
        for (var entry in data.entries) {
          final proveedor = entry.key;
          final items = entry.value;
          final provNombre = proveedor?.nombre ?? "Sin_Proveedor";
          final provFileName = provNombre
              .replaceAll(RegExp(r'[\\/*?:\[\]]'), '_')
              .replaceAll(' ', '_');
          final fileName = "${cleanBaseFileName}_${provFileName}.xlsx";

          var excel = Excel.createExcel();
          Sheet sheetObject =
              excel[provNombre.substring(
                0,
                (provNombre.length > 30 ? 30 : provNombre.length),
              )];

          // Generar contenido solo para este proveedor (combinado o separado por facturable)
          _buildExcelSheetContent(
            sheetObject,
            {proveedor: items},
            includeTotalsRow: false,
            facturableFilter: separateByFacturable,
          ); // Pasar flag

          var fileBytes = excel.save(fileName: "temp.xlsx");
          if (fileBytes != null) {
            // ... (guardar archivo temporal como antes)
            final Directory tempDir = await getTemporaryDirectory();
            final String filePath = '${tempDir.path}/$fileName';
            final File file = File(filePath);
            await file.writeAsBytes(fileBytes, flush: true);
            filesToShare.add(XFile(filePath));
            debugPrint(
              "ExcelExportService: Archivo temporal proveedor '$provNombre': $filePath",
            );
          }
        }
        // Compartir TODOS los archivos generados
        if (filesToShare.isNotEmpty) {
          debugPrint(
            "ExcelExportService: Compartiendo ${filesToShare.length} archivos...",
          );
          // --- USO CORRECTO SHARE PLUS v11 ---
          final params = ShareParams(
            files: filesToShare, // Lista de XFile
            subject: 'Listas de Compras por Proveedor: $baseFileName',
            text: 'Se adjuntan las listas de compras separadas por proveedor.',
          );
          await SharePlus.instance.share(params);
          // ---------------------------------
          return true;
        } else {
          return false;
        }
      } else {
        // --- Exportar un ÚNICO Archivo con Todos los Proveedores ---
        var excel = Excel.createExcel();
        // Crear hoja(s) según el flag separateByFacturable
        if (separateByFacturable) {
          // Crear hoja para Facturables
          Sheet facturableSheet = excel['Facturables'];
          _buildExcelSheetContent(
            facturableSheet,
            data,
            includeTotalsRow: true,
            facturableFilter: true,
          ); // Filtrar facturables

          // Crear hoja para No Facturables
          Sheet noFacturableSheet = excel['No_Facturables'];
          _buildExcelSheetContent(
            noFacturableSheet,
            data,
            includeTotalsRow: true,
            facturableFilter: false,
          ); // Filtrar no facturables

          // Podrías añadir una hoja resumen combinada si quieres
          // Sheet resumenSheet = excel['Resumen_Total'];
          // _buildExcelSheetContent(resumenSheet, data, includeTotalsRow: true, facturableFilter: null); // Sin filtro
        } else {
          // Crear una única hoja combinada
          final sheetName = cleanBaseFileName.substring(
            0,
            (cleanBaseFileName.length > 30 ? 30 : cleanBaseFileName.length),
          );
          Sheet sheetObject = excel[sheetName];
          _buildExcelSheetContent(
            sheetObject,
            data,
            includeTotalsRow: true,
            facturableFilter: null,
          ); // Sin filtro
        }

        // Guardar y compartir el archivo único
        var fileBytes = excel.save(fileName: "temp.xlsx");
        if (fileBytes != null) {
          // ... (guardar archivo temporal como antes)
          final Directory tempDir = await getTemporaryDirectory();
          final String filePath =
              '${tempDir.path}/${cleanBaseFileName}_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.xlsx';
          final File file = File(filePath);
          await file.writeAsBytes(fileBytes, flush: true);
          debugPrint(
            "ExcelExportService: Archivo único temporal creado: $filePath",
          );

          // --- USO CORRECTO SHARE PLUS v11 ---
          final xFile = XFile(filePath);
          final params = ShareParams(
            files: [xFile], // Lista con UN XFile
            subject: 'Lista de Compras: $baseFileName',
            text:
                'Se adjunta la lista de compras ${separateByFacturable ? "(separada por facturabilidad)" : "(completa)"}.',
          );
          await SharePlus.instance.share(params);
          // ---------------------------------
          return true;
        } else {
          return false;
        }
      }
    } catch (e, st) {
      debugPrint("[ExcelExportService][ERROR] Exportando a Excel: $e\n$st");
      if (context.mounted) {
        _showSnackBar(context, "Error al exportar a Excel: $e", isError: true);
      }
      return false;
    }
  }

  /// Construye el contenido de una hoja de cálculo Excel con los datos de la lista de compras.
  ///
  /// Este método interno se encarga de formatear y organizar los datos en la hoja de cálculo,
  /// aplicando estilos y agrupaciones según los parámetros proporcionados.
  ///
  /// Parámetros:
  /// - [sheetObject]: Objeto que representa la hoja de cálculo donde se escribirán los datos.
  /// - [data]: Mapa que contiene la lista de compras agrupada por proveedor.
  /// - [includeTotalsRow]: Si es `true`, incluye una fila con el total general al final.
  /// - [facturableFilter]: Filtro opcional para mostrar solo ítems facturables (`true`),
  ///   no facturables (`false`), o todos (`null`).
  ///
  /// Notas:
  /// - Los estilos se aplican automáticamente a las celdas de encabezado, datos y totales.
  /// - Los valores numéricos se formatean según el estándar de la moneda local.
  /// - Los totales se calculan automáticamente.
  ///
  /// Ejemplo de uso interno:
  /// ```dart
  /// _buildExcelSheetContent(
  ///   sheetObject,
  ///   shoppingListData,
  ///   includeTotalsRow: true,
  ///   facturableFilter: null, // Mostrar todos los ítems
  /// );
  /// ```
  void _buildExcelSheetContent(
    Sheet sheetObject,
    GroupedShoppingListResult data, {
    bool includeTotalsRow = true,
    required bool? facturableFilter,
  }) {
    // --- Estilos (Definir como antes) ---
    CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString("#B0BEC5"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    CellStyle proveedorStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString("#1565C0"),
    );
    CellStyle totalStyle = CellStyle(
      bold: true,
      numberFormat: NumFormat.standard_0,
    ); // Formato moneda USD
    CellStyle numberCellStyle = CellStyle(numberFormat: NumFormat.standard_0);

    // --- Encabezados ---
    List<String> headers = [
      /* ... tu lista de encabezados ... */ "Proveedor Codigo",
      "Proveedor Nombre",
      "Insumo Codigo",
      "Insumo Nombre",
      "Cantidad",
      "Unidad",
      "Categoria Insumo",
      "Precio Unitario",
      "Costo Estimado",
    ];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // --- Escribir Datos ---
    int rowIndex = 1;
    double costoTotalGeneralExcel = 0.0;

    // Iterar sobre los datos recibidos (puede ser el mapa completo o solo una entrada)
    data.forEach((proveedor, items) {
      final provCodigo = proveedor?.codigo ?? '';
      final provNombre = proveedor?.nombre ?? 'Sin Proveedor';
      double subtotalProveedorExcel = 0.0;
      bool proveedorHeaderWritten = false;

      // Filtrar items según facturableFilter ANTES de iterar
      List<ShoppingListItem> itemsFiltrados =
          items.where((item) {
            // Si el filtro es null, incluir todos.
            // Si el filtro es true, incluir solo item.esFacturable == true (y null si es combinado?).
            // Si el filtro es false, incluir solo item.esFacturable == false (y null si es combinado?).
            // IMPORTANTE: Esto asume que ShoppingListItem tiene el campo esFacturable?
            // Si trabajas con la lista combinada, esFacturable siempre será null aquí.
            // La separación REAL debe hacerse en la llamada a _mapDetailedTotalsToShoppingListItems en el ShoppingListService.
            // Este filtro aquí solo sirve si LLAMASTE a getSeparatedGroupedShoppingList.
            if (facturableFilter == null) {
              return true; // Incluir todos si no hay filtro
            }
            // Si el item NO tiene el flag (porque se generó combinado), lo incluimos si el filtro es null
            // Si el item SÍ tiene el flag, debe coincidir con el filtro
            return item.esFacturable == facturableFilter;
          }).toList();

      // Si no hay items después de filtrar, saltar este proveedor
      if (itemsFiltrados.isEmpty) return;

      // Fila de título del proveedor (solo si hay más de un proveedor en los datos O si es el grupo sin proveedor)
      if (data.length > 1 || proveedor == null) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        cell.value = TextCellValue(provNombre);
        cell.cellStyle = proveedorStyle;
        rowIndex++;
        proveedorHeaderWritten = true;
      }

      // Escribir items del proveedor
      for (var item in itemsFiltrados) {
        List<CellValue> rowData = [
          TextCellValue(provCodigo),
          TextCellValue(
            provNombre,
          ), // Repetir nombre/código en cada fila para facilitar filtrado en Excel
          TextCellValue(item.insumo.codigo), TextCellValue(item.insumo.nombre),
          DoubleCellValue(item.cantidad), TextCellValue(item.unidad),
          TextCellValue(item.insumo.categorias.join(', ')),
          DoubleCellValue(item.insumo.precioUnitario),
          DoubleCellValue(item.costoItem),
        ];
        // Aplicar estilos numéricos/moneda
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .cellStyle = numberCellStyle; // Cantidad
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
            )
            .cellStyle = totalStyle; // Precio Unitario
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
            )
            .cellStyle = totalStyle; // Costo Item

        sheetObject.insertRowIterables(rowData, rowIndex);
        subtotalProveedorExcel += item.costoItem;
        rowIndex++;
      }

      // Fila de subtotal por proveedor (opcional, puedes activarlo con otro flag)
      // if (items.isNotEmpty) { ... escribir subtotal ... rowIndex++; }

      // Añadir espacio si hay más de un grupo en los datos
      if (data.length > 1 && items.isNotEmpty && proveedorHeaderWritten) {
        rowIndex++;
      }

      costoTotalGeneralExcel += subtotalProveedorExcel;
    }); // Fin forEach proveedor

    // --- Fila de Total General (si se indica) ---
    if (includeTotalsRow) {
      rowIndex++;
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue("TOTAL GENERAL:");
      var totalCell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
      );
      totalCell.value = DoubleCellValue(costoTotalGeneralExcel);
      totalCell.cellStyle = totalStyle;
    }
  } // Fin _buildExcelSheetContent

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // Asegurarse que el contexto sigue siendo válido si se llama desde un Future
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green[600],
      ),
    );
  }
 }// Fin ExcelExportService
