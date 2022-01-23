SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditProfileCustomer]
(
 @val [dbo].[CreditProfileCustomer] READONLY
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
MERGE [dbo].[CreditProfileCustomers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[ApprovedExchangeId]=S.[ApprovedExchangeId],[ApprovedRegulatorId]=S.[ApprovedRegulatorId],[BusinessTypeId]=S.[BusinessTypeId],[BusinessTypeNAICSCodeId]=S.[BusinessTypeNAICSCodeId],[BusinessTypesSICsCodeId]=S.[BusinessTypesSICsCodeId],[CIPDocumentSourceForName]=S.[CIPDocumentSourceForName],[CIPDocumentSourceNameId]=S.[CIPDocumentSourceNameId],[City]=S.[City],[CompanyName]=S.[CompanyName],[ConsentDate]=S.[ConsentDate],[CreationDate]=S.[CreationDate],[CustomerId]=S.[CustomerId],[CustomerName]=S.[CustomerName],[DateOfBirth]=S.[DateOfBirth],[Description]=S.[Description],[Division]=S.[Division],[FirstName]=S.[FirstName],[HomeAddressLine1]=S.[HomeAddressLine1],[HomeAddressLine2]=S.[HomeAddressLine2],[HomeCity]=S.[HomeCity],[HomeDivision]=S.[HomeDivision],[HomePostalCode]=S.[HomePostalCode],[HomeStateId]=S.[HomeStateId],[IncomeTaxStatus]=S.[IncomeTaxStatus],[IsBillingAddressSameAsMain]=S.[IsBillingAddressSameAsMain],[IsCorporate]=S.[IsCorporate],[IsSoleProprietor]=S.[IsSoleProprietor],[JurisdictionOfSovereignId]=S.[JurisdictionOfSovereignId],[LastFourDigitUniqueIdentificationNumber]=S.[LastFourDigitUniqueIdentificationNumber],[LastName]=S.[LastName],[LegalFormationTypeConfigId]=S.[LegalFormationTypeConfigId],[LegalNameValidationDate]=S.[LegalNameValidationDate],[PartyType]=S.[PartyType],[PercentageOfGovernmentOwnership]=S.[PercentageOfGovernmentOwnership],[PostalCode]=S.[PostalCode],[StateId]=S.[StateId],[StateOfIncorporationId]=S.[StateOfIncorporationId],[Status]=S.[Status],[UniqueIdentificationNumber_CT]=S.[UniqueIdentificationNumber_CT],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[ApprovedExchangeId],[ApprovedRegulatorId],[BusinessTypeId],[BusinessTypeNAICSCodeId],[BusinessTypesSICsCodeId],[CIPDocumentSourceForName],[CIPDocumentSourceNameId],[City],[CompanyName],[ConsentDate],[CreatedById],[CreatedTime],[CreationDate],[CustomerId],[CustomerName],[DateOfBirth],[Description],[Division],[FirstName],[HomeAddressLine1],[HomeAddressLine2],[HomeCity],[HomeDivision],[HomePostalCode],[HomeStateId],[Id],[IncomeTaxStatus],[IsBillingAddressSameAsMain],[IsCorporate],[IsSoleProprietor],[JurisdictionOfSovereignId],[LastFourDigitUniqueIdentificationNumber],[LastName],[LegalFormationTypeConfigId],[LegalNameValidationDate],[PartyType],[PercentageOfGovernmentOwnership],[PostalCode],[StateId],[StateOfIncorporationId],[Status],[UniqueIdentificationNumber_CT])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[ApprovedExchangeId],S.[ApprovedRegulatorId],S.[BusinessTypeId],S.[BusinessTypeNAICSCodeId],S.[BusinessTypesSICsCodeId],S.[CIPDocumentSourceForName],S.[CIPDocumentSourceNameId],S.[City],S.[CompanyName],S.[ConsentDate],S.[CreatedById],S.[CreatedTime],S.[CreationDate],S.[CustomerId],S.[CustomerName],S.[DateOfBirth],S.[Description],S.[Division],S.[FirstName],S.[HomeAddressLine1],S.[HomeAddressLine2],S.[HomeCity],S.[HomeDivision],S.[HomePostalCode],S.[HomeStateId],S.[Id],S.[IncomeTaxStatus],S.[IsBillingAddressSameAsMain],S.[IsCorporate],S.[IsSoleProprietor],S.[JurisdictionOfSovereignId],S.[LastFourDigitUniqueIdentificationNumber],S.[LastName],S.[LegalFormationTypeConfigId],S.[LegalNameValidationDate],S.[PartyType],S.[PercentageOfGovernmentOwnership],S.[PostalCode],S.[StateId],S.[StateOfIncorporationId],S.[Status],S.[UniqueIdentificationNumber_CT])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
