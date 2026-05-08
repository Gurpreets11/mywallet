class DatabaseConstants {
  static const String databaseName = 'my_wallet.db';
  static const int databaseVersion = 3;

  // Common Columns
  static const String colId = 'id';

  // Expense Table
  static const String tableExpenses = 'expenses';

  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colDate = 'date';
  static const String colPaymentMode = 'payment_mode';
  static const String colNotes = 'notes';
  static const String colCreatedAt = 'created_at';

  // Income Table
  static const String tableIncome = 'income';

  static const String colSource = 'source';

  // Investment Table
  static const String tableInvestments = 'investments';

  static const String colInvestmentType = 'investment_type';
  static const String colAmountInvested = 'amount_invested';
  static const String colCurrentValue = 'current_value';
  static const String colInvestmentDate = 'investment_date';

  // Loan Table
  static const String tableLoans = 'loans';

  static const String colLoanName = 'loan_name';
  static const String colLenderName = 'lender_name';
  static const String colTotalAmount = 'total_amount';
  static const String colInterestRate = 'interest_rate';
  static const String colStartDate = 'start_date';
  static const String colEmiAmount = 'emi_amount';
  static const String colTenureMonths = 'tenure_months';
  static const String colOutstandingAmount = 'outstanding_amount';
  static const String colStatus = 'status';

  // Loan Payment Table
  static const String tableLoanPayments = 'loan_payments';

  static const String colLoanId = 'loan_id';
  static const String colAmountPaid = 'amount_paid';
  static const String colPaymentDate = 'payment_date';

  // Transaction Type Table
  static const String tableTransactionTypes = 'transaction_types';

  static const String colTypeName = 'type_name';

  // Category Table
  static const String tableCategories = 'categories';

  static const String colTransactionTypeId = 'transaction_type_id';
  static const String colCategoryName = 'category_name';
  static const String colIconName = 'icon_name';
  static const String colColorCode = 'color_code';
  static const String colIsActive = 'is_active';

  // Subcategory Table

  static const String tableSubcategories = 'subcategories';

  static const String colCategoryId = 'category_id';
  static const String colSubcategoryName = 'subcategory_name';
}