SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetFinancialValuesForPayoffAssets]
(
	@LeaseAssetIds LeaseAssetDetailType ReadOnly,
	@LeaseFinanceId BIGINT,
	@PayoffEffectiveDate Date = null,
	@IsPayoffAtInception BIT,
	@IsInstallLeasePayoff BIT,
	@IsCapitalLeasePayoff BIT,
	@IsOperatingLeasePayoff BIT,
	@IsOTPLeasePayoff BIT,
	@CommencementDate DATE,
	@MaturityDate DATE,
	@ReceivableEntityType NVARCHAR(10),
	@InvoicedBillingStatus NVARCHAR(20),
	@UnInvoicedBillingStatus NVARCHAR(20),
	@AssetValueHistoryNBVImpairmentType NVARCHAR(30),
	@CapitalLeaseRentalType NVARCHAR(40),
	@OperatingLeaseRentalType NVARCHAR(40),
	@FloatRateReceivableType NVARCHAR(40),
	@IsOperatingLease BIT,
	@IsChargedOffLease BIT,
	@IsSyndicatedServiced BIT,
	@AssetValueHistoryResidualRecaptureType NVARCHAR(30),
	@ResidualRetainedFactor DECIMAL(18,16),
	@SyndicationType NVARCHAR(30),
	@InterimInterestPaymentType NVARCHAR(30),
	@InterimRentPaymentType NVARCHAR(30),
	@AVHSourceModule_FixedTermDepreciation NVARCHAR(30),
	@AVHSourceModule_Syndications NVARCHAR(20),
	@Syndication_ApprovalStatus NVARCHAR(30),
	@SyndicationType_ParticipatedSale NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #SelectedLeaseAssets
(
LeaseAssetId BIGINT,
AssetId BIGINT,
IsLeaseAsset BIT,
IsFailedSaleLeaseBack BIT
);
CREATE CLUSTERED INDEX IDX_SelectedLeaseAssets ON #SelectedLeaseAssets(LeaseAssetId,AssetId)

INSERT INTO #SelectedLeaseAssets
SELECT LA.Id,LA.AssetId, LA.IsLeaseAsset,LA.IsFailedSaleLeaseback
FROM LeaseAssets LA JOIN @LeaseAssetIds LAI ON LAI.Id = LA.Id;
DECLARE @ContractId BIGINT = (SELECT TOP 1 ContractId FROM LeaseFinances WHERE Id=@LeaseFinanceId);
DECLARE @EffectiveDate DATE = CASE WHEN @IsPayoffAtInception = 1 THEN @PayoffEffectiveDate ELSE DATEADD(DAY,1,@PayoffEffectiveDate) END;

CREATE TABLE #LeaseAssetSKUs
(
LeaseAssetId BIGINT,
AssetId BIGINT,
IsLeaseComponent BIT,
BookedResidual DECIMAL(16,2),
NBV DECIMAL(16,2)
);

INSERT INTO #LeaseAssetSKUs
SELECT SA.LeaseAssetId, SA.AssetId, LAS.IsLeaseComponent, SUM(BookedResidual_Amount) 'BookedResidual', SUM(NBV_Amount) 'NBV'
FROM #SelectedLeaseAssets SA
JOIN LeaseAssetSKUs LAS ON SA.LeaseAssetId = LAS.LeaseAssetId
GROUP BY SA.LeaseAssetId, SA.AssetId, LAS.IsLeaseComponent

CREATE TABLE #AssetLeaseIncomeScheduleInfo
(
AssetId BIGINT,
LeaseFinanceId BIGINT,
LeaseAssetId BIGINT,
LeaseIncomeScheduleId BIGINT,
IsSchedule BIT,
IncomeDate DATE,
IsLessorOwned BIT,
IsAssetIncomeActive BIT,
DeferredRentalIncome_Amount DECIMAL(16,2),
Depreciation_Amount DECIMAL(16,2),
FinanceBeginNetBookValue_Amount DECIMAL(16,2),
DeferredSellingProfitIncomeBalance_Amount DECIMAL(16,2),
LeaseBeginNetBookValue_Amount DECIMAL(16,2),
FinanceEndNetBookValue_Amount DECIMAL(16,2),
LeaseEndNetBookValue_Amount DECIMAL(16,2),
LeaseIncome_Amount DECIMAL(16,2),
LeaseResidualIncome_Amount DECIMAL(16,2),
FinanceIncome_Amount DECIMAL(16,2),
FinanceResidualIncome_Amount DECIMAL(16,2),
LeaseDeferredRentalIncome_Amount DECIMAL(16,2),
EndNetBookValue_Amount DECIMAL(16,2)
);
CREATE NONCLUSTERED INDEX IDX_AssetLeaseIncomeScheduleInfo ON #AssetLeaseIncomeScheduleInfo(LeaseAssetId,AssetId,LeaseFinanceId) INCLUDE(LeaseIncomeScheduleId,IncomeDate,IsSchedule,IsLessorOwned)

Select AIS.Id,SLA.AssetId, SLA.LeaseAssetId, AIS.LeaseIncomeScheduleId
INTO #AssetIncomeScheduleInfo FROM #SelectedLeaseAssets SLA
JOIN AssetIncomeSchedules AIS ON AIS.AssetId = SLA.AssetId

SELECT DISTINCT AIS.LeaseIncomeScheduleId INTO #LeaseIncomeScheduleIds FROM #AssetIncomeScheduleInfo AIS

SELECT 
LIS.Id,
LIS.LeaseFinanceId,
LIS.Id AS LeaseIncomeScheduleId,
LIS.IsSchedule,
LIS.IncomeDate,
LIS.IsLessorOwned
INTO #LeaseIncomeScheduleInfo 
FROM #LeaseIncomeScheduleIds LISIDs 
JOIN LeaseIncomeSchedules LIS ON LISIDs.LeaseIncomeScheduleId =  LIS.Id


INSERT INTO #AssetLeaseIncomeScheduleInfo
SELECT AISI.AssetId,
LIS.LeaseFinanceId,
AISI.LeaseAssetId,
LIS.Id AS LeaseIncomeScheduleId,
LIS.IsSchedule,
LIS.IncomeDate,
LIS.IsLessorOwned,
AIS.IsActive AS IsAssetIncomeActive,
AIS.DeferredRentalIncome_Amount,
AIS.Depreciation_Amount,
AIS.FinanceBeginNetBookValue_Amount,
AIS.DeferredSellingProfitIncomeBalance_Amount,
AIS.LeaseBeginNetBookValue_Amount,
AIS.FinanceEndNetBookValue_Amount,
AIS.LeaseEndNetBookValue_Amount,
AIS.LeaseIncome_Amount,
AIS.LeaseResidualIncome_Amount,
AIS.FinanceIncome_Amount,
AIS.FinanceResidualIncome_Amount,
AIS.LeaseDeferredRentalIncome_Amount,
AIS.EndNetBookValue_Amount
FROM #AssetIncomeScheduleInfo AISI
JOIN AssetIncomeSchedules AIS ON AIS.Id = AISI.Id
JOIN #LeaseIncomeScheduleInfo LIS ON LIS.Id =  AIS.LeaseIncomeScheduleId
 
CREATE TABLE #NBVInfo
(
LeaseAssetId BIGINT,
NBV DECIMAL(16,2)
)
CREATE TABLE #LeaseComponentNBVInfo
(   
    LeaseAssetId BIGINT,
	NBV DECIMAL(16,2),
);

CREATE TABLE #NonLeaseComponentNBVInfo
(   
    LeaseAssetId BIGINT,
	NBV DECIMAL(16,2),
);

CREATE TABLE #LatestAssetValueInformation
(
	LeaseAssetId BIGINT,
	AssetValueHistoryId BIGINT,
	IsLeaseComponent BIT,
	RowNumber BIGINT
);
CREATE TABLE #OTPNBVImpairmentInfo
(
LeaseAssetId BIGINT,
NBVImpairment DECIMAL(16,2),
IsLeaseComponent BIT
);
CREATE TABLE #OTPDeprecicationInfo
(
LeaseAssetId BIGINT,
OTPDepreciation DECIMAL(16,2)
);
CREATE TABLE #OTPDeferredRentalIncomeInfo
(
LeaseAssetId BIGINT,
DeferredRentalIncome DECIMAL(16,2)
);
CREATE TABLE #MaturityDatePaymentDetails
(
LeaseAssetId BIGINT,
LeasePayment Decimal(16,2),
FinancePayment Decimal(16,2),
PaymentType NVARCHAR(28)
);
CREATE TABLE #SoldNBVDetails
(
LeaseAssetId BIGINT,
SoldNBV DECIMAL(16,2)
);
CREATE TABLE #DSPIncomeBalanceInfo
(
LeaseAssetId BIGINT,
DSPBalanceAsOfPayoffEffectiveDate DECIMAL(16,2)
);
DECLARE @LeaseIncomeScheduleId BIGINT;
IF @IsOTPLeasePayoff = 1 AND @PayoffEffectiveDate > @MaturityDate AND @IsChargedOffLease = 0
BEGIN
INSERT INTO #OTPDeferredRentalIncomeInfo
SELECT ALIS.LeaseAssetId, SUM(ALIS.DeferredRentalIncome_Amount)
FROM #AssetLeaseIncomeScheduleInfo ALIS
JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId AND ALIS.IsSchedule = 1 AND ALIS.IsLessorOwned = 1 AND ALIS.IsAssetIncomeActive = 1 AND ALIS.IncomeDate = @PayoffEffectiveDate
GROUP BY ALIS.LeaseAssetId
INSERT INTO #OTPDeprecicationInfo
SELECT ALIS.LeaseAssetId, SUM(ALIS.Depreciation_Amount) * -1
FROM #AssetLeaseIncomeScheduleInfo ALIS
JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId AND ALIS.IsAssetIncomeActive = 1
AND ALIS.IsSchedule = 1 AND ALIS.IsLessorOwned = 1
AND ALIS.IncomeDate > @MaturityDate
AND ALIS.IncomeDate <= @PayoffEffectiveDate
GROUP BY ALIS.LeaseAssetId

INSERT INTO #OTPNBVImpairmentInfo
SELECT SLA.LeaseAssetId,
 0 - SUM(AVH.Value_Amount),
AVH.IsLeaseComponent
FROM #SelectedLeaseAssets SLA
JOIN AssetValueHistories AVH ON SLA.AssetId = AVH.AssetId 
WHERE AVH.SourceModule = @AssetValueHistoryNBVImpairmentType AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1
AND AVH.IncomeDate > @MaturityDate AND AVH.IncomeDate <= @PayoffEffectiveDate
GROUP BY SLA.LeaseAssetId,AVH.IsLeaseComponent

--INSERT INTO #NLCOTPNBVImpairmentInfo
--SELECT LA.Id, 0 - SUM(AVH.Value_Amount)
--FROM #SelectedLeaseAssets SLA
--JOIN LeaseAssets LA ON SLA.LeaseAssetId = LA.Id
--JOIN AssetValueHistories AVH ON LA.AssetId = AVH.AssetId  AND AVH.IsLeaseComponent = 0
--WHERE AVH.SourceModule = @AssetValueHistoryNBVImpairmentType AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1
--AND AVH.IncomeDate > @MaturityDate AND AVH.IncomeDate <= @PayoffEffectiveDate
--GROUP BY LA.Id

END;
IF @IsChargedOffLease = 0
BEGIN
	IF @PayoffEffectiveDate < @CommencementDate
	BEGIN
		 INSERT INTO #LeaseComponentNBVInfo
		 SELECT SA.LeaseAssetId, LA.NBV_Amount - LA.CapitalizedInterimInterest_Amount - LA.CapitalizedInterimRent_Amount - LA.CapitalizedProgressPayment_Amount
		 FROM #SelectedLeaseAssets SA
		 JOIN LeaseAssets LA ON SA.LeaseAssetId = LA.Id
		 JOIN Assets AST ON LA.AssetId = AST.Id
		 WHERE AST.IsSKU = 0 and LA.IsLeaseAsset = 1;

		 INSERT INTO #NonLeaseComponentNBVInfo
		 SELECT SA.LeaseAssetId, LA.NBV_Amount - LA.CapitalizedInterimInterest_Amount - LA.CapitalizedInterimRent_Amount - LA.CapitalizedProgressPayment_Amount
		 FROM #SelectedLeaseAssets SA
		 JOIN LeaseAssets LA ON SA.LeaseAssetId = LA.Id
		 JOIN Assets AST ON LA.AssetId = AST.Id
		 WHERE AST.IsSKU = 0 and LA.IsLeaseAsset = 0;

		 INSERT INTO #LeaseComponentNBVInfo
		 SELECT LA.Id 'LeaseAssetId', SUM(LASK.NBV_Amount) - SUM(LASK.CapitalizedInterimInterest_Amount) - SUM(LASK.CapitalizedInterimRent_Amount) - SUM(LASK.CapitalizedProgressPayment_Amount)
		 FROM #SelectedLeaseAssets SA
		 JOIN LeaseAssets LA ON SA.LeaseAssetId = LA.Id
		 JOIN Assets AST ON LA.AssetId = AST.Id
		 JOIN LeaseAssetSKUs LASK ON LA.Id = LASK.LeaseAssetId
		 WHERE AST.IsSKU = 1 and LASK.IsLeaseComponent = 1
		 GROUP BY LA.Id;
		 

		 INSERT INTO #NonLeaseComponentNBVInfo
		 SELECT LA.Id 'LeaseAssetId', SUM(LASK.NBV_Amount) - SUM(LASK.CapitalizedInterimInterest_Amount) - SUM(LASK.CapitalizedInterimRent_Amount) - SUM(LASK.CapitalizedProgressPayment_Amount)
		 FROM #SelectedLeaseAssets SA
		 JOIN LeaseAssets LA ON SA.LeaseAssetId = LA.Id
		 JOIN Assets AST ON LA.AssetId = AST.Id
		 JOIN LeaseAssetSKUs LASK ON LA.Id = LASK.LeaseAssetId
		 WHERE AST.IsSKU = 1 and LASK.IsLeaseComponent = 0
		 GROUP BY LA.Id;
	END
	ELSE IF @PayoffEffectiveDate < @MaturityDate
	BEGIN
		IF @IsOperatingLease = 1
		BEGIN
			INSERT INTO #LatestAssetValueInformation
			SELECT SA.LeaseAssetId, AVH.Id, AVH.IsLeaseComponent,  RowNumber = ROW_NUMBER() OVER (PARTITION BY SA.LeaseAssetId,AVH.IsLeaseComponent ORDER BY AVH.IncomeDate ASC, AVH.Id DESC) 
			FROM #SelectedLeaseAssets SA
			JOIN AssetValueHistories AVH ON SA.AssetId = AVH.AssetId AND AVH.IncomeDate >= @EffectiveDate AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1
			WHERE SA.IsFailedSaleLeaseBack=0;

			INSERT INTO #LeaseComponentNBVInfo
			SELECT SA.LeaseAssetId, AVH.BeginBookValue_Amount
			FROM #SelectedLeaseAssets SA
			JOIN #LatestAssetValueInformation AVI ON SA.LeaseAssetId = AVI.LeaseAssetId
			JOIN AssetValueHistories AVH ON AVI.AssetValueHistoryId = AVH.Id AND AVH.IsLessorOwned = 1
			and AVH.IsLeaseComponent = AVI.IsLeaseComponent
            WHERE AVI.RowNumber=1 and AVI.IsLeaseComponent = 1 and AVH.IsLeaseComponent = 1;


			SELECT TOP 1 @LeaseIncomeScheduleId = LI.Id FROM LeaseIncomeSchedules LI 
				JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
				JOIN Contracts C ON LF.ContractId = C.Id
				WHERE C.Id= @ContractId AND LI.IsSchedule=1 AND LI.IsLessorOwned=1 AND LI.IncomeDate >= @EffectiveDate ORDER BY LI.IncomeDate;

            INSERT INTO #NonLeaseComponentNBVInfo
            SELECT LAS.LeaseAssetId, SUM(AIS.FinanceBeginNetBookValue_Amount)
            FROM #LeaseAssetSKUs LAS
            JOIN #AssetLeaseIncomeScheduleInfo AIS ON LAS.AssetId = AIS.AssetId AND AIS.LeaseIncomeScheduleId = @LeaseIncomeScheduleId
			WHERE LAS.IsLeaseComponent = 0
            GROUP BY LAS.LeaseAssetId;


		    INSERT INTO #NonLeaseComponentNBVInfo
		    SELECT SA.LeaseAssetId, SUM(AIS.FinanceBeginNetBookValue_Amount)
		    FROM #SelectedLeaseAssets SA
			JOIN Assets A ON SA.AssetId = A.Id And A.IsSKU = 0 AND SA.IsLeaseAsset = 0
			JOIN #AssetLeaseIncomeScheduleInfo AIS ON SA.AssetId = AIS.AssetId
			WHERE AIS.LeaseIncomeScheduleId = @LeaseIncomeScheduleId
			GROUP BY SA.LeaseAssetId;
        END
		ELSE
		BEGIN
			SELECT TOP 1 @LeaseIncomeScheduleId = LI.Id FROM LeaseIncomeSchedules LI 
			JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
			JOIN Contracts C ON LF.ContractId = C.Id
			WHERE C.Id= @ContractId AND LI.IsSchedule=1 AND LI.IsLessorOwned=1 AND LI.IncomeDate >= @EffectiveDate ORDER BY LI.IncomeDate;

			INSERT INTO #DSPIncomeBalanceInfo 
			SELECT ALIS.LeaseAssetId, SUM(ALIS.DeferredSellingProfitIncomeBalance_Amount) 
			FROM #AssetLeaseIncomeScheduleInfo ALIS
			JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
			WHERE LF.ContractId = @ContractId AND ALIS.IsSchedule = 1 AND ALIS.IsLessorOwned = 1 AND ALIS.IsAssetIncomeActive = 1 AND ALIS.IncomeDate = @PayoffEffectiveDate 
			GROUP BY ALIS.LeaseAssetId;		
					 
			INSERT INTO #LeaseComponentNBVInfo
		    SELECT ALIS.LeaseAssetId as 'LeaseAssetId', ALIS.LeaseBeginNetBookValue_Amount - ISNULL(DRI.DSPBalanceAsOfPayoffEffectiveDate,0.0)  as 'BeginNetBookValue_Amount' --PROD01-18269
			FROM #AssetLeaseIncomeScheduleInfo ALIS
			LEFT JOIN #DSPIncomeBalanceInfo DRI ON ALIS.LeaseAssetId = DRI.LeaseAssetId
			WHERE ALIS.LeaseIncomeScheduleId = @LeaseIncomeScheduleId
			
			INSERT INTO #NonLeaseComponentNBVInfo
		    SELECT ALIS.LeaseAssetId as 'LeaseAssetId', ALIS.FinanceBeginNetBookValue_Amount as 'BeginNetBookValue_Amount' --PROD01-18269
			FROM #AssetLeaseIncomeScheduleInfo ALIS
			WHERE ALIS.LeaseIncomeScheduleId = @LeaseIncomeScheduleId;
		END
	END
	ELSE IF @PayoffEffectiveDate = @MaturityDate
	BEGIN

		SELECT TOP 1 @LeaseIncomeScheduleId = LI.Id FROM LeaseIncomeSchedules LI 
				JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
				JOIN Contracts C ON LF.ContractId = C.Id
				WHERE C.Id= @ContractId AND LI.IsSchedule=1 AND LI.IsLessorOwned=1 AND LI.IncomeDate = @MaturityDate;

		IF @IsOperatingLease = 1
		BEGIN
  
			INSERT INTO #NonLeaseComponentNBVInfo   
			SELECT ALIS.LeaseAssetId, ALIS.FinanceEndNetBookValue_Amount
			FROM #AssetLeaseIncomeScheduleInfo ALIS
			WHERE ALIS.LeaseIncomeScheduleId = @LeaseIncomeScheduleId;

			INSERT INTO #LatestAssetValueInformation
			SELECT SA.LeaseAssetId, AVH.Id, AVH.IsLeaseComponent, RowNumber = ROW_NUMBER() OVER (PARTITION BY SA.LeaseAssetId ORDER BY AVH.IncomeDate DESC, AVH.Id DESC) 
			FROM #SelectedLeaseAssets SA
			JOIN AssetValueHistories AVH ON SA.AssetId = AVH.AssetId
			WHERE SA.IsFailedSaleLeaseBack=0 AND AVH.IsLeaseComponent = 1 AND AVH.IncomeDate <= @PayoffEffectiveDate AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1;

			INSERT INTO #LeaseComponentNBVInfo
			SELECT SA.LeaseAssetId, AVH.EndBookValue_Amount
			FROM #SelectedLeaseAssets SA
			JOIN #LatestAssetValueInformation AVI ON SA.LeaseAssetId = AVI.LeaseAssetId
			JOIN AssetValueHistories AVH ON AVI.AssetValueHistoryId = AVH.Id
            WHERE AVI.RowNumber = 1

		END
		ELSE
		BEGIN
  
			INSERT INTO #NonLeaseComponentNBVInfo
			SELECT ALIS.LeaseAssetId, ALIS.FinanceEndNetBookValue_Amount
			FROM #AssetLeaseIncomeScheduleInfo ALIS
			WHERE ALIS.LeaseIncomeScheduleId = @LeaseIncomeScheduleId;

			INSERT INTO #LeaseComponentNBVInfo   
			SELECT ALIS.LeaseAssetId, ALIS.LeaseEndNetBookValue_Amount 
			FROM #AssetLeaseIncomeScheduleInfo ALIS
			WHERE ALIS.LeaseIncomeScheduleId = @LeaseIncomeScheduleId;

		END
	END
	ELSE 
	BEGIN
	INSERT INTO #LatestAssetValueInformation
		SELECT SA.LeaseAssetId, AVH.Id,AVH.IsLeaseComponent, RowNumber = ROW_NUMBER() OVER (PARTITION BY SA.LeaseAssetId,AVH.IsLeaseComponent ORDER BY AVH.IncomeDate DESC, AVH.Id DESC) 
		FROM #SelectedLeaseAssets SA
		JOIN AssetValueHistories AVH ON SA.AssetId = AVH.AssetId
		WHERE AVH.IncomeDate <= @PayoffEffectiveDate AND AVH.IncomeDate >= @MaturityDate AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1;

		INSERT INTO #LeaseComponentNBVInfo
		SELECT SA.LeaseAssetId, AVH.EndBookValue_Amount
		FROM #SelectedLeaseAssets SA
		JOIN #LatestAssetValueInformation AVI ON SA.LeaseAssetId = AVI.LeaseAssetId
		JOIN AssetValueHistories AVH ON AVI.AssetValueHistoryId = AVH.Id AND AVH.IsLessorOwned = 1 AND AVI.IsLeaseComponent = AVH.IsLeaseComponent
		WHERE AVI.RowNumber = 1 and SA.IsFailedSaleLeaseBack=0 AND AVH.IsLeaseComponent = 1

		INSERT INTO #NonLeaseComponentNBVInfo
		SELECT SA.LeaseAssetId, SUM(AVH.EndBookValue_Amount)
		FROM #SelectedLeaseAssets SA
		JOIN #LatestAssetValueInformation AVI ON SA.LeaseAssetId = AVI.LeaseAssetId
		JOIN AssetValueHistories AVH ON AVI.AssetValueHistoryId = AVH.Id AND AVH.IsLessorOwned = 1 AND AVI.IsLeaseComponent = AVH.IsLeaseComponent
		WHERE AVI.RowNumber = 1 and (SA.IsFailedSaleLeaseBack=1 OR AVH.IsLeaseComponent = 0)
		GROUP BY SA.LeaseAssetId

	END
	
END;

WITH CTE_ReceivableInfo
AS
(
	Select R.Id AS ReceivableId,R.FunderId,RT.Name,LP.StartDate 
	FROM Receivables R 
	JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND RT.IsRental = 1
	JOIN LeasePaymentSchedules LP ON LP.Id = R.PaymentScheduleId
	WHERE  R.EntityId = @ContractId
	AND R.IsActive = 1 
	AND R.IsDummy = 0 
	AND R.EntityType = @ReceivableEntityType 
	AND R.PaymentScheduleId IS NOT NULL
	AND (R.FunderId IS NULL OR @IsSyndicatedServiced = 1)
	AND R.SourceTable = '_'
	AND RT.Name IN (@CapitalLeaseRentalType,@OperatingLeaseRentalType,@FloatRateReceivableType)
)
SELECT LeaseAssetId = SLA.LeaseAssetId,
RentalPeriodStartDate = R.StartDate,
LCAmount = CASE WHEN R.FunderId IS NULL THEN RD.LeaseComponentAmount_Amount ELSE 0.0 END,
LCSyndicatedAmount = CASE WHEN R.FunderId IS NOT NULL THEN RD.LeaseComponentAmount_Amount ELSE 0.0 END,
NLCAmount = CASE WHEN R.FunderId IS NULL THEN RD.NonLeaseComponentAmount_Amount ELSE 0.0 END,
NLCSyndicatedAmount = CASE WHEN R.FunderId IS NOT NULL THEN RD.NonLeaseComponentAmount_Amount ELSE 0.0 END,
EffectiveBalance = CASE WHEN R.FunderId IS NULL THEN RD.EffectiveBalance_Amount ELSE 0.0 END,
BilledStatus = RD.BilledStatus,
ReceivableType = R.Name
INTO #LeaseAssetRentalsInfo
FROM #SelectedLeaseAssets SLA
JOIN ReceivableDetails RD ON RD.AssetId = SLA.AssetId AND RD.IsActive = 1
JOIN CTE_ReceivableInfo R ON RD.ReceivableId = R.ReceivableId

SELECT LeaseAssetId, OutstandingRentalBilled = SUM(EffectiveBalance) INTO #OutstandingRentalsBilledInfo
FROM #LeaseAssetRentalsInfo
WHERE BilledStatus = @InvoicedBillingStatus
GROUP BY LeaseAssetId;

SELECT LeaseAssetId, OutstandingRentalUnbilled = SUM(EffectiveBalance) INTO #OutstandingRentalsUnbilledInfo
FROM #LeaseAssetRentalsInfo
WHERE BilledStatus = @UnInvoicedBillingStatus
AND RentalPeriodStartDate >= @EffectiveDate
GROUP BY LeaseAssetId;

CREATE TABLE #RemainingRentalsInfo
(
LeaseAssetId BIGINT,
LCRemainingRent DECIMAL(16,2),
LCSyndicatedRemainingRent DECIMAL(16,2),
NLCRemainingRent DECIMAL(16,2),
NLCSyndicatedRemainingRent DECIMAL(16,2)
);

CREATE TABLE #LCCalculatedNBVInfo
(
LeaseAssetId BIGINT,
CalculatedNBV DECIMAL(16,2)
);
CREATE TABLE #NLCCalculatedNBVInfo
(
LeaseAssetId BIGINT,
CalculatedNBV DECIMAL(16,2)
);
CREATE TABLE #LeaseAssetUnearnedIncomeInfo
(
	LeaseAssetId BIGINT,
	LeaseComponentUnearnedIncome DECIMAL(16,2),
	NonLeaseComponentUnearnedIncome DECIMAL(16,2),
	LeaseComponentUnearnedResidualIncome DECIMAL(16,2),
	NonLeaseComponentUnearnedResidualIncome DECIMAL(16,2)
);
CREATE TABLE #NBVImpairmentInfo
(
LeaseAssetId BIGINT,
NBVImpairment DECIMAL(16,2),
IsLeaseComponent BIT
);

CREATE TABLE #FixedTermDepreciationInfo
(
LeaseAssetId BIGINT,
FixedTermDepreciation DECIMAL(16,2)
);
CREATE TABLE #DeferredRentalIncomeInfo
(
LeaseAssetId BIGINT,
DeferredRentalIncome DECIMAL(16,2),
DeferredSellingProfitIncomeBalance DECIMAL(16,2)
);
CREATE TABLE #OwnedNBVOnMaturityDetails
(
LeaseAssetId BIGINT,
NBVOnMaturity DECIMAL(16,2)
);
CREATE TABLE #SyndicatedNBVOnMaturityDetails
(
LeaseAssetId BIGINT,
NBVOnMaturity DECIMAL(16,2)
);
IF @IsCapitalLeasePayoff = 1
BEGIN

	INSERT INTO #RemainingRentalsInfo
	SELECT LR.LeaseAssetId, 
	LCRemainingRent = SUM(LR.LCAmount),
	LCSyndicatedRemainingRent = SUM(LR.LCSyndicatedAmount),
	NLCRemainingRent = SUM(LR.NLCAmount),
	NLCSyndicatedRemainingRent = SUM(LR.NLCSyndicatedAmount)
	FROM #LeaseAssetRentalsInfo LR 
	WHERE LR.RentalPeriodStartDate >= @EffectiveDate AND LR.RentalPeriodStartDate <= @MaturityDate AND LR.ReceivableType <> @FloatRateReceivableType
	GROUP BY LR.LeaseAssetId;

	IF @IsChargedOffLease = 0
	BEGIN
		INSERT INTO #LeaseAssetUnearnedIncomeInfo 
		SELECT ALIS.LeaseAssetId, SUM(ALIS.LeaseIncome_Amount - ALIS.LeaseResidualIncome_Amount),SUM(ALIS.FinanceIncome_Amount - ALIS.FinanceResidualIncome_Amount), SUM(ALIS.LeaseResidualIncome_Amount) , SUM(ALIS.FinanceResidualIncome_Amount) 
		FROM #AssetLeaseIncomeScheduleInfo ALIS
		JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id AND LF.ContractId = @ContractId
		WHERE ALIS.IsAssetIncomeActive = 1 AND ALIS.IsSchedule = 1 AND ALIS.IsLessorOwned = 1 AND ALIS.IncomeDate >= @EffectiveDate
		GROUP BY ALIS.LeaseAssetId;

		INSERT INTO #DeferredRentalIncomeInfo 
		SELECT ALIS.LeaseAssetId, 0 as DeferredRentalIncome_Amount, SUM(ALIS.DeferredSellingProfitIncomeBalance_Amount) 
		FROM #AssetLeaseIncomeScheduleInfo ALIS
		JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
		WHERE LF.ContractId = @ContractId AND ALIS.IsSchedule = 1 AND ALIS.IsLessorOwned = 1 AND ALIS.IsAssetIncomeActive = 1 AND ALIS.IncomeDate = @PayoffEffectiveDate 
		GROUP BY ALIS.LeaseAssetId;

		IF @SyndicationType != 'FullSale'
		BEGIN
		    /*LC Asset without SKU*/
			INSERT INTO #LCCalculatedNBVInfo
			SELECT SLA.LeaseAssetId, ISNULL(FR.LCRemainingRent, 0.0) + 
			(LA.BookedResidual_Amount * @ResidualRetainedFactor) - 
			(ISNULL(LUI.LeaseComponentUnearnedIncome, 0.0)) - (ISNULL(LUI.LeaseComponentUnearnedResidualIncome, 0.0))
			FROM #SelectedLeaseAssets SLA
			JOIN LeaseAssets LA ON SLA.LeaseAssetId = LA.Id AND LA.IsLeaseAsset = 1
			JOIN Assets A ON LA.AssetId = A.Id AND A.IsSKU = 0
			LEFT JOIN #RemainingRentalsInfo FR ON SLA.LeaseAssetId = FR.LeaseAssetId
			LEFT JOIN #LeaseAssetUnearnedIncomeInfo LUI ON SLA.LeaseAssetId = LUI.LeaseAssetId;


			/*NLC Asset without SKU*/
			INSERT INTO #NLCCalculatedNBVInfo
			SELECT SLA.LeaseAssetId, ISNULL(FR.NLCRemainingRent, 0.0) + 
			(LA.BookedResidual_Amount * @ResidualRetainedFactor) - 
			(ISNULL(LUI.NonLeaseComponentUnearnedIncome, 0.0)) - (ISNULL(LUI.NonLeaseComponentUnearnedResidualIncome, 0.0))
			FROM #SelectedLeaseAssets SLA
			JOIN LeaseAssets LA ON SLA.LeaseAssetId = LA.Id AND LA.IsLeaseAsset = 0
			JOIN Assets A ON LA.AssetId = A.Id AND A.IsSKU = 0
			LEFT JOIN #RemainingRentalsInfo FR ON SLA.LeaseAssetId = FR.LeaseAssetId
			LEFT JOIN #LeaseAssetUnearnedIncomeInfo LUI ON SLA.LeaseAssetId = LUI.LeaseAssetId;
			
			 /*LC Asset with SKU*/
            INSERT INTO #LCCalculatedNBVInfo
			SELECT LAS.LeaseAssetId, ISNULL(FR.LCRemainingRent, 0.0) + 
			(LAS.BookedResidual * @ResidualRetainedFactor) - 
			(ISNULL(LUI.LeaseComponentUnearnedIncome, 0.0)) - (ISNULL(LUI.LeaseComponentUnearnedResidualIncome, 0.0))
			FROM #LeaseAssetSKUs LAS
			LEFT JOIN #RemainingRentalsInfo FR ON LAS.LeaseAssetId = FR.LeaseAssetId
			LEFT JOIN #LeaseAssetUnearnedIncomeInfo LUI ON LAS.LeaseAssetId = LUI.LeaseAssetId
			WHERE LAS.IsLeaseComponent = 1


		      /*NLC Asset with SKU*/           
		    INSERT INTO #NLCCalculatedNBVInfo
			SELECT LAS.LeaseAssetId, ISNULL(FR.NLCRemainingRent, 0.0) + 
			(LAS.BookedResidual * @ResidualRetainedFactor) - 
			(ISNULL(LUI.NonLeaseComponentUnearnedIncome, 0.0)) - (ISNULL(LUI.NonLeaseComponentUnearnedResidualIncome, 0.0))
			FROM #LeaseAssetSKUs LAS
			LEFT JOIN #RemainingRentalsInfo FR ON LAS.LeaseAssetId = FR.LeaseAssetId
			LEFT JOIN #LeaseAssetUnearnedIncomeInfo LUI ON LAS.LeaseAssetId = LUI.LeaseAssetId
			WHERE LAS.IsLeaseComponent = 0
		END
	END
END;
IF @IsOperatingLeasePayoff = 1
BEGIN

	INSERT INTO #RemainingRentalsInfo
	SELECT LR.LeaseAssetId, 
	LCRemainingRent = SUM(LR.LCAmount),
	LCSyndicatedRemainingRent = SUM(LR.LCSyndicatedAmount),
	NLCRemainingRent = SUM(LR.NLCAmount),
	NLCSyndicatedRemainingRent = SUM(LR.NLCSyndicatedAmount)
	FROM #LeaseAssetRentalsInfo LR 
	WHERE LR.RentalPeriodStartDate >= @EffectiveDate AND LR.RentalPeriodStartDate <= @MaturityDate AND LR.ReceivableType <> @FloatRateReceivableType
	GROUP BY LR.LeaseAssetId;


	IF @IsChargedOffLease = 0
	BEGIN
	INSERT INTO #LeaseAssetUnearnedIncomeInfo (LeaseAssetId,NonLeaseComponentUnearnedIncome,NonLeaseComponentUnearnedResidualIncome)
	SELECT ALIS.LeaseAssetId,SUM(ALIS.FinanceIncome_Amount - ALIS.FinanceResidualIncome_Amount) , SUM(ALIS.FinanceResidualIncome_Amount) 
		FROM #AssetLeaseIncomeScheduleInfo ALIS
		JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
		WHERE LF.ContractId = @ContractId AND ALIS.IsAssetIncomeActive = 1 AND ALIS.IsSchedule = 1 AND ALIS.IsLessorOwned = 1 AND ALIS.IncomeDate >= @EffectiveDate 
		GROUP BY ALIS.LeaseAssetId;
	END

	IF @IsChargedOffLease = 0 AND @IsPayoffAtInception = 0
	BEGIN
		INSERT INTO #DeferredRentalIncomeInfo 
		SELECT ALIS.LeaseAssetId, 
	    SUM(ALIS.LeaseDeferredRentalIncome_Amount) 'DeferredRentalIncome'
		, 0 as DeferredSellingProfitIncomeBalance_Amount 
		FROM #AssetLeaseIncomeScheduleInfo ALIS
		JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
		WHERE LF.ContractId = @ContractId AND ALIS.IsSchedule = 1 AND ALIS.IsLessorOwned = 1 AND ALIS.IsAssetIncomeActive = 1 AND ALIS.IncomeDate = @PayoffEffectiveDate 
		GROUP BY ALIS.LeaseAssetId;
	END

	INSERT INTO #SoldNBVDetails
	SELECT SLA.LeaseAssetId, SUM(0 - AVH.Value_Amount) 
	FROM #SelectedLeaseAssets SLA
	JOIN AssetValueHistories AVH ON SLA.AssetId = AVH.AssetId
	WHERE AVH.SourceModule ='Syndications'
	AND AVH.IsSchedule = 1
	AND AVH.IsLessorOwned = 1
	AND AVH.IncomeDate >= @CommencementDate
	GROUP BY SLA.LeaseAssetId

END;
IF @IsOperatingLease = 1 AND @PayoffEffectiveDate >= @CommencementDate AND @PayoffEffectiveDate <= @MaturityDate AND @IsChargedOffLease = 0
BEGIN
	IF @IsPayoffAtInception = 0
	BEGIN

		SELECT 
			LeaseAssetId = LA.Id, 
			FixedTermDepreciation = CASE WHEN RF.Id IS NOT NULL AND RF.ReceivableForTransferType = @SyndicationType_ParticipatedSale AND AVH.IncomeDate < RF.EffectiveDate THEN (0 - AVH.Value_Amount) * (RF.RetainedPercentage/100)
									ELSE (0 - AVH.Value_Amount)
									END
		INTO #FixedTermDepreciations
		FROM #SelectedLeaseAssets SLA
		JOIN LeaseAssets LA ON SLA.LeaseAssetId = LA.Id
		JOIN AssetValueHistories AVH ON LA.AssetId = AVH.AssetId 
		JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
		JOIN Contracts C ON LF.ContractId = C.Id
		LEFT JOIN ReceivableForTransfers RF ON C.Id = RF.ContractId AND RF.ApprovalStatus= @Syndication_ApprovalStatus
		WHERE LF.ContractId = @ContractId
		AND AVH.SourceModule = @AVHSourceModule_FixedTermDepreciation
		AND AVH.IsSchedule = 1 
		AND AVH.IsLessorOwned = 1
		AND AVH.IncomeDate >= @CommencementDate 
		AND AVH.IncomeDate <= @PayoffEffectiveDate;

		INSERT INTO #FixedTermDepreciationInfo
		SELECT 
			LeaseAssetId, 
			ROUND(SUM(FixedTermDepreciation),2) 
		FROM #FixedTermDepreciations
		GROUP BY LeaseAssetId;

		SELECT 	
		LeaseAssetId = LA.Id,
		NBVImpairment = CASE WHEN RF.Id IS NOT NULL AND RF.ReceivableForTransferType = @SyndicationType_ParticipatedSale AND AVH.IncomeDate < RF.EffectiveDate THEN (0 - AVH.Value_Amount) * (RF.RetainedPercentage/100)
						ELSE (0 - AVH.Value_Amount)
						END,
		AVH.IsLeaseComponent
		INTO #NBVImpairments
		FROM #SelectedLeaseAssets SLA
		JOIN LeaseAssets LA ON SLA.LeaseAssetId = LA.Id
		JOIN AssetValueHistories AVH ON LA.AssetId = AVH.AssetId 
		JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
		JOIN Contracts C ON LF.ContractId = C.Id
		LEFT JOIN ReceivableForTransfers RF ON C.Id = RF.ContractId AND RF.ApprovalStatus= @Syndication_ApprovalStatus
		WHERE LF.ContractId = @ContractId
		AND AVH.SourceModule = @AssetValueHistoryNBVImpairmentType 
		AND AVH.IsSchedule = 1 
		AND AVH.IsLessorOwned = 1
		AND AVH.IncomeDate >= @CommencementDate 
		AND AVH.IncomeDate <= @PayoffEffectiveDate;

		INSERT INTO #NBVImpairmentInfo
		SELECT 
			LeaseAssetId, 
			ROUND(SUM(NBVImpairment),2) ,
			IsLeaseComponent
		FROM #NBVImpairments
		GROUP BY LeaseAssetId,IsLeaseComponent;
		
	END

	IF @SyndicationType != 'FullSale'
	BEGIN
	/*Lease Component Asset without SKU*/
		INSERT INTO #LCCalculatedNBVInfo
		SELECT 
			SLA.LeaseAssetId, 
			ROUND(LA.NBV_Amount * (CASE WHEN RF.Id IS NOT NULL AND RF.ReceivableForTransferType = @SyndicationType_ParticipatedSale THEN RF.RetainedPercentage/100 ELSE 1 END), 2)
			- ISNULL(FD.FixedTermDepreciation, 0.0)  
			- ISNULL(NI.NBVImpairment, 0.0) 
			
		FROM #SelectedLeaseAssets SLA
		JOIN LeaseAssets LA ON SLA.LeaseAssetId = LA.Id 
		JOIN Assets A ON LA.AssetId = A.Id And A.IsSKU = 0
		JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
		JOIN Contracts C ON LF.ContractId = C.Id
		LEFT JOIN ReceivableForTransfers RF ON C.Id = RF.ContractId AND RF.ApprovalStatus= @Syndication_ApprovalStatus
		LEFT JOIN #FixedTermDepreciationInfo FD ON SLA.LeaseAssetId = FD.LeaseAssetId
		LEFT JOIN #NBVImpairmentInfo NI ON SLA.LeaseAssetId = NI.LeaseAssetId AND NI.IsLeaseComponent = 1 
		WHERE SLA.IsLeaseAsset = 1;



		
	/*Non Lease Component Asset without SKU*/
		INSERT INTO #NLCCalculatedNBVInfo
			SELECT SLA.LeaseAssetId, ISNULL(FR.NLCRemainingRent, 0.0) + (LA.BookedResidual_Amount * @ResidualRetainedFactor) -
			(ISNULL(LUI.NonLeaseComponentUnearnedIncome, 0.0)) - 
			(ISNULL(LUI.NonLeaseComponentUnearnedResidualIncome, 0.0))
			FROM #SelectedLeaseAssets SLA
			JOIN LeaseAssets LA ON SLA.LeaseAssetId = LA.Id
			JOIN Assets A ON LA.AssetId = A.Id And A.IsSKU = 0
			LEFT JOIN #RemainingRentalsInfo FR ON SLA.LeaseAssetId = FR.LeaseAssetId
			LEFT JOIN #LeaseAssetUnearnedIncomeInfo LUI ON SLA.LeaseAssetId = LUI.LeaseAssetId 
			WHERE SLA.IsLeaseAsset = 0;


  /*Lease Component Asset with SKU*/

			INSERT INTO #LCCalculatedNBVInfo
			SELECT 
				LAS.LeaseAssetId, 
				ROUND(LAS.NBV * (CASE WHEN RF.Id IS NOT NULL AND RF.ReceivableForTransferType = @SyndicationType_ParticipatedSale THEN RF.RetainedPercentage/100 ELSE 1 END), 2)
				- ISNULL(FD.FixedTermDepreciation, 0.0)  
				- ISNULL(NI.NBVImpairment, 0.0) 
			
			FROM #LeaseAssetSKUs LAS
			JOIN LeaseAssets LA ON LAS.LeaseAssetId = LA.Id AND LAS.IsLeaseComponent = 1
			JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
			JOIN Contracts C ON LF.ContractId = C.Id
			LEFT JOIN ReceivableForTransfers RF ON C.Id = RF.ContractId AND RF.ApprovalStatus= @Syndication_ApprovalStatus
			LEFT JOIN #FixedTermDepreciationInfo FD ON LAS.LeaseAssetId = FD.LeaseAssetId
			LEFT JOIN #NBVImpairmentInfo NI ON LAS.LeaseAssetId = NI.LeaseAssetId AND NI.IsLeaseComponent = 1;

	/*Non Lease Component Asset with SKU*/

			INSERT INTO #NLCCalculatedNBVInfo
			SELECT LAS.LeaseAssetId, ISNULL(FR.NLCRemainingRent, 0.0) + (LAS.BookedResidual * @ResidualRetainedFactor) -
			(ISNULL(LUI.NonLeaseComponentUnearnedIncome, 0.0)) - 
			(ISNULL(LUI.NonLeaseComponentUnearnedResidualIncome, 0.0))
			FROM #LeaseAssetSKUs LAS
			LEFT JOIN #RemainingRentalsInfo FR ON LAS.LeaseAssetId = FR.LeaseAssetId
			LEFT JOIN #LeaseAssetUnearnedIncomeInfo LUI ON LAS.LeaseAssetId = LUI.LeaseAssetId
			WHERE LAS.IsLeaseComponent = 0

	END

END;
IF @IsInstallLeasePayoff = 1
BEGIN
INSERT INTO #OwnedNBVOnMaturityDetails
SELECT LA.Id, LA.BookedResidual_Amount - LA.CustomerGuaranteedResidual_Amount - LA.ThirdPartyGuaranteedResidual_Amount
FROM LeaseAssets LA
JOIN #SelectedLeaseAssets SLA ON LA.Id = SLA.LeaseAssetId;
END
ELSE
BEGIN
INSERT INTO #OwnedNBVOnMaturityDetails
SELECT ALIS.LeaseAssetId, SUM(ALIS.EndNetBookValue_Amount)
FROM #AssetLeaseIncomeScheduleInfo ALIS
JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId
AND ALIS.IsLessorOwned=1
AND ALIS.IsSchedule=1
AND ALIS.IncomeDate = @MaturityDate
GROUP BY ALIS.LeaseAssetId;
IF @IsSyndicatedServiced = 1
BEGIN
INSERT INTO #SyndicatedNBVOnMaturityDetails
SELECT ALIS.LeaseAssetId, SUM(ALIS.EndNetBookValue_Amount)
FROM #AssetLeaseIncomeScheduleInfo ALIS
JOIN LeaseFinances LF ON ALIS.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId
AND ALIS.IsLessorOwned=0
AND ALIS.IsSchedule=1
AND ALIS.IncomeDate=@MaturityDate
GROUP BY ALIS.LeaseAssetId;
END
END;
WITH CTE_FloatRateRemainingRentals AS
(
SELECT
LR.LeaseAssetId,
RemainingFloatRateRent = SUM(LR.LCAmount + LR.NLCAmount),
SyndicatedRemainingFloatRateRent = SUM(LR.LCSyndicatedAmount +LR.NLCSyndicatedAmount)
FROM #LeaseAssetRentalsInfo LR
WHERE LR.RentalPeriodStartDate >= @PayoffEffectiveDate AND LR.RentalPeriodStartDate <= @MaturityDate AND LR.ReceivableType = @FloatRateReceivableType
GROUP BY LR.LeaseAssetId
)

SELECT 
	LeaseAssetId = SLA.LeaseAssetId,
	LCRemainingRentals = ISNULL(RI.LCRemainingRent, 0.0),
	NLCRemainingRentals = ISNULL(RI.NLCRemainingRent, 0.0),
	LCSyndicatedRemainingRentals = ISNULL(RI.LCSyndicatedRemainingRent, 0.0),
	NLCSyndicatedRemainingRentals = ISNULL(RI.NLCSyndicatedRemainingRent, 0.0),
	FloatRateRemainingRentals = ISNULL(FRI.RemainingFloatRateRent, 0.0),
	SyndicatedFloatRateRemainingRentals = ISNULL(FRI.SyndicatedRemainingFloatRateRent, 0.0),
	LCOwnedNBV = ISNULL(LCNI.NBV, 0.0),
	NLCOwnedNBV = ISNULL(NLCNI.NBV, 0.0),
	OutstandingRentalBilled = ISNULL(ORB.OutstandingRentalBilled, 0.0),
	OutstandingRentalsUnbilled = ISNULL(ORU.OutstandingRentalUnbilled, 0.0),
	LeaseComponentUnearnedIncome = ISNULL(UI.LeaseComponentUnearnedIncome, 0.0),
	NonLeaseComponentUnearnedIncome = ISNULL(UI.NonLeaseComponentUnearnedIncome, 0.0),
	LeaseComponentUnearnedResidualIncome = ISNULL(UI.LeaseComponentUnearnedResidualIncome, 0.0),
	NonLeaseComponentUnearnedResidualIncome = ISNULL(UI.NonLeaseComponentUnearnedResidualIncome, 0.0),
	LCAccumulatedNBVImpairment = ISNULL(LCNBI.NBVImpairment, 0.0),
	NLCAccumulatedNBVImpairment = ISNULL(NLCNBI.NBVImpairment, 0.0),
	FixedTermDepreciation = ISNULL(FD.FixedTermDepreciation, 0.0),
	DeferredRentalIncome = ISNULL(DR.DeferredRentalIncome,0.0),
	DeferredSellingProfitIncomeBalance = ISNULL(DR.DeferredSellingProfitIncomeBalance,0.0),
	LCCalculatedNBV = ISNULL(LCN.CalculatedNBV,0.0),
	NLCCalculatedNBV = ISNULL(NLCN.CalculatedNBV,0.0),
	LCOTPAccumulatedNBVImpairment = ISNULL(LCONBI.NBVImpairment,0.0),
	NLCOTPAccumulatedNBVImpairment = ISNULL(NLCONBI.NBVImpairment,0.0),
	OTPDepreciation = ISNULL(ODP.OTPDepreciation,0.0),
	OTPDeferredRentalIncome = ISNULL(ODR.DeferredRentalIncome,0.0),
	OwnedNBVOnMaturity = ISNULL(OLR.NBVOnMaturity,0.0),
	SyndicatedNBVOnMaturity = ISNULL(SLR.NBVOnMaturity, 0.0)
	FROM #SelectedLeaseAssets SLA
	LEFT JOIN #LeaseComponentNBVInfo LCNI ON SLA.LeaseAssetId = LCNI.LeaseAssetId
	LEFT JOIN #NonLeaseComponentNBVInfo NLCNI ON SLA.LeaseAssetId = NLCNI.LeaseAssetId
	LEFT JOIN #OutstandingRentalsBilledInfo ORB ON SLA.LeaseAssetId = ORB.LeaseAssetId
	LEFT JOIN #OutstandingRentalsUnbilledInfo ORU ON SLA.LeaseAssetId = ORU.LeaseAssetId
	LEFT JOIN #RemainingRentalsInfo RI ON SLA.LeaseAssetId = RI.LeaseAssetId
	LEFT JOIN CTE_FloatRateRemainingRentals FRI ON SLA.LeaseAssetId = FRI.LeaseAssetId
	LEFT JOIN #LeaseAssetUnearnedIncomeInfo UI ON SLA.LeaseAssetId = UI.LeaseAssetId
	LEFT JOIN #NBVImpairmentInfo LCNBI ON SLA.LeaseAssetId = LCNBI.LeaseAssetId AND LCNBI.IsLeaseComponent = 1
	LEFT JOIN #NBVImpairmentInfo NLCNBI ON SLA.LeaseAssetId = NLCNBI.LeaseAssetId AND NLCNBI.IsLeaseComponent = 0
	LEFT JOIN #FixedTermDepreciationInfo FD ON SLA.LeaseAssetId = FD.LeaseAssetId
	LEFT JOIN #DeferredRentalIncomeInfo DR ON SLA.LeaseAssetId = DR.LeaseAssetId
	LEFT JOIN #LCCalculatedNBVInfo LCN ON SLA.LeaseAssetId = LCN.LeaseAssetId
	LEFT JOIN #NLCCalculatedNBVInfo NLCN ON SLA.LeaseAssetId = NLCN.LeaseAssetId
	LEFT JOIN #OTPNBVImpairmentInfo LCONBI ON SLA.LeaseAssetId = LCONBI.LeaseAssetId AND LCONBI.IsLeaseComponent = 1
	LEFT JOIN #OTPNBVImpairmentInfo NLCONBI ON SLA.LeaseAssetId = NLCONBI.LeaseAssetId AND NLCONBI.IsLeaseComponent = 0
	LEFT JOIN #OTPDeprecicationInfo ODP ON SLA.LeaseAssetId = ODP.LeaseAssetId
	LEFT JOIN #OTPDeferredRentalIncomeInfo ODR ON SLA.LeaseAssetId = ODR.LeaseAssetId 
	LEFT JOIN #OwnedNBVOnMaturityDetails OLR ON SLA.LeaseAssetId = OLR.LeaseAssetId
	LEFT JOIN #SyndicatedNBVOnMaturityDetails SLR ON SLA.LeaseAssetId = SLR.LeaseAssetId  
		
DROP TABLE
#LeaseAssetSKUs,
#AssetIncomeScheduleInfo,
#AssetLeaseIncomeScheduleInfo,
#LeaseIncomeScheduleIds,
#SelectedLeaseAssets,
#LatestAssetValueInformation,
#RemainingRentalsInfo,
#LeaseComponentNBVInfo,
#NonLeaseComponentNBVInfo,
#LCCalculatedNBVInfo,
#NLCCalculatedNBVInfo,
#DeferredRentalIncomeInfo,
#FixedTermDepreciationInfo,
#LeaseAssetRentalsInfo,
#LeaseAssetUnearnedIncomeInfo,
#NBVImpairmentInfo,
#OTPDeferredRentalIncomeInfo,
#OTPDeprecicationInfo,
#OTPNBVImpairmentInfo,
#OutstandingRentalsBilledInfo,
#OutstandingRentalsUnbilledInfo,
#OwnedNBVOnMaturityDetails,
#SyndicatedNBVOnMaturityDetails,
#MaturityDatePaymentDetails
END

GO
