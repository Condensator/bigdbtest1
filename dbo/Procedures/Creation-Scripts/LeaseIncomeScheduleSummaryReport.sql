SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseIncomeScheduleSummaryReport]
(
@SequenceNumber NVARCHAR(40),
@IsAccounting BIT
)
AS
BEGIN
WITH CTE_AssetSummary
AS
(
SELECT
MIN(LeaseAssets.InterimRentStartDate) AS MinimumInterimRentStartDate,
MIN(LeaseAssets.InterimInterestStartDate) AS MinimumInterimInterestStartDate,
SUM(LeaseAssets.NBV_Amount - LeaseAssets.ETCAdjustmentAmount_Amount) NBV,
SUM(LeaseAssets.BookedResidual_Amount) BookedResidual,
SUM(LeaseAssets.CustomerGuaranteedResidual_Amount) CustomerGuaranteedResidual,
SUM(LeaseAssets.ThirdPartyGuaranteedResidual_Amount) ThirdPartyGuaranteedResidual,
SUM(LeaseAssets.BookedResidual_Amount -
LeaseAssets.CustomerGuaranteedResidual_Amount -
LeaseAssets.ThirdPartyGuaranteedResidual_Amount) LessorRisk,
LeaseFinances.Id LeaseFinanceId
FROM
LeaseAssets
INNER JOIN LeaseFinances
ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND
(LeaseAssets.IsActive = 1)
INNER JOIN Contracts
ON LeaseFinances.ContractId = Contracts.Id AND
LeaseFinances.IsCurrent = 1
WHERE
Contracts.SequenceNumber = @SequenceNumber
GROUP BY
LeaseFinances.Id
)
SELECT
contract.SequenceNumber,
leaseDetail.LeaseContractType,
legalEntity.LegalEntityNumber,
party.PartyNumber CustomerNumber,
party.PartyName CustomerName,
currencyCode.ISO Currency,
ISNULL(NBV,0.00) NetLeaseInvestment,
ISNULL(BookedResidual,0.00) BookedResidual,
ISNULL(CustomerGuaranteedResidual,0.00) CustomerGuaranteedResidual,
ISNULL(ThirdPartyGuaranteedResidual,0.00) ThirdPartyGuaranteedResidual,
ISNULL(LessorRisk,0.00) LessorRisk,
CASE WHEN leaseDetail.IsAdvance=1 THEN 'Advance'
ELSE 'Arrear'
END AS 'AdvanceOrArrear',
leaseDetail.NumberOfPayments,
leaseDetail.NumberOfInceptionPayments,
leaseDetail.InceptionPayment_Amount InceptionPayment,
leaseDetail.PaymentFrequency,
leaseDetail.LessorYield,
leaseDetail.ManagementYield,
leaseDetail.CommencementDate,
leaseDetail.MaturityDate,
leaseDetail.TermInMonths LeaseTermInMonths,
MinimumInterimInterestStartDate,
MinimumInterimRentStartDate,
lease.BookingStatus,
InstrumentTypes.Code AS InstrumentType,
leaseDetail.ProfitLossStatus,
contract.AccountingStandard,
leaseDetail.FMV_Amount FMV
FROM
Contracts AS contract
INNER JOIN
Currencies AS currency ON contract.CurrencyId = currency.Id
INNER JOIN
CurrencyCodes AS currencyCode ON currency.CurrencyCodeId = currencyCode.Id
INNER JOIN
LeaseFinances AS lease ON contract.Id = lease.ContractId AND lease.IsCurrent = 1
INNER JOIN
LegalEntities AS legalEntity ON lease.LegalEntityId = legalEntity.Id
INNER JOIN
Parties AS party ON lease.CustomerId = party.Id
INNER JOIN
LeaseFinanceDetails AS leaseDetail ON lease.Id = leaseDetail.Id
INNER JOIN
InstrumentTypes ON lease.InstrumentTypeId = InstrumentTypes.Id
LEFT JOIN CTE_AssetSummary ON
lease.Id = CTE_AssetSummary.LeaseFinanceId
WHERE
contract.SequenceNumber=@SequenceNumber
END

GO
