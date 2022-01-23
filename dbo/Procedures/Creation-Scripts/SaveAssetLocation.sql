SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetLocation]
(
 @val [dbo].[AssetLocation] READONLY
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
MERGE [dbo].[AssetLocations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EffectiveFromDate]=S.[EffectiveFromDate],[IsActive]=S.[IsActive],[IsCurrent]=S.[IsCurrent],[IsFLStampTaxExempt]=S.[IsFLStampTaxExempt],[LienCredit_Amount]=S.[LienCredit_Amount],[LienCredit_Currency]=S.[LienCredit_Currency],[LocationId]=S.[LocationId],[ReciprocityAmount_Amount]=S.[ReciprocityAmount_Amount],[ReciprocityAmount_Currency]=S.[ReciprocityAmount_Currency],[TaxBasisType]=S.[TaxBasisType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxAssessedInLegacySystem]=S.[UpfrontTaxAssessedInLegacySystem],[UpfrontTaxMode]=S.[UpfrontTaxMode]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[EffectiveFromDate],[IsActive],[IsCurrent],[IsFLStampTaxExempt],[LienCredit_Amount],[LienCredit_Currency],[LocationId],[ReciprocityAmount_Amount],[ReciprocityAmount_Currency],[TaxBasisType],[UpfrontTaxAssessedInLegacySystem],[UpfrontTaxMode])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[EffectiveFromDate],S.[IsActive],S.[IsCurrent],S.[IsFLStampTaxExempt],S.[LienCredit_Amount],S.[LienCredit_Currency],S.[LocationId],S.[ReciprocityAmount_Amount],S.[ReciprocityAmount_Currency],S.[TaxBasisType],S.[UpfrontTaxAssessedInLegacySystem],S.[UpfrontTaxMode])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
