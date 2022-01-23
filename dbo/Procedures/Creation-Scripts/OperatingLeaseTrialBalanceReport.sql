SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[OperatingLeaseTrialBalanceReport]
(
@AsOfDate DATETIMEOFFSET,
@LegalEntityNumber NVARCHAR(MAX),
@SequenceNumber NVARCHAR(80) = NULL,
@PartyName NVARCHAR(500) = NULL,
@OperatingContractType NVARCHAR(50),
@CommencedBookingStatus NVARCHAR(50)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT Item as LegalEntityNumber INTO #LegalEntityNumbers FROM ConvertCSVToStringTable(@LegalEntityNumber,',')

SELECT
C.SequenceNumber,
PT.PartyName,
LF.Id 'LeaseFinanceId',
C.Id 'ContractId',
C.Alias 'Alias',
CASE WHEN LFD.IsOverTermLease = 1 THEN 'True' ELSE 'False' END AS 'IsOtp',
LFD.BookedResidual_Amount ,
LF.bookingstatus ,
LF.ApprovalStatus ,
CurrencyCodes.Symbol
INTO
#GeneralLeaseTemp
FROM Contracts C
JOIN LeaseFinances LF ON C.Id = LF.ContractId and LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN Parties PT ON LF.CustomerId = PT.Id
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN #LegalEntityNumbers [LEN] ON LE.LegalEntityNumber = [LEN].LegalEntityNumber
LEFT JOIN Currencies on Currencies.Id=C.CurrencyId
LEFT JOIN CurrencyCodes ON CurrencyCodes.Id=Currencies.CurrencyCodeId
Where
LF.IsCurrent = 1
AND LF.BookingStatus = @CommencedBookingStatus
AND (LFD.LeaseContractType = @OperatingContractType OR  LFD.IsOverTermLease = 1)
AND (@SequenceNumber IS NULL OR C.SequenceNumber = @SequenceNumber)
AND (@PartyName IS NULL OR PT.PartyName = @PartyName);

create table #OriginalAssetCostTemp(
	OriginalAssetCost Decimal(16,2),
	LeaseFinanceId BIGINT,
	ContractId BIGINT
);

insert into #OriginalAssetCostTemp
SELECT
SUM(LAS.NBV_Amount) 'OriginalAssetCost',
GLT.LeaseFinanceId,
GLT.ContractId
FROM #GeneralLeaseTemp GLT
JOIN LeaseAssets LA ON GLT.LeaseFinanceId = LA.LeaseFinanceId
Join LeaseAssetSKUs LAS ON LA.Id = LAS.LeaseAssetId
WHERE LAS.IsLeaseComponent=1 AND LAS.IsActive=1 AND ((LA.TerminationDate IS NULL AND LA.IsActive=1) OR LA.TerminationDate > @AsOfDate ) 
GROUP BY GLT.ContractId,GLT.LeaseFinanceId
union
SELECT
SUM(LA.NBV_Amount) 'OriginalAssetCost',
GLT.LeaseFinanceId,
GLT.ContractId
FROM #GeneralLeaseTemp GLT
JOIN LeaseAssets LA ON GLT.LeaseFinanceId = LA.LeaseFinanceId
Join Assets A ON LA.AssetId = A.Id
WHERE LA.IsLeaseAsset=1 AND A.IsSKU=0 AND ((LA.TerminationDate IS NULL AND LA.IsActive=1) OR LA.TerminationDate > @AsOfDate )--Changes
GROUP BY GLT.ContractId,GLT.LeaseFinanceId;

select SUM(OriginalAssetCost) 'OriginalAssetCost',LeaseFinanceId, ContractId 
into #OriginalAssetCost
from #OriginalAssetCostTemp 
group by #OriginalAssetCostTemp.LeaseFinanceId,#OriginalAssetCostTemp.ContractId

SELECT
SUM(AVH.Value_Amount) 'Accumulateddepreciation',
GLT.LeaseFinanceId,
GLT.ContractId
INTO #Accumulateddepreciation
FROM #GeneralLeaseTemp GLT
JOIN LeaseAssets LA ON GLT.LeaseFinanceId = LA.LeaseFinanceId
JOIN Assets AT ON LA.AssetId = AT.Id
JOIN AssetValueHistories AVH ON AT.Id = AVH.AssetId
WHERE AVH.IsSchedule = 1
AND AVH.IsLessorOwned = 1
AND AVH.IncomeDate <= @AsOfDate
AND AVH.SourceModule = 'FixedTermDepreciation'
GROUP BY GLT.ContractId,GLT.LeaseFinanceId;
select
OTPResidualRecapture ResidualRecaptueAmount,
ContractID
INTO #ResidualRecaptueAmount
from
(select ROW_NUMBER() OVER (PARTITION BY RNI.ContractID ORDER BY RNI.Id desc) as 'RowNum' ,
OTPResidualRecapture ,
ContractID
from
RemainingNetInvestments RNI
where IsActive=1 and Cast(CreatedTime as date)<=@AsOfDate
)T
where T.RowNum=1
SELECT
#GeneralLeaseTemp.ContractID,
#GeneralLeaseTemp.BookedResidual_Amount
INTO #BookedAmount
FROM #GeneralLeaseTemp where #GeneralLeaseTemp.bookingstatus in ('Commenced','Terminated','FullyPaidOff')
and #GeneralLeaseTemp.Approvalstatus in ('Approved','InsuranceFollowup')
create table #MaxAssetValueHistoryId (
	ContractId BIGINT,
	LeaseFinanceId BIGINT,
	AssetValueHistoryId BIGINT,
	RowNum BIGINT
);
insert into #MaxAssetValueHistoryId
Select GLT.ContractId ,GLT.LeaseFinanceId, AVH.Id as 'AssetValueHistoryId', ROW_NUMBER() OVER (PARTITION BY  LA.Id , GLT.ContractId ORDER BY AVH.Id desc) as 'RowNum'
From #GeneralLeaseTemp GLT
JOIN LeaseAssets LA ON GLT.LeaseFinanceId = LA.LeaseFinanceId
JOIN Assets AT ON LA.AssetId = AT.Id
JOIN AssetValueHistories AVH ON AT.Id = AVH.AssetId
WHERE AVH.IsSchedule = 1
AND AVH.IsLessorOwned = 1
AND AVH.IncomeDate <= @AsOfDate
AND AT.IsSKU = 1 
AND AVH.IsLeaseComponent=1 AND ((LA.TerminationDate IS NULL AND LA.IsActive=1 ) OR La.TerminationDate > @AsOfDate  )
union
Select GLT.ContractId ,GLT.LeaseFinanceId, AVH.Id as 'AssetValueHistoryId', ROW_NUMBER() OVER (PARTITION BY LA.Id , GLT.ContractId ORDER BY AVH.Id desc) as 'RowNum'
From #GeneralLeaseTemp GLT
JOIN LeaseAssets LA ON GLT.LeaseFinanceId = LA.LeaseFinanceId
JOIN Assets AT ON LA.AssetId = AT.Id
JOIN AssetValueHistories AVH ON AT.Id = AVH.AssetId
WHERE AVH.IsSchedule = 1
AND AVH.IsLessorOwned = 1
AND AVH.IncomeDate <= @AsOfDate
AND AT.IsSKU = 0 
AND LA.IsLeaseAsset=1 AND ((LA.TerminationDate IS NULL AND LA.IsActive=1 ) OR La.TerminationDate > @AsOfDate  ) -- Changes

SELECT
SUM(AVH.EndBookValue_Amount) 'NBV',
MaxAVH.LeaseFinanceId,
MaxAVH.ContractId
INTO #NBVTemp
FROM #MaxAssetValueHistoryId MaxAVH
JOIN AssetValueHistories AVH ON MaxAVH.AssetValueHistoryId = AVH.Id
WHERE MaxAVH.RowNum = 1
GROUP BY MaxAVH.ContractId,MaxAVH.LeaseFinanceId;
;WITH Cte_MaxLeaseIncomeSchedule AS
(
SELECT LIS.Id as 'LeaseIncomeScheduleId',GLT.ContractId ,GLT.LeaseFinanceId, ROW_NUMBER() OVER (PARTITION BY LF.Id ORDER BY LIS.Id desc) as 'RowNum'
FROM #GeneralLeaseTemp GLT
JOIN Contracts C ON GLT.ContractId = C.Id
JOIN LeaseFinances LF ON c.Id = LF.ContractId
JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId
where LIS.IsSchedule = 1
AND LF.IsCurrent = 1
AND LIS.IsLessorOwned = 1
AND LIS.IncomeDate <= @AsOfDate
AND LF.BookingStatus = @CommencedBookingStatus
)
SELECT
LIS.DeferredRentalIncome_Amount 'DeferredRentalBalance',
CTE.LeaseFinanceId,
CTE.ContractId
INTO #DeferredRentalBalance
FROM Cte_MaxLeaseIncomeSchedule CTE
JOIN LeaseIncomeSchedules LIS ON CTE.LeaseIncomeScheduleId = LIS.Id
where CTE.RowNum = 1
SELECT GLT.ContractId,GLT.LeaseFinanceId, SUM (RD.NonLeaseComponentAmount_Amount) 'FinancingLeaseReceivable'
INTO #FinancingLeaseReceivableTemp
FROM #GeneralLeaseTemp GLT
JOIN Receivables R ON GLT.ContractId = R.EntityId AND R.EntityType='CT'
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN LeasePaymentSchedules LPS on R.PaymentScheduleId=LPS.Id
JOIN ReceivableCodes RC on R.ReceivableCodeId=RC.Id
JOIN ReceivableTypes RT on RC.ReceivableTypeId=RT.Id
WHERE LPS.StartDate > @AsOfDate AND RT.Name='OperatingLeaseRental'
GROUP BY GLT.ContractId,GLT.LeaseFinanceId;

create table #FinancingResidualBookedTemp(
	FinancingResidualBooked decimal(16,2),
	LeaseFinanceId bigint,
	ContractId bigint
);

INSERT INTO #FinancingResidualBookedTemp
SELECT SUM (LAS.BookedResidual_Amount) 'FinancingResidualBooked',
GLT.LeaseFinanceId,
GLT.ContractId
FROM #GeneralLeaseTemp GLT
JOIN LeaseAssets LA ON GLT.LeaseFinanceId = LA.LeaseFinanceId
JOIN LeaseAssetSKUs LAS ON LA.Id = LAS.LeaseAssetId
WHERE LAS.IsLeaseComponent=0 AND LAS.IsActive = 1 AND
((LA.TerminationDate = NULL AND LA.IsActive = 1) OR LA.TerminationDate > @AsOfDate)
GROUP BY GLT.LeaseFinanceId,GLT.ContractId
UNION
SELECT SUM (LA.BookedResidual_Amount) 'FinancingResidualBooked',
GLT.LeaseFinanceId,
GLT.ContractId
FROM #GeneralLeaseTemp GLT
JOIN LeaseAssets LA ON GLT.LeaseFinanceId = LA.LeaseFinanceId
JOIN Assets A ON LA.AssetId = A.Id
WHERE LA.IsLeaseAsset=0 AND A.IsSKU = 0 AND
((LA.TerminationDate = NULL AND LA.IsActive = 1) OR LA.TerminationDate > @AsOfDate)
GROUP BY GLT.LeaseFinanceId,GLT.ContractId;

select sum(FinancingResidualBooked) 'FinancingResidualBooked',LeaseFinanceId,ContractId into #FinancingResidualBooked from #FinancingResidualBookedTemp
group by LeaseFinanceId,ContractId

SELECT
SUM (LI.FinanceIncome_Amount) 'FinancingUnearnedIncome',
SUM (LI.FinanceResidualIncome_Amount) 'FinancingUnearnedResidualIncome',
GLT.LeaseFinanceId,
GLT.ContractId
INTO #FinancingUnearnedIncomeTemp
FROM #GeneralLeaseTemp GLT
JOIN LeaseFinances LF ON GLT.ContractId = LF.ContractId
JOIN LeaseIncomeSchedules LI ON LF.Id = LI.LeaseFinanceId
WHERE LI.IncomeDate > @AsOfDate
AND LI.IsSchedule =1
AND LI.IsLessorOwned =1
AND LF.IsCurrent = 1
AND LF.BookingStatus = @CommencedBookingStatus
GROUP BY GLT.ContractId,GLT.LeaseFinanceId;
;WITH CTE_FinancingNBV AS
(
SELECT GLT.ContractId, GLT.LeaseFinanceId, LeaseIncomeScheduleId = LI.Id, ROW_NUMBER() OVER (PARTITION BY GLT.ContractId, GLT.LeaseFinanceId ORDER BY LI.IncomeDate) AS 'RowNumber'
FROM #GeneralLeaseTemp GLT
JOIN LeaseFinances LF ON GLT.ContractId = LF.ContractId
JOIN LeaseIncomeSchedules LI ON LF.Id = LI.LeaseFinanceId
WHERE LI.IncomeDate > @AsOfDate
AND LI.IsSchedule =1
AND LI.IsLessorOwned =1
AND LF.IsCurrent = 1
AND LF.BookingStatus = @CommencedBookingStatus
)
SELECT
LI.FinanceBeginNetBookValue_Amount 'FinancingNBV',
CTE.LeaseFinanceId,
CTE.ContractId
INTO #FinancingNBVTemp
FROM LeaseIncomeSchedules LI
JOIN CTE_FinancingNBV CTE ON CTE.LeaseIncomeScheduleId = LI.Id
WHERE CTE.RowNumber = 1
SELECT
Currencies.Name,
GLt.ContractId
INTO #CURRENCYTEMP
FROM
#GeneralLeaseTemp GLT
JOIN Contracts on GLT.ContractId=Contracts.Id
JOIN Currencies on Contracts.CurrencyId=Currencies.Id
select
GLT.SequenceNumber,
GLT.PartyName 'CustomerName',
GLT.Alias,
GLT.IsOtp,
ISNULL(OAC.OriginalAssetCost,0.0) 'OriginalAssetCost',
ISNULL(AD.Accumulateddepreciation,0.0) 'Accumulateddepreciation',
ISNULL(NBV.NBV,0.0) 'NBV',
ISNULL(CASE WHEN #BookedAmount.BookedResidual_Amount>0 THEN (#BookedAmount.BookedResidual_Amount-ResidualRecaptueAmount.ResidualRecaptueAmount)
ELSE #BookedAmount.BookedResidual_Amount END,0.0) as 'ResidualBalance',
ISNULL(DRB.DeferredRentalBalance,0.0) 'DeferredRentalBalance',
GLT.Symbol,
ISNULL(FinancingLeaseReceivableTemp.FinancingLeaseReceivable,0.0) 'FinancingLeaseReceivable',
ISNULL(FinancingResidualBooked.FinancingResidualBooked,0.0) 'FinancingResidualBooked',
ISNULL(FinancingUnearnedIncomeTemp.FinancingUnearnedIncome,0.0) 'FinancingUnearnedIncome',
ISNULL(FinancingUnearnedIncomeTemp.FinancingUnearnedResidualIncome,0.0) 'FinancingUnearnedResidualIncome',
ISNULL(FinancingNBVTemp.FinancingNBV,0.0) 'FinancingNBV',
#CURRENCYTEMP.Name 'Currency'
FROM
#GeneralLeaseTemp GLT
LEFT JOIN #OriginalAssetCost OAC ON GLT.ContractId = OAC.ContractId
LEFT JOIN #Accumulateddepreciation AD ON GLT.ContractId = AD.ContractId
LEFT JOIN #NBVTemp NBV ON GLT.ContractId = NBV.ContractId
LEFT JOIN #DeferredRentalBalance DRB ON GLT.ContractId = DRB.ContractId
LEFT JOIN #BookedAmount on #BookedAmount.ContractID=GLT.ContractId
LEFT JOIN #ResidualRecaptueAmount  ResidualRecaptueAmount on ResidualRecaptueAmount.ContractID=GLT.ContractID
LEFT JOIN #FinancingLeaseReceivableTemp FinancingLeaseReceivableTemp on GLT.ContractId=FinancingLeaseReceivableTemp.ContractId
LEFT JOIN #FinancingResidualBooked FinancingResidualBooked on GLT.ContractId=FinancingResidualBooked.ContractId
LEFT JOIN #FinancingUnearnedIncomeTemp FinancingUnearnedIncomeTemp on GLT.ContractId=FinancingUnearnedIncomeTemp.ContractId
LEFT JOIN #FinancingNBVTemp FinancingNBVTemp on GLT.ContractId=FinancingNBVTemp.ContractId
LEFT JOIN #CURRENCYTEMP on #CURRENCYTEMP.ContractId=GLT.ContractId
DROP TABLE #OriginalAssetCostTemp;
DROP TABLE #GeneralLeaseTemp;
DROP TABLE #OriginalAssetCost;
DROP TABLE #Accumulateddepreciation;
DROP TABLE #NBVTemp;
DROP TABLE #DeferredRentalBalance;
DROP TABLE #BookedAmount;
DROP TABLE #ResidualRecaptueAmount;
DROP TABLE #FinancingLeaseReceivableTemp;
DROP TABLE #FinancingResidualBookedTemp;
DROP TABLE #FinancingResidualBooked;
DROP TABLE #FinancingUnearnedIncomeTemp;
DROP TABLE #FinancingNBVTemp;
DROP TABLE #MaxAssetValueHistoryId;
END

GO
