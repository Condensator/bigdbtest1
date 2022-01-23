SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReceivableDetails]
(
@ReceivableIds nvarchar(max)
)
AS
SET NOCOUNT ON;
SELECT * INTO #OriginalReceivables FROM ConvertCSVToBigIntTable(@ReceivableIds, ',');
SELECT
Receivables.Id as ReceivableId,
LegalEntities.Id as LegalEntityId,
ReceivableTypes.Name as ReceivableType,
Receivables.TotalAmount_Amount as ReceivableAmount_Amount,
Receivables.TotalAmount_Currency as ReceivableAmount_Currency,
Receivables.TotalBalance_Amount as ReceivableBalance_Amount,
Receivables.TotalBalance_Currency as ReceivableBalance_Currency,
Receivables.TotalEffectiveBalance_Amount as ReceivableEffectiveBalance_Amount,
Receivables.TotalEffectiveBalance_Currency as ReceivableEffectiveBalance_Currency,
Case When SUM(ReceivableTaxes.Amount_Amount) Is Not Null Then SUM(ReceivableTaxes.Amount_Amount) Else 0.00 End  as ReceivableTaxAmount_Amount,
Receivables.TotalAmount_Currency as ReceivableTaxAmount_Currency,
Case When SUM(ReceivableTaxes.Balance_Amount) Is Not Null Then SUM(ReceivableTaxes.Balance_Amount) Else 0.00 End as ReceivableTaxBalance_Amount,
Receivables.TotalBalance_Currency as ReceivableTaxBalance_Currency,
Case When SUM(ReceivableTaxes.EffectiveBalance_Amount) Is Not Null Then SUM(ReceivableTaxes.EffectiveBalance_Amount) Else 0.00 End as ReceivableTaxEffectiveBalance_Amount,
Receivables.TotalEffectiveBalance_Currency as ReceivableTaxEffectiveBalance_Currency,
Receivables.EntityType,
Receivables.DueDate,
Parties.PartyName as CustomerName,
Parties.PartyNumber as CustomerPartyNumber,
Parties.DoingBusinessAs as DoingBusinessAs,
CASE WHEN (Sundries.Id IS NOT NULL AND SundryContracts.Id IS NOT NULL)THEN SundryContracts.SequenceNumber
WHEN (SecurityDeposits.Id IS NOT NULL AND SecurityDepositContracts.Id IS NOT NULL ) THEN SecurityDepositContracts.SequenceNumber
END as ContractSequenceNumber,
CASE WHEN (Sundries.Id IS NOT NULL)THEN Sundries.CurrencyId
WHEN (Contracts.Id IS NOT NULL AND Contracts.Id IS NOT NULL) THEN ContractC.Id
WHEN (Parties.Id IS NOT NULL) THEN LegalEntityCurrency.Id
WHEN (SecurityDeposits.Id IS NOT NULL) THEN SDC.Id
END as CurrencyId,
CASE WHEN (Sundries.Id IS NOT NULL)THEN SundryCurrencyCodes.ISO
WHEN (Contracts.Id IS NOT NULL AND Contracts.Id IS NOT NULL) THEN ContractCC.ISO
WHEN (Parties.Id IS NOT NULL) THEN LegalEntityCurrencyCode.ISO
WHEN (SecurityDeposits.Id IS NOT NULL) THEN SDCC.ISO
END as CurrencyCode,
CASE WHEN 1 = ALL(SELECT IsTaxAssessed FROM ReceivableDetails JOIN #OriginalReceivables originalReceivables ON ReceivableDetails.ReceivableId=originalReceivables.Id) THEN Cast(1 AS BIT) ELSE Cast(0 AS BIT) END as IsTaxAssessed
FROM Receivables
join #OriginalReceivables on Receivables.Id =#OriginalReceivables.ID
join ReceivableCodes on Receivables.ReceivableCodeId=ReceivableCodes.ID
join ReceivableTypes on ReceivableCodes.ReceivableTypeId=ReceivableTypes.ID
left join ReceivableTaxes On Receivables.Id = ReceivableTaxes.ReceivableId And ReceivableTaxes.IsActive=1
left join Parties on Receivables.CustomerId=Parties.Id
left join LegalEntities on Receivables.LegalEntityId = LegalEntities.Id
left join Currencies as LegalEntityCurrency on LegalEntities.CurrencyId=LegalEntityCurrency.ID
left join CurrencyCodes as LegalEntityCurrencyCode on LegalEntityCurrency.CurrencyCodeId  = LegalEntityCurrencyCode.Id
left join Sundries on Receivables.Id =Sundries.ReceivableId
left join Currencies as SundryCurrencies on Sundries.CurrencyId=SundryCurrencies.Id
left join CurrencyCodes as SundryCurrencyCodes on SundryCurrencies.CurrencyCodeId  = SundryCurrencyCodes.Id
left join Contracts as SundryContracts on Sundries.ContractId = SundryContracts.Id
left join SecurityDeposits on Receivables.Id = SecurityDeposits.ReceivableId
left join LegalEntities as SDLE on SecurityDeposits.LegalEntityId = SDLE.Id
left join Currencies as SDC on SDLE.CurrencyId = SDC.Id
left join CurrencyCodes as SDCC on SDC.CurrencyCodeId = SDCC.Id
left join Contracts as SecurityDepositContracts on SecurityDeposits.ContractId = SecurityDepositContracts.Id
left join Contracts on Receivables.EntityType = 'CT' and Receivables.EntityId=Contracts.Id
left join Currencies as ContractC on Contracts.CurrencyId=ContractC.Id
left join CurrencyCodes as ContractCC on ContractC.CurrencyCodeId = ContractCC.Id
WHERE
Receivables.IsActive=1
GROUP BY Receivables.Id,ReceivableTypes.Name,Receivables.EntityType,Receivables.DueDate,Parties.Id
,Contracts.Id,ContractC.Id, ContractCC.Id,Parties.PartyName,Parties.PartyNumber,SundryContracts.SequenceNumber,
SecurityDepositContracts.SequenceNumber,LegalEntities.Id,LegalEntityCurrency.Id,LegalEntityCurrencyCode.ISO,ContractCC.ISO,
Sundries.CurrencyId,SundryCurrencyCodes.ISO,Sundries.Id, SecurityDeposits.Id, SDC.Id,SDCC.ISO, SundryContracts.Id, SecurityDepositContracts.Id, Parties.DoingBusinessAs,  Receivables.TotalAmount_Amount,
Receivables.TotalAmount_Currency,
Receivables.TotalBalance_Amount,
Receivables.TotalBalance_Currency,
Receivables.TotalEffectiveBalance_Amount,
Receivables.TotalEffectiveBalance_Currency

GO
