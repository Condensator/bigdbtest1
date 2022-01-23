SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LoanIncomeScheduleLoanDetailsReport]
(
@ContractId BIGINT,
@IsAccounting BIT
)
AS
BEGIN
SELECT
SequenceNumber,
Contracts.Alias,
PartyNumber [Customer Number],
PartyName [Customer Name] ,
LineofBusinesses.Name [LineOfBusiness],
LegalEntities.Name,
CommencementDate,
MaturityDate,
NumberOfPayments,
LoanAmount_Amount,
LoanAmount_Currency,
DayCountConvention 'DayCountConvention',
PaymentFrequency,
CompoundingFrequency,
InterimDayCountConvention 'InterimDayCountConvention',
InterimFrequency,
InterimCompoundingFrequency,
IsDailySensitive,
SyndicationType,
ChargeOffStatus,
IsNonAccrual,
@IsAccounting 'IsAccounting',
InstrumentTypes.Code [Instrument Type],
Case When LoanFinances.IsAdvance = 1 Then 'Advance' Else 'Arrear' End [Advance/Arrear]
FROM Contracts
INNER JOIN LoanFinances ON
LoanFinances.ContractId = Contracts.Id
AND LoanFinances.IsCurrent = 1
INNER JOIN Parties ON
Parties.Id = LoanFinances.CustomerId
INNER JOIN LineofBusinesses ON
LineofBusinesses.Id = Contracts.LineofBusinessId
INNER JOIN LegalEntities ON
LegalEntities.Id = LoanFinances.LegalEntityId
INNER JOIN InstrumentTypes ON
LoanFinances.InstrumentTypeId = InstrumentTypes.Id
WHERE Contracts.Id = @ContractId
END

GO
