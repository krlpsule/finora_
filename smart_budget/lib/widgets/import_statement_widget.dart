import 'package:flutter/material.dart';
import 'finora_/smart_budget/lib/services/statement_parser_service.dart'; 

class ImportStatementWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onDataLoaded;

  const ImportStatementWidget({Key? key, required this.onDataLoaded}) : super(key: key);

  @override
  State<ImportStatementWidget> createState() => _ImportStatementWidgetState();
}

class _ImportStatementWidgetState extends State<ImportStatementWidget> {
  final StatementParserService _service = StatementParserService();
  bool _isLoading = false;
  // Bottom Sheet
  void _showSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select the format",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              SizedBox(height: 10),
              Text("Please select the type of your file before you upload :", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 20),
              
              // Excel 
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: Icon(Icons.table_view, color: Colors.green)),
                title: Text("Excel Spreadsheet (.xlsx)"),
                onTap: () => _processFile(FileTypeOption.excel, ctx),
              ),
              
              // CSV 
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: Icon(Icons.list_alt, color: Colors.blue)),
                title: Text("CSV File (.csv)"),
                onTap: () => _processFile(FileTypeOption.csv, ctx),
              ),

              // PDF 
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red.shade100, child: Icon(Icons.picture_as_pdf, color: Colors.red)),
                title: Text("PDF file (.pdf)"),
                onTap: () => _processFile(FileTypeOption.pdf, ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processFile(FileTypeOption type, BuildContext sheetContext) async {
    Navigator.pop(sheetContext); 
    setState(() => _isLoading = true);

    try {
      final data = await _service.pickAndParseFile(type);
      
      if (data.isNotEmpty) {
        widget.onDataLoaded(data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${data.length} adet işlem başarıyla yüklendi!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Did not select file or file is empty
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Can not read the file. $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
      : IconButton(
          onPressed: () => _showSelectionSheet(context),
          icon: Icon(Icons.upload_file, size: 28),
          tooltip: "Ekstre Yükle",
        );
  }
}
