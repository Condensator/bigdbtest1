SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdatePartialEncryption]
(
@PartyInfoList  PartyInfoType readonly,
@PartyContactInfoList  PartyContactInfoType readonly,
@BankAccountInfoList  BankAccountInfoType readonly
)
AS
BEGIN
SET NOCOUNT ON
UPDATE Parties
SET LastFourDigitUniqueIdentificationNumber = PartyList.FourDigitUniqueIdentificationNumber
FROM Parties
JOIN @PartyInfoList PartyList ON Parties.Id = PartyList.PartyId
UPDATE PartyContacts
SET LastFourDigitSocialSecurityNumber = PartyContactList.FourDigitSocialSecurityNumber
FROM PartyContacts
JOIN @PartyContactInfoList PartyContactList ON PartyContacts.Id = PartyContactList.PartyContactId
UPDATE BankAccounts
SET LastFourDigitAccountNumber = BankAccountList.FourDigitAccountNumber
FROM BankAccounts
JOIN @BankAccountInfoList BankAccountList ON BankAccounts.Id = BankAccountList.BankId
END

GO
