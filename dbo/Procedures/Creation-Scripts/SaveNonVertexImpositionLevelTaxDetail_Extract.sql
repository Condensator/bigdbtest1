SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexImpositionLevelTaxDetail_Extract]
(
 @val [dbo].[NonVertexImpositionLevelTaxDetail_Extract] READONLY
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
MERGE [dbo].[NonVertexImpositionLevelTaxDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[EffectiveRate]=S.[EffectiveRate],[ImpositionType]=S.[ImpositionType],[IsTaxExempt]=S.[IsTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[JurisdictionLevel]=S.[JurisdictionLevel],[ReceivableDetailId]=S.[ReceivableDetailId],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[EffectiveRate],[ImpositionType],[IsTaxExempt],[JobStepInstanceId],[JurisdictionLevel],[ReceivableDetailId],[TaxTypeId])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[EffectiveRate],S.[ImpositionType],S.[IsTaxExempt],S.[JobStepInstanceId],S.[JurisdictionLevel],S.[ReceivableDetailId],S.[TaxTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
