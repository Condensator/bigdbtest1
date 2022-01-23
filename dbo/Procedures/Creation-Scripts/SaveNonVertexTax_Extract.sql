SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexTax_Extract]
(
 @val [dbo].[NonVertexTax_Extract] READONLY
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
MERGE [dbo].[NonVertexTax_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[CalculatedTax]=S.[CalculatedTax],[Currency]=S.[Currency],[EffectiveRate]=S.[EffectiveRate],[ExemptionAmount]=S.[ExemptionAmount],[ExemptionType]=S.[ExemptionType],[ImpositionType]=S.[ImpositionType],[IsCashBased]=S.[IsCashBased],[JobStepInstanceId]=S.[JobStepInstanceId],[JurisdictionId]=S.[JurisdictionId],[JurisdictionLevel]=S.[JurisdictionLevel],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableId]=S.[ReceivableId],[TaxResult]=S.[TaxResult],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CalculatedTax],[CreatedById],[CreatedTime],[Currency],[EffectiveRate],[ExemptionAmount],[ExemptionType],[ImpositionType],[IsCashBased],[JobStepInstanceId],[JurisdictionId],[JurisdictionLevel],[ReceivableDetailId],[ReceivableId],[TaxResult],[TaxTypeId])
    VALUES (S.[AssetId],S.[CalculatedTax],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[EffectiveRate],S.[ExemptionAmount],S.[ExemptionType],S.[ImpositionType],S.[IsCashBased],S.[JobStepInstanceId],S.[JurisdictionId],S.[JurisdictionLevel],S.[ReceivableDetailId],S.[ReceivableId],S.[TaxResult],S.[TaxTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
