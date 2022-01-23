SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuoteLeaseDetail]
(
 @val [dbo].[PreQuoteLeaseDetail] READONLY
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
MERGE [dbo].[PreQuoteLeaseDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetValuation_Amount]=S.[AssetValuation_Amount],[AssetValuation_Currency]=S.[AssetValuation_Currency],[BuyoutAmount_Amount]=S.[BuyoutAmount_Amount],[BuyoutAmount_Currency]=S.[BuyoutAmount_Currency],[BuyoutSalesTax_Amount]=S.[BuyoutSalesTax_Amount],[BuyoutSalesTax_Currency]=S.[BuyoutSalesTax_Currency],[DiscountRate]=S.[DiscountRate],[EstimatedPropertyTax_Amount]=S.[EstimatedPropertyTax_Amount],[EstimatedPropertyTax_Currency]=S.[EstimatedPropertyTax_Currency],[FMV_Amount]=S.[FMV_Amount],[FMV_Currency]=S.[FMV_Currency],[IsActive]=S.[IsActive],[IsComputationPerformed]=S.[IsComputationPerformed],[IsSalesTaxAssessed]=S.[IsSalesTaxAssessed],[LateFee_Amount]=S.[LateFee_Amount],[LateFee_Currency]=S.[LateFee_Currency],[Maintenance_Amount]=S.[Maintenance_Amount],[Maintenance_Currency]=S.[Maintenance_Currency],[OtherCharge_Amount]=S.[OtherCharge_Amount],[OtherCharge_Currency]=S.[OtherCharge_Currency],[OTPRent_Amount]=S.[OTPRent_Amount],[OTPRent_Currency]=S.[OTPRent_Currency],[PayoffAmount_Amount]=S.[PayoffAmount_Amount],[PayoffAmount_Currency]=S.[PayoffAmount_Currency],[PayoffSalesTax_Amount]=S.[PayoffSalesTax_Amount],[PayoffSalesTax_Currency]=S.[PayoffSalesTax_Currency],[PreQuoteLeaseId]=S.[PreQuoteLeaseId],[PropertyTax_Amount]=S.[PropertyTax_Amount],[PropertyTax_Currency]=S.[PropertyTax_Currency],[TerminationOptionId]=S.[TerminationOptionId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetValuation_Amount],[AssetValuation_Currency],[BuyoutAmount_Amount],[BuyoutAmount_Currency],[BuyoutSalesTax_Amount],[BuyoutSalesTax_Currency],[CreatedById],[CreatedTime],[DiscountRate],[EstimatedPropertyTax_Amount],[EstimatedPropertyTax_Currency],[FMV_Amount],[FMV_Currency],[IsActive],[IsComputationPerformed],[IsSalesTaxAssessed],[LateFee_Amount],[LateFee_Currency],[Maintenance_Amount],[Maintenance_Currency],[OtherCharge_Amount],[OtherCharge_Currency],[OTPRent_Amount],[OTPRent_Currency],[PayoffAmount_Amount],[PayoffAmount_Currency],[PayoffSalesTax_Amount],[PayoffSalesTax_Currency],[PreQuoteId],[PreQuoteLeaseId],[PropertyTax_Amount],[PropertyTax_Currency],[TerminationOptionId])
    VALUES (S.[AssetValuation_Amount],S.[AssetValuation_Currency],S.[BuyoutAmount_Amount],S.[BuyoutAmount_Currency],S.[BuyoutSalesTax_Amount],S.[BuyoutSalesTax_Currency],S.[CreatedById],S.[CreatedTime],S.[DiscountRate],S.[EstimatedPropertyTax_Amount],S.[EstimatedPropertyTax_Currency],S.[FMV_Amount],S.[FMV_Currency],S.[IsActive],S.[IsComputationPerformed],S.[IsSalesTaxAssessed],S.[LateFee_Amount],S.[LateFee_Currency],S.[Maintenance_Amount],S.[Maintenance_Currency],S.[OtherCharge_Amount],S.[OtherCharge_Currency],S.[OTPRent_Amount],S.[OTPRent_Currency],S.[PayoffAmount_Amount],S.[PayoffAmount_Currency],S.[PayoffSalesTax_Amount],S.[PayoffSalesTax_Currency],S.[PreQuoteId],S.[PreQuoteLeaseId],S.[PropertyTax_Amount],S.[PropertyTax_Currency],S.[TerminationOptionId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
