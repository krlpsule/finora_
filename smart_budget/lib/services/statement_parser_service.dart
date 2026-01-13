// lib/services/statement_parser_service.dart

import 'dart:io';
import 'dart:typed_data'; // Required for Uint8List
import 'dart:convert'; // Required for UTF8 decode
import 'package:flutter/foundation.dart'; // Required for kIsWeb check
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // Ensure this is in pubspec.yaml

// Enum to match the one used in Dashboard or Widgets
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

      // 4. GET BYTES (Crucial for Web Compatibility and null safety)
      if (kIsWeb) {
        // On Web, path is null. We must use the bytes loaded in memory.
        if (platformFile.bytes != null) {
          fileBytes = platformFile.bytes!;
        } else {
          throw Exception(
              "Web file bytes are null. Ensure 'withData: true' is used.");
        }
      } else {
        // On Mobile/Desktop, we prefer reading from path, but fallback to bytes if path is null
        if (platformFile.path != null) {
          fileBytes = File(platformFile.path!).readAsBytesSync();
        } else if (platformFile.bytes != null) {
          fileBytes = platformFile.bytes!;
        } else {
          throw Exception("File path and bytes are both null.");
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

  // --- HELPER: Robust Amount Parsing (Handles Turkey/EU vs US formats) ---
  double _parseAmount(String amountStr) {
    try {
      // 1. Remove unnecessary characters (letters, currency symbols like TL, $, etc.)
      // Keep only digits, dots, commas, and the negative sign.
      String clean = amountStr.replaceAll(RegExp(r'[^0-9.,-]'), '').trim();

      if (clean.isEmpty) return 0.0;

      // 2. Format Check (Turkey: 1.234,56 vs US: 1,234.56)
      // If there is a comma but no dot, or the comma is after the last dot, it's likely a decimal separator (TR format).
      // Example: 100,50 or 1.000,50
      if (clean.contains(',') && !clean.contains('.')) {
        // Only comma exists (e.g., 100,50) -> Replace comma with dot
        clean = clean.replaceAll(',', '.');
      } else if (clean.contains(',') && clean.contains('.')) {
        // Both exist. Determine which one is the decimal separator by position.
        int lastDotIndex = clean.lastIndexOf('.');
        int lastCommaIndex = clean.lastIndexOf(',');

        if (lastCommaIndex > lastDotIndex) {
          // Comma is at the end (TR Format: 1.200,50)
          // -> Remove dots (thousands separator), replace comma with dot (decimal).
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Dot is at the end (US Format: 1,200.50)
          // -> Remove commas (thousands separator).
          clean = clean.replaceAll(',', '');
        }
      }

      return double.tryParse(clean) ?? 0.0;
    } catch (e) {
      print("Amount parse error: $e");
      return 0.0;
    }
  }

  // --- HELPER: Determine Transaction Type (Credit Card Logic) ---
  String _determineType(double amount, String description) {
    String descUpper = description.toUpperCase();

    // 1. Check for explicit Expense keywords (to prevent false positives)
    if (descUpper.contains('FATURA') || descUpper.contains('BILL')) {
      return 'Expense';
    }

    // 2. Check for explicit Income keywords (Payments to card, Refunds, etc.)
    // These indicate money entering the card account (reducing debt).
    if (descUpper.contains('ÖDEME') || // TR: Payment
        descUpper.contains('ODEME') || // TR: Payment (normalized)
        descUpper.contains('İADE') || // TR: Refund
        descUpper.contains('IADE') || // TR: Refund (normalized)
        descUpper.contains('REFUND') ||
        descUpper.contains('YATIRILAN') || // TR: Deposited
        descUpper.contains('ALACAK') || // TR: Credit
        descUpper.contains('DEPOSIT') ||
        descUpper.contains('PAYMENT') ||
        descUpper.contains('RETURN')) {
      return 'Income';
    }

    // 3. Negative Amount Check
    // In many bank statements, negative numbers indicate a refund or payment to the card.
    if (amount < 0) {
      return 'Income';
    }

    // 4. Default Assumption for Credit Cards
    // Positive numbers are standard purchases -> Expense.
    return 'Expense';
  }

  // --- CSV PARSER ---
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
        // Ensure strictly required columns exist (assumed: 0=Date, 1=Desc, 2=Amount)
        if (row.length < 3) continue;

        String dateStr = row[0].toString();
        String desc = row[1].toString();
        String amountStr = row[2].toString();

        double amount = _parseAmount(amountStr);
        String type = _determineType(amount, desc);

        transactions.add({
          'date': dateStr,
          'title': desc,
          'amount': amount.abs(), // Always store as absolute positive value
          'type': type,
        });
      } catch (e) {
        print("Error parsing CSV row $i: $e");
      }
    }
    return transactions;
  }

  // --- EXCEL PARSER ---
  Future<List<Map<String, dynamic>>> _parseExcel(Uint8List bytes) async {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> transactions = [];

    // Get the first sheet (usually contains the data)
    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];

    if (table != null) {
      // Loop starts at 1 to skip headers
      for (var i = 1; i < table.maxRows; i++) {
        try {
          final row = table.rows[i];
          // Check for empty rows or insufficient columns
          if (row.isEmpty || row.length < 3) continue;

          String dateStr = row[0]?.value?.toString() ?? "";
          String desc = row[1]?.value?.toString() ?? "Unknown";
          String amountStr = row[2]?.value?.toString() ?? "0";

          double amount = _parseAmount(amountStr);
          String type = _determineType(amount, desc);

          // Only add if amount is valid (non-zero)
          if (amount != 0) {
            transactions.add({
              'date': dateStr,
              'title': desc,
              'amount': amount.abs(),
              'type': type,
            });
          }
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
        print(
            "--- WARNING: No text found in PDF. It might be an image/scan format. ---");
        return [];
      }

      List<Map<String, dynamic>> transactions = [];
      List<String> lines = text.split('\n');

      // Regex for Dates (supports DD/MM/YYYY, DD-MM-YYYY, etc.)
      RegExp dateRegex = RegExp(r'(\d{2}[./-]\d{2}[./-]\d{2,4})');
      // Regex for Amounts (Basic match for numbers with decimals)
      RegExp amountRegex = RegExp(r'([+-]?\d{1,3}(?:[.,]\d{3})*[.,]\d{2})');

      String? currentDate;
      String currentDesc = "";
      String? currentAmountStr;

      for (String rawLine in lines) {
        String line = rawLine.trim();
        if (line.isEmpty) continue;

        // Check if the line contains a date (Start of a new transaction)
        if (dateRegex.hasMatch(line)) {
          // If we were building a previous transaction, save it now.
          if (currentDate != null && currentAmountStr != null) {
            _addTransactionToList(
                transactions, currentDate, currentDesc, currentAmountStr);
          }

          var dateMatch = dateRegex.firstMatch(line);
          currentDate = dateMatch!.group(1);

          // Get the rest of the line after the date
          String restOfLine = line.substring(dateMatch.end).trim();

          // Check if the amount is on the same line
          var amountMatch = amountRegex.firstMatch(restOfLine);
          if (amountMatch != null) {
            currentAmountStr = amountMatch.group(1);

            // Description is typically between date and amount, or around the amount.
            // Removing the amount string to isolate description.
            currentDesc = restOfLine.replaceAll(currentAmountStr!, '').trim();
          } else {
            // Amount might be on the next line
            currentDesc = restOfLine;
            currentAmountStr = null;
          }
        } else {
          // No date found. This could be a continuation of the description or a lone amount.
          if (currentDate != null) {
            if (currentAmountStr == null) {
              // Try to find the amount on this subsequent line
              var amountMatch = amountRegex.firstMatch(line);
              if (amountMatch != null) {
                currentAmountStr = amountMatch.group(1);
                // Append any remaining text to description
                currentDesc +=
                    " " + line.replaceAll(currentAmountStr!, '').trim();
              } else {
                // Still no amount, just append line to description
                currentDesc += " " + line;
              }
            } else {
              // We already have Date and Amount, so this line is likely extra description details
              currentDesc += " " + line;
            }
          }
        }
      }

      // Add the very last transaction found in the loop
      if (currentDate != null && currentAmountStr != null) {
        _addTransactionToList(
            transactions, currentDate, currentDesc, currentAmountStr);
      }

      return transactions;
    } catch (e) {
      print("PDF Parsing Failed: $e");
      return [];
    }
  }

  // --- HELPER: Add Transaction to List (Used by PDF Parser) ---
  void _addTransactionToList(List<Map<String, dynamic>> list, String date,
      String desc, String amountStr) {
    double amount = _parseAmount(amountStr);

    // Simple filter to remove summary lines (e.g., 'Total', 'Balance Carried Forward')
    if (desc.toLowerCase().contains('devreden') ||
        desc.toLowerCase().contains('toplam') ||
        desc.toLowerCase().contains('total')) {
      return;
    }

    String type = _determineType(amount, desc);

    list.add({
      'date': date,
      'title': desc.trim(),
      'amount': amount.abs(),
      'type': type,
    });
  }
}
