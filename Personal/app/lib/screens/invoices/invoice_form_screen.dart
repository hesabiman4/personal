import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/client.dart';
import '../../models/receivable.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../services/database_service.dart';

/// Invoice creation/edit form screen
class InvoiceFormScreen extends StatefulWidget {
  final Receivable? existingInvoice;
  final Client? selectedClient;

  const InvoiceFormScreen({
    super.key,
    this.existingInvoice,
    this.selectedClient,
  });

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  Client? _selectedClient;
  DateTime _issuedOn = DateTime.now();
  DateTime? _dueOn;
  bool _isLoading = false;

  bool get isEditMode => widget.existingInvoice != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode && widget.existingInvoice != null) {
      _loadExistingInvoice(widget.existingInvoice!);
    } else if (widget.selectedClient != null) {
      _selectedClient = widget.selectedClient;
    }
  }

  void _loadExistingInvoice(Receivable invoice) {
    _referenceController.text = invoice.reference;
    _descriptionController.text = invoice.description;
    _amountController.text = Formatters.amountToDecimalString(invoice.amountMinor);
    _issuedOn = invoice.issuedOn;
    _dueOn = invoice.dueOn;
    
    // Find and set client
    final finance = context.read<FinanceProvider>();
    _selectedClient = finance.clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => invoice.clientId.isNotEmpty 
          ? Client(id: invoice.clientId, name: 'Unknown', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Client(id: '', name: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Invoice' : 'Create Invoice'),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Client>(
                      value: _selectedClient,
                      decoration: const InputDecoration(
                        hintText: 'Select client',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: context.watch<FinanceProvider>().clients
                          .where((c) => !c.isArchived)
                          .map((client) => DropdownMenuItem(
                                value: client,
                                child: Text(client.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClient = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a client';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Invoice reference
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Reference *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., INV-2024-001',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt),
                      ),
                      validator: Validators.required,
                    ),
                    const Text(
                      'This will be shown to the client',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Describe the service or product',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: Validators.required,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Amount
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffixText: 'USD',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Issued On *',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(_issuedOn, (date) {
                              setState(() {
                                _issuedOn = date;
                              });
                            }),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(Formatters.formatDate(_issuedOn)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due On',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(_dueOn ?? DateTime.now(), (date) {
                              setState(() {
                                _dueOn = date;
                              });
                            }),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event),
                              ),
                              child: Text(
                                _dueOn != null 
                                    ? Formatters.formatDate(_dueOn!)
                                    : 'Optional',
                                style: TextStyle(
                                  color: _dueOn == null ? Colors.grey : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveInvoice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditMode ? 'Update Invoice' : 'Create Invoice',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(DateTime initialDate, Function(DateTime) onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amountString = _amountController.text.trim();
      final amountMinor = Formatters.decimalStringToAmount(amountString);

      if (isEditMode && widget.existingInvoice != null) {
        // Update existing invoice
        final updatedInvoice = widget.existingInvoice!.copyWith(
          clientId: _selectedClient!.id,
          reference: _referenceController.text.trim(),
          description: _descriptionController.text.trim(),
          amountMinor: amountMinor,
          issuedOn: _issuedOn,
          dueOn: _dueOn,
          updatedAt: DateTime.now(),
        );
        await context.read<FinanceProvider>().updateReceivable(updatedInvoice);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice updated successfully')),
        );
      } else {
        // Create new invoice
        final invoice = Receivable(
          id: DatabaseService.uuid.v4(),
          clientId: _selectedClient!.id,
          reference: _referenceController.text.trim(),
          description: _descriptionController.text.trim(),
          amountMinor: amountMinor,
          issuedOn: _issuedOn,
          dueOn: _dueOn,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await context.read<FinanceProvider>().addReceivable(invoice);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully')),
        );
      }
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice? This cannot be undone.'),
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

    if (confirmed == true && widget.existingInvoice != null) {
      try {
        await context.read<FinanceProvider>().deleteReceivable(widget.existingInvoice!.id);
        Navigator.pop(context);
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
