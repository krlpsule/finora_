// lib/services/statement_parser_service.dart

import 'dart:typed_data'; // Required for Uint8List
import 'dart:convert'; // Required for UTF8 decode
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// File option enum (Shared with ImportStatementWidget)
enum FileTypeOption { csv, excel, pdf }

class StatementParserService {
  // Main method: Picks the file, reads content as bytes, and delegates parsing.
  Future<List<Map<String, dynamic>>> pickAndParseFile(
      FileTypeOption type) async {
    List<String> allowedExtensions = [];

    switch (type) {
      case FileTypeOption.csv:
        allowedExtensions = ['csv'];
        break;
      case FileTypeOption.excel:
        allowedExtensions = ['xlsx', 'xls'];
        break;
      case FileTypeOption.pdf:
        allowedExtensions = ['pdf'];
        break;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      // CRITICAL: Ensure 'withData: true' for web compatibility (reading bytes)
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.single;
      final fileBytes = pickedFile.bytes;

      if (fileBytes == null) {
        throw Exception(
            "File content could not be read (Bytes are null). Please try a different file.");
      }

      // Delegate the parsing based on the selected file type
      if (type == FileTypeOption.csv) {
        return await _parseCSV(fileBytes);
      } else if (type == FileTypeOption.excel) {
        return await _parseExcel(fileBytes);
      } else {
        return await _parsePDF(fileBytes);
      }
    }
    return [];
  }

// --- 1. CSV PARSING ---
  Future<List<Map<String, dynamic>>> _parseCSV(Uint8List bytes) async {
    try {
      // Convert bytes to text (Platform-independent reading)
      String fileContent = utf8.decode(bytes);

      String delimiter = _detectDelimiter(fileContent);
      print("Detected delimiter: '$delimiter'"); // Print detected delimiter

      List<List<dynamic>> fields = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n',
      ).convert(fileContent);

      List<Map<String, dynamic>> transactions = [];

      // Start from 1 to skip the header row
      for (var i = 1; i < fields.length; i++) {
        var row = fields[i];
        if (row.length < 3) continue; // Skip if row is too short
        try {
          // Default columns assumed: [0] Date | [1] Description | [2] Amount
          String amountRaw = row[2].toString();

          // Clean the amount string for European/Turkish format (',' as decimal)
          String cleanAmount = amountRaw
              .replaceAll('TL', '')
              .replaceAll('TRY', '')
              .replaceAll(' ', '')
              .replaceAll('.', '') // Remove thousands separator dot
              .replaceAll(',', '.') // Replace comma decimal with dot decimal
              .trim();

          double amount = double.tryParse(cleanAmount) ?? 0.0;
          String type = amount < 0 ? 'Expense' : 'Income';

          transactions.add({
            'date': row[0].toString(),
            'title': row[1].toString(),
            'amount': amount.abs(), // Use absolute value for amount field
            'type': type,
          });
        } catch (e) {
          print("Exception occurred while reading row $i: $e");
          continue;
        }
      }
      return transactions;
    } catch (e) {
      print("Failed to read CSV $e");
      return [];
    }
  }

  // Helper function: Finds the most likely field delimiter
  String _detectDelimiter(String content) {
    if (content.isEmpty) return ';';
    String firstLine = content.split('\n').first;
    int commaCount = firstLine.split(',').length - 1;
    int semiCount = firstLine.split(';').length - 1;
    // Assume semicolon if count is greater or equal (common in non-US CSVs)
    if (semiCount >= commaCount) {
      return ';';
    } else {
      return ',';
    }
  }

// --- 2. EXCEL PARSING ---
  Future<List<Map<String, dynamic>>> _parseExcel(Uint8List bytes) async {
    // Decode Excel file from bytes
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> transactions = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      // Skip the first row (headers)
      for (int i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        try {
          // Default columns assumed: [0] Date, [1] Description, [2] Amount
          var dateVal = row[0]?.value;
          var descVal = row[1]?.value;
          var amountVal = row[2]?.value;

          if (dateVal != null && amountVal != null) {
            transactions.add({
              'date': dateVal.toString(),
              'title': descVal.toString(),
              'amount': double.tryParse(amountVal.toString()) ?? 0.0,
              'type': 'Unknown' // Type determination needs refinement for Excel
            });
          }
        } catch (e) {
          print("Excel exception: $e");
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
