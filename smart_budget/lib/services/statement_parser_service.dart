// lib/services/statement_parser_service.dart

import 'dart:io';
import 'dart:typed_data'; // Required for Uint8List
import 'dart:convert'; // Required for UTF8 decode
import 'package:flutter/foundation.dart'; // Required for kIsWeb check
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // Ensure this is in pubspec.yaml

// Enum to match the one used in Dashboard
enum FileTypeOption { excel, csv, pdf }

class StatementParserService {
  /// Opens the file picker, reads the file as bytes (Web-safe), and parses it.
  Future<List<Map<String, dynamic>>> pickAndParseFile(
      FileTypeOption type) async {
    try {
      // 1. Define allowed extensions based on selection
      List<String> allowedExtensions = [];
      switch (type) {
        case FileTypeOption.excel:
          allowedExtensions = ['xlsx', 'xls'];
          break;
        case FileTypeOption.csv:
          allowedExtensions = ['csv'];
          break;
        case FileTypeOption.pdf:
          allowedExtensions = ['pdf'];
          break;
      }

      // 2. Open File Picker
      // 'withData: true' is CRITICAL for Web to load the file into memory
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      // 3. Check if user canceled
      if (result == null || result.files.isEmpty) {
        return [];
      }

      PlatformFile platformFile = result.files.first;
      Uint8List fileBytes;

      // 4. GET BYTES (Crucial for Web Compatibility)
      if (kIsWeb) {
        // On Web, path is null. We must use the bytes loaded in memory.
        if (platformFile.bytes != null) {
          fileBytes = platformFile.bytes!;
        } else {
          throw Exception(
              "Web file bytes are null. Ensure 'withData: true' is used.");
        }
      } else {
        // On Mobile/Desktop, we can read from the path if bytes are empty
        if (platformFile.path != null) {
          fileBytes = File(platformFile.path!).readAsBytesSync();
        } else {
          throw Exception("File path is null on mobile!");
        }
      }

      // 5. Send bytes to the appropriate parser
      if (type == FileTypeOption.csv) {
        return _parseCSV(fileBytes);
      } else if (type == FileTypeOption.excel) {
        return _parseExcel(fileBytes);
      } else if (type == FileTypeOption.pdf) {
        return _parsePDF(fileBytes);
      }

      return [];
    } catch (e) {
      print("Error in pickAndParseFile: $e");
      return []; // Return empty list on error
    }
  }

  // --- CSV PARSER (Using Bytes) ---
  Future<List<Map<String, dynamic>>> _parseCSV(Uint8List bytes) async {
    // Decode bytes to string
    final String csvContent = utf8.decode(bytes);

    // Convert CSV string to List
    final List<List<dynamic>> fields =
        const CsvToListConverter().convert(csvContent);

    List<Map<String, dynamic>> transactions = [];

    // Loop starts at 1 to skip headers
    for (var i = 1; i < fields.length; i++) {
      try {
        final row = fields[i];
        // Assumes columns: 0=Date, 1=Description, 2=Amount
        if (row.length < 3) continue;

        String dateStr = row[0].toString();
        String desc = row[1].toString();
        String amountStr = row[2].toString();

        // Clean amount string and parse
        double amount =
            double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ??
                0.0;
        String type = amount >= 0 ? 'Income' : 'Expense';

        transactions.add({
          'date': dateStr,
          'title': desc,
          'amount': amount.abs(),
          'type': type,
        });
      } catch (e) {
        print("Error parsing CSV row $i: $e");
      }
    }
    return transactions;
  }

  // --- EXCEL PARSER (Using Bytes) ---
  Future<List<Map<String, dynamic>>> _parseExcel(Uint8List bytes) async {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> transactions = [];

    // Get the first sheet
    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];

    if (table != null) {
      // Loop starts at 1 to skip headers
      for (var i = 1; i < table.maxRows; i++) {
        try {
          final row = table.rows[i];
          // Assumes columns: 0=Date, 1=Desc, 2=Amount
          if (row.length < 3) continue;

          String dateStr = row[0]?.value.toString() ?? "";
          String desc = row[1]?.value.toString() ?? "Unknown";
          String amountStr = row[2]?.value.toString() ?? "0";

          double amount =
              double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ??
                  0.0;
          String type = amount >= 0 ? 'Income' : 'Expense';

          transactions.add({
            'date': dateStr,
            'title': desc,
            'amount': amount.abs(),
            'type': type,
          });
        } catch (e) {
          print("Error parsing Excel row $i: $e");
        }
      }
    }
    return transactions;
  }

  // --- PDF PARSER (Robust Line Merging Logic) ---
  Future<List<Map<String, dynamic>>> _parsePDF(Uint8List bytes) async {
  try {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    String text = extractor.extractText();
    document.dispose();

    if (text.trim().isEmpty) {
      print("--- WARNING: No text found in PDF. It might be an image/scan format. ---");
      return [];
    }

    List<Map<String, dynamic>> transactions = [];
    List<String> lines = text.split('\n');

    RegExp dateRegex = RegExp(r'^\s*(\d{2}[./-]\d{2}[./-]\d{2,4}|\d{4}[./-]\d{2}[./-]\d{2})');
    RegExp amountRegex = RegExp(r'([+-]?\s*\d{1,3}(?:[.,]\d{3})*[.,]\d{2})');

    String? currentDate;
    String currentDesc = "";
    String? currentAmountStr;

    for (String rawLine in lines) {
      String line = rawLine.trim();
      if (line.isEmpty) continue;

      if (dateRegex.hasMatch(line)) {
        if (currentDate != null && currentAmountStr != null) {
          _addTransactionToList(transactions, currentDate, currentDesc, currentAmountStr);
        }

        var dateMatch = dateRegex.firstMatch(line);
        currentDate = dateMatch!.group(1);

        String restOfLine = line.substring(dateMatch.end).trim();
        var amountMatch = amountRegex.firstMatch(restOfLine);

        if (amountMatch != null) {
          currentAmountStr = amountMatch.group(1);
          int amountIndex = restOfLine.lastIndexOf(currentAmountStr!);
          currentDesc = amountIndex > 0 ? restOfLine.substring(0, amountIndex).trim() : "No Description";
        } else {
          currentDesc = restOfLine;
          currentAmountStr = null;
        }
      } else {
        if (currentDate != null) {
          if (currentAmountStr == null) {
            var amountMatch = amountRegex.firstMatch(line);
            if (amountMatch != null) {
              currentAmountStr = amountMatch.group(1);
              String descPart = line.substring(0, line.indexOf(currentAmountStr!)).trim();
              currentDesc = (currentDesc + " " + descPart).trim();
            } else {
              currentDesc = (currentDesc + " " + line).trim();
            }
          } else {
            currentDesc = (currentDesc + " " + line).trim();
          }
        }
      }
    }

    if (currentDate != null && currentAmountStr != null) {
      _addTransactionToList(transactions, currentDate, currentDesc.isEmpty ? "No Description" : currentDesc, currentAmountStr);
    }

    return transactions;
  } catch (e) {
    print("PDF Parsing Failed: $e");
    return [];
  }
}}
