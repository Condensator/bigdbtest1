SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FinanceLeaseTrialBalanceReport]
(
@AsOfDate AS DATE,
@LegalEntityNumber AS NVARCHAR(40) = NULL,
@PartyName AS NVARCHAR(500) = NULL,
@SequenceNumber AS NVARCHAR(80) = NULL
)
AS
BEGIN
CREATE TABLE #LeaseReceivables
(
ContractId BIGINT,
Amount DECIMAL(16,2)
);
CREATE TABLE #FinanceReceivables
(
ContractId BIGINT,
Amount DECIMAL(16,2)
);
CREATE TABLE #UnEarned_Incomes
(
ContractId BIGINT,
UnearnedIncome DECIMAL(16,2),
UnearnedResidualIncome DECIMAL(16,2),
UnearnedFinanceIncome DECIMAL(16,2),
UnearnedFinanceResidualIncome DECIMAL(16,2),
DeferredSellingProfitIncome DECIMAL(16,2)
);
CREATE TABLE #Lease_NBV
(
ContractId BIGINT,
BeginNBV DECIMAL(16,2),
FinanceBeginNBV DECIMAL(16,2)
);
CREATE TABLE #LeaseAssetBookedResiduals
(
ContractId BIGINT,
Residual DECIMAL(16,2)
);
CREATE TABLE #LeaseAssetBookedResidualsTemp
(
ContractId BIGINT,
Residual DECIMAL(16,2)
);
CREATE TABLE #FinanceAssetBookedResiduals
(
ContractId BIGINT,
Residual DECIMAL(16,2)
);
CREATE TABLE #FinanceAssetBookedResidualsTemp
(
ContractId BIGINT,
Residual DECIMAL(16,2)
);
CREATE UNIQUE INDEX LeaseReceivables_Id
ON #LeaseReceivables(ContractId)
CREATE UNIQUE INDEX UnEarned_Incomes_Id
ON #UnEarned_Incomes(ContractId)
CREATE UNIQUE INDEX Lease_NBV_Id
ON #Lease_NBV(ContractId)
SELECT
ContractId = C.Id,
CurrentLeaseFinanceId = LF.Id,
SequenceNumber = C.SequenceNumber,
LegalEntityName = LE.Name,
CustomerName = P.PartyName,
ContractAlias = C.Alias,
LessorYield = LFD.LessorYield,
RemainingTermInMonths = (LFD.TermInMonths - (CASE WHEN @AsOfDate < LFD.CommencementDate THEN 0 ELSE (dbo.DaysDifferenceBy30360(LFD.CommencementDate,@AsOfDate) / 30.0) END))
INTO #ContractDetails
FROM Contracts C
JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN Parties P ON LF.CustomerId = P.Id
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
WHERE LF.IsCurrent = 1
AND (P.PartyName = @PartyName or @PartyName IS NULL)
AND (LE.LegalEntityNumber = @LegalEntityNumber OR @LegalEntityNumber IS NULL)
AND (C.SequenceNumber = @SequenceNumber or @SequenceNumber IS NULL) AND
(LFD.LeaseContractType <> 'Operating' and LF.BookingStatus = 'Commenced');

SELECT DISTINCT #ContractDetails.ContractId,
ReceivableDetails.LeaseComponentAmount_Amount,
ReceivableDetails.NonLeaseComponentAmount_Amount,
ReceivableDetails.Id
INTO #cte_Receivables
FROM #ContractDetails
JOIN Receivables ON Receivables.EntityId = #ContractDetails.ContractId AND Receivables.EntityType = 'CT' AND Receivables.IsActive = 1
JOIN ReceivableDetails on Receivables.Id=ReceivableDetails.ReceivableId  AND ReceivableDetails.IsActive = 1
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id 
JOIN ReceivableCodes on Receivables.ReceivableCodeId=ReceivableCodes.Id
JOIN ReceivableTypes on ReceivableCodes.ReceivableTypeId=ReceivableTypes.Id
WHERE ReceivableTypes.Name='CapitalLeaseRental'
AND LeasePaymentSchedules.StartDate > @AsOfDate

INSERT INTO #LeaseReceivables
SELECT ContractId, SUM(LeaseComponentAmount_Amount) FROM #cte_Receivables
GROUP BY ContractId
INSERT INTO #FinanceReceivables
SELECT ContractId, SUM(NonLeaseComponentAmount_Amount) FROM #cte_Receivables
GROUP BY ContractId
INSERT INTO #UnEarned_Incomes
SELECT
#ContractDetails.ContractId,
SUM(LeaseIncomeSchedules.Income_Amount) - SUM(LeaseIncomeSchedules.ResidualIncome_Amount),
SUM(LeaseIncomeSchedules.ResidualIncome_Amount),
SUM(LeaseIncomeSchedules.FinanceIncome_Amount) - SUM(LeaseIncomeSchedules.FinanceResidualIncome_Amount),
SUM(LeaseIncomeSchedules.FinanceResidualIncome_Amount),
SUM(LeaseIncomeSchedules.DeferredSellingProfitIncome_Amount)
FROM #ContractDetails
JOIN LeaseFinances  ON  #ContractDetails.ContractId = LeaseFinances.ContractId
JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
WHERE LeaseIncomeSchedules.IncomeDate > @AsOfDate AND
(LeaseIncomeSchedules.IsSchedule = 1 and LeaseIncomeSchedules.IsLessorOwned = 1)
GROUP BY #ContractDetails.ContractId;
With Cte_NBV AS
(
SELECT
ContractId = #ContractDetails.ContractId,
BeginNBV = LeaseIncomeSchedules.BeginNetBookValue_Amount,
FinanceBeginNBV = LeaseIncomeSchedules.FinanceBeginNetBookValue_Amount,
RowNumber = ROW_NUMBER() OVER (PARTITION BY #ContractDetails.ContractId ORDER BY LeaseIncomeSchedules.IncomeDate, LeaseIncomeSchedules.Id ASC)
FROM #ContractDetails
JOIN LeaseFinances  ON  #ContractDetails.ContractId = LeaseFinances.ContractId
JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
WHERE LeaseIncomeSchedules.IncomeDate > @AsOfDate AND
(LeaseIncomeSchedules.IsSchedule = 1 and LeaseIncomeSchedules.IsLessorOwned = 1)
)
INSERT INTO #Lease_NBV(ContractId,BeginNBV,FinanceBeginNBV)
SELECT ContractId,BeginNBV,FinanceBeginNBV FROM Cte_NBV WHERE Cte_NBV.RowNumber = 1;

SELECT DISTINCT #ContractDetails.ContractId,
LeaseAssets.BookedResidual_Amount AssetBookedResidual_Amount,
LeaseAssetSKUs.BookedResidual_Amount SKUBookedResidual_Amount,
LeaseAssetSKUs.IsLeaseComponent,
LeaseAssetSKUs.Id LeaseAssetSKUId,
LeaseAssets.IsLeaseAsset
INTO #cte_LeaseBookedResidual
FROM LeaseAssets
JOIN #ContractDetails ON LeaseAssets.LeaseFinanceId = #ContractDetails.CurrentLeaseFinanceId
LEFT JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId
WHERE (LeaseAssets.TerminationDate is null or LeaseAssets.TerminationDate > @AsOfDate)


INSERT INTO #LeaseAssetBookedResidualsTemp
SELECT ContractId, SUM(SKUBookedResidual_Amount) FROM #cte_LeaseBookedResidual
WHERE LeaseAssetSKUId IS NOT NULL AND IsLeaseComponent=1
GROUP BY ContractId
UNION
SELECT ContractId, SUM(AssetBookedResidual_Amount) FROM #cte_LeaseBookedResidual
WHERE LeaseAssetSKUId IS NULL AND IsLeaseAsset=1
GROUP BY ContractId

INSERT INTO #LeaseAssetBookedResiduals
SELECT ContractId,SUM(Residual) FROM #LeaseAssetBookedResidualsTemp
GROUP BY ContractId;

INSERT INTO #FinanceAssetBookedResidualsTemp
SELECT ContractId, SUM(SKUBookedResidual_Amount) FROM #cte_LeaseBookedResidual
WHERE LeaseAssetSKUId IS NOT NULL AND IsLeaseComponent=0
GROUP BY ContractId
UNION 
SELECT ContractId, SUM(AssetBookedResidual_Amount) FROM #cte_LeaseBookedResidual
WHERE LeaseAssetSKUId IS NULL AND IsLeaseAsset=0
GROUP BY ContractId

INSERT INTO #FinanceAssetBookedResiduals
SELECT ContractId,SUM(Residual) FROM #FinanceAssetBookedResidualsTemp
GROUP BY ContractId;
SELECT
SequenceNumber = #ContractDetails.SequenceNumber,
CustomerName = #ContractDetails.CustomerName,
ContractAlias = #ContractDetails.ContractAlias,
LessorYield = #ContractDetails.LessorYield,
RemainingTermInMonths = #ContractDetails.RemainingTermInMonths,
LeaseReceivable = ISNULL(#LeaseReceivables.Amount,0.0),
FinanceReceivable = ISNULL(#FinanceReceivables.Amount,0.0),
UnearnedIncome = ISNULL(#UnEarned_Incomes.UnearnedIncome,0.0),
UnearnedResidualIncome = ISNULL(#UnEarned_Incomes.UnearnedResidualIncome,0.0),
UnearnedFinanceIncome = ISNULL(#UnEarned_Incomes.UnearnedFinanceIncome,0.0),
UnearnedFinanceResidualIncome = ISNULL(#UnEarned_Incomes.UnearnedFinanceResidualIncome,0.0),
DeferredSellingProfitIncome = ISNULL(#UnEarned_Incomes.DeferredSellingProfitIncome,0.0),
LeaseAssetResidual = ISNULL(#LeaseAssetBookedResiduals.Residual,0.0),
FinanceAssetResidual = ISNULL(#FinanceAssetBookedResiduals.Residual,0.0),
BeginNBV = ISNULL(#Lease_NBV.BeginNBV,0.0),
FinanceBeginNBV = ISNULL(#Lease_NBV.FinanceBeginNBV,0.0),
LegalEntityName = #ContractDetails.LegalEntityName
FROM #ContractDetails
LEFT JOIN #Lease_NBV ON #ContractDetails.ContractId = #Lease_NBV.ContractId
LEFT JOIN #LeaseReceivables ON #ContractDetails.ContractId = #LeaseReceivables.ContractId
LEFT JOIN #FinanceReceivables ON #ContractDetails.ContractId = #FinanceReceivables.ContractId
LEFT JOIN #UnEarned_Incomes ON #ContractDetails.ContractId = #UnEarned_Incomes.ContractId
LEFT JOIN #LeaseAssetBookedResiduals ON #ContractDetails.ContractId = #LeaseAssetBookedResiduals.ContractId
LEFT JOIN #FinanceAssetBookedResiduals ON #ContractDetails.ContractId = #FinanceAssetBookedResiduals.ContractId;
END

GO
