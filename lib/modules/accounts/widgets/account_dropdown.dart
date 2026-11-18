import 'package:flutter/material.dart';

import '../models/account_model.dart';
import '../repositories/account_repository.dart';

/// "Account" picker used on the expense, income, loan EMI and investment
/// forms. It loads the accounts itself, and when [value] is empty (new entry,
/// or an old entry created before accounts existed) it selects the default
/// account and reports it through [onChanged].
class AccountDropdown extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;

  const AccountDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Account',
  });

  @override
  State<AccountDropdown> createState() => _AccountDropdownState();
}

class _AccountDropdownState extends State<AccountDropdown> {
  List<AccountModel> _accounts = [];
  int? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final accounts = await AccountRepository().getAccounts();
      if (!mounted || accounts.isEmpty) return;

      final ids = accounts.map((a) => a.id).toSet();
      final selected = ids.contains(widget.value)
          ? widget.value
          : accounts.first.id; // first = default account

      setState(() {
        _accounts = accounts;
        _selected = selected;
      });
      if (selected != widget.value) widget.onChanged(selected);
    } catch (_) {
      // The form still works without accounts (entry stays on the default).
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accounts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey(_selected),
        initialValue: _selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
        ),
        items: [
          for (final a in _accounts)
            DropdownMenuItem<int>(
              value: a.id,
              child: Text(a.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          setState(() => _selected = value);
          widget.onChanged(value);
        },
      ),
    );
  }
}
