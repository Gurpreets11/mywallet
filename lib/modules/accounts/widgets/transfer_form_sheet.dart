import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';

/// Bottom sheet to move money between two accounts.
Future<void> showTransferFormSheet(
  BuildContext context, {
  required List<AccountModel> accounts,
  AccountTransferModel? transfer,
  bool duplicate = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TransferFormSheet(
      accounts: accounts,
      transfer: transfer,
      duplicate: duplicate,
    ),
  );
}

class _TransferFormSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final AccountTransferModel? transfer;
  final bool duplicate;
  const _TransferFormSheet({
    required this.accounts,
    this.transfer,
    this.duplicate = false,
  });

  @override
  State<_TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<_TransferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late int _fromId;
  late int _toId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ids = widget.accounts.map((a) => a.id!).toList();
    _fromId = ids.first;
    _toId = ids[1];
    final t = widget.transfer;
    if (t != null) {
      if (ids.contains(t.fromAccountId)) _fromId = t.fromAccountId;
      if (ids.contains(t.toAccountId)) _toId = t.toAccountId;
      _amountController.text = t.amount.toString();
      _notesController.text = t.notes ?? '';
      if (!widget.duplicate) _date = DateTime.tryParse(t.date) ?? _date;
    }
  }

  bool get _isEdit => widget.transfer != null && !widget.duplicate;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_fromId == _toId) {
      SnackbarUtils.showSnackbar(context, 'Choose two different accounts');
      return;
    }
    setState(() => _saving = true);

    final dashboard = context.read<DashboardProvider>();
    final navigator = Navigator.of(context);
    try {
      final model = AccountTransferModel(
        id: _isEdit ? widget.transfer!.id : null,
        fromAccountId: _fromId,
        toAccountId: _toId,
        amount: double.parse(_amountController.text.trim()),
        date: _date.toIso8601String(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _isEdit
            ? widget.transfer!.createdAt
            : AppDateUtils.getCurrentTimestamp(),
      );
      if (_isEdit) {
        await AccountRepository().updateTransfer(model);
      } else {
        await AccountRepository().addTransfer(model);
      }
      await dashboard.loadAccounts();
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarUtils.showSnackbar(context, 'Could not save transfer');
    }
  }

  List<DropdownMenuItem<int>> get _items => [
    for (final a in widget.accounts)
      DropdownMenuItem<int>(
        value: a.id,
        child: Text(a.name, overflow: TextOverflow.ellipsis),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit
                  ? 'Edit transfer'
                  : widget.duplicate
                  ? 'Duplicate transfer'
                  : 'Transfer money',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _fromId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'From'),
              items: _items,
              onChanged: (v) {
                if (v != null) setState(() => _fromId = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _toId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'To'),
              items: _items,
              onChanged: (v) {
                if (v != null) setState(() => _toId = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${CurrencyUtils.symbol} ',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return (n == null || n <= 0)
                    ? 'Enter an amount greater than zero'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(AppDateUtils.formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(_isEdit ? 'Save changes' : 'Transfer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
