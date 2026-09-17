import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Your Name'),
                  subtitle: Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return Text(settings.ownerName ?? 'Not set');
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showNameDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return Text(settings.ownerEmail ?? 'Not set');
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showEmailDialog(context);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appearance Section
          const Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Theme'),
                      subtitle: Text(_getThemeName(settings.themeMode)),
                      trailing: DropdownButton<ThemeMode>(
                        value: settings.themeMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            settings.setThemeMode(value);
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data Section
          const Text(
            'Data & Export',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export to CSV'),
                  subtitle: const Text('Download your financial data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement CSV export
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV export coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Permanently delete all transactions and clients'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () {
                    _showClearDataConfirmation(context);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Version'),
                  subtitle: Text(AppConstants.appVersion),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Storage'),
                  subtitle: const Text('All data stored locally on this device'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showNameDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Your Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<SettingsProvider>().setOwnerName(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SettingsProvider>().setOwnerEmail(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all transactions, clients, and invoices. '
          'This action cannot be undone.\n\n'
          'Default accounts and categories will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement clear data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clear data coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
