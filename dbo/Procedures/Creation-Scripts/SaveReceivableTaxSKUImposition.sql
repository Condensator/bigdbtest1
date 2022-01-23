SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableTaxSKUImposition]
(
 @val [dbo].[ReceivableTaxSKUImposition] READONLY
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
MERGE [dbo].[ReceivableTaxSKUImpositions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AppliedTaxRate]=S.[AppliedTaxRate],[AssetSKUId]=S.[AssetSKUId],[ExemptionAmount_Amount]=S.[ExemptionAmount_Amount],[ExemptionAmount_Currency]=S.[ExemptionAmount_Currency],[ExemptionRate]=S.[ExemptionRate],[ExemptionType]=S.[ExemptionType],[ExternalJurisdictionLevelId]=S.[ExternalJurisdictionLevelId],[ExternalTaxImpositionType]=S.[ExternalTaxImpositionType],[IsActive]=S.[IsActive],[TaxableBasisAmount_Amount]=S.[TaxableBasisAmount_Amount],[TaxableBasisAmount_Currency]=S.[TaxableBasisAmount_Currency],[TaxBasisType]=S.[TaxBasisType],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AppliedTaxRate],[AssetSKUId],[CreatedById],[CreatedTime],[ExemptionAmount_Amount],[ExemptionAmount_Currency],[ExemptionRate],[ExemptionType],[ExternalJurisdictionLevelId],[ExternalTaxImpositionType],[IsActive],[ReceivableTaxDetailId],[TaxableBasisAmount_Amount],[TaxableBasisAmount_Currency],[TaxBasisType],[TaxTypeId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AppliedTaxRate],S.[AssetSKUId],S.[CreatedById],S.[CreatedTime],S.[ExemptionAmount_Amount],S.[ExemptionAmount_Currency],S.[ExemptionRate],S.[ExemptionType],S.[ExternalJurisdictionLevelId],S.[ExternalTaxImpositionType],S.[IsActive],S.[ReceivableTaxDetailId],S.[TaxableBasisAmount_Amount],S.[TaxableBasisAmount_Currency],S.[TaxBasisType],S.[TaxTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
