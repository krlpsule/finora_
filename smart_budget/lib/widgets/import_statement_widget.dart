// lib/widgets/import_statement_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/statement_parser_service.dart'; 
import '../models/transaction_model.dart'; 
import '../features/transaction/transaction_bloc.dart'; 
import '../features/transaction/transaction_event.dart'; 

class ImportStatementWidget extends StatefulWidget {
  // CRITICAL: Removed the onDataLoaded callback. 
  // Data is now sent directly to TransactionBloc.
  const ImportStatementWidget({Key? key}) : super(key: key); 

  @override
  State<ImportStatementWidget> createState() => _ImportStatementWidgetState();
}

class _ImportStatementWidgetState extends State<ImportStatementWidget> {
  final StatementParserService _service = StatementParserService();
  bool _isLoading = false;

  // Shows the modal sheet for file type selection
  void _showSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select the format",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 10),
              const Text("Please select the type of your file before you upload:", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              
              // Excel Option
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.table_view, color: Colors.green)),
                title: const Text("Excel Spreadsheet (.xlsx)"),
                onTap: () => _processFile(FileTypeOption.excel, ctx),
              ),
              
              // CSV Option
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.list_alt, color: Colors.blue)),
                title: const Text("CSV File (.csv)"),
                onTap: () => _processFile(FileTypeOption.csv, ctx),
              ),

              // PDF Option
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red.shade100, child: const Icon(Icons.picture_as_pdf, color: Colors.red)),
                title: const Text("PDF file (.pdf)"),
                onTap: () => _processFile(FileTypeOption.pdf, ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  // Handles file selection, parsing, and sending data to the BLoC
  Future<void> _processFile(FileTypeOption type, BuildContext sheetContext) async {
    // Close the bottom sheet immediately
    Navigator.pop(sheetContext); 
    setState(() => _isLoading = true);

    // Get access to the Transaction BLoC
    final transactionBloc = context.read<TransactionBloc>();

    try {
      // Delegate file picking and parsing to the Service
      final data = await _service.pickAndParseFile(type);
      
      if (data.isNotEmpty) {
        int successCount = 0;
        
        // 🚨 CRITICAL STEP: Iterate through the parsed Map list and send to BLoC
        for (var map in data) {
          try {
            // Convert Map data received from parser to a TransactionModel
            // NOTE: This requires TransactionModel.fromMapForImport(map) to exist.
            final newTransaction = TransactionModel.fromMapForImport(map); 
            
            // Send the new transaction to Firebase via BLoC
            transactionBloc.add(AddTransactionEvent(newTransaction));
            successCount++;
            
          } catch (e) {
            print("Error processing single imported transaction: $e");
            // Skip transactions that failed model conversion
          }
        }

        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$successCount transactions successfully loaded to Firebase!"),
            backgroundColor: Colors.green,
          ),
        );
        
      } else {
        // Feedback if parsing failed or file was empty
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error: File is empty or parsing failed. Please check the file format or columns."),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      // Global error handling (e.g., FilePicker cancelled, or FileBytes error)
      print("CRITICAL FILE PARSING ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Critical Error: Could not process file. $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
      : IconButton(
          onPressed: () => _showSelectionSheet(context),
          icon: const Icon(Icons.upload_file, size: 28),
          tooltip: "Import Statement",
        );
  }
}