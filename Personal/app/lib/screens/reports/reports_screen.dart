import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';

/// Reports screen with income vs expense charts
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month'; // 'week', 'month', 'year', 'all'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadData();
    });
  }

  DateTimeRange _getPeriodRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        return DateTimeRange(
          start: now.subtract(Duration(days: now.weekday - 1)),
          end: now,
        );
      case 'month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      default:
        return DateTimeRange(
          start: DateTime(2000, 1, 1),
          end: now,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodRange = _getPeriodRange();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          if (finance.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = finance.getFilteredTransactions(
            startDate: periodRange.start,
            endDate: periodRange.end,
          );

          final totalIncome = transactions
              .where((t) => t.type == 'income')
              .fold<int>(0, (sum, t) => sum + t.amountMinor);

          final totalExpenses = transactions
              .where((t) => t.type == 'expense')
              .fold<int>(0, (sum, t) => sum + t.amountMinor);

          final balance = totalIncome - totalExpenses;

          // Calculate category breakdown
          final incomeByCategory = _groupByCategory(
            transactions.where((t) => t.type == 'income').toList(),
            finance,
          );
          final expensesByCategory = _groupByCategory(
            transactions.where((t) => t.type == 'expense').toList(),
            finance,
          );

          return RefreshIndicator(
            onRefresh: () => finance.loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCard(
                    context,
                    'Total Income',
                    totalIncome,
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    context,
                    'Total Expenses',
                    totalExpenses,
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    context,
                    'Net Balance',
                    balance,
                    balance >= 0 ? Colors.blue : Colors.orange,
                    Icons.account_balance_wallet,
                  ),

                  const SizedBox(height: 24),

                  // Income Breakdown
                  if (incomeByCategory.isNotEmpty) ...[
                    const Text(
                      'Income by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBreakdown(incomeByCategory, totalIncome),
                    const SizedBox(height: 24),
                  ],

                  // Expense Breakdown
                  if (expensesByCategory.isNotEmpty) ...[
                    const Text(
                      'Expenses by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBreakdown(expensesByCategory, totalExpenses),
                    const SizedBox(height: 24),
                  ],

                  // Recent Activity Summary
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentActivity(transactions.take(5).toList(), finance),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    int amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(amount, 'USD'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    Map<String, int> categoryAmounts,
    int total,
  ) {
    final sortedCategories = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: sortedCategories.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(entry.value, 'USD'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Transaction> transactions, FinanceProvider finance) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No recent transactions',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final category = finance.getCategoryById(transaction.categoryId);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction.type == 'income'
                  ? Colors.green[100]
                  : Colors.red[100],
              child: Icon(
                _getIconForCategory(category?.iconKey),
                size: 20,
                color: transaction.type == 'income' ? Colors.green : Colors.red,
              ),
            ),
            title: Text(category?.name ?? 'Unknown'),
            subtitle: Text(Formatters.formatDate(transaction.occurredOn)),
            trailing: Text(
              transaction.type == 'income'
                  ? '+${Formatters.formatCurrency(transaction.amountMinor, 'USD')}'
                  : '-${Formatters.formatCurrency(transaction.amountMinor, 'USD')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.type == 'income' ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, int> _groupByCategory(List<Transaction> transactions, FinanceProvider finance) {
    final Map<String, int> result = {};
    for (final transaction in transactions) {
      final category = finance.getCategoryById(transaction.categoryId);
      final categoryName = category?.name ?? 'Unknown';
      result[categoryName] = (result[categoryName] ?? 0) + transaction.amountMinor;
    }
    return result;
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
