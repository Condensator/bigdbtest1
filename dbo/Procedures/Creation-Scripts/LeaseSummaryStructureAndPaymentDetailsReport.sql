SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseSummaryStructureAndPaymentDetailsReport]
(
@SequenceNumber NVARCHAR(40)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
Contracts.SequenceNumber,
Contracts.AccountingStandard,
LeaseFinanceDetails.LessorYieldLeaseAsset,
LeaseFinanceDetails.LessorYieldFinanceAsset,
LeaseFinanceDetails.LeaseContractType,
CurrencyCodes.ISO AS Currency,
Contracts.Alias,
Parties.PartyNumber,
Parties.PartyName,
LineofBusinesses.Name AS LineofBusiness,
LegalEntities.Name AS LegalEntity,
LeaseFinances.BookingStatus,
Contracts.ChargeOffStatus,
Contracts.SyndicationType,
OriginationSourceTypes.Name,
LeaseFinances.HoldingStatus,
LeaseFinanceDetails.CommencementDate AS CommencementDate,
LeaseFinanceDetails.MaturityDate AS MaturityDate,
CASE WHEN LeaseFinanceDetails.IsAdvance=1 THEN 'Advance' ELSE 'Arrear' END AS IsAdvance,
LeaseFinanceDetails.NumberOfPayments,
LeaseFinanceDetails.NumberOfInceptionPayments,
LeaseFinanceDetails.CustomerTermInMonths TermInMonths,
LeaseFinanceDetails.DayCountConvention,
LeaseFinanceDetails.PaymentFrequency,
LeaseFinanceDetails.InterimAssessmentMethod,
LeaseFinanceDetails.InterimPaymentFrequency,
LeaseFinanceDetails.InterimInterestDayCountConvention,
LeaseFinanceDetails.InterimRentDayCountConvention,
CASE WHEN LeaseFinanceDetails.InterimAssessmentMethod = '_' THEN '_' WHEN LeaseFinanceDetails.IsInterimRentInAdvance=1 THEN 'Advance' ELSE 'Arrear' END AS IsInterimRentInAdvance,
CASE WHEN LeaseFinanceDetails.IsRegularPaymentStream=1 THEN 'Regular'ELSE 'Irregular' END AS LeaseStructureType,
SUM(LeaseAssets.BookedResidual_Amount) AS BookedResidual_Amount,
SUM(LeaseAssets.Rent_Amount) AS RegularPaymentAmount,
SUM(LeaseAssets.NBV_Amount - LeaseAssets.ETCAdjustmentAmount_Amount) AS NetInvestmentAmount,
LeaseFinanceDetails.LessorYield
FROM
Contracts
INNER JOIN
Currencies ON Contracts.CurrencyId = Currencies.Id
INNER JOIN
CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
INNER JOIN
LineofBusinesses ON Contracts.LineofBusinessId = LineofBusinesses.Id
INNER JOIN
LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
INNER JOIN
LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN
ContractOriginations ON LeaseFinances.ContractOriginationId = ContractOriginations.Id
LEFT JOIN
OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
INNER JOIN
Parties ON LeaseFinances.CustomerId = Parties.Id
INNER JOIN
LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
LEFT JOIN
LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
WHERE
Contracts.SequenceNumber=@SequenceNumber
GROUP BY
Contracts.SequenceNumber,
Contracts.AccountingStandard,
LeaseFinanceDetails.LessorYieldLeaseAsset,
LeaseFinanceDetails.LessorYieldFinanceAsset,
LeaseFinanceDetails.LeaseContractType,
CurrencyCodes.ISO,
Contracts.Alias,
Parties.PartyNumber,
Parties.PartyName,
LineofBusinesses.Name,
LegalEntities.Name,
LeaseFinances.BookingStatus,
Contracts.ChargeOffStatus,
Contracts.SyndicationType,
Contracts.u_ConversionSource,
OriginationSourceTypes.Name,
LeaseFinances.HoldingStatus,
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.MaturityDate,
LeaseFinanceDetails.IsAdvance,
LeaseFinanceDetails.NumberOfPayments,
LeaseFinanceDetails.NumberOfInceptionPayments,
LeaseFinanceDetails.CustomerTermInMonths,
LeaseFinanceDetails.DayCountConvention,
LeaseFinanceDetails.PaymentFrequency,
LeaseFinanceDetails.InterimAssessmentMethod,
LeaseFinanceDetails.InterimPaymentFrequency,
LeaseFinanceDetails.InterimInterestDayCountConvention,
LeaseFinanceDetails.InterimRentDayCountConvention,
LeaseFinanceDetails.IsRegularPaymentStream,
LeaseFinanceDetails.BookedResidual_Amount,
LeaseFinanceDetails.IsInterimRentInAdvance,
LeaseFinanceDetails.LessorYield
END

GO
