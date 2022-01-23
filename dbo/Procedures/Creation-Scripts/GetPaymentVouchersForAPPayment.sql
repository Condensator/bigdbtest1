SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPaymentVouchersForAPPayment]
(
@VoucherIds nvarchar(max)
)
AS
SET NOCOUNT ON;
SELECT * INTO #ExistingVouchers FROM ConvertCSVToBigIntTable(@VoucherIds, ',');
SELECT
PaymentVouchers.Id as PaymentVoucherId,
Parties.PartyName as PayeeName,
Parties.Id as VendorId,
Vendors.Type as VendorType,
LegalEntities.Id as LegalEntityId,
LegalEntities.LegalEntityNumber as LegalEntityNumber,
LegalEntities.Name as LegalEntityName,
Currencies.Id as CurrencyId,
CurrencyCodes.ISO as CurrencyISO,
RemitToes.Name as RemitToName,
PaymentVouchers.ReceiptType as RemittanceType,
CASE
WHEN BankAccounts.LastFourDigitAccountNumber IS NOT NULL THEN '****'+BankAccounts.LastFourDigitAccountNumber
ELSE NULL END AS PayFromAccount,
MAX(PaymentVouchers.Amount_Amount) as PaymentAmount_Amount,
MAX(PaymentVouchers.Amount_Currency) as PaymentAmount_Currency,
PaymentVouchers.Status as VoucherStatus,
MAX(Payables.SourceTable) as Source,
MAX(Payables.SourceId) as SourceId,
LegalEntities.GLConfigurationId as GLConfigurationId,
Parties.PartyNumber as PayeeNumber,
PaymentVouchers.RemitToId AS RemitToId,
PartyContacts.FullName AS RemitToContact,
PartyAddresses.AddressLine1 AS RemitToAddressLine1,
PartyAddresses.AddressLine2 AS RemitToAddressLine2,
PartyAddresses.City AS RemitToCity,
States.LongName AS RemitToState,
Countries.LongName AS RemitToCountry,
PartyAddresses.Description AS RemitToDescription,
PaymentVouchers.IsManual as IsManual,
MAX(PaymentVouchers.WithholdingTaxAmount_Amount) WithholdingTaxAmount_Amount,
MAX(PaymentVouchers.WithholdingTaxAmount_Currency) as WithholdingTaxAmount_Currency
FROM PaymentVouchers
JOIN #ExistingVouchers
ON PaymentVouchers.Id =#ExistingVouchers.ID
JOIN LegalEntities
ON PaymentVouchers.LegalEntityId= LegalEntities.Id
JOIN RemitToes
ON PaymentVouchers.RemitToId =RemitToes.Id
LEFT JOIN PartyContacts
ON RemitToes.PartyContactId = PartyContacts.Id
LEFT JOIN PartyAddresses
ON RemitToes.PartyAddressId = PartyAddresses.Id
LEFT JOIN States
ON PartyAddresses.StateId = States.Id
LEFT JOIN Countries
ON States.CountryId = Countries.Id
JOIN BankAccounts
ON PaymentVouchers.PayFromAccountId = BankAccounts.Id
JOIN PaymentVoucherDetails
ON PaymentVouchers.Id =PaymentVoucherDetails.PaymentVoucherId
JOIN TreasuryPayables
ON PaymentVoucherDetails.TreasuryPayableId = TreasuryPayables.Id
JOIN Parties
ON TreasuryPayables.PayeeId = Parties.Id
JOIN Vendors
ON Parties.Id = Vendors.Id
JOIN Currencies
ON TreasuryPayables.CurrencyId=Currencies.Id
JOIN CurrencyCodes
ON Currencies.CurrencyCodeId = CurrencyCodes.Id
JOIN TreasuryPayableDetails
ON TreasuryPayables.Id=TreasuryPayableDetails.TreasuryPayableId AND TreasuryPayableDetails.IsActive = 1
JOIN Payables
ON TreasuryPayableDetails.PayableId = Payables.Id
GROUP BY
PaymentVouchers.Id,
Parties.PartyName,
Parties.PartyNumber,
Parties.Id,
Vendors.Type,
LegalEntities.Id,
LegalEntities.LegalEntityNumber,
LegalEntities.Name,
LegalEntities.GLConfigurationId,
Currencies.Id ,
CurrencyCodes.ISO ,
RemitToes.Name ,
PaymentVouchers.ReceiptType ,
BankAccounts.LastFourDigitAccountNumber,
PaymentVouchers.Status ,
PaymentVouchers.RemitToId ,
PartyContacts.FullName ,
PartyAddresses.AddressLine1 ,
PartyAddresses.AddressLine2 ,
PartyAddresses.City ,
States.LongName ,
Countries.LongName ,
PartyAddresses.Description,
PaymentVouchers.IsManual

GO
