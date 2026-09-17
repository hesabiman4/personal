import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/formatters.dart';
import '../transactions/transaction_form_screen.dart';
import '../clients/client_details_screen.dart';
import '../invoices/invoices_screen.dart';

/// Home screen showing balance overview, quick actions, and recent activity
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return Text(settings.getPersonalizedGreeting());
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<FinanceProvider>().loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              _buildBalanceCard(),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // Outstanding Clients
              _buildOutstandingClientsSection(),
              
              const SizedBox(height: 24),
              
              // Recent Transactions
              _buildRecentTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer2<FinanceProvider, SettingsProvider>(
      builder: (context, finance, settings, _) {
        final balance = finance.currentBalance;
        final currencyCode = settings.currencyCode;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        settings.isBalanceVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => settings.toggleBalanceVisibility(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  settings.isBalanceVisible
                      ? Formatters.formatCurrency(balance, currencyCode)
                      : '••••••',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: settings.isBalanceVisible
                        ? (balance >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.red)
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // 30-day comparison would go here
                // TODO: Implement balance comparison
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
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
            icon: const Icon(Icons.arrow_downward),
            label: const Text('Add Income'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionFormScreen(
                    type: TransactionType.expense,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingClientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Who Owes You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InvoicesScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<FinanceProvider>(
          builder: (context, finance, _) {
            // Calculate outstanding amounts from receivables
            final outstandingList = finance.receivables.map((r) {
              // Calculate total paid from transactions linked to this receivable
              final paidTransactions = finance.transactions
                  .where((t) => t.receivableId == r.id && t.type == 'income')
                  .toList();
              final totalPaidMinor = paidTransactions.fold<int>(
                0,
                (sum, t) => sum + t.amountMinor,
              );
              final outstanding = r.amountMinor - totalPaidMinor;
              
              if (outstanding <= 0) return null;
              
              return {
                'client_id': r.clientId,
                'name': finance.getClientById(r.clientId)?.name ?? 'Unknown',
                'outstanding': outstanding,
                'due_on': r.dueOn,
              };
            }).where((item) => item != null).cast<Map<String, dynamic>>().toList();

            // Group by client and sum outstanding amounts
            final clientMap = <String, Map<String, dynamic>>{};
            for (var item in outstandingList) {
              final clientId = item['client_id'] as String;
              if (clientMap.containsKey(clientId)) {
                clientMap[clientId]!['outstanding'] = 
                    (clientMap[clientId]!['outstanding'] as int) + (item['outstanding'] as int);
                // Keep earliest due date
                if (item['due_on'] != null) {
                  final existingDue = clientMap[clientId]!['due_on'] as DateTime?;
                  if (existingDue == null || (item['due_on'] as DateTime).isBefore(existingDue)) {
                    clientMap[clientId]!['due_on'] = item['due_on'];
                  }
                }
              } else {
                clientMap[clientId] = item;
              }
            }
            
            final clients = clientMap.values.toList();
            clients.sort((a, b) {
              final aDue = a['due_on'] as DateTime?;
              final bDue = b['due_on'] as DateTime?;
              if (aDue == null && bDue == null) return 0;
              if (aDue == null) return 1;
              if (bDue == null) return -1;
              return aDue.compareTo(bDue);
            });
            
            if (clients.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No outstanding payments',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }
            
            return Column(
              children: clients.take(5).map((client) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        Formatters.getInitials(client['name'] as String),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(client['name'] as String),
                    subtitle: Text(
                      'Due: ${Formatters.formatCurrency(client['outstanding'] as int, 'USD')}',
                    ),
                    trailing: client['due_on'] != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Due ${Formatters.formatRelativeDate(client['due_on'] as DateTime)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      // Navigate to client details
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to transactions screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<FinanceProvider>(
          builder: (context, finance, _) {
            final transactions = finance.getRecentTransactions(limit: 5);
            
            if (transactions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }
            
            return Column(
              children: transactions.map((transaction) {
                final category = finance.getCategoryById(transaction.categoryId);
                final account = finance.getAccountById(transaction.accountId);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
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
                    title: Text(category?.name ?? 'Unknown'),
                    subtitle: Text(account?.name ?? ''),
                    trailing: Text(
                      transaction.type == 'income'
                          ? '+${Formatters.formatNumber(transaction.amountMinor / 100.0)}'
                          : '-${Formatters.formatNumber(transaction.amountMinor / 100.0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.type == 'income'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
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
