SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOpportunityCustomer]
(
 @val [dbo].[OpportunityCustomer] READONLY
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
MERGE [dbo].[OpportunityCustomers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[ApprovedExchangeId]=S.[ApprovedExchangeId],[ApprovedRegulatorId]=S.[ApprovedRegulatorId],[BusinessTypeId]=S.[BusinessTypeId],[BusinessTypeNAICSCodeId]=S.[BusinessTypeNAICSCodeId],[BusinessTypesSICsCodeId]=S.[BusinessTypesSICsCodeId],[CIPDocumentSourceForName]=S.[CIPDocumentSourceForName],[CIPDocumentSourceNameId]=S.[CIPDocumentSourceNameId],[City]=S.[City],[CompanyName]=S.[CompanyName],[CreationDate]=S.[CreationDate],[CustomerId]=S.[CustomerId],[CustomerName]=S.[CustomerName],[DateOfBirth]=S.[DateOfBirth],[DateofIssueID]=S.[DateofIssueID],[Description]=S.[Description],[Division]=S.[Division],[EIKNumber_CT]=S.[EIKNumber_CT],[FirstName]=S.[FirstName],[Gender]=S.[Gender],[HomeAddressLine1]=S.[HomeAddressLine1],[HomeAddressLine2]=S.[HomeAddressLine2],[HomeAddressLine3]=S.[HomeAddressLine3],[HomeCity]=S.[HomeCity],[HomeDivision]=S.[HomeDivision],[HomeNeighborhood]=S.[HomeNeighborhood],[HomePostalCode]=S.[HomePostalCode],[HomeSettlement]=S.[HomeSettlement],[HomeStateId]=S.[HomeStateId],[HomeSubdivisionOrMunicipality]=S.[HomeSubdivisionOrMunicipality],[IncomeTaxStatus]=S.[IncomeTaxStatus],[IsBillingAddressSameAsMain]=S.[IsBillingAddressSameAsMain],[IsCorporate]=S.[IsCorporate],[IsSoleProprietor]=S.[IsSoleProprietor],[IssuedIn]=S.[IssuedIn],[IsVATRegistration]=S.[IsVATRegistration],[JurisdictionOfSovereignId]=S.[JurisdictionOfSovereignId],[LastFourDigitUniqueIdentificationNumber]=S.[LastFourDigitUniqueIdentificationNumber],[LastName]=S.[LastName],[LegalFormationTypeConfigId]=S.[LegalFormationTypeConfigId],[LegalNameValidationDate]=S.[LegalNameValidationDate],[MiddleName]=S.[MiddleName],[NationalIdCardNumber_CT]=S.[NationalIdCardNumber_CT],[Neighborhood]=S.[Neighborhood],[PartyType]=S.[PartyType],[PercentageOfGovernmentOwnership]=S.[PercentageOfGovernmentOwnership],[PostalCode]=S.[PostalCode],[Representative1]=S.[Representative1],[Representative2]=S.[Representative2],[Representative3]=S.[Representative3],[Settlement]=S.[Settlement],[StateId]=S.[StateId],[StateOfIncorporationId]=S.[StateOfIncorporationId],[Status]=S.[Status],[SubdivisionOrMunicipality]=S.[SubdivisionOrMunicipality],[UniqueIdentificationNumber_CT]=S.[UniqueIdentificationNumber_CT],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATRegistration]=S.[VATRegistration],[WayOfRepresentation]=S.[WayOfRepresentation]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[AddressLine3],[ApprovedExchangeId],[ApprovedRegulatorId],[BusinessTypeId],[BusinessTypeNAICSCodeId],[BusinessTypesSICsCodeId],[CIPDocumentSourceForName],[CIPDocumentSourceNameId],[City],[CompanyName],[CreatedById],[CreatedTime],[CreationDate],[CustomerId],[CustomerName],[DateOfBirth],[DateofIssueID],[Description],[Division],[EIKNumber_CT],[FirstName],[Gender],[HomeAddressLine1],[HomeAddressLine2],[HomeAddressLine3],[HomeCity],[HomeDivision],[HomeNeighborhood],[HomePostalCode],[HomeSettlement],[HomeStateId],[HomeSubdivisionOrMunicipality],[Id],[IncomeTaxStatus],[IsBillingAddressSameAsMain],[IsCorporate],[IsSoleProprietor],[IssuedIn],[IsVATRegistration],[JurisdictionOfSovereignId],[LastFourDigitUniqueIdentificationNumber],[LastName],[LegalFormationTypeConfigId],[LegalNameValidationDate],[MiddleName],[NationalIdCardNumber_CT],[Neighborhood],[PartyType],[PercentageOfGovernmentOwnership],[PostalCode],[Representative1],[Representative2],[Representative3],[Settlement],[StateId],[StateOfIncorporationId],[Status],[SubdivisionOrMunicipality],[UniqueIdentificationNumber_CT],[VATRegistration],[WayOfRepresentation])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[ApprovedExchangeId],S.[ApprovedRegulatorId],S.[BusinessTypeId],S.[BusinessTypeNAICSCodeId],S.[BusinessTypesSICsCodeId],S.[CIPDocumentSourceForName],S.[CIPDocumentSourceNameId],S.[City],S.[CompanyName],S.[CreatedById],S.[CreatedTime],S.[CreationDate],S.[CustomerId],S.[CustomerName],S.[DateOfBirth],S.[DateofIssueID],S.[Description],S.[Division],S.[EIKNumber_CT],S.[FirstName],S.[Gender],S.[HomeAddressLine1],S.[HomeAddressLine2],S.[HomeAddressLine3],S.[HomeCity],S.[HomeDivision],S.[HomeNeighborhood],S.[HomePostalCode],S.[HomeSettlement],S.[HomeStateId],S.[HomeSubdivisionOrMunicipality],S.[Id],S.[IncomeTaxStatus],S.[IsBillingAddressSameAsMain],S.[IsCorporate],S.[IsSoleProprietor],S.[IssuedIn],S.[IsVATRegistration],S.[JurisdictionOfSovereignId],S.[LastFourDigitUniqueIdentificationNumber],S.[LastName],S.[LegalFormationTypeConfigId],S.[LegalNameValidationDate],S.[MiddleName],S.[NationalIdCardNumber_CT],S.[Neighborhood],S.[PartyType],S.[PercentageOfGovernmentOwnership],S.[PostalCode],S.[Representative1],S.[Representative2],S.[Representative3],S.[Settlement],S.[StateId],S.[StateOfIncorporationId],S.[Status],S.[SubdivisionOrMunicipality],S.[UniqueIdentificationNumber_CT],S.[VATRegistration],S.[WayOfRepresentation])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
