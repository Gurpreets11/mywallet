import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';

/// Bottom sheet to create ([account] == null) or edit an account.
Future<void> showAccountFormSheet(
  BuildContext context, {
  AccountModel? account,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AccountFormSheet(account: account),
  );
}

class _AccountFormSheet extends StatefulWidget {
  final AccountModel? account;
  const _AccountFormSheet({this.account});

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late AccountType _type;
  bool _saving = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameController = TextEditingController(text: a?.name ?? '');
    final opening = a?.openingBalance ?? 0;
    _balanceController = TextEditingController(
      text: a == null || opening == 0
          ? ''
          : (opening == opening.roundToDouble()
                ? opening.toStringAsFixed(0)
                : opening.toString()),
    );
    _type = a?.type ?? AccountType.bank;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = AccountRepository();
    final dashboard = context.read<DashboardProvider>();
    final messenger = Navigator.of(context);
    final opening = double.tryParse(_balanceController.text.trim()) ?? 0;

    try {
      if (_isEdit) {
        await repo.updateAccount(
          AccountModel(
            id: widget.account!.id,
            name: _nameController.text.trim(),
            type: _type,
            openingBalance: opening,
            isDefault: widget.account!.isDefault,
            createdAt: widget.account!.createdAt,
          ),
        );
      } else {
        await repo.addAccount(
          AccountModel(
            name: _nameController.text.trim(),
            type: _type,
            openingBalance: opening,
            createdAt: AppDateUtils.getCurrentTimestamp(),
          ),
        );
      }
      await dashboard.loadAccounts();
      messenger.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarUtils.showSnackbar(context, 'Could not save account');
    }
  }

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
              _isEdit ? 'Edit account' : 'New account',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'e.g. HDFC Savings',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in AccountType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 18),
                        const SizedBox(width: 10),
                        Text(t.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Opening balance',
                prefixText: '₹ ',
                helperText:
                    'What this account holds right now (use a minus sign for a card you owe on)',
                helperMaxLines: 2,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null; // empty = 0
                return double.tryParse(t) == null ? 'Enter a valid amount' : null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_isEdit ? 'Update account' : 'Add account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
