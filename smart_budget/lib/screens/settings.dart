import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool dailyReminders = true;
  @override
  Widget build(BuildContext context) {
    final notif = Provider.of<NotificationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Daily reminders'),
            value: dailyReminders,
            onChanged: (v) {
              setState(() => dailyReminders = v);
              if (v) {
                notif.showSimpleNotification(1, 'Finora hatırlatma',
                    'Bugün harcamalarını kaydetmeyi unutma!');
              }
            },
          ),
          ListTile(
              title: Text('Notification settings'),
              trailing: Icon(Icons.chevron_right)),
          ListTile(
              title: Text('Speech settings (microphone)'),
              trailing: Icon(Icons.chevron_right)),
          ListTile(
              title: Text('About Finora'), subtitle: Text('Version 0.1.0')),
        ],
      ),
    );
  }
}
