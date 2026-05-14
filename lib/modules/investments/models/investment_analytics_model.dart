import 'investment_model.dart';

class InvestmentAnalyticsModel {

  final InvestmentModel?
  topPerformer;

  final InvestmentModel?
  worstPerformer;

  final InvestmentModel?
  highestRoi;

  final InvestmentModel?
  highestInvestment;

  const InvestmentAnalyticsModel({

    this.topPerformer,

    this.worstPerformer,

    this.highestRoi,

    this.highestInvestment,
  });
}