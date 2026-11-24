import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/utils/snackbar_utils.dart';
import 'package:mywallet/core/widgets/app_responsive_content.dart';
import 'package:mywallet/core/widgets/app_section_header.dart';
import 'package:mywallet/core/widgets/common_button.dart';
import 'package:mywallet/core/widgets/common_delete_dialog.dart';
import 'package:mywallet/core/widgets/common_text_field.dart';
import 'package:mywallet/core/widgets/date_range_presets.dart';
import 'package:mywallet/core/widgets/empty_view.dart';
import 'package:mywallet/core/widgets/loading_view.dart';
import 'package:mywallet/core/widgets/transaction_list_header.dart';
import 'package:mywallet/core/widgets/type_to_confirm_dialog.dart';
import 'package:mywallet/modules/categories/widgets/name_dialog.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('simple widgets', () {
    testWidgets('EmptyView shows message, icon and optional action', (t) async {
      var tapped = 0;
      await t.pumpWidget(
        host(
          EmptyView(
            message: 'Nothing here',
            icon: Icons.savings,
            actionText: 'Add one',
            onAction: () => tapped++,
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byIcon(Icons.savings), findsOneWidget);
      await t.tap(find.text('Add one'));
      expect(tapped, 1);
    });

    testWidgets('EmptyView without an action has no button', (t) async {
      await t.pumpWidget(host(const EmptyView(message: 'Empty')));
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('LoadingView shows a spinner', (t) async {
      await t.pumpWidget(host(const LoadingView()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CommonButton fires onPressed', (t) async {
      var n = 0;
      await t.pumpWidget(
        host(CommonButton(text: 'Save', onPressed: () => n++)),
      );
      await t.tap(find.text('Save'));
      expect(n, 1);
    });

    testWidgets('AppSectionHeader shows the title and trailing widget', (
      t,
    ) async {
      await t.pumpWidget(
        host(
          const AppSectionHeader(title: 'Recent', trailing: Text('View all')),
        ),
      );
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
    });

    testWidgets('AppResponsiveContent caps the width', (t) async {
      t.view.physicalSize = const Size(2000, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        host(
          const AppResponsiveContent(
            maxWidth: 600,
            padding: EdgeInsets.zero,
            child: SizedBox.expand(key: Key('inner')),
          ),
        ),
      );
      expect(t.getSize(find.byKey(const Key('inner'))).width, 600);
    });

    testWidgets('CommonTextField validates through a Form', (t) async {
      final key = GlobalKey<FormState>();
      final c = TextEditingController();
      await t.pumpWidget(
        host(
          Form(
            key: key,
            child: CommonTextField(
              controller: c,
              label: 'Name',
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
        ),
      );
      expect(key.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text('Required'), findsOneWidget);
      await t.enterText(find.byType(TextFormField), 'Asha');
      expect(key.currentState!.validate(), isTrue);
    });
  });

  group('DateRangePresets', () {
    test('presets cover the expected ranges', () {
      final presets = DateRangePresets.presets();
      expect(presets.map((p) => p.$1), [
        'This month',
        'Last month',
        'Last 7 days',
        'Last 30 days',
        'This year',
      ]);
      final today = DateTime.now();
      final thisMonth = presets[0].$2;
      expect(thisMonth.start, DateTime(today.year, today.month, 1));
      final last7 = presets[2].$2;
      expect(last7.end.difference(last7.start).inDays, 6);
      final last30 = presets[3].$2;
      expect(last30.end.difference(last30.start).inDays, 29);
      final lastMonth = presets[1].$2;
      expect(lastMonth.start.day, 1);
      expect(lastMonth.end.add(const Duration(days: 1)).day, 1);
    });

    testWidgets('selecting a chip reports its range and marks the match', (
      t,
    ) async {
      DateTimeRange? picked;
      final current = DateRangePresets.presets()[2].$2;
      await t.pumpWidget(
        host(DateRangePresets(range: current, onSelected: (r) => picked = r)),
      );
      final selected = t
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((c) => c.selected)
          .toList();
      expect(selected, hasLength(1));
      await t.tap(find.text('This year'));
      expect(picked, isNotNull);
      expect(picked!.start.month, 1);
      expect(picked!.start.day, 1);
    });
  });

  group('TransactionListHeader', () {
    testWidgets('shows summary and count, and reports search / sort', (
      t,
    ) async {
      final controller = TextEditingController();
      String? searched;
      var cleared = 0;
      String? sorted;
      await t.pumpWidget(
        host(
          TransactionListHeader(
            searchController: controller,
            onSearchChanged: (v) => searched = v,
            onSearchCleared: () => cleared++,
            summaryLabel: 'Spent this month',
            summaryAmount: '₹100.00',
            summaryIcon: Icons.trending_up,
            summaryIconColor: Colors.red,
            summaryIconBackground: Colors.red.shade100,
            countText: '3 transactions',
            sortValue: 'newest',
            onSortChanged: (v) => sorted = v,
          ),
        ),
      );
      expect(find.text('Spent this month'), findsOneWidget);
      expect(find.text('₹100.00'), findsOneWidget);
      expect(find.text('3 transactions'), findsOneWidget);
      expect(find.text('Newest'), findsOneWidget);

      await t.enterText(find.byType(TextField), 'tea');
      expect(searched, 'tea');
      await t.pump();
      await t.tap(find.byIcon(Icons.close));
      expect(cleared, 1);

      await t.tap(find.text('Newest'));
      await t.pumpAndSettle();
      await t.tap(find.text('Highest amount').last);
      await t.pumpAndSettle();
      expect(sorted, 'highest');
    });
  });

  group('delete confirmations', () {
    testWidgets('confirmDelete returns true on Delete and false on Cancel', (
      t,
    ) async {
      bool? result;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async => result = await confirmDelete(
                  context,
                  title: 'Delete expense?',
                  message: 'This cannot be undone.',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text('Delete expense?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(result, isTrue);

      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('confirmDelete returns false when dismissed outside', (
      t,
    ) async {
      bool? result;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async => result = await confirmDelete(
                  context,
                  title: 'T',
                  message: 'M',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(5, 5)); // barrier
      await t.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('confirmLabel can be customised', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => confirmDelete(
                  context,
                  title: 'T',
                  message: 'M',
                  confirmLabel: 'Remove',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('CommonDeleteDialog calls onConfirm', (t) async {
      var confirmed = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonDeleteDialog(
              title: 'Sure?',
              message: 'msg',
              onConfirm: () => confirmed++,
            ),
          ),
        ),
      );
      await t.tap(find.text('Delete'));
      await t.pump();
      expect(confirmed, 1);
    });
  });

  group('TypeToConfirmDialog', () {
    Future<void> open(WidgetTester t, void Function(bool) onResult) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async => onResult(
                  await TypeToConfirmDialog.show(
                    context,
                    title: 'Erase everything',
                    message: 'All data will go.',
                    confirmLabel: 'Erase',
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('confirm stays disabled until the keyword is typed', (t) async {
      bool? result;
      await open(t, (v) => result = v);
      expect(find.text('Type DELETE to confirm:'), findsOneWidget);

      Finder confirm() => find.widgetWithText(ElevatedButton, 'Erase');
      expect(t.widget<ElevatedButton>(confirm()).onPressed, isNull);

      await t.enterText(find.byType(TextField), 'delet');
      await t.pump();
      expect(t.widget<ElevatedButton>(confirm()).onPressed, isNull);

      await t.enterText(find.byType(TextField), 'delete'); // case-insensitive
      await t.pump();
      expect(t.widget<ElevatedButton>(confirm()).onPressed, isNotNull);

      await t.tap(confirm());
      await t.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancel returns false', (t) async {
      bool? result;
      await open(t, (v) => result = v);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('promptForName', () {
    Future<void> open(
      WidgetTester t,
      void Function(String?) onResult, {
      String? initial,
    }) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async => onResult(
                  await promptForName(
                    context,
                    title: 'New category',
                    initial: initial,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('empty name shows an error and keeps the dialog open', (
      t,
    ) async {
      String? result = 'unset';
      await open(t, (v) => result = v);
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      expect(result, 'unset');
    });

    testWidgets('a name is trimmed and returned', (t) async {
      String? result;
      await open(t, (v) => result = v);
      await t.enterText(find.byType(TextField), '  Pets  ');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(result, 'Pets');
    });

    testWidgets('the initial value is pre-filled', (t) async {
      await open(t, (_) {}, initial: 'Food');
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('a name that is too long is refused', (t) async {
      String? result = 'unset';
      await open(t, (v) => result = v);
      await t.enterText(find.byType(TextField), 'x' * 200);
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.textContaining('Max'), findsOneWidget);
      expect(result, 'unset');
    });
  });

  group('SnackbarUtils', () {
    testWidgets('showSnackbar shows the message', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => SnackbarUtils.showSnackbar(context, 'Saved'),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pump();
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('showUndo shows UNDO, runs the callback and auto-dismisses', (
      t,
    ) async {
      var undone = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => SnackbarUtils.showUndo(
                  context,
                  'Expense deleted',
                  () async => undone++,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pump(); // start the slide-in
      await t.pump(const Duration(milliseconds: 750)); // finish it
      expect(find.text('Expense deleted'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      await t.tap(find.text('UNDO'));
      await t.pump();
      expect(undone, 1);
      await t.pump(const Duration(seconds: 1));

      // Show again and let the timer run: it must dismiss by itself.
      await t.tap(find.text('go'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 750));
      expect(find.text('Expense deleted'), findsOneWidget);
      await t.pump(const Duration(seconds: 11));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Expense deleted'), findsNothing);
    });
  });
}
