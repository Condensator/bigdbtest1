SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBlendedItemAsset]
(
 @val [dbo].[BlendedItemAsset] READONLY
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
MERGE [dbo].[BlendedItemAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BookBasis_Amount]=S.[BookBasis_Amount],[BookBasis_Currency]=S.[BookBasis_Currency],[Cost_Amount]=S.[Cost_Amount],[Cost_Currency]=S.[Cost_Currency],[IsActive]=S.[IsActive],[LeaseAssetId]=S.[LeaseAssetId],[NewTaxBasis_Amount]=S.[NewTaxBasis_Amount],[NewTaxBasis_Currency]=S.[NewTaxBasis_Currency],[TaxCredit_Amount]=S.[TaxCredit_Amount],[TaxCredit_Currency]=S.[TaxCredit_Currency],[TaxCreditTaxBasisPercentage]=S.[TaxCreditTaxBasisPercentage],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxReduction_Amount]=S.[UpfrontTaxReduction_Amount],[UpfrontTaxReduction_Currency]=S.[UpfrontTaxReduction_Currency]
WHEN NOT MATCHED THEN
	INSERT ([BlendedItemId],[BookBasis_Amount],[BookBasis_Currency],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[IsActive],[LeaseAssetId],[NewTaxBasis_Amount],[NewTaxBasis_Currency],[TaxCredit_Amount],[TaxCredit_Currency],[TaxCreditTaxBasisPercentage],[UpfrontTaxReduction_Amount],[UpfrontTaxReduction_Currency])
    VALUES (S.[BlendedItemId],S.[BookBasis_Amount],S.[BookBasis_Currency],S.[Cost_Amount],S.[Cost_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[LeaseAssetId],S.[NewTaxBasis_Amount],S.[NewTaxBasis_Currency],S.[TaxCredit_Amount],S.[TaxCredit_Currency],S.[TaxCreditTaxBasisPercentage],S.[UpfrontTaxReduction_Amount],S.[UpfrontTaxReduction_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
