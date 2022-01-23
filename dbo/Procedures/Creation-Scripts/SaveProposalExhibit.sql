SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveProposalExhibit]
(
 @val [dbo].[ProposalExhibit] READONLY
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
MERGE [dbo].[ProposalExhibits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BankIndexDescription]=S.[BankIndexDescription],[BaseRate]=S.[BaseRate],[CompoundingFrequency]=S.[CompoundingFrequency],[CreditProfileId]=S.[CreditProfileId],[CustomerTerm]=S.[CustomerTerm],[DayCountConvention]=S.[DayCountConvention],[DealProductTypeId]=S.[DealProductTypeId],[DealTypeId]=S.[DealTypeId],[DownPayment_Amount]=S.[DownPayment_Amount],[DownPayment_Currency]=S.[DownPayment_Currency],[DueDay]=S.[DueDay],[EstimatedBalloonAmount_Amount]=S.[EstimatedBalloonAmount_Amount],[EstimatedBalloonAmount_Currency]=S.[EstimatedBalloonAmount_Currency],[ExpectedCommencementDate]=S.[ExpectedCommencementDate],[FrequencyStartDate]=S.[FrequencyStartDate],[GuaranteedResidual_Amount]=S.[GuaranteedResidual_Amount],[GuaranteedResidual_Currency]=S.[GuaranteedResidual_Currency],[GuaranteedResidualFactor]=S.[GuaranteedResidualFactor],[InceptionPayment_Amount]=S.[InceptionPayment_Amount],[InceptionPayment_Currency]=S.[InceptionPayment_Currency],[InceptionRentFactor]=S.[InceptionRentFactor],[IndexAsofDate]=S.[IndexAsofDate],[IrregularFrequencyDescription]=S.[IrregularFrequencyDescription],[IsActive]=S.[IsActive],[IsAdvance]=S.[IsAdvance],[IsIndexBased]=S.[IsIndexBased],[IsIndexBasedProgressFunding]=S.[IsIndexBasedProgressFunding],[IsProgressFunding]=S.[IsProgressFunding],[IsRegularPaymentStream]=S.[IsRegularPaymentStream],[IsResidualSharing]=S.[IsResidualSharing],[IsSaleLeaseback]=S.[IsSaleLeaseback],[Number]=S.[Number],[NumberOfInceptionPayments]=S.[NumberOfInceptionPayments],[NumberofPayments]=S.[NumberofPayments],[PaymentFrequency]=S.[PaymentFrequency],[PricingBaseIndexId]=S.[PricingBaseIndexId],[PricingCommencementDate]=S.[PricingCommencementDate],[PricingOption]=S.[PricingOption],[ProgramIndicatorConfigId]=S.[ProgramIndicatorConfigId],[ProgressFundingBaseIndexId]=S.[ProgressFundingBaseIndexId],[ProgressFundingBaseRate]=S.[ProgressFundingBaseRate],[ProgressFundingCeilingRate]=S.[ProgressFundingCeilingRate],[ProgressFundingDescription]=S.[ProgressFundingDescription],[ProgressFundingFloorRate]=S.[ProgressFundingFloorRate],[ProgressFundingIndexAsofDate]=S.[ProgressFundingIndexAsofDate],[ProgressFundingSpread]=S.[ProgressFundingSpread],[ProgressFundingTotalRate]=S.[ProgressFundingTotalRate],[ProposalExhibitTemplateId]=S.[ProposalExhibitTemplateId],[ProposedResidual_Amount]=S.[ProposedResidual_Amount],[ProposedResidual_Currency]=S.[ProposedResidual_Currency],[ProposedResidualFactor]=S.[ProposedResidualFactor],[Rent_Amount]=S.[Rent_Amount],[Rent_Currency]=S.[Rent_Currency],[RentFactor]=S.[RentFactor],[ResidualatRisk_Amount]=S.[ResidualatRisk_Amount],[ResidualatRisk_Currency]=S.[ResidualatRisk_Currency],[Revolving]=S.[Revolving],[Spread]=S.[Spread],[Term]=S.[Term],[TotalRate]=S.[TotalRate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorSubsidy_Amount]=S.[VendorSubsidy_Amount],[VendorSubsidy_Currency]=S.[VendorSubsidy_Currency]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BankIndexDescription],[BaseRate],[CompoundingFrequency],[CreatedById],[CreatedTime],[CreditProfileId],[CustomerTerm],[DayCountConvention],[DealProductTypeId],[DealTypeId],[DownPayment_Amount],[DownPayment_Currency],[DueDay],[EstimatedBalloonAmount_Amount],[EstimatedBalloonAmount_Currency],[ExpectedCommencementDate],[FrequencyStartDate],[GuaranteedResidual_Amount],[GuaranteedResidual_Currency],[GuaranteedResidualFactor],[InceptionPayment_Amount],[InceptionPayment_Currency],[InceptionRentFactor],[IndexAsofDate],[IrregularFrequencyDescription],[IsActive],[IsAdvance],[IsIndexBased],[IsIndexBasedProgressFunding],[IsProgressFunding],[IsRegularPaymentStream],[IsResidualSharing],[IsSaleLeaseback],[Number],[NumberOfInceptionPayments],[NumberofPayments],[PaymentFrequency],[PricingBaseIndexId],[PricingCommencementDate],[PricingOption],[ProgramIndicatorConfigId],[ProgressFundingBaseIndexId],[ProgressFundingBaseRate],[ProgressFundingCeilingRate],[ProgressFundingDescription],[ProgressFundingFloorRate],[ProgressFundingIndexAsofDate],[ProgressFundingSpread],[ProgressFundingTotalRate],[ProposalExhibitTemplateId],[ProposalId],[ProposedResidual_Amount],[ProposedResidual_Currency],[ProposedResidualFactor],[Rent_Amount],[Rent_Currency],[RentFactor],[ResidualatRisk_Amount],[ResidualatRisk_Currency],[Revolving],[Spread],[Term],[TotalRate],[VendorSubsidy_Amount],[VendorSubsidy_Currency])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BankIndexDescription],S.[BaseRate],S.[CompoundingFrequency],S.[CreatedById],S.[CreatedTime],S.[CreditProfileId],S.[CustomerTerm],S.[DayCountConvention],S.[DealProductTypeId],S.[DealTypeId],S.[DownPayment_Amount],S.[DownPayment_Currency],S.[DueDay],S.[EstimatedBalloonAmount_Amount],S.[EstimatedBalloonAmount_Currency],S.[ExpectedCommencementDate],S.[FrequencyStartDate],S.[GuaranteedResidual_Amount],S.[GuaranteedResidual_Currency],S.[GuaranteedResidualFactor],S.[InceptionPayment_Amount],S.[InceptionPayment_Currency],S.[InceptionRentFactor],S.[IndexAsofDate],S.[IrregularFrequencyDescription],S.[IsActive],S.[IsAdvance],S.[IsIndexBased],S.[IsIndexBasedProgressFunding],S.[IsProgressFunding],S.[IsRegularPaymentStream],S.[IsResidualSharing],S.[IsSaleLeaseback],S.[Number],S.[NumberOfInceptionPayments],S.[NumberofPayments],S.[PaymentFrequency],S.[PricingBaseIndexId],S.[PricingCommencementDate],S.[PricingOption],S.[ProgramIndicatorConfigId],S.[ProgressFundingBaseIndexId],S.[ProgressFundingBaseRate],S.[ProgressFundingCeilingRate],S.[ProgressFundingDescription],S.[ProgressFundingFloorRate],S.[ProgressFundingIndexAsofDate],S.[ProgressFundingSpread],S.[ProgressFundingTotalRate],S.[ProposalExhibitTemplateId],S.[ProposalId],S.[ProposedResidual_Amount],S.[ProposedResidual_Currency],S.[ProposedResidualFactor],S.[Rent_Amount],S.[Rent_Currency],S.[RentFactor],S.[ResidualatRisk_Amount],S.[ResidualatRisk_Currency],S.[Revolving],S.[Spread],S.[Term],S.[TotalRate],S.[VendorSubsidy_Amount],S.[VendorSubsidy_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
