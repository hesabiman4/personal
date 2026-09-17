import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/receivable.dart';
import '../../models/client.dart';
import '../../utils/formatters.dart';
import 'invoice_form_screen.dart';

/// Invoices list screen showing all receivables
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _filterStatus = 'all'; // all, unpaid, partially_paid, paid, overdue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Invoices'),
              ),
              const PopupMenuItem(
                value: 'unpaid',
                child: Text('Unpaid'),
              ),
              const PopupMenuItem(
                value: 'partially_paid',
                child: Text('Partially Paid'),
              ),
              const PopupMenuItem(
                value: 'paid',
                child: Text('Paid'),
              ),
              const PopupMenuItem(
                value: 'overdue',
                child: Text('Overdue'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          if (finance.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get summaries for all receivables
          final summaries = finance.receivables.map((r) {
            // Calculate total paid from transactions linked to this receivable
            final paidTransactions = finance.transactions
                .where((t) => t.receivableId == r.id && t.type == 'income')
                .toList();
            final totalPaidMinor = paidTransactions.fold<int>(
              0,
              (sum, t) => sum + t.amountMinor,
            );
            return ReceivableSummary.calculate(
              receivable: r,
              totalPaidMinor: totalPaidMinor,
            );
          }).toList();

          // Filter based on status
          var filteredSummaries = summaries;
          if (_filterStatus == 'unpaid') {
            filteredSummaries = summaries.where((s) => s.isUnpaid).toList();
          } else if (_filterStatus == 'partially_paid') {
            filteredSummaries = summaries.where((s) => s.isPartiallyPaid).toList();
          } else if (_filterStatus == 'paid') {
            filteredSummaries = summaries.where((s) => s.isFullyPaid).toList();
          } else if (_filterStatus == 'overdue') {
            filteredSummaries = summaries.where((s) => s.receivable.isOverdue && !s.isFullyPaid).toList();
          }

          // Sort by due date (overdue first, then by due date)
          filteredSummaries.sort((a, b) {
            if (a.receivable.isOverdue && !b.receivable.isOverdue) return -1;
            if (!a.receivable.isOverdue && b.receivable.isOverdue) return 1;
            if (a.receivable.dueOn == null && b.receivable.dueOn != null) return 1;
            if (a.receivable.dueOn != null && b.receivable.dueOn == null) return -1;
            if (a.receivable.dueOn == null && b.receivable.dueOn == null) return 0;
            return a.receivable.dueOn!.compareTo(b.receivable.dueOn!);
          });

          if (filteredSummaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyStateMessage(),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateInvoice(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Invoice'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => finance.loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredSummaries.length,
              itemBuilder: (context, index) {
                final summary = filteredSummaries[index];
                final invoice = summary.receivable;
                
                // Get client name
                final client = finance.getClientById(invoice.clientId);
                final clientName = client?.name ?? 'Unknown Client';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(summary).withOpacity(0.2),
                      child: Icon(
                        _getStatusIcon(summary),
                        color: _getStatusColor(summary),
                      ),
                    ),
                    title: Text(
                      invoice.reference,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clientName),
                        Text(
                          'Due: ${invoice.dueOn != null ? Formatters.formatDate(invoice.dueOn!) : 'No due date'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: invoice.isOverdue && !summary.isFullyPaid
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        if (summary.isPartiallyPaid) ...[
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: summary.paymentPercentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(summary),
                            ),
                          ),
                          Text(
                            '${summary.paymentPercentage.toStringAsFixed(0)}% paid',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(invoice.amountTotalMinor, 'USD'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (!summary.isFullyPaid)
                          Text(
                            'Due: ${Formatters.formatCurrency(summary.outstandingMinor, 'USD')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(summary),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (summary.isFullyPaid)
                          const Text(
                            'PAID',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => _navigateToInvoiceDetails(invoice),
                    onLongPress: () => _showInvoiceOptions(summary),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateInvoice(),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (_filterStatus) {
      case 'unpaid':
        return 'No unpaid invoices';
      case 'partially_paid':
        return 'No partially paid invoices';
      case 'paid':
        return 'No paid invoices';
      case 'overdue':
        return 'No overdue invoices';
      default:
        return 'No invoices yet';
    }
  }

  Color _getStatusColor(ReceivableSummary summary) {
    if (summary.isFullyPaid) return Colors.green;
    if (summary.receivable.isOverdue) return Colors.red;
    if (summary.isPartiallyPaid) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon(ReceivableSummary summary) {
    if (summary.isFullyPaid) return Icons.check_circle;
    if (summary.receivable.isOverdue) return Icons.warning;
    if (summary.isPartiallyPaid) return Icons.pending;
    return Icons.receipt_long;
  }

  void _navigateToCreateInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InvoiceFormScreen(),
      ),
    );
  }

  void _navigateToInvoiceDetails(Receivable invoice) {
    // Navigate to invoice details screen (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invoice details for ${invoice.reference}')),
    );
  }

  void _showInvoiceOptions(ReceivableSummary summary) {
    final invoice = summary.receivable;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Invoice'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceFormScreen(existingInvoice: invoice),
                  ),
                );
              },
            ),
            if (!summary.isFullyPaid)
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Record Payment'),
                onTap: () {
                  Navigator.pop(context);
                  _recordPayment(invoice);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Invoice', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(invoice);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _recordPayment(Receivable invoice) {
    // Navigate to payment recording screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Record payment for ${invoice.reference}')),
    );
  }

  Future<void> _confirmDelete(Receivable invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice ${invoice.reference}? This cannot be undone.'),
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
      try {
        await context.read<FinanceProvider>().deleteReceivable(invoice.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
