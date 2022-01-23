SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteLeaseAsset]
(
 @val [dbo].[PreQuoteLeaseAsset] READONLY
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
MERGE [dbo].[PreQuoteLeaseAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetValuation_Amount]=S.[AssetValuation_Amount],[AssetValuation_Currency]=S.[AssetValuation_Currency],[BookedResidual_Amount]=S.[BookedResidual_Amount],[BookedResidual_Currency]=S.[BookedResidual_Currency],[BuyoutAmount_Amount]=S.[BuyoutAmount_Amount],[BuyoutAmount_Currency]=S.[BuyoutAmount_Currency],[BuyoutSalesTaxRate]=S.[BuyoutSalesTaxRate],[CalculatedNBV_Amount]=S.[CalculatedNBV_Amount],[CalculatedNBV_Currency]=S.[CalculatedNBV_Currency],[DepreciationTerm]=S.[DepreciationTerm],[EstimatedPropertyTax_Amount]=S.[EstimatedPropertyTax_Amount],[EstimatedPropertyTax_Currency]=S.[EstimatedPropertyTax_Currency],[FMV_Amount]=S.[FMV_Amount],[FMV_Currency]=S.[FMV_Currency],[IsActive]=S.[IsActive],[LeaseAssetId]=S.[LeaseAssetId],[NBV_Amount]=S.[NBV_Amount],[NBV_Currency]=S.[NBV_Currency],[NBVAsOfEffectiveDate_Amount]=S.[NBVAsOfEffectiveDate_Amount],[NBVAsOfEffectiveDate_Currency]=S.[NBVAsOfEffectiveDate_Currency],[OutstandingRentalBilled_Amount]=S.[OutstandingRentalBilled_Amount],[OutstandingRentalBilled_Currency]=S.[OutstandingRentalBilled_Currency],[OutstandingRentalsUnbilled_Amount]=S.[OutstandingRentalsUnbilled_Amount],[OutstandingRentalsUnbilled_Currency]=S.[OutstandingRentalsUnbilled_Currency],[PayoffAmount_Amount]=S.[PayoffAmount_Amount],[PayoffAmount_Currency]=S.[PayoffAmount_Currency],[PreQuoteLeaseId]=S.[PreQuoteLeaseId],[RemainingRentals_Amount]=S.[RemainingRentals_Amount],[RemainingRentals_Currency]=S.[RemainingRentals_Currency],[SalesTaxRate]=S.[SalesTaxRate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsefulLife]=S.[UsefulLife]
WHEN NOT MATCHED THEN
	INSERT ([AssetValuation_Amount],[AssetValuation_Currency],[BookedResidual_Amount],[BookedResidual_Currency],[BuyoutAmount_Amount],[BuyoutAmount_Currency],[BuyoutSalesTaxRate],[CalculatedNBV_Amount],[CalculatedNBV_Currency],[CreatedById],[CreatedTime],[DepreciationTerm],[EstimatedPropertyTax_Amount],[EstimatedPropertyTax_Currency],[FMV_Amount],[FMV_Currency],[IsActive],[LeaseAssetId],[NBV_Amount],[NBV_Currency],[NBVAsOfEffectiveDate_Amount],[NBVAsOfEffectiveDate_Currency],[OutstandingRentalBilled_Amount],[OutstandingRentalBilled_Currency],[OutstandingRentalsUnbilled_Amount],[OutstandingRentalsUnbilled_Currency],[PayoffAmount_Amount],[PayoffAmount_Currency],[PreQuoteId],[PreQuoteLeaseId],[RemainingRentals_Amount],[RemainingRentals_Currency],[SalesTaxRate],[Status],[UsefulLife])
    VALUES (S.[AssetValuation_Amount],S.[AssetValuation_Currency],S.[BookedResidual_Amount],S.[BookedResidual_Currency],S.[BuyoutAmount_Amount],S.[BuyoutAmount_Currency],S.[BuyoutSalesTaxRate],S.[CalculatedNBV_Amount],S.[CalculatedNBV_Currency],S.[CreatedById],S.[CreatedTime],S.[DepreciationTerm],S.[EstimatedPropertyTax_Amount],S.[EstimatedPropertyTax_Currency],S.[FMV_Amount],S.[FMV_Currency],S.[IsActive],S.[LeaseAssetId],S.[NBV_Amount],S.[NBV_Currency],S.[NBVAsOfEffectiveDate_Amount],S.[NBVAsOfEffectiveDate_Currency],S.[OutstandingRentalBilled_Amount],S.[OutstandingRentalBilled_Currency],S.[OutstandingRentalsUnbilled_Amount],S.[OutstandingRentalsUnbilled_Currency],S.[PayoffAmount_Amount],S.[PayoffAmount_Currency],S.[PreQuoteId],S.[PreQuoteLeaseId],S.[RemainingRentals_Amount],S.[RemainingRentals_Currency],S.[SalesTaxRate],S.[Status],S.[UsefulLife])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
