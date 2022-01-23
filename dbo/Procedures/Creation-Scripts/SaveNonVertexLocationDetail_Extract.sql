SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveNonVertexLocationDetail_Extract]
(
 @val [dbo].[NonVertexLocationDetail_Extract] READONLY
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
MERGE [dbo].[NonVertexLocationDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CountryId]=S.[CountryId],[CountryShortName]=S.[CountryShortName],[IsCityTaxExempt]=S.[IsCityTaxExempt],[IsCountryTaxExempt]=S.[IsCountryTaxExempt],[IsCountyTaxExempt]=S.[IsCountyTaxExempt],[IsStateTaxExempt]=S.[IsStateTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[JurisdictionId]=S.[JurisdictionId],[LocationId]=S.[LocationId],[StateId]=S.[StateId],[StateShortName]=S.[StateShortName],[TaxBasisType]=S.[TaxBasisType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxMode]=S.[UpfrontTaxMode]
WHEN NOT MATCHED THEN
	INSERT ([CountryId],[CountryShortName],[CreatedById],[CreatedTime],[IsCityTaxExempt],[IsCountryTaxExempt],[IsCountyTaxExempt],[IsStateTaxExempt],[JobStepInstanceId],[JurisdictionId],[LocationId],[StateId],[StateShortName],[TaxBasisType],[UpfrontTaxMode])
    VALUES (S.[CountryId],S.[CountryShortName],S.[CreatedById],S.[CreatedTime],S.[IsCityTaxExempt],S.[IsCountryTaxExempt],S.[IsCountyTaxExempt],S.[IsStateTaxExempt],S.[JobStepInstanceId],S.[JurisdictionId],S.[LocationId],S.[StateId],S.[StateShortName],S.[TaxBasisType],S.[UpfrontTaxMode])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
