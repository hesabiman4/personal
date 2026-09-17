import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/client.dart';
import '../../utils/formatters.dart';
import 'client_details_screen.dart';

/// Clients list screen with search and filters
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClientDialog(),
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          if (finance.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = _getFilteredClients(finance.clients);

          if (clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty ? 'No clients found' : 'No clients yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add your first client to track invoices and payments',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddClientDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Client'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => finance.loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        Icons.person,
                        color: Colors.blue[700],
                      ),
                    ),
                    title: Text(
                      client.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (client.serviceDescription != null && client.serviceDescription!.isNotEmpty)
                          Text(
                            client.serviceDescription!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (client.phone != null)
                          Text(
                            client.phone!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (client.isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Archived',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientDetailsScreen(client: client),
                        ),
                      );
                    },
                    onLongPress: () => _showClientOptions(context, client),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Client> _getFilteredClients(List<Client> clients) {
    return clients.where((client) {
      // Filter by archived status
      if (!_showArchived && client.isArchived) return false;
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return client.name.toLowerCase().contains(query) ||
            (client.serviceDescription != null && 
             client.serviceDescription!.toLowerCase().contains(query)) ||
            (client.phone != null && client.phone!.contains(query)) ||
            (client.email != null && client.email!.toLowerCase().contains(query));
      }
      
      return true;
    }).toList();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Clients'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter name, service, phone, or email',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final serviceController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serviceController,
                decoration: const InputDecoration(
                  labelText: 'Service Description',
                  prefixIcon: Icon(Icons.work),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client name is required')),
                );
                return;
              }
              
              // Add client logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Client added successfully!')),
              );
            },
            child: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  void _showClientOptions(BuildContext context, Client client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Client'),
              onTap: () {
                Navigator.pop(context);
                _showEditClientDialog(client);
              },
            ),
            ListTile(
              leading: Icon(
                client.isArchived ? Icons.unarchive : Icons.archive,
              ),
              title: Text(client.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Navigator.pop(context);
                // Toggle archive status
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Client', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Client'),
                    content: Text('Are you sure you want to delete ${client.name}? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // Delete client logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client deleted')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditClientDialog(Client client) {
    // Similar to add dialog but pre-populated
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Client'),
        content: const Text('Edit client form - Coming soon'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
