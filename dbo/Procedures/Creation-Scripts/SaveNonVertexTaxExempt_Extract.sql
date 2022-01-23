SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexTaxExempt_Extract]
(
 @val [dbo].[NonVertexTaxExempt_Extract] READONLY
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
MERGE [dbo].[NonVertexTaxExempt_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[CityTaxExemptRule]=S.[CityTaxExemptRule],[CountryTaxExemptRule]=S.[CountryTaxExemptRule],[CountyTaxExemptRule]=S.[CountyTaxExemptRule],[IsCityTaxExempt]=S.[IsCityTaxExempt],[IsCountryTaxExempt]=S.[IsCountryTaxExempt],[IsCountyTaxExempt]=S.[IsCountyTaxExempt],[IsStateTaxExempt]=S.[IsStateTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableDetailId]=S.[ReceivableDetailId],[StateTaxExemptRule]=S.[StateTaxExemptRule],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CityTaxExemptRule],[CountryTaxExemptRule],[CountyTaxExemptRule],[CreatedById],[CreatedTime],[IsCityTaxExempt],[IsCountryTaxExempt],[IsCountyTaxExempt],[IsStateTaxExempt],[JobStepInstanceId],[ReceivableDetailId],[StateTaxExemptRule])
    VALUES (S.[AssetId],S.[CityTaxExemptRule],S.[CountryTaxExemptRule],S.[CountyTaxExemptRule],S.[CreatedById],S.[CreatedTime],S.[IsCityTaxExempt],S.[IsCountryTaxExempt],S.[IsCountyTaxExempt],S.[IsStateTaxExempt],S.[JobStepInstanceId],S.[ReceivableDetailId],S.[StateTaxExemptRule])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
