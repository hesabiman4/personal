import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/client.dart';
import '../../utils/formatters.dart';

/// Client details screen showing client info, invoices, and payments
class ClientDetailsScreen extends StatefulWidget {
  final Client client;
  
  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditClientDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archive') {
                _toggleArchiveStatus();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Archive'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Invoices'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
          ],
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(finance),
              _buildInvoicesTab(finance),
              _buildPaymentsTab(finance),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInvoiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildInfoTab(FinanceProvider finance) {
    final client = widget.client;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client avatar and name
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: Text(
              client.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (client.serviceDescription != null && client.serviceDescription!.isNotEmpty)
            Center(
              child: Text(
                client.serviceDescription!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 24),
          
          // Contact information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (client.phone != null) ...[
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone'),
                      subtitle: Text(client.phone!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                  ],
                  if (client.email != null) ...[
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(client.email!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Added On'),
                    subtitle: Text(Formatters.formatDate(client.createdAt)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status badge
          Row(
            children: [
              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: client.isArchived ? Colors.grey[200] : Colors.green[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  client.isArchived ? 'Archived' : 'Active',
                  style: TextStyle(
                    color: client.isArchived ? Colors.grey : Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(FinanceProvider finance) {
    // Filter receivables for this client
    final clientInvoices = finance.receivables
        .where((r) => r.clientId == widget.client.id)
        .toList();
    
    if (clientInvoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No invoices yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateInvoiceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Invoice'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: clientInvoices.length,
      itemBuilder: (context, index) {
        final invoice = clientInvoices[index];
        final isPaid = invoice.amountDueMinor <= 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPaid ? Colors.green[100] : Colors.orange[100],
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: isPaid ? Colors.green : Colors.orange,
              ),
            ),
            title: Text('Invoice #${invoice.id.substring(0, 8)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Due: ${invoice.dueOn != null ? Formatters.formatDate(invoice.dueOn!) : 'N/A'}'),
                Text(
                  'Amount: ${Formatters.formatCurrency(invoice.amountTotalMinor, 'USD')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isPaid)
                  const Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                else
                  Text(
                    'Due: ${Formatters.formatCurrency(invoice.amountDueMinor, 'USD')}',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            onTap: () {
              // Navigate to invoice details
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(FinanceProvider finance) {
    // Filter transactions for this client
    final clientTransactions = finance.transactions
        .where((t) => t.clientId == widget.client.id)
        .toList();
    
    if (clientTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payments recorded',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: clientTransactions.length,
      itemBuilder: (context, index) {
        final transaction = clientTransactions[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction.type == 'income' ? Colors.green[100] : Colors.red[100],
              child: Icon(
                transaction.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                color: transaction.type == 'income' ? Colors.green : Colors.red,
              ),
            ),
            title: Text(transaction.type == 'income' ? 'Payment Received' : 'Refund'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${Formatters.formatDate(transaction.occurredOn)}'),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  Text(transaction.note!),
              ],
            ),
            trailing: Text(
              transaction.type == 'income'
                  ? '+${Formatters.formatCurrency(transaction.amountMinor, 'USD')}'
                  : '-${Formatters.formatCurrency(transaction.amountMinor, 'USD')}',
              style: TextStyle(
                color: transaction.type == 'income' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCreateInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Invoice'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invoice creation form - Coming soon'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog() {
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

  void _toggleArchiveStatus() {
    // Toggle archive logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.client.isArchived ? 'Client unarchived' : 'Client archived'),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${widget.client.name}? This cannot be undone.'),
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client deleted')),
      );
    }
  }
}
