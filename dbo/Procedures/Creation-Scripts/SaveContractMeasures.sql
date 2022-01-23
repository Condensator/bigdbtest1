SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractMeasures]
(
 @val [dbo].[ContractMeasures] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[ContractMeasures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdditionalFeeIncome]=S.[AdditionalFeeIncome],[BlendedExpense]=S.[BlendedExpense],[BlendedIncome]=S.[BlendedIncome],[ChargeOffExpenseLeaseComponent]=S.[ChargeOffExpenseLeaseComponent],[ChargeOffExpenseNLC]=S.[ChargeOffExpenseNLC],[ChargeOffGainOnRecoveryLeaseComponent]=S.[ChargeOffGainOnRecoveryLeaseComponent],[ChargeOffGainOnRecoveryNonLeaseComponent]=S.[ChargeOffGainOnRecoveryNonLeaseComponent],[ChargeOffRecoveryLeaseComponent]=S.[ChargeOffRecoveryLeaseComponent],[ChargeOffRecoveryNonLeaseComponent]=S.[ChargeOffRecoveryNonLeaseComponent],[CostOfGoodsSold]=S.[CostOfGoodsSold],[Currency]=S.[Currency],[DepreciationAmount]=S.[DepreciationAmount],[EarnedIncome]=S.[EarnedIncome],[EarnedResidualIncome]=S.[EarnedResidualIncome],[EarnedSellingProfitIncome]=S.[EarnedSellingProfitIncome],[FinanceEarnedIncome]=S.[FinanceEarnedIncome],[FinancingCostOfGoodsSold]=S.[FinancingCostOfGoodsSold],[FinancingEarnedResidualIncome]=S.[FinancingEarnedResidualIncome],[FinancingLossOnUnguaranteedResidual]=S.[FinancingLossOnUnguaranteedResidual],[FinancingRevenue]=S.[FinancingRevenue],[GLPostedInterimInterestIncome]=S.[GLPostedInterimInterestIncome],[GLPostedInterimRentIncome]=S.[GLPostedInterimRentIncome],[ImpairmentAdjustmentPayoff]=S.[ImpairmentAdjustmentPayoff],[LossOnUnguaranteedResidual]=S.[LossOnUnguaranteedResidual],[NBVImpairment]=S.[NBVImpairment],[NetChargeOff]=S.[NetChargeOff],[OTPDepreciation]=S.[OTPDepreciation],[OTPIncome]=S.[OTPIncome],[RecoveryIncome]=S.[RecoveryIncome],[RentalIncome]=S.[RentalIncome],[ResidualRecapture]=S.[ResidualRecapture],[Revenue]=S.[Revenue],[SaleProceeds]=S.[SaleProceeds],[SalesTypeLeaseGrossProfit]=S.[SalesTypeLeaseGrossProfit],[ScrapePayableExpenseRecognition]=S.[ScrapePayableExpenseRecognition],[ScrapeReceivableIncome]=S.[ScrapeReceivableIncome],[SupplementalIncome]=S.[SupplementalIncome],[SyndicationServiceFee]=S.[SyndicationServiceFee],[SyndicationServiceFeeAbsorb]=S.[SyndicationServiceFeeAbsorb],[TotalGLPostedFloatRateIncome]=S.[TotalGLPostedFloatRateIncome],[TransferToIncome]=S.[TransferToIncome],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ValuationExpense]=S.[ValuationExpense]
WHEN NOT MATCHED THEN
	INSERT ([AdditionalFeeIncome],[BlendedExpense],[BlendedIncome],[ChargeOffExpenseLeaseComponent],[ChargeOffExpenseNLC],[ChargeOffGainOnRecoveryLeaseComponent],[ChargeOffGainOnRecoveryNonLeaseComponent],[ChargeOffRecoveryLeaseComponent],[ChargeOffRecoveryNonLeaseComponent],[CostOfGoodsSold],[CreatedById],[CreatedTime],[Currency],[DepreciationAmount],[EarnedIncome],[EarnedResidualIncome],[EarnedSellingProfitIncome],[FinanceEarnedIncome],[FinancingCostOfGoodsSold],[FinancingEarnedResidualIncome],[FinancingLossOnUnguaranteedResidual],[FinancingRevenue],[GLPostedInterimInterestIncome],[GLPostedInterimRentIncome],[Id],[ImpairmentAdjustmentPayoff],[LossOnUnguaranteedResidual],[NBVImpairment],[NetChargeOff],[OTPDepreciation],[OTPIncome],[RecoveryIncome],[RentalIncome],[ResidualRecapture],[Revenue],[SaleProceeds],[SalesTypeLeaseGrossProfit],[ScrapePayableExpenseRecognition],[ScrapeReceivableIncome],[SupplementalIncome],[SyndicationServiceFee],[SyndicationServiceFeeAbsorb],[TotalGLPostedFloatRateIncome],[TransferToIncome],[ValuationExpense])
    VALUES (S.[AdditionalFeeIncome],S.[BlendedExpense],S.[BlendedIncome],S.[ChargeOffExpenseLeaseComponent],S.[ChargeOffExpenseNLC],S.[ChargeOffGainOnRecoveryLeaseComponent],S.[ChargeOffGainOnRecoveryNonLeaseComponent],S.[ChargeOffRecoveryLeaseComponent],S.[ChargeOffRecoveryNonLeaseComponent],S.[CostOfGoodsSold],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[DepreciationAmount],S.[EarnedIncome],S.[EarnedResidualIncome],S.[EarnedSellingProfitIncome],S.[FinanceEarnedIncome],S.[FinancingCostOfGoodsSold],S.[FinancingEarnedResidualIncome],S.[FinancingLossOnUnguaranteedResidual],S.[FinancingRevenue],S.[GLPostedInterimInterestIncome],S.[GLPostedInterimRentIncome],S.[Id],S.[ImpairmentAdjustmentPayoff],S.[LossOnUnguaranteedResidual],S.[NBVImpairment],S.[NetChargeOff],S.[OTPDepreciation],S.[OTPIncome],S.[RecoveryIncome],S.[RentalIncome],S.[ResidualRecapture],S.[Revenue],S.[SaleProceeds],S.[SalesTypeLeaseGrossProfit],S.[ScrapePayableExpenseRecognition],S.[ScrapeReceivableIncome],S.[SupplementalIncome],S.[SyndicationServiceFee],S.[SyndicationServiceFeeAbsorb],S.[TotalGLPostedFloatRateIncome],S.[TransferToIncome],S.[ValuationExpense])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
