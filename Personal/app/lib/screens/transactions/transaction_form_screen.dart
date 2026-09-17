import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/transaction.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

/// Transaction form screen for adding/editing income or expense
class TransactionFormScreen extends StatefulWidget {
  final TransactionType type;
  final Transaction? transaction; // Optional transaction for edit mode

  const TransactionFormScreen({super.key, required this.type, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedClientId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadData();
      
      // If editing, populate form with existing transaction data
      if (widget.transaction != null) {
        final t = widget.transaction!;
        _amountController.text = (t.amountMinor / 100).toStringAsFixed(2);
        _noteController.text = t.note ?? '';
        _selectedAccountId = t.accountId;
        _selectedCategoryId = t.categoryId;
        _selectedClientId = t.clientId;
        _selectedDate = t.occurredOn;
        // Parse time if available
        if (t.occurredTime.isNotEmpty) {
          final parts = t.occurredTime.split(':');
          if (parts.length == 2) {
            _selectedTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final isEditMode = widget.transaction != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? (isIncome ? 'Edit Income' : 'Edit Expense') : (isIncome ? 'Add Income' : 'Add Expense')),
        backgroundColor: isIncome ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          if (_selectedAccountId == null && finance.accounts.isNotEmpty) {
            _selectedAccountId = finance.accounts.first.id;
          }
          
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Amount display
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    color: isIncome ? Colors.green[50] : Colors.red[50],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${Formatters.formatCurrency((_amountController.text.isEmpty ? 0 : double.tryParse(_amountController.text) ?? 0) * 100, 'USD').replaceAll('\\$', '')}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Numeric keypad
                Expanded(
                  flex: 3,
                  child: _buildNumericKeypad(),
                ),
                
                // Details section
                Expanded(
                  flex: 2,
                  child: _buildDetailsSection(finance),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        String label;
        VoidCallback? onTap;
        
        if (index < 9) {
          label = '${index + 1}';
          onTap = () => _appendDigit(label);
        } else if (index == 9) {
          label = '0';
          onTap = () => _appendDigit('0');
        } else if (index == 10) {
          label = '.';
          onTap = () => _appendDecimal();
        } else {
          label = '⌫';
          onTap = _deleteLastChar;
        }
        
        return ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 2,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildDetailsSection(FinanceProvider finance) {
    final isIncome = widget.type == TransactionType.income;
    final categories = isIncome ? finance.incomeCategories : finance.expenseCategories;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date selector
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(Formatters.formatDate(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Account selector
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: finance.accounts.map((account) {
                  return DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Category selector
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.category),
                ),
                hint: const Text('Select a category'),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(_getIconForCategory(category.iconKey), size: 20),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Note field
          Card(
            child: TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.note),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 2,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Client selector (optional)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedClientId,
                decoration: const InputDecoration(
                  labelText: 'Client (optional)',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.person),
                ),
                hint: const Text('No client'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No client'),
                  ),
                  ...finance.clients.map((client) {
                    return DropdownMenuItem(
                      value: client.id,
                      child: Text(client.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedClientId = value;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Transaction'),
          ),
        ],
      ),
    );
  }

  void _appendDigit(String digit) {
    setState(() {
      _amountController.text += digit;
    });
  }

  void _appendDecimal() {
    final text = _amountController.text;
    // Only allow one decimal point and max 2 decimal places
    if (!text.contains('.') && !text.endsWith('.')) {
      setState(() {
        _amountController.text += '.';
      });
    } else if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length == 2 && parts[1].length < 2) {
        // Append the decimal that was already pressed
        setState(() {
          // Don't append anything extra, just keep the decimal
        });
      }
    }
  }

  void _deleteLastChar() {
    setState(() {
      if (_amountController.text.isNotEmpty) {
        _amountController.text = 
            _amountController.text.substring(0, _amountController.text.length - 1);
      }
    });
  }

  Future<void> _saveTransaction() async {
    // Validate amount
    final amountText = _amountController.text;
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Validate required fields
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final amount = double.parse(amountText);
      final amountMinor = (amount * 100).round();

      final isEditMode = widget.transaction != null;
      final transaction = Transaction(
        id: isEditMode ? widget.transaction!.id : '', // Keep existing ID when editing
        type: widget.type == TransactionType.income ? 'income' : 'expense',
        amountMinor: amountMinor,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId!,
        occurredOn: _selectedDate,
        occurredTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        note: _noteController.text.isEmpty ? null : _noteController.text,
        clientId: _selectedClientId,
        createdAt: isEditMode ? widget.transaction!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isEditMode) {
        await context.read<FinanceProvider>().updateTransaction(transaction);
      } else {
        await context.read<FinanceProvider>().addTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode 
                ? 'Transaction updated successfully!'
                : '${widget.type == TransactionType.income ? 'Income' : 'Expense'} added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
