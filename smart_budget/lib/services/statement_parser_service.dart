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
      // 1. Load PDF and extract text
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      // 🚨 CRITICAL CHECK: Is the PDF an Image/Scan?
      // If the extracted text is empty, it means the PDF is likely an image (scan).
      // We return an empty list and print a warning. We do NOT generate fake data.
      if (text.trim().isEmpty) {
        print(
            "--- WARNING: No text found in PDF. It might be an image/scan format. ---");
        return [];
      }

      print("--- PDF LOG START (Raw Text) ---");
      // print(text); // Uncomment to debug raw text output in console
      print("--- PDF LOG END ---");

      List<Map<String, dynamic>> transactions = [];
      List<String> lines = text.split('\n');

      // 2. Define Regex for Date
      // Allows leading whitespace, supports DD.MM.YYYY or YYYY.MM.DD
      RegExp dateRegex = RegExp(r'^\s*(\d{2}[/.-]\d{2}[/.-]\d{2,4})');

      // 3. Define Regex for Amount
      // Captures formats like "1.250,50" (TR) or "1,250.50" (US).
      // Ignores trailing currency codes (TL, USD, etc.)
      RegExp amountRegex =
          RegExp(r'([+-]?\s*\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\s*([A-Z]{2,3})?$');

      String? currentDate;
      String currentDesc = "";
      String? currentAmountStr;

      // 4. Line-by-Line Analysis
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;

        // CASE A: Line starts with a DATE -> New Transaction
        if (dateRegex.hasMatch(line)) {
          // Save previous transaction if exists
          if (currentDate != null && currentAmountStr != null) {
            _addTransactionToList(
                transactions, currentDate, currentDesc, currentAmountStr);
          }

          // Start new transaction
          var dateMatch = dateRegex.firstMatch(line);
          currentDate = dateMatch!.group(1); // Extract date

          // Get the rest of the line
          String restOfLine = line.substring(dateMatch.end).trim();

          // Look for amount in this line
          var amountMatch = amountRegex.firstMatch(restOfLine);
          if (amountMatch != null) {
            currentAmountStr = amountMatch.group(1);
            // Description is usually between Date and Amount
            int amountIndex = restOfLine.lastIndexOf(currentAmountStr!);
            if (amountIndex > 0) {
              currentDesc = restOfLine.substring(0, amountIndex).trim();
            } else {
              currentDesc = "No Description";
            }
          } else {
            // Amount not found in this line (might be on next line)
            currentDesc = restOfLine;
            currentAmountStr = null;
          }
        }
        // CASE B: Line does NOT start with Date -> Detail/Continuation line
        else {
          if (currentDate != null) {
            if (currentAmountStr == null) {
              // If we haven't found the amount yet, look for it here
              var amountMatch = amountRegex.firstMatch(line);
              if (amountMatch != null) {
                currentAmountStr = amountMatch.group(1);
                String descPart =
                    line.substring(0, line.indexOf(currentAmountStr!)).trim();
                currentDesc += " $descPart";
              } else {
                currentDesc += " $line";
              }
            } else {
              // If amount is already found, this is just extra description
              currentDesc += " $line";
            }
          }
        }
      }

      // Add the final transaction after loop ends
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

  // --- HELPER METHOD (Smart Keyword Detection: TR + EN) ---
  void _addTransactionToList(List<Map<String, dynamic>> list, String? date,
      String desc, String? amountStr) {
    if (date == null || amountStr == null) return;

    try {
      // 1. Check for minus sign before cleaning
      bool hasMinusSign = amountStr.contains('-') || amountStr.contains('–');

      String lowerDesc = desc.toLowerCase();

      // 2. Expense Keywords (Turkish + English)
      bool isExpenseKeyword =
          // Turkish
          lowerDesc.contains('gider') ||
              lowerDesc.contains('odeme') ||
              lowerDesc.contains('ödeme') ||
              lowerDesc.contains('alisveris') ||
              lowerDesc.contains('alışveriş') ||
              lowerDesc.contains('cekilen') ||
              lowerDesc.contains('komisyon') ||
              lowerDesc.contains('transfer') ||
              lowerDesc.contains('eft') ||
              lowerDesc.contains('havale') ||
              lowerDesc.contains('fatura') ||
              // English
              lowerDesc.contains('payment') ||
              lowerDesc.contains('expense') ||
              lowerDesc.contains('purchase') ||
              lowerDesc.contains('withdrawal') ||
              lowerDesc.contains('fee') ||
              lowerDesc.contains('charge') ||
              lowerDesc.contains('bill') ||
              lowerDesc.contains('invoice') ||
              lowerDesc.contains('sent') ||
              // Brands/Subscriptions
              lowerDesc.contains('netflix') ||
              lowerDesc.contains('spotify') ||
              lowerDesc.contains('youtube') ||
              lowerDesc.contains('amazon') ||
              lowerDesc.contains('apple');

      // 3. Clean the Amount String
      // Remove dots (thousand separator) and replace comma with dot (decimal)
      String cleanAmount = amountStr.replaceAll('.', '').replaceAll(',', '.');
      // Remove everything except numbers and dots
      cleanAmount = cleanAmount.replaceAll(RegExp(r'[^0-9.]'), '');

      double amount = double.parse(cleanAmount);

      // 4. Determine Transaction Type
      String type = 'Income'; // Default

      if (hasMinusSign || isExpenseKeyword) {
        type = 'Expense';
      }

      // Salary/Deposit keywords override Expense detection (Always Income)
      if (lowerDesc.contains('maas') ||
          lowerDesc.contains('maaş') ||
          lowerDesc.contains('yatirilan') ||
          lowerDesc.contains('refund') || // English
          lowerDesc.contains('iade') || // Turkish
          lowerDesc.contains('deposit')) {
        // English
        type = 'Income';
      }

      list.add({
        'date': date,
        'title': desc.trim(),
        'amount': amount.abs(), // Store as absolute value
        'type': type,
      });
    } catch (e) {
      print("Error converting transaction ($amountStr): $e");
    }
  }
}
