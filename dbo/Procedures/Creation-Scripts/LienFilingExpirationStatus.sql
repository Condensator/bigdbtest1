SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[LienFilingExpirationStatus]
(
@EntityType NVARCHAR(MAX)
,@CustomerNumber NVARCHAR(40) = NULL
,@ContractSequenceNumber NVARCHAR(40) = NULL
,@LegalEntity NVARCHAR(40) = NULL
,@AsOfDate DATETIME = NULL
,@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
--Customer Filings
SELECT
LienFiling.EntityType [EntityType]
,Party.PartyNumber [Customer#]
,Party.PartyName [CustomerName]
,'' [Sequence#]
,NULL [Maturity Date]
,LienFiling.Id LienID
,LienFiling.TransactionType [TransactionType]
,Debtor.PartyName [FirstDebtor]
,CASE
WHEN LienFiling.SecuredPartyType = 'LegalEntity'
THEN  LegalEntity.Name
WHEN LienFiling.SecuredPartyType = 'Funder'
THEN SecuredFunder.PartyName
ELSE  ' '
END [SecuredParty]
,LienFiling.LienRefNumber [LienReference#]
,LienResponse.AuthorityFileNumber [File#]
,LienResponse.AuthorityFilingStatus [FilingStatus]
,LienResponse.AuthorityFilingType [FilingType]
,LienResponse.AuthorityFileDate [FileDate]
,LienResponse.AuthorityFileExpiryDate [ExpirationDate]
,ISNULL(EntityResourcesForState.Value,State.ShortName) [State]
,ISNULL(EntityResourcesForCountry.Value,Country.ShortName) [Country]
,LegalEntity.LegalEntityNumber [LegalEntity#]
,NULL [LeaseFinanceId]
,NULL [LoanFinanceId]
INTO #LienFiling
FROM LienFilings LienFiling
JOIN LienResponses LienResponse on LienResponse.Id = LienFiling.Id
JOIN States State on State.Id = LienFiling.StateId
LEFT JOIN EntityResources EntityResourcesForState ON State.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'ShortName'
AND EntityResourcesForState.Culture= @Culture
JOIN Countries Country on Country.Id=State.CountryId
LEFT JOIN EntityResources EntityResourcesForCountry ON Country.Id = EntityResourcesForCountry.EntityId
AND EntityResourcesForCountry.EntityType = 'Country'
AND EntityResourcesForCountry.Name = 'ShortName'
AND EntityResourcesForCountry.Culture= @Culture
JOIN Parties Party on Party.Id  = LienFiling.CustomerId
LEFT JOIN Parties Debtor on Debtor.Id = LienFiling.FirstDebtorId
LEFT JOIN Parties SecuredFunder on SecuredFunder.Id = LienFiling.SecuredFunderId
LEFT JOIN LegalEntities LegalEntity on LegalEntity.Id = LienFiling.SecuredLegalEntityId
WHERE LienFiling.EntityType = @EntityType
AND (@CustomerNumber IS NULL OR Party.PartyNumber = @CustomerNumber)
AND (@LegalEntity  IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')) )
AND (@AsOfDate  IS NULL OR CAST(LienResponse.AuthorityFileExpiryDate AS DATE) <= CAST(@AsOfDate AS DATE))
UNION ALL
--Lease Filings
SELECT
LienFiling.EntityType [EntityType]
,Party.PartyNumber [Customer#]
,Party.PartyName [CustomerName]
,Contract.SequenceNumber [Sequence#]
,leasefinancedetails.MaturityDate [Maturity Date]
,LienFiling.Id LienID
,LienFiling.TransactionType [TransactionType]
,Debtor.PartyName [FirstDebtor]
,CASE
WHEN LienFiling.SecuredPartyType = 'LegalEntity'
THEN  LegalEntity.Name
WHEN LienFiling.SecuredPartyType = 'Funder'
THEN SecuredFunder.PartyName
ELSE  ' '
END [SecuredParty]
,LienFiling.LienRefNumber [LienReference#]
,LienResponse.AuthorityFileNumber [File#]
,LienResponse.AuthorityFilingStatus [FilingStatus]
,LienResponse.AuthorityFilingType [FilingType]
,LienResponse.AuthorityFileDate [FileDate]
,LienResponse.AuthorityFileExpiryDate [ExpirationDate]
,ISNULL(EntityResourcesForState.Value,State.ShortName) [State]
,ISNULL(EntityResourcesForCountry.Value,Country.ShortName) [Country]
,LegalEntity.LegalEntityNumber [LegalEntity#]
,leasefinance.Id [LeaseFinanceId]
,NULL [LoanFinanceId]
FROM LienFilings LienFiling
JOIN LienResponses LienResponse on LienResponse.Id = LienFiling.Id
JOIN States State on State.Id = LienFiling.StateId
LEFT JOIN EntityResources EntityResourcesForState ON State.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'ShortName'
AND EntityResourcesForState.Culture= @Culture
JOIN Countries Country on Country.Id=State.CountryId
LEFT JOIN EntityResources EntityResourcesForCountry ON Country.Id = EntityResourcesForCountry.EntityId
AND EntityResourcesForCountry.EntityType = 'Country'
AND EntityResourcesForCountry.Name = 'ShortName'
AND EntityResourcesForCountry.Culture= @Culture
JOIN Contracts Contract ON Contract.Id = LienFiling.ContractId
JOIN LeaseFinances leasefinance on leasefinance.ContractId = Contract.Id AND leasefinance.IsCurrent=1
JOIN LeaseFinanceDetails leasefinancedetails on leasefinancedetails.Id = leasefinance.Id
JOIN Parties Party on Party.Id  = LienFiling.CustomerId
LEFT JOIN Parties Debtor on Debtor.Id = LienFiling.FirstDebtorId
LEFT JOIN Parties SecuredFunder on SecuredFunder.Id = LienFiling.SecuredFunderId
LEFT JOIN LegalEntities LegalEntity on LegalEntity.Id = LienFiling.SecuredLegalEntityId
WHERE Contract.ContractType = @EntityType
AND (@ContractSequenceNumber IS NULL OR Contract.SequenceNumber  = @ContractSequenceNumber)
AND (@LegalEntity  IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')) )
AND (@AsOfDate  IS NULL OR CAST(LienResponse.AuthorityFileExpiryDate AS DATE) <= CAST(@AsOfDate AS DATE))
UNION ALL
--Loan Filings
SELECT
LienFiling.EntityType [EntityType]
,Party.PartyNumber [Customer#]
,Party.PartyName [CustomerName]
,Contract.SequenceNumber [Sequence#]
,loanfinance.MaturityDate [Maturity Date]
,LienFiling.Id LienID
,LienFiling.TransactionType [TransactionType]
,Debtor.PartyName [FirstDebtor]
,CASE
WHEN LienFiling.SecuredPartyType = 'LegalEntity'
THEN  LegalEntity.Name
WHEN LienFiling.SecuredPartyType = 'Funder'
THEN SecuredFunder.PartyName
ELSE  ' '
END [SecuredParty]
,LienFiling.LienRefNumber [LienReference#]
,LienResponse.AuthorityFileNumber [File#]
,LienResponse.AuthorityFilingStatus [FilingStatus]
,LienResponse.AuthorityFilingType [FilingType]
,LienResponse.AuthorityFileDate [FileDate]
,LienResponse.AuthorityFileExpiryDate [ExpirationDate]
,ISNULL(EntityResourcesForState.Value,State.ShortName) [State]
,ISNULL(EntityResourcesForCountry.Value,Country.ShortName) [Country]
,LegalEntity.LegalEntityNumber [LegalEntity#]
,NULL [LeaseFinanceId]
,loanfinance.Id [LoanFinanceId]
FROM LienFilings LienFiling
JOIN LienResponses LienResponse on LienResponse.Id = LienFiling.Id
JOIN States State on State.Id = LienFiling.StateId
LEFT JOIN EntityResources EntityResourcesForState ON State.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'ShortName'
AND EntityResourcesForState.Culture= @Culture
JOIN Countries Country on Country.Id=State.CountryId
LEFT JOIN EntityResources EntityResourcesForCountry ON Country.Id = EntityResourcesForCountry.EntityId
AND EntityResourcesForCountry.EntityType = 'Country'
AND EntityResourcesForCountry.Name = 'ShortName'
AND EntityResourcesForCountry.Culture= @Culture
JOIN Contracts Contract ON Contract.Id = LienFiling.ContractId
JOIN LoanFinances loanfinance on loanfinance.ContractId = Contract.Id AND loanfinance.IsCurrent=1
JOIN Parties Party on Party.Id  = LienFiling.CustomerId
LEFT JOIN Parties Debtor on Debtor.Id = LienFiling.FirstDebtorId
LEFT JOIN Parties SecuredFunder on SecuredFunder.Id = LienFiling.SecuredFunderId
LEFT JOIN LegalEntities LegalEntity on LegalEntity.Id = LienFiling.SecuredLegalEntityId
WHERE Contract.ContractType = @EntityType
AND (@ContractSequenceNumber IS NULL OR Contract.SequenceNumber  = @ContractSequenceNumber)
AND (@LegalEntity  IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')) )
AND (@AsOfDate  IS NULL OR CAST(LienResponse.AuthorityFileExpiryDate AS DATE) <= CAST(@AsOfDate AS DATE))
ORDER BY Party.PartyName,Sequence#,LienFiling.Id
;WITH CTE_LoanPaymentDate AS(
SELECT lf.LoanFinanceId,MAX(pv.PaymentDate) [PVPaymentDate],MAX(dr.PaymentDate) [DRPaymentDate]
FROM dbo.LoanFundings lf
INNER JOIN dbo.PayableInvoices pi
ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri
ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr
ON dri.DisbursementRequestId = dr.Id
INNER JOIN dbo.DisbursementRequestPayables drp
ON drp.DisbursementRequestId = dr.Id
INNER JOIN dbo.TreasuryPayableDetails tpd
ON tpd.PayableId = drp.PayableId
INNER JOIN dbo.PaymentVoucherDetails pvd
ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
INNER JOIN dbo.PaymentVouchers pv
ON pvd.PaymentVoucherId = pv.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 0
GROUP BY lf.LoanFinanceId
)
SELECT
LoanFinanceId,
(SELECT MAX(v) FROM (VALUES (PVPaymentDate),(DRPaymentDate)) AS value(v)) [PaymentDate]
INTO #LienLoan FROM CTE_LoanPaymentDate
;WITH CTE_LeasePaymentDate AS(
SELECT lf.LeaseFinanceId,MAX(pv.PaymentDate) [PVPaymentDate],MAX(dr.PaymentDate) [DRPaymentDate]
FROM dbo.LeaseFundings lf
INNER JOIN dbo.PayableInvoices pi
ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri
ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr
ON dri.DisbursementRequestId = dr.Id
INNER JOIN dbo.DisbursementRequestPayables drp
ON drp.DisbursementRequestId = dr.Id
INNER JOIN dbo.TreasuryPayableDetails tpd
ON tpd.PayableId = drp.PayableId
INNER JOIN dbo.PaymentVoucherDetails pvd
ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
INNER JOIN dbo.PaymentVouchers pv
ON pvd.PaymentVoucherId = pv.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 0
GROUP BY lf.LeaseFinanceId
)
SELECT
LeaseFinanceId,
(SELECT MAX(v) FROM (VALUES (PVPaymentDate),(DRPaymentDate)) AS value(v)) [PaymentDate]
INTO #LienLease FROM CTE_LeasePaymentDate
SELECT
lf.EntityType,
lf.Customer#,
lf.CustomerName,
lf.Sequence#,
lf.[Maturity Date],
lf.LienID,
lf.TransactionType,
lf.FirstDebtor,
lf.SecuredParty,
lf.LienReference#,
lf.File#,
lf.FilingStatus,
lf.FilingType,
lf.FileDate,
lf.ExpirationDate,
lf.State,
lf.Country,
lf.LegalEntity#,
ISNULL(#LienLease.PaymentDate,#LienLoan.PaymentDate) [FundingDate]
FROM dbo.#LienFiling lf
LEFT JOIN #LienLoan
ON lf.LoanFinanceId = #LienLoan.LoanFinanceId
LEFT JOIN #LienLease
ON lf.LeaseFinanceId = #LienLease.LeaseFinanceId
DROP TABLE #LienFiling
DROP TABLE #LienLoan
DROP TABLE #LienLease
END

GO
