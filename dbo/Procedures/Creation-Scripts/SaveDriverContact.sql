SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDriverContact]
(
 @val [dbo].[DriverContact] READONLY
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
MERGE [dbo].[DriverContacts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BenefitsAndProtection]=S.[BenefitsAndProtection],[CIPDocumentSourceForAddress]=S.[CIPDocumentSourceForAddress],[CIPDocumentSourceForName]=S.[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN]=S.[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId]=S.[CIPDocumentSourceNameId],[DateOfBirth]=S.[DateOfBirth],[Description]=S.[Description],[EMailId]=S.[EMailId],[ExtensionNumber1]=S.[ExtensionNumber1],[ExtensionNumber2]=S.[ExtensionNumber2],[FaxNumber]=S.[FaxNumber],[FirstName]=S.[FirstName],[FullName]=S.[FullName],[IsActive]=S.[IsActive],[IsAssumptionApproved]=S.[IsAssumptionApproved],[IsFromAssumption]=S.[IsFromAssumption],[IsImportedContact]=S.[IsImportedContact],[IsSCRA]=S.[IsSCRA],[LastFourDigitSocialSecurityNumber]=S.[LastFourDigitSocialSecurityNumber],[LastName]=S.[LastName],[LastName2]=S.[LastName2],[MailingAddressId]=S.[MailingAddressId],[MiddleName]=S.[MiddleName],[MobilePhoneNumber]=S.[MobilePhoneNumber],[MortgageHighCredit_Amount]=S.[MortgageHighCredit_Amount],[MortgageHighCredit_Currency]=S.[MortgageHighCredit_Currency],[OwnershipPercentage]=S.[OwnershipPercentage],[ParalegalName]=S.[ParalegalName],[PartyContactId]=S.[PartyContactId],[PhoneNumber1]=S.[PhoneNumber1],[PhoneNumber2]=S.[PhoneNumber2],[Prefix]=S.[Prefix],[SCRAEndDate]=S.[SCRAEndDate],[SCRAStartDate]=S.[SCRAStartDate],[SecretaryName]=S.[SecretaryName],[SFDCContactId]=S.[SFDCContactId],[SocialSecurityNumber_CT]=S.[SocialSecurityNumber_CT],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Webpage]=S.[Webpage]
WHEN NOT MATCHED THEN
	INSERT ([BenefitsAndProtection],[CIPDocumentSourceForAddress],[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId],[CreatedById],[CreatedTime],[DateOfBirth],[Description],[DriverId],[EMailId],[ExtensionNumber1],[ExtensionNumber2],[FaxNumber],[FirstName],[FullName],[IsActive],[IsAssumptionApproved],[IsFromAssumption],[IsImportedContact],[IsSCRA],[LastFourDigitSocialSecurityNumber],[LastName],[LastName2],[MailingAddressId],[MiddleName],[MobilePhoneNumber],[MortgageHighCredit_Amount],[MortgageHighCredit_Currency],[OwnershipPercentage],[ParalegalName],[PartyContactId],[PhoneNumber1],[PhoneNumber2],[Prefix],[SCRAEndDate],[SCRAStartDate],[SecretaryName],[SFDCContactId],[SocialSecurityNumber_CT],[UniqueIdentifier],[Webpage])
    VALUES (S.[BenefitsAndProtection],S.[CIPDocumentSourceForAddress],S.[CIPDocumentSourceForName],S.[CIPDocumentSourceForTaxIdOrSSN],S.[CIPDocumentSourceNameId],S.[CreatedById],S.[CreatedTime],S.[DateOfBirth],S.[Description],S.[DriverId],S.[EMailId],S.[ExtensionNumber1],S.[ExtensionNumber2],S.[FaxNumber],S.[FirstName],S.[FullName],S.[IsActive],S.[IsAssumptionApproved],S.[IsFromAssumption],S.[IsImportedContact],S.[IsSCRA],S.[LastFourDigitSocialSecurityNumber],S.[LastName],S.[LastName2],S.[MailingAddressId],S.[MiddleName],S.[MobilePhoneNumber],S.[MortgageHighCredit_Amount],S.[MortgageHighCredit_Currency],S.[OwnershipPercentage],S.[ParalegalName],S.[PartyContactId],S.[PhoneNumber1],S.[PhoneNumber2],S.[Prefix],S.[SCRAEndDate],S.[SCRAStartDate],S.[SecretaryName],S.[SFDCContactId],S.[SocialSecurityNumber_CT],S.[UniqueIdentifier],S.[Webpage])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
