import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/modules/budgets/models/budget_model.dart';
import 'package:mywallet/modules/budgets/repositories/budget_repository.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/repositories/expense_repository.dart';
import 'package:mywallet/modules/goals/models/savings_goal_model.dart';
import 'package:mywallet/modules/goals/repositories/goal_repository.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  group('BudgetRepository', () {
    test('shows how much of the month has been spent', () async {
      final cat = await CategoryRepository().addCategory(0, 'Zz Budget Cat');
      final budgets = BudgetRepository();
      final expenses = ExpenseRepository();

      await budgets.saveBudget(
        BudgetModel(
          categoryId: cat,
          categoryName: 'Zz Budget Cat',
          amount: 1000,
          month: 11,
          year: 2026,
        ),
      );
      for (final (day, amount) in [(2, 300.0), (20, 450.0)]) {
        await expenses.insertExpense(
          ExpenseModel(
            amount: amount,
            categoryId: cat,
            categoryName: 'Zz Budget Cat',
            date: iso(2026, 11, day),
            paymentMode: 'Cash',
            createdAt: iso(2026, 11, day),
          ),
        );
      }
      // Other months do not count.
      await expenses.insertExpense(
        ExpenseModel(
          amount: 999,
          categoryId: cat,
          categoryName: 'Zz Budget Cat',
          date: iso(2026, 10, 31),
          paymentMode: 'Cash',
          createdAt: iso(2026, 10, 31),
        ),
      );

      final list = await budgets.getBudgets(month: 11, year: 2026);
      final b = list.firstWhere((x) => x.categoryId == cat);
      expect(b.spentAmount, 750);
      expect(b.remainingAmount, 250);
      expect(b.isExceeded, isFalse);
      expect(b.isNearLimit, isFalse); // 75% < 80%
    });

    test('delete removes it and saving again restores it', () async {
      final cat = await CategoryRepository().addCategory(0, 'Zz Budget Undo');
      final budgets = BudgetRepository();
      final model = BudgetModel(
        categoryId: cat,
        categoryName: 'Zz Budget Undo',
        amount: 400,
        month: 11,
        year: 2026,
      );
      await budgets.saveBudget(model);
      var list = await budgets.getBudgets(month: 11, year: 2026);
      final saved = list.firstWhere((b) => b.categoryId == cat);

      await budgets.deleteBudget(saved.id!);
      list = await budgets.getBudgets(month: 11, year: 2026);
      expect(list.where((b) => b.categoryId == cat), isEmpty);

      await budgets.saveBudget(saved); // what Undo does
      list = await budgets.getBudgets(month: 11, year: 2026);
      final back = list.firstWhere((b) => b.categoryId == cat);
      expect(back.id, saved.id);
      expect(back.amount, 400);
    });

    test('BudgetModel limit flags', () {
      const near = BudgetModel(
        categoryId: 1,
        categoryName: 'x',
        amount: 100,
        month: 1,
        year: 2026,
        spentAmount: 85,
      );
      expect(near.isNearLimit, isTrue);
      expect(near.isExceeded, isFalse);
      const over = BudgetModel(
        categoryId: 1,
        categoryName: 'x',
        amount: 100,
        month: 1,
        year: 2026,
        spentAmount: 120,
      );
      expect(over.isExceeded, isTrue);
      expect(over.progress, 1.0);
    });
  });

  group('GoalRepository', () {
    SavingsGoalModel goal(String name, double target) => SavingsGoalModel(
      name: name,
      targetAmount: target,
      createdAt: iso(2026, 11, 1),
    );

    test('tracks contributions and detects a reached goal', () async {
      final repo = GoalRepository();
      final id = await repo.addGoal(goal('Laptop', 1000));

      await repo.addContribution(
        GoalContributionModel(
          goalId: id,
          amount: 400,
          date: iso(2026, 11, 2),
          createdAt: iso(2026, 11, 2),
        ),
      );
      var g = (await repo.getGoals()).firstWhere((x) => x.goal.id == id);
      expect(g.saved, 400);
      expect(g.remaining, 600);
      expect(g.isReached, isFalse);

      await repo.addContribution(
        GoalContributionModel(
          goalId: id,
          amount: 700,
          date: iso(2026, 11, 3),
          createdAt: iso(2026, 11, 3),
        ),
      );
      g = (await repo.getGoals()).firstWhere((x) => x.goal.id == id);
      expect(g.isReached, isTrue);
      expect(g.remaining, 0);
    });

    test('a withdrawal lowers the saved amount', () async {
      final repo = GoalRepository();
      final id = await repo.addGoal(goal('Trip', 500));
      for (final amount in [300.0, -100.0]) {
        await repo.addContribution(
          GoalContributionModel(
            goalId: id,
            amount: amount,
            date: iso(2026, 11, 2),
            createdAt: iso(2026, 11, 2),
          ),
        );
      }
      final g = (await repo.getGoals()).firstWhere((x) => x.goal.id == id);
      expect(g.saved, 200);
    });

    test('delete removes contributions and restore brings them back', () async {
      final repo = GoalRepository();
      final id = await repo.addGoal(goal('Bike', 800));
      await repo.addContribution(
        GoalContributionModel(
          goalId: id,
          amount: 250,
          date: iso(2026, 11, 2),
          createdAt: iso(2026, 11, 2),
        ),
      );
      final g = (await repo.getGoals()).firstWhere((x) => x.goal.id == id);
      final contributions = await repo.getContributions(id);
      expect(contributions, hasLength(1));

      await repo.deleteGoal(id);
      expect((await repo.getGoals()).where((x) => x.goal.id == id), isEmpty);
      expect(await repo.getContributions(id), isEmpty);

      await repo.restoreGoal(g.goal, contributions);
      final back = (await repo.getGoals()).firstWhere((x) => x.goal.id == id);
      expect(back.saved, 250);
      expect(back.goal.name, 'Bike');
    });
  });
}
