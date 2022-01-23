SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseTaxAssessmentDetail]
(
 @val [dbo].[LeaseTaxAssessmentDetail] READONLY
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
MERGE [dbo].[LeaseTaxAssessmentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetTypeId]=S.[AssetTypeId],[Exemption]=S.[Exemption],[IsActive]=S.[IsActive],[LocationId]=S.[LocationId],[OtherBasisTypesAvailable]=S.[OtherBasisTypesAvailable],[PrepaidUpfrontTax_Amount]=S.[PrepaidUpfrontTax_Amount],[PrepaidUpfrontTax_Currency]=S.[PrepaidUpfrontTax_Currency],[SalesTaxAmount_Amount]=S.[SalesTaxAmount_Amount],[SalesTaxAmount_Currency]=S.[SalesTaxAmount_Currency],[SalesTaxRate]=S.[SalesTaxRate],[TaxBasisTypeId]=S.[TaxBasisTypeId],[TaxCodeId]=S.[TaxCodeId],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxMode]=S.[UpfrontTaxMode],[UpfrontTaxPayable_Amount]=S.[UpfrontTaxPayable_Amount],[UpfrontTaxPayable_Currency]=S.[UpfrontTaxPayable_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AssetTypeId],[CreatedById],[CreatedTime],[Exemption],[IsActive],[LeaseFinanceId],[LocationId],[OtherBasisTypesAvailable],[PrepaidUpfrontTax_Amount],[PrepaidUpfrontTax_Currency],[SalesTaxAmount_Amount],[SalesTaxAmount_Currency],[SalesTaxRate],[TaxBasisTypeId],[TaxCodeId],[TaxTypeId],[UpfrontTaxMode],[UpfrontTaxPayable_Amount],[UpfrontTaxPayable_Currency])
    VALUES (S.[AssetTypeId],S.[CreatedById],S.[CreatedTime],S.[Exemption],S.[IsActive],S.[LeaseFinanceId],S.[LocationId],S.[OtherBasisTypesAvailable],S.[PrepaidUpfrontTax_Amount],S.[PrepaidUpfrontTax_Currency],S.[SalesTaxAmount_Amount],S.[SalesTaxAmount_Currency],S.[SalesTaxRate],S.[TaxBasisTypeId],S.[TaxCodeId],S.[TaxTypeId],S.[UpfrontTaxMode],S.[UpfrontTaxPayable_Amount],S.[UpfrontTaxPayable_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
