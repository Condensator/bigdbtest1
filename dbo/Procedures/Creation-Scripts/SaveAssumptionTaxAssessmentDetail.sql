SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssumptionTaxAssessmentDetail]
(
 @val [dbo].[AssumptionTaxAssessmentDetail] READONLY
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
MERGE [dbo].[AssumptionTaxAssessmentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetTypeId]=S.[AssetTypeId],[IsActive]=S.[IsActive],[IsDummy]=S.[IsDummy],[LocationId]=S.[LocationId],[OtherBasisTypesAvailable]=S.[OtherBasisTypesAvailable],[SalesTaxAmount_Amount]=S.[SalesTaxAmount_Amount],[SalesTaxAmount_Currency]=S.[SalesTaxAmount_Currency],[SalesTaxRate]=S.[SalesTaxRate],[TaxBasisTypeId]=S.[TaxBasisTypeId],[TaxCodeId]=S.[TaxCodeId],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxMode]=S.[UpfrontTaxMode]
WHEN NOT MATCHED THEN
	INSERT ([AssetTypeId],[AssumptionId],[CreatedById],[CreatedTime],[IsActive],[IsDummy],[LocationId],[OtherBasisTypesAvailable],[SalesTaxAmount_Amount],[SalesTaxAmount_Currency],[SalesTaxRate],[TaxBasisTypeId],[TaxCodeId],[TaxTypeId],[UpfrontTaxMode])
    VALUES (S.[AssetTypeId],S.[AssumptionId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsDummy],S.[LocationId],S.[OtherBasisTypesAvailable],S.[SalesTaxAmount_Amount],S.[SalesTaxAmount_Currency],S.[SalesTaxRate],S.[TaxBasisTypeId],S.[TaxCodeId],S.[TaxTypeId],S.[UpfrontTaxMode])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
