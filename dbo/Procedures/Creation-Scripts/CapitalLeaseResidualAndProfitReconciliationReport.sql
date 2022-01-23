SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CapitalLeaseResidualAndProfitReconciliationReport]
(
@FromDate DATETIME = NULL
,@ToDate DATETIME = NULL
,@CustomerId AS NVARCHAR(40) = NULL
,@SequenceNumber AS NVARCHAR(40) = NULL
,@LeaseContractType NVARCHAR(40) = NULL
,@CommaSeparatedLegalEntityIds NVARCHAR(MAX) = NULL
)
AS
BEGIN
SET NOCOUNT ON;
SELECT ID AS LegalEntityId INTO #InputLegalEntities FROM ConvertCSVToBigIntTable(@CommaSeparatedLegalEntityIds,',');
SELECT
Contracts.Id as ContractId,
Contracts.SequenceNumber AS SequenceNumber,
LegalEntities.LegalEntityNumber AS LegalEntityNumber,
Parties.PartyNumber as CustomerNumber,
Parties.PartyName as CustomerName,
LeaseFinanceDetails.LeaseContractType AS LeaseContractType,
Currencies.Name AS Currency
INTO #ContractDetails 
FROM Contracts
JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent=1
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN Parties on LeaseFinances.CustomerId=Parties.Id
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
JOIN Currencies ON Contracts.CurrencyId = Currencies.Id
WHERE (@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)
AND (@CustomerId IS NULL OR LeaseFinances.CustomerId = @CustomerId)
AND (@LeaseContractType IS NULL OR LeaseFinanceDetails.LeaseContractType = @LeaseContractType)
AND (@CommaSeparatedLegalEntityIds IS NULL OR LegalEntities.Id IN (SELECT LegalEntityId FROM #InputLegalEntities));

select #ContractDetails.ContractId,LeaseFinances.Id as LeaseFinanceId,LeaseAssets.AssetId,LeaseAssets.Id as LeaseAssetId,LeaseAssets.InstallationDate,sum(LeaseAssetSKUs.BookedResidual_Amount) BookedResidual_Amount,LeaseAssets.IsActive into #ComponentDetails 
from #ContractDetails 
join LeaseFinances on #ContractDetails.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
join LeaseAssets on LeaseFinances.Id = LeaseAssets.LeaseFinanceId
join LeaseAssetSKUs on LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId
WHERE (LeaseAssets.IsActive = 1 OR LeaseAssets.TerminationDate IS NOT NULL)
AND LeaseAssetSKUs.IsLeaseComponent = 1
group by #ContractDetails.ContractId,LeaseFinances.Id,LeaseAssets.AssetId,LeaseAssets.InstallationDate,LeaseAssets.IsActive,LeaseAssets.Id

create table #EligibleLeaseAssets(
	ContractId BIGINT,
	CurrentLeaseFinanceId BIGINT,
	AssetId BIGINT,
	LeaseAssetId BIGINT,
	InstallationDate Date,
	BookedResidual Decimal(16,2),
	IsActive BIT,
	IsEligibleForDSP BIT,
	DSP Decimal(16,2)
);
INSERT INTO #EligibleLeaseAssets
SELECT
ContractId = CD.ContractId,
CurrentLeaseFinanceId = CD.LeaseFinanceId,
AssetId = CD.AssetId,
LeaseAssetId = CD.LeaseAssetId,
CD.InstallationDate,
BookedResidual = CD.BookedResidual_Amount,
CD.IsActive,
IsEligibleForDSP = CASE WHEN LFD.ProfitLossStatus = 'Profit' AND LFD.LeaseContractType = 'DirectFinance' THEN 1 ELSE 0 END,
DSP = LA.FMV_Amount - LA.NBV_Amount
FROM #ComponentDetails CD
JOIN LeaseFinanceDetails LFD ON CD.LeaseFinanceId = LFD.Id
join LeaseAssets LA on CD.LeaseAssetId = LA.ID
UNION
SELECT
ContractId = C.ContractId,
CurrentLeaseFinanceId = LF.Id,
AssetId = LA.AssetId,
LeaseAssetId = LA.Id,
LA.InstallationDate,
BookedResidual = LA.BookedResidual_Amount,
LA.IsActive,
IsEligibleForDSP = CASE WHEN LFD.ProfitLossStatus = 'Profit' AND LFD.LeaseContractType = 'DirectFinance' THEN 1 ELSE 0 END,
DSP = LA.FMV_Amount - LA.NBV_Amount
FROM #ContractDetails C
JOIN LeaseFinances LF ON C.ContractId = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
JOIN Assets A ON LA.AssetId = A.Id
WHERE (LA.IsActive = 1 OR LA.TerminationDate IS NOT NULL)
AND LA.IsLeaseAsset = 1
AND LF.IsCurrent = 1
AND A.IsSKU=0;

SELECT EA.ContractId, ResidualIncomeBalance = AI.LeaseResidualIncomeBalance_Amount, RowNumber = ROW_NUMBER() OVER (PARTITION BY EA.ContractId, EA.AssetId ORDER BY LI.IncomeDate ASC)
INTO #ResidualIncomeBalances
FROM AssetIncomeSchedules AI
JOIN LeaseIncomeSchedules LI ON AI.LeaseIncomeScheduleId = LI.Id
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN #EligibleLeaseAssets EA ON AI.AssetId = EA.AssetId AND LF.ContractId = EA.ContractId
WHERE AI.IsActive = 1
AND LI.IsSchedule = 1
AND LI.IsLessorOwned = 1
AND EA.InstallationDate < @FromDate
AND EA.IsActive = 1;

SELECT ContractId, PVOfResidual = SUM(ResidualIncomeBalance)
INTO #PVOfResiduals
FROM #ResidualIncomeBalances
WHERE RowNumber = 1
GROUP BY ContractId;

SELECT EA.ContractId, ResidualIncome = SUM(AI.LeaseResidualIncome_Amount)
INTO #ResidualIncomesBeforeFromDate
FROM AssetIncomeSchedules AI
JOIN LeaseIncomeSchedules LI ON AI.LeaseIncomeScheduleId = LI.Id
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN #EligibleLeaseAssets EA ON AI.AssetId = EA.AssetId AND LF.ContractId = EA.ContractId
WHERE LI.AdjustmentEntry = 0
AND LI.IsLessorOwned = 1
AND LI.IsAccounting = 1
AND LI.IsGLPosted = 1
AND LI.PostDate IS NOT NULL
AND LI.PostDate < @FromDate
AND EA.IsActive = 1
GROUP BY EA.ContractId;

SELECT EA.ContractId, BookedResidual = SUM(EA.BookedResidual)
INTO #ResidualsAdded
FROM #EligibleLeaseAssets EA
WHERE EA.InstallationDate >= @FromDate
AND EA.InstallationDate <= @ToDate
AND EA.IsActive = 1
GROUP BY EA.ContractId;

SELECT EA.ContractId, ResidualIncome = SUM(AI.LeaseResidualIncome_Amount)
INTO #RecognizedResiduals
FROM AssetIncomeSchedules AI
JOIN LeaseIncomeSchedules LI ON AI.LeaseIncomeScheduleId = LI.Id
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN #EligibleLeaseAssets EA ON AI.AssetId = EA.AssetId AND LF.ContractId = EA.ContractId
WHERE LI.AdjustmentEntry = 0
AND LI.IsLessorOwned = 1
AND LI.IsAccounting = 1
AND LI.IsGLPosted = 1
AND LI.PostDate IS NOT NULL
AND LI.PostDate >= @FromDate AND LI.PostDate <= @ToDate
AND EA.InstallationDate <= @ToDate
AND EA.IsActive = 1
GROUP BY EA.ContractId;

SELECT EA.ContractId, NetResidualImpairment = SUM(LAD.ResidualImpairmentAmount_Amount)
INTO #NetResidualImpairments
FROM #ContractDetails C
JOIN LeaseFinances LF ON C.ContractId = LF.ContractId
JOIN LeaseAmendments LAM ON LAM.CurrentLeaseFinanceId = LF.Id
join LeaseAmendmentImpairmentAssetDetails LAD ON LAD.LeaseAmendmentId = LAM.Id
join #EligibleLeaseAssets EA ON EA.AssetId = LAD.AssetId
WHERE EA.IsActive = 1
AND LAM.PostDate >= @FromDate AND  LAM.PostDate <= @ToDate
AND LAM.AmendmentType = 'ResidualImpairment' AND LAM.LeaseAmendmentStatus='Approved'
GROUP BY EA.ContractId;

SELECT EA.ContractId, EA.AssetId, EA.IsEligibleForDSP
INTO #AssetsPaidOffBetweenFromAndToDate
FROM #EligibleLeaseAssets EA
JOIN LeaseAssets LA ON EA.AssetId = LA.AssetId
JOIN PayoffAssets PA ON LA.Id = PA.LeaseAssetId
JOIN Payoffs PF ON PA.PayoffId = PF.Id
WHERE PF.Status = 'Activated'
AND PF.PostDate >= @FromDate AND PF.PostDate <= @ToDate
AND PA.IsActive = 1
AND EA.IsActive = 0;

SELECT PA.ContractId, RemovedResidual = SUM(AI.LeaseResidualIncome_Amount)
INTO #RemovedResiduals
FROM AssetIncomeSchedules AI
JOIN LeaseIncomeSchedules LI ON AI.LeaseIncomeScheduleId = LI.Id
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN #AssetsPaidOffBetweenFromAndToDate PA ON AI.AssetId = PA.AssetId AND LF.ContractId = PA.ContractId
WHERE AI.IsActive = 1
AND LI.IsLessorOwned = 1
AND LI.IsAccounting = 1
AND LI.IsGLPosted = 1
AND LI.PostDate <= @ToDate
GROUP BY PA.ContractId;

SELECT EA.ContractId, NetResidualImpairment = SUM(LAD.ResidualImpairmentAmount_Amount)
INTO #NetResidualImpairmentsForPaidOffAssets
FROM #ContractDetails C
JOIN LeaseFinances LF ON C.ContractId = LF.ContractId
JOIN LeaseAmendments LAM ON LAM.CurrentLeaseFinanceId = LF.Id
join LeaseAmendmentImpairmentAssetDetails LAD ON LAD.LeaseAmendmentId = LAM.Id
join #EligibleLeaseAssets EA ON EA.AssetId = LAD.AssetId
WHERE EA.IsActive = 0
AND LAM.PostDate >= @FromDate AND  LAM.PostDate <= @ToDate
AND LAM.AmendmentType = 'ResidualImpairment' AND LAM.LeaseAmendmentStatus='Approved'
GROUP BY EA.ContractId;

SELECT EA.ContractId, DSPIncomeBalance = AI.DeferredSellingProfitIncomeBalance_Amount, RowNumber = ROW_NUMBER() OVER (PARTITION BY EA.ContractId, EA.AssetId ORDER BY LI.PostDate DESC)
INTO #DSPIncomeBalances
FROM AssetIncomeSchedules AI
JOIN LeaseIncomeSchedules LI ON AI.LeaseIncomeScheduleId = LI.Id
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN #EligibleLeaseAssets EA ON AI.AssetId = EA.AssetId AND LF.ContractId = EA.ContractId
WHERE AI.IsActive = 1
AND LI.IsLessorOwned = 1
AND LI.IsAccounting = 1
AND LI.PostDate < @FromDate
AND EA.InstallationDate < @FromDate
AND EA.IsActive = 1
AND EA.IsEligibleForDSP = 1;

SELECT ContractId, BeginValueOfDSP = SUM(DSPIncomeBalance)
INTO #DSPBeginValues
FROM #DSPIncomeBalances
WHERE RowNumber = 1
GROUP BY ContractId;

SELECT ContractId, DSP = SUM(DSP)
INTO #DSPs
FROM #EligibleLeaseAssets
WHERE IsActive = 1 AND IsEligibleForDSP = 1
GROUP BY ContractId;

SELECT EA.ContractId, DSPIncome = SUM(AI.DeferredSellingProfitIncome_Amount)
INTO #EarnedDSPProfits
FROM AssetIncomeSchedules AI
JOIN LeaseIncomeSchedules LI ON AI.LeaseIncomeScheduleId = LI.Id
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN #EligibleLeaseAssets EA ON AI.AssetId = EA.AssetId AND LF.ContractId = EA.ContractId
WHERE LI.AdjustmentEntry = 0
AND LI.IsLessorOwned = 1
AND LI.IsAccounting = 1
AND LI.IsGLPosted = 1
AND LI.PostDate IS NOT NULL
AND LI.PostDate >= @FromDate AND LI.PostDate <= @ToDate
AND EA.InstallationDate <= @ToDate
AND EA.IsActive = 1
AND EA.IsEligibleForDSP = 1
GROUP BY EA.ContractId;

SELECT PA.ContractId, DSPIncomeBalance = AI.DeferredSellingProfitIncomeBalance_Amount, RowNumber = ROW_NUMBER() OVER (PARTITION BY PA.ContractId, PA.AssetId ORDER BY LI.PostDate DESC)
INTO #DSPIncomeBalancesOfPaidOffAssets
FROM AssetIncomeSchedules AI
JOIN LeaseIncomeSchedules LI ON AI.LeaseIncomeScheduleId = LI.Id
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN #AssetsPaidOffBetweenFromAndToDate PA ON AI.AssetId = PA.AssetId AND LF.ContractId = PA.ContractId
WHERE AI.IsActive = 1
AND LI.IsLessorOwned = 1
AND LI.IsAccounting = 1
AND LI.IsGLPosted = 1
AND LI.PostDate <= @ToDate
AND PA.IsEligibleForDSP = 1;

SELECT ContractId, RemovedProfit = SUM(DSPIncomeBalance)
INTO #RemovedDSPs
FROM #DSPIncomeBalancesOfPaidOffAssets
WHERE RowNumber = 1
GROUP BY ContractId;
-- Result
SELECT
C.ContractId,
C.SequenceNumber,
C.LegalEntityNumber,
C.CustomerNumber,
C.CustomerName,
C.LeaseContractType,
C.Currency,
BeginValueOfResidualBooked = ISNULL(PV.PVOfResidual,0.00) + ISNULL(RI.ResidualIncome, 0.00),
ResidualAdded = ISNULL(RA.BookedResidual,0.00),
RecognizedResidual = ISNULL(RR.ResidualIncome,0.00),
NetResidualImpairment = ISNULL(Imps.NetResidualImpairment,0.00),
RemovedResidual =ISNULL(ReR.RemovedResidual,0.00) + ISNULL(ImpsPA.NetResidualImpairment,0.00),
BeginValueOfSellingProfit = ISNULL(DSPBV.BeginValueOfDSP, 0.00),
DeferredSellingProfit = ISNULL(DSP.DSP, 0.00),
EarnedProfit = ISNULL(EDSP.DSPIncome,0.00),
RemovedProfit = ISNULL(ReDSP.RemovedProfit, 0.00)
FROM #ContractDetails C
LEFT JOIN #PVOfResiduals PV ON C.ContractId = PV.ContractId
LEFT JOIN #ResidualIncomesBeforeFromDate RI ON C.ContractId = RI.ContractId
LEFT JOIN #ResidualsAdded RA ON C.ContractId = RA.ContractId
LEFT JOIN #RecognizedResiduals RR ON C.ContractId = RR.ContractId
LEFT JOIN #NetResidualImpairments Imps ON C.ContractId = Imps.ContractId
LEFT JOIN #RemovedResiduals ReR ON C.ContractId = ReR.ContractId
LEFT JOIN #NetResidualImpairmentsForPaidOffAssets ImpsPA ON C.ContractId = ImpsPA.ContractId
LEFT JOIN #DSPBeginValues DSPBV ON C.ContractId = DSPBV.ContractId
LEFT JOIN #DSPs DSP ON C.ContractId = DSP.ContractId
LEFT JOIN #EarnedDSPProfits EDSP ON C.ContractId = EDSP.ContractId
LEFT JOIN #RemovedDSPs ReDSP ON C.ContractId = ReDSP.ContractId;
END

GO
