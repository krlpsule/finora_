// lib/services/statement_parser_service.dart

import 'dart:typed_data'; // Required for Uint8List
import 'dart:convert'; // Required for UTF8 decode
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import '../models/transaction_model.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // Ensure this is in pubspec.yaml if using PDF
// If you don't use syncfusion, remove the PDF logic or use a different package

// Enum to match the one used in Dashboard
enum FileTypeOption { excel, csv, pdf }

class StatementParserService {
  
  /// Opens the file picker for the specific type and returns parsed data
  Future<List<Map<String, dynamic>>> pickAndParseFile(FileTypeOption type) async {
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

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      if (type == FileTypeOption.csv) {
        return _parseCSV(path);
      } else if (type == FileTypeOption.excel) {
        return _parseExcel(path);
      } else if (type == FileTypeOption.pdf) {
        // PDF parsing is complex and structure-dependent. 
        // Returning empty or mock data for now unless you have specific PDF logic.
        return []; 
      }
    }
    return [];
  }

  // --- CSV PARSER ---
  Future<List<Map<String, dynamic>>> _parseCSV(String path) async {
    final input = File(path).openRead();
    final fields = await input
        .transform(SystemEncoding().decoder) // Uses system encoding to handle special chars
        .transform(const CsvToListConverter())
        .toList();

    List<Map<String, dynamic>> transactions = [];

    // Loop starts at 1 to skip headers
    for (var i = 1; i < fields.length; i++) {
      try {
        final row = fields[i];
        // ADJUST INDICES: 0=Date, 1=Description, 2=Amount (Example)
        String dateStr = row[0].toString();
        String desc = row[1].toString();
        String amountStr = row[2].toString();

        double amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
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

  // --- EXCEL PARSER ---
  Future<List<Map<String, dynamic>>> _parseExcel(String path) async {
    var bytes = File(path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> transactions = [];

    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];

    if (table != null) {
      // Loop starts at 1 to skip headers
      for (var i = 1; i < table.maxRows; i++) {
        try {
          final row = table.rows[i];
          // ADJUST INDICES: 0=Date, 1=Desc, 2=Amount
          String dateStr = row[0]?.value.toString() ?? "";
          String desc = row[1]?.value.toString() ?? "Unknown";
          String amountStr = row[2]?.value.toString() ?? "0";

          double amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
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

// --- 3. PDF PARSING ---
  Future<List<Map<String, dynamic>>> _parsePDF(Uint8List bytes) async {
    try {
      // Decode PDF from bytes
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      // Extract all text content
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      List<Map<String, dynamic>> transactions = [];
      List<String> lines = text.split('\n');

      // Broad Regex pattern to capture Date, Description, and Amount (handling various formats)
      // This Regex needs to be adapted to the specific bank statement layout!
      RegExp exp = RegExp(
          r'(\d{2}[/.-]\d{2}[/.-]\d{4}|\d{4}[/.-]\d{2}[/.-]\d{2})\s*(.+?)\s+([+-]?\s*\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2}))\s*(TL|USD|EUR)?');

      for (String line in lines) {
        var match = exp.firstMatch(line);
        if (match != null) {
          String date = match.group(1)!;
          String desc = match.group(2)!;
          String amountStr = match.group(3)!;

          // Convert to double, handling European number format (',' as decimal separator)
          double amount =
              double.parse(amountStr.replaceAll('.', '').replaceAll(',', '.'));

          transactions.add({
            'date': date,
            'title': desc.trim(),
            'amount': amount,
            'type': 'Expense' // Type determination needs refinement
          });
        }
      }

      if (transactions.isEmpty) {
        print("PDF PARSING DEBUG: Regex did not match any transactions.");
      }

      return transactions;
    } catch (e) {
      print("PDF Parsing Failed: $e");
      // Return empty list on parsing failure
      return [];
    }
  }
}


