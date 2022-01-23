SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDiscountingDetailsForAmortizationReport]
(
@DiscountingId BIGINT,
@IsAccounting BIT
)
AS
--DECLARE
--@DiscountingId BIGINT = 10,
--@IsAccounting BIT = 1
BEGIN
SET NOCOUNT ON
CREATE TABLE #TotalAmount
(
TotalPrincipalPayment DECIMAL(18,2) DEFAULT 0,
TotalInterestPayment DECIMAL(18,2) DEFAULT 0,
TotalPayment DECIMAL(18,2) DEFAULT 0,
DiscountingFinanceId BIGINT
);
CREATE TABLE #LoanAmountTemp
(
LoanAmount DECIMAL(18,2) DEFAULT 0,
DiscountingFinanceId BIGINT
);
;WITH CTE_LoanAmount AS
(
select sum(DiscountingAmendmentDetails.DiscountingProceedsAmount_Amount) AS LoanAmount,
DiscountingFinanceId
from DiscountingAmendmentDetails where  DiscountingFinanceId in
(select id from discountingfinances where DiscountingId=@DiscountingId and IsCurrent=1)
group by DiscountingFinanceId
)
INSERT INTO #LoanAmountTemp
SELECT * FROM CTE_LoanAmount
;WITH CTE_TotalAmount	AS(
SELECT
SUM(Principal_Amount) AS TotalPrincipalPayment,
SUM(DiscountingRepaymentSchedules.Interest_Amount) AS TotalInterestPayment,
SUM(Amount_Amount) AS TotalPayment,
DiscountingFinances.id AS DiscountingFinanceId
FROM Discountings JOIN DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
JOIN DiscountingRepaymentSchedules ON DiscountingFinances.id = DiscountingRepaymentSchedules.DiscountingFinanceId
WHERE Discountings.Id =@DiscountingId AND DiscountingFinances.IsCurrent=1 GROUP BY DiscountingFinances.id)
INSERT INTO #TotalAmount
SELECT * FROM CTE_TotalAmount
SELECT
SequenceNumber,
Discountings.Alias,
PartyNumber [Funder Number],
PartyName [Funder Name],
LineofBusinesses.Name [LineOfBusiness],
LegalEntities.Name [LegalEntity],
CommencementDate,
MaturityDate,
NumberOfPayments,
#LoanAmountTemp.LoanAmount AS LoanAmount,
@IsAccounting AS IsAccounting,
DayCountConvention AS DayCountConvention,
PaymentFrequency,
CompoundingFrequency,
Yield,
#TotalAmount.TotalInterestPayment AS TotalInterestPayment,
#TotalAmount.TotalPayment AS TotalPayment,
#TotalAmount.TotalPrincipalPayment AS TotalPrincipalPayment ,
CASE WHEN DiscountingFinances.Advance = 1 THEN 'Advance' ELSE 'Arrear' END [Advance/Arrear]
FROM Discountings
INNER JOIN DiscountingFinances ON
DiscountingFinances.DiscountingId = Discountings.Id
AND DiscountingFinances.IsCurrent = 1
INNER JOIN Parties ON
Parties.Id = DiscountingFinances.FunderId
INNER JOIN LineofBusinesses ON
LineofBusinesses.Id = DiscountingFinances.LineofBusinessId
INNER JOIN LegalEntities ON
LegalEntities.Id = DiscountingFinances.LegalEntityId
INNER JOIN InstrumentTypes ON
DiscountingFinances.InstrumentTypeId = InstrumentTypes.Id
INNER JOIN  #TotalAmount ON
DiscountingFinances.Id = #TotalAmount.DiscountingFinanceId
INNER JOIN  #LoanAmountTemp ON
DiscountingFinances.Id = #LoanAmountTemp.DiscountingFinanceId
WHERE Discountings.Id = @DiscountingId
IF OBJECT_ID('tempdb..#TotalAmount') IS NOT NULL
DROP TABLE #TotalAmount
IF OBJECT_ID('tempdb..#LoanAmountTemp') IS NOT NULL
DROP TABLE #LoanAmountTemp
END

GO
