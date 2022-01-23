SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDeltaLoadTestReconReport]
AS
BEGIN

set nocount on;
Declare @starttime datetimeoffset, @endtime datetimeoffset, @usercount int, @CurrentDate datetimeoffset;

select top 1 @starttime = starttime, @endtime = endtime
from loadtest2010..LoadTestRun
where RunDuration=3900 
order by starttime desc

Select @usercount= max(computedvalue) from loadtest2010..LoadTestComputedCounterSample
		where CounterName = 'User Load' and 
		instanceName = '_total'and 
		intervalstarttime >= @starttime and
        intervalendtime <= @endtime

DECLARE @NoOfUsers Int = @usercount		-- Number of users in Loadtest
DECLARE @ExpectedAdjuster float = 500 /CAST(@NoOfUsers AS float)
Declare @AssetCreatedTime datetimeoffset = '2017-11-15 15:25:15.4765995 +05:30';

select top 1 @CurrentDate = starttime AT TIME ZONE 'India Standard Time'
from loadtest2010..LoadTestRun
where RunDuration=3900 
order by starttime desc					-- Start Time of Loadtest


DROP TABLE if exists #Modules
CREATE TABLE #Modules (Id int NOT NULL, ModuleName NVARCHAR(100), Expected Int, Actual Int)

INSERT INTO #Modules SELECT * FROM 
(
SELECT 1 Id, 'Login' Module, 500/@ExpectedAdjuster Expected, Count(*) [Count] FROM UserLoginAudits WHERE CreatedTime > @CurrentDate  and loginname <> 'Somadatta.Purohit' UNION ALL
SELECT 2 Id, 'Customer' Module, 100/@ExpectedAdjuster Expected, Count(*) [Count] FROM Customers WHERE CreatedTime > @CurrentDate And Status = 'Active' UNION ALL
SELECT 3 Id, 'BillTo', 100/@ExpectedAdjuster, Count(*) FROM BillToes WHERE CreatedTime > @CurrentDate AND IsActive = 1 UNION ALL
SELECT 4 Id, 'Location', 150/@ExpectedAdjuster, Count(*) FROM Locations WHERE CreatedTime > @CurrentDate AND IsActive = 1 UNION ALL
SELECT 5 Id, 'Asset', 5400/@ExpectedAdjuster, Count(*) FROM Assets WHERE CreatedTime > @CurrentDate UNION ALL
SELECT 6 Id, 'Asset SKUs', 54000/@ExpectedAdjuster, COUNT(*) FROM AssetSKUs WHERE CreatedTime > @CurrentDate UNION ALL
SELECT 7 Id, 'Asset Location Change', 50/@ExpectedAdjuster, (select count(*) from (select distinct alc.LocationId, alc.NewLocationId from AssetsLocationChanges alc
join AssetsLocationChangeDetails alcd on alc.id = alcd.AssetsLocationChangeId join AssetLocations al on al.AssetId = alcd.AssetId
where alc.CreatedTime >= @CurrentDate) as InternalQuery) UNION ALL 
SELECT 8 Id, 'Payable Invoice', 540/@ExpectedAdjuster, Count(*) FROM PayableInvoices WHERE CreatedTime > @CurrentDate And Status = 'Completed'  UNION ALL
SELECT 9 Id, 'Payable Invoice Assets', 5400/@ExpectedAdjuster, Count(*) FROM PayableInvoices P JOIN PayableInvoiceAssets PA ON P.Id = PA.PayableInvoiceId WHERE P.CreatedTime > @CurrentDate And Status = 'Completed'  UNION ALL
SELECT 10 Id, 'Payable Invoice Asset SKUs', 54000/@ExpectedAdjuster, COUNT(*) FROM PayableInvoices P 
	 JOIN PayableInvoiceAssets PA ON P.Id = PA.PayableInvoiceId 
	 JOIN PayableInvoiceAssetSKUs ON PA.Id = PayableInvoiceAssetSKUs.PayableInvoiceAssetId
	 WHERE P.CreatedTime > @CurrentDate And Status = 'Completed' UNION ALL
SELECT 11 Id, 'Payable Invoice Other Costs', 540/@ExpectedAdjuster, Count(*) FROM PayableInvoices P JOIN PayableInvoiceOtherCosts PA ON P.Id = PA.PayableInvoiceId WHERE P.CreatedTime > @CurrentDate And Status = 'Completed'  UNION ALL
Select 12 Id, 'Lease with 20 Assets', 120/@ExpectedAdjuster, Count(*) from (Select LeaseFinanceId, Count(1) C From LeaseAssets LA Join LeaseFinances L On LA.LeaseFinanceId = L.Id Join COntracts C On L.ContractId = C.Id
Where C.CreatedTime > @CurrentDate AND L.BookingStatus = 'Commenced' Group By LeaseFinanceId Having COunt(1) = 20) T UNION ALL
Select 13 Id, 'Lease with 100 Assets', 30/@ExpectedAdjuster, Count(*) from (Select LeaseFinanceId, Count(1) C From LeaseAssets LA Join LeaseFinances L On LA.LeaseFinanceId = L.Id Join COntracts C On L.ContractId = C.Id
Where C.CreatedTime > @CurrentDate AND L.BookingStatus = 'Commenced' Group By LeaseFinanceId Having COunt(1) > 20) T UNION ALL
SELECT 14 Id, 'Lease Assets', 5400/@ExpectedAdjuster, Count(*) FROM Contracts C JOIN LeaseFinances LF ON C.Id = LF.ContractId JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId 
	WHERE C.CreatedTime > @CurrentDate And LF.BookingStatus = 'Commenced' And LA.IsActive = 1 UNION ALL
SELECT 15 Id, 'Lease Asset SKUs', 54000/@ExpectedAdjuster, COUNT(*) FROM Contracts C JOIN LeaseFinances LF ON C.Id = LF.ContractId JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId 
    JOIN  LeaseAssetSKUs LAS ON LA.Id = LAS.LeaseAssetId WHERE C.CreatedTime >  @CurrentDate And LF.BookingStatus = 'Commenced' And LA.IsActive = 1 UNION ALL
SELECT 16 Id, 'Lease Blended Items', 300/@ExpectedAdjuster, Count(*) FROM Contracts C JOIN LeaseFinances LF ON C.Id = LF.ContractId JOIN LeaseBlendedItems LA ON LF.Id = LA.LeaseFinanceId 
	WHERE C.CreatedTime > @CurrentDate And LF.BookingStatus = 'Commenced' UNION ALL
SELECT 17 Id, 'Lease Income Schedules', 5550/@ExpectedAdjuster, Count(*) FROM Contracts C JOIN LeaseFinances LF ON C.Id = LF.ContractId JOIN LeaseIncomeSchedules LA ON LF.Id = LA.LeaseFinanceId 
	WHERE C.CreatedTime > @CurrentDate And LF.BookingStatus = 'Commenced' UNION ALL
SELECT 18 Id, 'Lease Asset Income Schedules', 199800/@ExpectedAdjuster, Count(*) FROM Contracts C JOIN LeaseFinances LF ON C.Id = LF.ContractId JOIN LeaseIncomeSchedules LA ON LF.Id = LA.LeaseFinanceId 
	JOIN AssetIncomeSchedules A on LA.Id = A.LeaseIncomeScheduleId
	WHERE C.CreatedTime > @CurrentDate And LF.BookingStatus = 'Commenced' UNION ALL
SELECT 19 Id, 'Receipt',500/@ExpectedAdjuster, Count(*) FROM Receipts WHERE CreatedTime > @CurrentDate And Status = 'Posted' UNION ALL
SELECT 20 Id, 'Receipt Receivable Details',25000/@ExpectedAdjuster, Count(*) FROM Receipts R JOIN ReceiptApplications RA ON R.Id = RA.ReceiptId 
	JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId WHERE R.CreatedTime > @CurrentDate And Status = 'Posted' UNION ALL
SELECT 21 Id, 'Lease Restructure' Module, 20/@ExpectedAdjuster Expected, Count(*) [Count] FROM LeaseAmendments WHERE LeaseAmendmentStatus = 'Approved'
	and AmendmentType = 'Restructure' and CreatedTime > @CurrentDate  UNION ALL
SELECT 22 Id, 'Sundry PassThrough', 100/@ExpectedAdjuster, Count(*) FROM Sundries WHERE CreatedTime > @CurrentDate And SundryType = 'PassThrough' And IsActive = 1 UNION ALL
SELECT 23 Id, 'Sundry PassThrough - Receivables', 5000/@ExpectedAdjuster, Count(*) FROM Sundries S JOIN Receivables R ON S.ReceivableId = R.Id
	JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId WHERE S.CreatedTime > @CurrentDate And SundryType = 'PassThrough' And S.IsActive = 1 UNION ALL
SELECT 24 Id, 'Sundry Details', 5000/@ExpectedAdjuster, Count(*) FROM SundryDetails WHERE CreatedTime > @CurrentDate And IsActive = 1 UNION ALL
SELECT 25 Id, 'Payoff - Full', 75/@ExpectedAdjuster, Count(*)  FROM Payoffs WHERE CreatedTime > @CurrentDate And FullPayoff = 1 And Status = 'Activated' UNION ALL
SELECT 26 Id, 'Payoff Asset - Full', 4500/@ExpectedAdjuster, Count(*)  FROM Payoffs P JOIN PayoffAssets PA ON P.Id = PA.PayoffId WHERE P.CreatedTime > @CurrentDate 
	And FullPayoff = 1 And P.Status = 'Activated' UNION ALL
SELECT 27 Id, 'Payoff - Partial', 100/@ExpectedAdjuster, Count(*)  FROM Payoffs WHERE CreatedTime > @CurrentDate And FullPayoff = 0 And Status = 'Activated' UNION ALL
SELECT 28 Id, 'Payoff Asset - Partial', 1000/@ExpectedAdjuster, Count(*)  FROM Payoffs P JOIN PayoffAssets PA ON P.Id = PA.PayoffId WHERE P.CreatedTime > @CurrentDate And FullPayoff = 0 
	And P.Status = 'Activated' UNION ALL
SELECT 29 Id, 'Collection WorkList', 50/@ExpectedAdjuster, Count(*) FROM CollectionWorkLists WHERE UpdatedTime > @CurrentDate And CreatedTime <= @CurrentDate UNION ALL
SELECT 30 Id, 'Asset Split' Module, 5/@ExpectedAdjuster Expected, Count(*) [Count] from AssetSplits where ApprovalStatus = 'Approved'
and CreatedTime > @CurrentDate UNION ALL
SELECT 31 Id, 'Asset Split Details' Module, 10/@ExpectedAdjuster Expected, Count(*) [Count] from AssetSplitDetails where AssetSplitid in (select id from AssetSplits
where ApprovalStatus = 'Approved' and CreatedTime > @CurrentDate) UNION ALL
SELECT 32 Id, 'Charge Off', 10/@ExpectedAdjuster,  Count(*) [Count]  FROM ChargeOffs where Status = 'Approved' and CreatedTime > @CurrentDate and ReceiptId is NULL and IsActive=1 UNION ALL
SELECT 33 Id, 'Charge Off Details', 300/@ExpectedAdjuster,  Count(*) [Count]  from ChargeOffAssetDetails where ChargeOffid in (Select id from ChargeOffs Where
Status = 'Approved' and CreatedTime > @CurrentDate and ReceiptId is NULL and IsActive=1) UNION ALL
SELECT 34 Id, 'Non Accrual', 1/@ExpectedAdjuster,  Count(*) [Count]  FROM NonAccruals where Status = 'Approved' and CreatedTime > @CurrentDate UNION ALL
SELECT 35 Id, 'Non Accrual Contracts', 40/@ExpectedAdjuster,  Count(*) [Count]  from NonAccrualContracts where NonAccrualId in (Select id from NonAccruals
where Status = 'Approved'and CreatedTime > @CurrentDate) UNION ALL
SELECT 36 Id, 'GL Transfer', 1/@ExpectedAdjuster,  Count(*) [Count]  from GLTransfers where Status = 'Approved' and CreatedTime > @CurrentDate UNION ALL
SELECT 37 Id, 'GL Transfer Deal Details', 50/@ExpectedAdjuster,  Count(*) [Count]  from GLTransferDealDetails where GLTransferId in (Select id from GLTransfers where
Status = 'Approved'and CreatedTime > @CurrentDate) UNION ALL
SELECT 38 Id, 'Activity', 400/@ExpectedAdjuster,  Count(*) [Count]  FROM Activities WHERE CreatedTime > @CurrentDate AND IsActive = 1 UNION ALL
SELECT 39 Id, 'Comment', 800/@ExpectedAdjuster ,Count(*) [Count]  FROM Comments WHERE CreatedTime > @CurrentDate AND IsActive = 1 
) List

Alter Table #Modules Add Deviation Decimal(18,2)
Update #Modules Set Deviation = (Cast(Actual as float)/Cast(Expected as float)) * 100 - 100

SELECT Id, ModuleName [Module Name], Expected, Actual, Deviation [Deviation %] FROM #Modules order by Id
DROP TABLE if exists #Modules
END

GO
