// lib/services/statement_parser_service.dart

import 'dart:typed_data'; // Required for Uint8List
import 'dart:convert'; // Required for UTF8 decode
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import '../models/transaction_model.dart';

// File option enum (Shared with ImportStatementWidget)
enum FileTypeOption { csv, excel, pdf }

class StatementParserService {
  
  /// Main function to determine file type and parse accordingly
  Future<List<TransactionModel>> parseFile(PlatformFile file) async {
    final extension = file.extension?.toLowerCase();
    
    if (extension == 'csv') {
      return _parseCSV(file.path!);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcel(file.path!);
    } else {
      throw Exception("Unsupported file format. Please use CSV or Excel.");
    }
  }

  // --- CSV PARSER ---
  Future<List<TransactionModel>> _parseCSV(String path) async {
    final input = File(path).openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    List<TransactionModel> transactions = [];

    // Skip header row (index 0) and start from 1
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      
      // ADJUST THESE INDEXES based on your bank's CSV format!
      // Example: Date (0), Description (1), Amount (2)
      try {
        final dateStr = row[0].toString(); 
        final description = row[1].toString();
        final amountStr = row[2].toString();

        // Basic clean up of amount string (remove currency symbols etc)
        double amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
        bool isIncome = amount > 0;

        transactions.add(TransactionModel(
          amount: amount.abs(),
          category: "Imported", // Default category
          note: description,
          date: DateTime.now(), // You might want to parse dateStr here
          isIncome: isIncome,
        ));
      } catch (e) {
        print("Error parsing row $i: $e");
      }
    }
    return transactions;
  }

  // --- EXCEL PARSER ---
  Future<List<TransactionModel>> _parseExcel(String path) async {
    var bytes = File(path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<TransactionModel> transactions = [];

    // Assume data is in the first sheet
    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];

    if (table != null) {
      // Skip header row (rowIndex 0)
      for (var i = 1; i < table.maxRows; i++) {
        final row = table.rows[i];
        
        // ADJUST INDEXES: col 0 = Date, col 1 = Desc, col 2 = Amount
        try {
          final descCellValue = row[1]?.value.toString() ?? "Unknown";
          final amountCellValue = row[2]?.value.toString() ?? "0";

          double amount = double.tryParse(amountCellValue.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
          
          transactions.add(TransactionModel(
            amount: amount.abs(),
            category: "Imported",
            note: descCellValue,
            date: DateTime.now(),
            isIncome: amount > 0,
          ));
        } catch (e) {
          print("Error parsing excel row $i: $e");
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

