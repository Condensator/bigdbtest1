SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLocation]
(
 @val [dbo].[Location] READONLY
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
MERGE [dbo].[Locations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[ApprovalStatus]=S.[ApprovalStatus],[City]=S.[City],[CityTaxExemptionRate]=S.[CityTaxExemptionRate],[Code]=S.[Code],[ContactPersonId]=S.[ContactPersonId],[CountryTaxExemptionRate]=S.[CountryTaxExemptionRate],[CustomerId]=S.[CustomerId],[Description]=S.[Description],[Division]=S.[Division],[DivisionTaxExemptionRate]=S.[DivisionTaxExemptionRate],[IncludedPostalCodeInLocationLookup]=S.[IncludedPostalCodeInLocationLookup],[IsActive]=S.[IsActive],[JurisdictionDetailId]=S.[JurisdictionDetailId],[JurisdictionId]=S.[JurisdictionId],[Latitude]=S.[Latitude],[Longitude]=S.[Longitude],[Name]=S.[Name],[Neighborhood]=S.[Neighborhood],[PortfolioId]=S.[PortfolioId],[PostalCode]=S.[PostalCode],[StateId]=S.[StateId],[StateTaxExemptionRate]=S.[StateTaxExemptionRate],[SubdivisionOrMunicipality]=S.[SubdivisionOrMunicipality],[TaxAreaId]=S.[TaxAreaId],[TaxAreaVerifiedTillDate]=S.[TaxAreaVerifiedTillDate],[TaxBasisType]=S.[TaxBasisType],[TaxExemptRuleId]=S.[TaxExemptRuleId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxMode]=S.[UpfrontTaxMode],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[AddressLine3],[ApprovalStatus],[City],[CityTaxExemptionRate],[Code],[ContactPersonId],[CountryTaxExemptionRate],[CreatedById],[CreatedTime],[CustomerId],[Description],[Division],[DivisionTaxExemptionRate],[IncludedPostalCodeInLocationLookup],[IsActive],[JurisdictionDetailId],[JurisdictionId],[Latitude],[Longitude],[Name],[Neighborhood],[PortfolioId],[PostalCode],[StateId],[StateTaxExemptionRate],[SubdivisionOrMunicipality],[TaxAreaId],[TaxAreaVerifiedTillDate],[TaxBasisType],[TaxExemptRuleId],[UpfrontTaxMode],[VendorId])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[ApprovalStatus],S.[City],S.[CityTaxExemptionRate],S.[Code],S.[ContactPersonId],S.[CountryTaxExemptionRate],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[Description],S.[Division],S.[DivisionTaxExemptionRate],S.[IncludedPostalCodeInLocationLookup],S.[IsActive],S.[JurisdictionDetailId],S.[JurisdictionId],S.[Latitude],S.[Longitude],S.[Name],S.[Neighborhood],S.[PortfolioId],S.[PostalCode],S.[StateId],S.[StateTaxExemptionRate],S.[SubdivisionOrMunicipality],S.[TaxAreaId],S.[TaxAreaVerifiedTillDate],S.[TaxBasisType],S.[TaxExemptRuleId],S.[UpfrontTaxMode],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
