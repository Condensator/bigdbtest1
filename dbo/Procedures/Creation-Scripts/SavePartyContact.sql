SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePartyContact]
(
 @val [dbo].[PartyContact] READONLY
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
MERGE [dbo].[PartyContacts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BenefitsAndProtection]=S.[BenefitsAndProtection],[BusinessEndTimeInHours]=S.[BusinessEndTimeInHours],[BusinessEndTimeInMinutes]=S.[BusinessEndTimeInMinutes],[BusinessStartTimeInHours]=S.[BusinessStartTimeInHours],[BusinessStartTimeInMinutes]=S.[BusinessStartTimeInMinutes],[CIPDocumentSourceForAddress]=S.[CIPDocumentSourceForAddress],[CIPDocumentSourceForName]=S.[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN]=S.[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId]=S.[CIPDocumentSourceNameId],[DateOfBirth]=S.[DateOfBirth],[Description]=S.[Description],[DrivingLicense]=S.[DrivingLicense],[EGNNumber_CT]=S.[EGNNumber_CT],[EMail2]=S.[EMail2],[EMailId]=S.[EMailId],[ExtensionNumber1]=S.[ExtensionNumber1],[ExtensionNumber2]=S.[ExtensionNumber2],[FaxNumber]=S.[FaxNumber],[FirstName]=S.[FirstName],[Foreigner]=S.[Foreigner],[FullName]=S.[FullName],[Gender]=S.[Gender],[IDCardIssuedIn]=S.[IDCardIssuedIn],[IDCardIssuedOn]=S.[IDCardIssuedOn],[IDCardNumber]=S.[IDCardNumber],[IsActive]=S.[IsActive],[IsAssumptionApproved]=S.[IsAssumptionApproved],[IsBookingNotificationAllowed]=S.[IsBookingNotificationAllowed],[IsCreditNotificationAllowed]=S.[IsCreditNotificationAllowed],[IsFromAssumption]=S.[IsFromAssumption],[IsSCRA]=S.[IsSCRA],[IssuedIn]=S.[IssuedIn],[IssuedOn]=S.[IssuedOn],[LastFourDigitSocialSecurityNumber]=S.[LastFourDigitSocialSecurityNumber],[LastName]=S.[LastName],[LastName2]=S.[LastName2],[LN4]=S.[LN4],[MailingAddressId]=S.[MailingAddressId],[MiddleName]=S.[MiddleName],[MobilePhoneNumber]=S.[MobilePhoneNumber],[MortgageHighCredit_Amount]=S.[MortgageHighCredit_Amount],[MortgageHighCredit_Currency]=S.[MortgageHighCredit_Currency],[NationalIdCardNumber_CT]=S.[NationalIdCardNumber_CT],[Notary]=S.[Notary],[OwnershipPercentage]=S.[OwnershipPercentage],[ParalegalName]=S.[ParalegalName],[ParentPartyContactId]=S.[ParentPartyContactId],[PassportAddress]=S.[PassportAddress],[PassportCountry]=S.[PassportCountry],[PassportIssuedOn]=S.[PassportIssuedOn],[PassportNo]=S.[PassportNo],[PhoneNumber1]=S.[PhoneNumber1],[PhoneNumber2]=S.[PhoneNumber2],[PowerOfAttorneyNumber]=S.[PowerOfAttorneyNumber],[PowerOfAttorneyValidity]=S.[PowerOfAttorneyValidity],[Prefix]=S.[Prefix],[RegistarationNoOfNotary]=S.[RegistarationNoOfNotary],[SCRAEndDate]=S.[SCRAEndDate],[SCRAStartDate]=S.[SCRAStartDate],[SecretaryName]=S.[SecretaryName],[SFDCContactId]=S.[SFDCContactId],[SocialSecurityNumber_CT]=S.[SocialSecurityNumber_CT],[TimeZoneId]=S.[TimeZoneId],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Validity]=S.[Validity],[VendorId]=S.[VendorId],[Webpage]=S.[Webpage]
WHEN NOT MATCHED THEN
	INSERT ([BenefitsAndProtection],[BusinessEndTimeInHours],[BusinessEndTimeInMinutes],[BusinessStartTimeInHours],[BusinessStartTimeInMinutes],[CIPDocumentSourceForAddress],[CIPDocumentSourceForName],[CIPDocumentSourceForTaxIdOrSSN],[CIPDocumentSourceNameId],[CreatedById],[CreatedTime],[DateOfBirth],[Description],[DrivingLicense],[EGNNumber_CT],[EMail2],[EMailId],[ExtensionNumber1],[ExtensionNumber2],[FaxNumber],[FirstName],[Foreigner],[FullName],[Gender],[IDCardIssuedIn],[IDCardIssuedOn],[IDCardNumber],[IsActive],[IsAssumptionApproved],[IsBookingNotificationAllowed],[IsCreditNotificationAllowed],[IsFromAssumption],[IsSCRA],[IssuedIn],[IssuedOn],[LastFourDigitSocialSecurityNumber],[LastName],[LastName2],[LN4],[MailingAddressId],[MiddleName],[MobilePhoneNumber],[MortgageHighCredit_Amount],[MortgageHighCredit_Currency],[NationalIdCardNumber_CT],[Notary],[OwnershipPercentage],[ParalegalName],[ParentPartyContactId],[PartyId],[PassportAddress],[PassportCountry],[PassportIssuedOn],[PassportNo],[PhoneNumber1],[PhoneNumber2],[PowerOfAttorneyNumber],[PowerOfAttorneyValidity],[Prefix],[RegistarationNoOfNotary],[SCRAEndDate],[SCRAStartDate],[SecretaryName],[SFDCContactId],[SocialSecurityNumber_CT],[TimeZoneId],[UniqueIdentifier],[Validity],[VendorId],[Webpage])
    VALUES (S.[BenefitsAndProtection],S.[BusinessEndTimeInHours],S.[BusinessEndTimeInMinutes],S.[BusinessStartTimeInHours],S.[BusinessStartTimeInMinutes],S.[CIPDocumentSourceForAddress],S.[CIPDocumentSourceForName],S.[CIPDocumentSourceForTaxIdOrSSN],S.[CIPDocumentSourceNameId],S.[CreatedById],S.[CreatedTime],S.[DateOfBirth],S.[Description],S.[DrivingLicense],S.[EGNNumber_CT],S.[EMail2],S.[EMailId],S.[ExtensionNumber1],S.[ExtensionNumber2],S.[FaxNumber],S.[FirstName],S.[Foreigner],S.[FullName],S.[Gender],S.[IDCardIssuedIn],S.[IDCardIssuedOn],S.[IDCardNumber],S.[IsActive],S.[IsAssumptionApproved],S.[IsBookingNotificationAllowed],S.[IsCreditNotificationAllowed],S.[IsFromAssumption],S.[IsSCRA],S.[IssuedIn],S.[IssuedOn],S.[LastFourDigitSocialSecurityNumber],S.[LastName],S.[LastName2],S.[LN4],S.[MailingAddressId],S.[MiddleName],S.[MobilePhoneNumber],S.[MortgageHighCredit_Amount],S.[MortgageHighCredit_Currency],S.[NationalIdCardNumber_CT],S.[Notary],S.[OwnershipPercentage],S.[ParalegalName],S.[ParentPartyContactId],S.[PartyId],S.[PassportAddress],S.[PassportCountry],S.[PassportIssuedOn],S.[PassportNo],S.[PhoneNumber1],S.[PhoneNumber2],S.[PowerOfAttorneyNumber],S.[PowerOfAttorneyValidity],S.[Prefix],S.[RegistarationNoOfNotary],S.[SCRAEndDate],S.[SCRAStartDate],S.[SecretaryName],S.[SFDCContactId],S.[SocialSecurityNumber_CT],S.[TimeZoneId],S.[UniqueIdentifier],S.[Validity],S.[VendorId],S.[Webpage])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
