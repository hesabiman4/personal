import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/finance_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'transaction_form_screen.dart';

/// Transactions list screen with search and filters
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedTypeFilter;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          if (finance.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = _getFilteredTransactions(finance);

          if (transactions.isEmpty) {
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
                    'No transactions found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionFormScreen(
                            type: TransactionType.income,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add your first transaction'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => finance.loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final category = finance.getCategoryById(transaction.categoryId);
                final account = finance.getAccountById(transaction.accountId);
                final client = finance.getClientById(transaction.clientId ?? '');

                return Dismissible(
                  key: Key(transaction.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.blue,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      return await _confirmDelete(context);
                    }
                    return true;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      finance.deleteTransaction(transaction.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    } else {
                      // Edit action - navigate to edit form
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionFormScreen(
                            type: transaction.type == 'income' ? TransactionType.income : TransactionType.expense,
                            transaction: transaction,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction.type == 'income'
                            ? Colors.green[100]
                            : Colors.red[100],
                        child: Icon(
                          _getIconForCategory(category?.iconKey),
                          color: transaction.type == 'income'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      title: Text(
                        category?.name ?? 'Unknown Category',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(account?.name ?? ''),
                          if (client != null)
                            Text(
                              'Client: ${client.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (transaction.note != null && transaction.note!.isNotEmpty)
                            Text(
                              transaction.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            transaction.type == 'income'
                                ? '+${Formatters.formatCurrency(transaction.amountMinor, 'USD')}'
                                : '-${Formatters.formatCurrency(transaction.amountMinor, 'USD')}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: transaction.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            Formatters.formatDate(transaction.occurredOn),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(FinanceProvider finance) {
    return finance.getFilteredTransactions(
      type: _selectedTypeFilter,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filter Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Type filter
                DropdownButtonFormField<String>(
                  value: _selectedTypeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('All Types'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTypeFilter = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Account filter
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('All Accounts'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Accounts')),
                    ...finance.accounts.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Category filter
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('All Categories'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ...finance.incomeCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text('📈 ${category.name}'),
                      );
                    }),
                    ...finance.expenseCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text('📉 ${category.name}'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Date range filter
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 30)),
                            end: DateTime.now(),
                          ),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                  child: Text(
                    _selectedDateRange != null
                        ? '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}'
                        : 'Select Date Range',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Clear filters button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTypeFilter = null;
                      _selectedAccountId = null;
                      _selectedCategoryId = null;
                      _selectedDateRange = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All Filters'),
                ),
                
                const SizedBox(height: 8),
                
                // Apply button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
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
        ) ??
        false;
  }

  IconData _getIconForCategory(String? iconKey) {
    switch (iconKey) {
      case 'work':
        return Icons.work;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.attach_money;
    }
  }
}
