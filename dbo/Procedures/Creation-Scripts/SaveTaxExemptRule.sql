SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxExemptRule]
(
 @val [dbo].[TaxExemptRule] READONLY
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
MERGE [dbo].[TaxExemptRules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CountryExemptionNumber]=S.[CountryExemptionNumber],[EntityType]=S.[EntityType],[IsCityTaxExempt]=S.[IsCityTaxExempt],[IsCountryTaxExempt]=S.[IsCountryTaxExempt],[IsCountyTaxExempt]=S.[IsCountyTaxExempt],[IsStateTaxExempt]=S.[IsStateTaxExempt],[StateExemptionNumber]=S.[StateExemptionNumber],[StateTaxExemptionReasonId]=S.[StateTaxExemptionReasonId],[TaxExemptionReasonId]=S.[TaxExemptionReasonId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CountryExemptionNumber],[CreatedById],[CreatedTime],[EntityType],[IsCityTaxExempt],[IsCountryTaxExempt],[IsCountyTaxExempt],[IsStateTaxExempt],[StateExemptionNumber],[StateTaxExemptionReasonId],[TaxExemptionReasonId])
    VALUES (S.[CountryExemptionNumber],S.[CreatedById],S.[CreatedTime],S.[EntityType],S.[IsCityTaxExempt],S.[IsCountryTaxExempt],S.[IsCountyTaxExempt],S.[IsStateTaxExempt],S.[StateExemptionNumber],S.[StateTaxExemptionReasonId],S.[TaxExemptionReasonId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
