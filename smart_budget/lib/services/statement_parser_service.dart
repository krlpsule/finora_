import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // PDF paketi

enum FileTypeOption { csv, excel, pdf }

class StatementParserService {
  
  // Main func: calls related parser accordingly the choice of user
  Future<List<Map<String, dynamic>>> pickAndParseFile(FileTypeOption type) async {
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
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      if (type == FileTypeOption.csv) {
        return await _parseCSV(file);
      } else if (type == FileTypeOption.excel) {
        return await _parseExcel(file);
      } else {
        return await _parsePDF(file);
      }
    }
    return [];
  }
// --- 1. CSV PARSING ---
  Future<List<Map<String, dynamic>>> _parseCSV(File file) async {
    try {
      // 1. read file as text
      String fileContent = await file.readAsString();
      
      // 2. Find Delimiter
      String delimiter = _detectDelimiter(fileContent);
      print("Tespit edilen ayırıcı: '$delimiter'"); // To see in console

      // 3. turn into list
      List<List<dynamic>> fields = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n',).convert(fileContent);
    
    List<Map<String, dynamic>> transactions = [];

    for (var i = 1; i < fields.length; i++) {
      var row = fields[i];
      if (row.length < 3) continue;
      try {
        // 1. Column Matching
        // Default: [0] Date | [1] Description | [2] Amount
        String dateRaw = row[0].toString(); 
        String descRaw = row[1].toString();
        String amountRaw = row[2].toString();

        // 2. String -> Double 
        // Turkish format: "1.250,50 TL" or "-500,00"
        // Code format: 1250.50 or -500.0
        String cleanAmount = amountRaw
            .replaceAll('TL', '')      
            .replaceAll('TRY', '')     
            .replaceAll(' ', '')       
            .replaceAll('.', '')       
            .replaceAll(',', '.')      
            .trim();

        double amount = double.tryParse(cleanAmount) ?? 0.0;

        // 3. Expense- Income
        String type = amount < 0 ? 'Gider' : 'Gelir';
      
        // 4. Add Data to List
        transactions.add({
          'date': dateRaw,           
          'title': descRaw,          
          'amount': amount.abs(),    
          'type': type,              
        });

      } catch (e) {
        print("Exception occured while reading: $i , $e");
        continue;
      }
    }
    
    return transactions;
      
    } catch (e) {
      print("Failed to read CSV $e");
      return [];
    }
  }

  // Helper function: find delimeter
  String _detectDelimiter(String content) {
    if (content.isEmpty) return ';';
    String firstLine = content.split('\n').first;
    int commaCount = firstLine.split(',').length - 1;
    int semiCount = firstLine.split(';').length - 1;
    if (semiCount >= commaCount) {
      return ';'; 
    } else {
      return ',';
    }
  }

  // --- 2. EXCEL PARSING ---
  Future<List<Map<String, dynamic>>> _parseExcel(File file) async {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> transactions = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      for (int i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        try {
          // Deafult: [0] Date, [1] Description, [2] Amount
          var dateVal = row[0]?.value;
          var descVal = row[1]?.value;
          var amountVal = row[2]?.value;

          if (dateVal != null && amountVal != null) {
            transactions.add({
              'date': dateVal.toString(),
              'title': descVal.toString(),
              'amount': double.tryParse(amountVal.toString()) ?? 0.0,
              'type': 'Unknown' 
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
  Future<List<Map<String, dynamic>>> _parsePDF(File file) async {
    // Extracting text from PDF
    final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
    String text = PdfTextExtractor(document).extractText();
    document.dispose();

    List<Map<String, dynamic>> transactions = [];
    List<String> lines = text.split('\n');

    // Default Regex: "10/10/2023 MARKET HARCAMASI 150,00 TL" 
    RegExp exp = RegExp(r'(\d{2}/\d{2}/\d{4})\s+(.+?)\s+(\d+[.,]\d{2})');

    for (String line in lines) {
      var match = exp.firstMatch(line);
      if (match != null) {
        String date = match.group(1)!;
        String desc = match.group(2)!;
        String amountStr = match.group(3)!;
        double amount = double.parse(amountStr.replaceAll('.', '').replaceAll(',', '.'));

        transactions.add({
          'date': date,
          'title': desc.trim(),
          'amount': amount,
          'type': 'Expences'
        });
      }
    }
    
    return transactions;
  }
}
