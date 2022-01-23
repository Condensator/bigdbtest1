SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepEntityEnMasseUpdateDetail]
(
 @val [dbo].[TaxDepEntityEnMasseUpdateDetail] READONLY
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
MERGE [dbo].[TaxDepEntityEnMasseUpdateDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[ContractId]=S.[ContractId],[DepreciationBeginDate]=S.[DepreciationBeginDate],[DepreciationEndDate]=S.[DepreciationEndDate],[Description]=S.[Description],[FXTaxBasisAmountInLE_Amount]=S.[FXTaxBasisAmountInLE_Amount],[FXTaxBasisAmountInLE_Currency]=S.[FXTaxBasisAmountInLE_Currency],[FXTaxBasisAmountInUSD_Amount]=S.[FXTaxBasisAmountInUSD_Amount],[FXTaxBasisAmountInUSD_Currency]=S.[FXTaxBasisAmountInUSD_Currency],[IsActive]=S.[IsActive],[IsComputationPending]=S.[IsComputationPending],[IsConditionalSale]=S.[IsConditionalSale],[IsStraightLineMethodUsed]=S.[IsStraightLineMethodUsed],[IsTaxDepreciationTerminated]=S.[IsTaxDepreciationTerminated],[TaxBasisAmount_Amount]=S.[TaxBasisAmount_Amount],[TaxBasisAmount_Currency]=S.[TaxBasisAmount_Currency],[TaxDepDisposalGLTemplateId]=S.[TaxDepDisposalGLTemplateId],[TaxDepreciationTemplateId]=S.[TaxDepreciationTemplateId],[TerminationDate]=S.[TerminationDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[ContractId],[CreatedById],[CreatedTime],[DepreciationBeginDate],[DepreciationEndDate],[Description],[FXTaxBasisAmountInLE_Amount],[FXTaxBasisAmountInLE_Currency],[FXTaxBasisAmountInUSD_Amount],[FXTaxBasisAmountInUSD_Currency],[IsActive],[IsComputationPending],[IsConditionalSale],[IsStraightLineMethodUsed],[IsTaxDepreciationTerminated],[TaxBasisAmount_Amount],[TaxBasisAmount_Currency],[TaxDepDisposalGLTemplateId],[TaxDepEntityEnMasseUpdateId],[TaxDepreciationTemplateId],[TerminationDate])
    VALUES (S.[AssetId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DepreciationBeginDate],S.[DepreciationEndDate],S.[Description],S.[FXTaxBasisAmountInLE_Amount],S.[FXTaxBasisAmountInLE_Currency],S.[FXTaxBasisAmountInUSD_Amount],S.[FXTaxBasisAmountInUSD_Currency],S.[IsActive],S.[IsComputationPending],S.[IsConditionalSale],S.[IsStraightLineMethodUsed],S.[IsTaxDepreciationTerminated],S.[TaxBasisAmount_Amount],S.[TaxBasisAmount_Currency],S.[TaxDepDisposalGLTemplateId],S.[TaxDepEntityEnMasseUpdateId],S.[TaxDepreciationTemplateId],S.[TerminationDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
