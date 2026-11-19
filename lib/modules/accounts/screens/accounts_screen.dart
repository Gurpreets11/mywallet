import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_delete_dialog.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';
import '../widgets/account_form_sheet.dart';
import '../widgets/transfer_form_sheet.dart';

/// Every account with its balance, plus the list of transfers between them.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().loadAccounts();
    });
  }

  Future<void> _transfer(List<AccountBalance> balances) async {
    if (balances.length < 2) {
      SnackbarUtils.showSnackbar(
        context,
        'Add another account first to transfer money',
      );
      return;
    }
    await showTransferFormSheet(
      context,
      accounts: balances.map((b) => b.account).toList(),
    );
  }

  Future<bool> _confirm(String title, String message, String action) =>
      confirmDelete(
        context,
        title: title,
        message: message,
        confirmLabel: action,
      );

  Future<void> _deleteAccount(AccountModel account) async {
    final ok = await _confirm(
      'Delete "${account.name}"?',
      'Its transactions are not deleted - they move to your default account.',
      'Delete',
    );
    if (!ok || !mounted) return;
    final dashboard = context.read<DashboardProvider>();
    await AccountRepository().deleteAccount(account.id!);
    await dashboard.loadAccounts();
  }

  Future<void> _setDefault(AccountModel account) async {
    final dashboard = context.read<DashboardProvider>();
    await AccountRepository().setDefault(account.id!);
    await dashboard.loadAccounts();
    if (!mounted) return;
    SnackbarUtils.showSnackbar(
      context,
      '"${account.name}" is now the default account',
    );
  }

  Future<void> _deleteTransfer(AccountTransferModel t) async {
    final ok = await _confirm(
      'Delete transfer?',
      'The money moves back to where it was.',
      'Delete',
    );
    if (!ok || !mounted) return;
    final dashboard = context.read<DashboardProvider>();
    await AccountRepository().deleteTransfer(t.id!);
    await dashboard.loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final balances = provider.accountBalances;
    final transfers = provider.accountTransfers;
    final names = {for (final b in balances) b.account.id: b.account.name};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            tooltip: 'Transfer money',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => _transfer(balances),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
      body: AppResponsiveContent(
        maxWidth: 800,
        padding: EdgeInsets.zero,
        child: RefreshIndicator(
          onRefresh: () => context.read<DashboardProvider>().loadAccounts(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              _TotalCard(total: provider.totalAccountBalance),
              const SizedBox(height: 8),
              if (balances.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final b in balances)
                  _AccountCard(
                    item: b,
                    onEdit: () =>
                        showAccountFormSheet(context, account: b.account),
                    onSetDefault: () => _setDefault(b.account),
                    onDelete: () => _deleteAccount(b.account),
                  ),
              if (transfers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                  child: Text(
                    'Transfers',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final t in transfers)
                  _TransferTile(
                    transfer: t,
                    from: names[t.fromAccountId] ?? 'Account',
                    to: names[t.toAccountId] ?? 'Account',
                    onDelete: () => _deleteTransfer(t),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total across accounts',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.formatAmount(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountBalance item;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.item,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final account = item.account;
    final negative = item.balance < 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  account.type.icon,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (account.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${account.type.label} • '
                      'In ${CurrencyUtils.formatAmount(item.moneyIn)} • '
                      'Out ${CurrencyUtils.formatAmount(item.moneyOut)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyUtils.formatAmount(item.balance),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: negative ? Colors.red : null,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'default') onSetDefault();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (!account.isDefault) ...[
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as default'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  final AccountTransferModel transfer;
  final String from;
  final String to;
  final VoidCallback onDelete;

  const _TransferTile({
    required this.transfer,
    required this.from,
    required this.to,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final date = DateTime.tryParse(transfer.date);
    final notes = (transfer.notes ?? '').trim();
    final meta = [
      if (date != null) AppDateUtils.formatDate(date),
      if (notes.isNotEmpty) notes,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              child: Icon(Icons.swap_horiz_rounded, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$from  →  $to',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            Text(
              CurrencyUtils.formatAmount(transfer.amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              tooltip: 'Delete transfer',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
