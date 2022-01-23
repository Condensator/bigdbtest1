SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepEntity]
(
 @val [dbo].[TaxDepEntity] READONLY
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
MERGE [dbo].[TaxDepEntities] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BlendedItemId]=S.[BlendedItemId],[ContractId]=S.[ContractId],[DepreciationBeginDate]=S.[DepreciationBeginDate],[DepreciationEndDate]=S.[DepreciationEndDate],[EntityType]=S.[EntityType],[FXTaxBasisAmount_Amount]=S.[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency]=S.[FXTaxBasisAmount_Currency],[IsActive]=S.[IsActive],[IsComputationPending]=S.[IsComputationPending],[IsConditionalSale]=S.[IsConditionalSale],[IsGLPosted]=S.[IsGLPosted],[IsStraightLineMethodUsed]=S.[IsStraightLineMethodUsed],[IsTaxDepreciationTerminated]=S.[IsTaxDepreciationTerminated],[PostDate]=S.[PostDate],[TaxBasisAmount_Amount]=S.[TaxBasisAmount_Amount],[TaxBasisAmount_Currency]=S.[TaxBasisAmount_Currency],[TaxDepDisposalTemplateId]=S.[TaxDepDisposalTemplateId],[TaxDepTemplateId]=S.[TaxDepTemplateId],[TaxProceedsAmount_Amount]=S.[TaxProceedsAmount_Amount],[TaxProceedsAmount_Currency]=S.[TaxProceedsAmount_Currency],[TerminatedByLeaseId]=S.[TerminatedByLeaseId],[TerminationDate]=S.[TerminationDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BlendedItemId],[ContractId],[CreatedById],[CreatedTime],[DepreciationBeginDate],[DepreciationEndDate],[EntityType],[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency],[IsActive],[IsComputationPending],[IsConditionalSale],[IsGLPosted],[IsStraightLineMethodUsed],[IsTaxDepreciationTerminated],[PostDate],[TaxBasisAmount_Amount],[TaxBasisAmount_Currency],[TaxDepDisposalTemplateId],[TaxDepTemplateId],[TaxProceedsAmount_Amount],[TaxProceedsAmount_Currency],[TerminatedByLeaseId],[TerminationDate])
    VALUES (S.[AssetId],S.[BlendedItemId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DepreciationBeginDate],S.[DepreciationEndDate],S.[EntityType],S.[FXTaxBasisAmount_Amount],S.[FXTaxBasisAmount_Currency],S.[IsActive],S.[IsComputationPending],S.[IsConditionalSale],S.[IsGLPosted],S.[IsStraightLineMethodUsed],S.[IsTaxDepreciationTerminated],S.[PostDate],S.[TaxBasisAmount_Amount],S.[TaxBasisAmount_Currency],S.[TaxDepDisposalTemplateId],S.[TaxDepTemplateId],S.[TaxProceedsAmount_Amount],S.[TaxProceedsAmount_Currency],S.[TerminatedByLeaseId],S.[TerminationDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
