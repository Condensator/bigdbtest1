SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CalculateNBVWithBlendedForReceiptWriteDown]
(
@ContractInfo ContractIdAsOfDateCollection Readonly,
@JobStepInstanceId BIGINT,
@UnknownValue NVARCHAR(20),
@LeaseContractTypeValues_Operating NVARCHAR(50),
@HoldingStatusValues_HFS NVARCHAR(50),
@SyndicationTypeValues_ParticipatedSale NVARCHAR(40), 
@AssetValueSourceModuleValues_Syndications NVARCHAR(20),
@AssetValueSourceModuleValues_FixedTermDepreciation NVARCHAR(40),
@AssetValueSourceModuleValues_OTPDepreciation NVARCHAR(40),
@AssetValueSourceModuleValues_ResidualRecapture NVARCHAR(40),
@BlendedItemBookRecognitionModeValues_RecognizeImmediately NVARCHAR(40),
@BlendedItemBookRecognitionModeValues_Capitalize NVARCHAR(40),
@BlendedItemOccurrenceValues_Recurring NVARCHAR(40),
@BlendedItemBookRecognitionModeValues_Accrete NVARCHAR(40),
@BlendedItemTypeValues_Income NVARCHAR(20),
@ReceivableTypeValues_CapitalLeaseRental NVARCHAR(40),
@ReceivableTypeValues_LeaseFloatRateAdj NVARCHAR(40),
@ReceivableTypeValues_OperatingLeaseRental NVARCHAR(40),
@LeasePaymentTypeValues_FixedTerm NVARCHAR(40),
@LeasePaymentTypeValues_DownPayment NVARCHAR(40),
@LeasePaymentTypeValues_MaturityPayment NVARCHAR(40),
@LeasePaymentTypeValues_CustomerGuaranteedResidual NVARCHAR(40),
@LeasePaymentTypeValues_ThirdPartyGuaranteedResidual NVARCHAR(40),
@ReceivableEntityTypeValues_CT NVARCHAR(5),
@ReceiptStatusValues_Posted NVARCHAR(20),
@ReceiptClassificationValues_NonCash NVARCHAR(40),
@ReceiptClassificationValues_NonAccrualNonDSLNonCash NVARCHAR(40),
@ReceivableTypeValues_LoanInterest NVARCHAR(40),
@ReceivableTypeValues_LoanPrincipal NVARCHAR(40),
@AssetComponentTypeValues_Lease NVARCHAR(40),
@AssetComponentTypeValues_Finance NVARCHAR(40),
@SystemConfigBlendedItemTypeValues_ReclassifiedFinanceComponent NVARCHAR(40),
@SystemConfigBlendedItemTypeValues_ReclassifiedLeaseComponent NVARCHAR(40)
)
AS
BEGIN
CREATE TABLE #ContractDetails
(
ContractId BIGINT NOT NULL,
LeaseFinanceId BIGINT,
LoanFinanceId BIGINT,
CommencementDate DATE,
MaturityDate DATE,
AsOfDate DATE,
CurrentNonAccrualDate DATE,
HoldingStatus NVARCHAR(40),
LeaseContractType NVARCHAR(40),
IsLease BIT NOT NULL,
IsDSL BIT NOT NULL,
NBV DECIMAL(16,2) NOT NULL,
ReceivableBalance DECIMAL(16,2) NOT NULL,
CashPostedAmount DECIMAL(16,2) NOT NULL
)
CREATE TABLE #AssetInfo
(
	ContractId BIGINT NOT NULL,
	IsLeaseComponent BIT NOT NULL,
	AssetId BIGINT,
	AssetSKUId BIGINT,
	NBV DECIMAL(16,2),
	SKUAssetNBV DECIMAL(16,2),
	LeaseFinanceId BIGINT
)
CREATE TABLE #BlendedDetails
(
	ContractId BIGINT,
	LeaseContractType NVARCHAR(40),
	AssetId BIGINT,
	AssetComponentType NVARCHAR(40),
	Amount DECIMAL(16,2)
)
--Fetch Lease Info
INSERT INTO #ContractDetails
SELECT 
	LF.ContractId,
	LF.Id AS LeaseFinanceId,
	NULL AS LoanFinanceId,
	LFD.CommencementDate,
	LFD.MaturityDate,
	C.AsOfDate,
	NULL AS CurrentNonAccrualDate,
	LF.HoldingStatus,
	LFD.LeaseContractType,
	CAST(1 AS BIT) AS IsLease,
	CAST(0 AS BIT) AS IsDSL,
	0.00 AS NBV,
	0.00 AS ReceivableBalance,
	0.00 AS CashPostedAmount
FROM LeaseFinances LF
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND LF.IsCurrent = 1
INNER JOIN @ContractInfo C ON LF.ContractId = C.ContractId

--Fetch Loan Info
INSERT INTO #ContractDetails
SELECT 
	LF.ContractId,
	NULL AS LeaseFinanceId,
	LF.Id AS LoanFinanceId,
	LF.CommencementDate,
	LF.MaturityDate,
	C.AsOfDate,
	NULL AS CurrentNonAccrualDate,
	LF.HoldingStatus,
	@UnknownValue AS LeaseContractType,
	CAST(0 AS BIT) AS IsLease,
	LF.IsDailySensitive AS IsDSL,
	0.00 AS NBV,
	0.00 AS ReceivableBalance,
	0.00 AS CashPostedAmount
FROM @ContractInfo C
INNER JOIN LoanFinances LF ON C.ContractId = LF.ContractId AND LF.IsCurrent = 1

SELECT 
	LASKU.IsLeaseComponent,
	LASKU.AssetSKUId,
	LASKU.NBV_Amount AS SKUAssetNBV,
	LASKU.LeaseAssetId
INTO #SKUAssetInfo
FROM #ContractDetails CD
INNER JOIN LeaseAssets LA ON CD.LeaseFinanceId = LA.LeaseFinanceId
INNER JOIN LeaseAssetSKUs LASKU ON LA.Id = LASKU.LeaseAssetId AND LASKU.IsActive = 1
WHERE (LA.IsActive = 1 OR LA.TerminationDate IS NOT NULL);

INSERT INTO #AssetInfo
SELECT DISTINCT
	CD.ContractId,
	CASE WHEN LASKU.LeaseAssetId IS NULL THEN LA.IsLeaseAsset ELSE LASKU.IsLeaseComponent END AS IsLeaseComponent,
	LA.AssetId,
	LASKU.AssetSKUId,
	LA.NBV_Amount AS Amount,
	LASKU.SKUAssetNBV,
	CD.LeaseFinanceId
FROM #ContractDetails CD
INNER JOIN LeaseAssets LA ON CD.LeaseFinanceId = LA.LeaseFinanceId
LEFT JOIN #SKUAssetInfo LASKU ON LA.Id = LASKU.LeaseAssetId 
;

--GetNBVFromAssetIncomeSchedules
--LeaseIncomeIdPostNonAccrual
WITH CTE_LeaseIncomeIdPostNonAccrual AS
(
SELECT  
	CD.ContractId,
	LIS.Id AS LISId,
	ROW_NUMBER() OVER (PARTITION BY ContractId ORDER BY IncomeDate) AS RowNumber
FROM #ContractDetails CD
INNER JOIN LeaseIncomeSchedules LIS ON CD.LeaseFinanceId = LIS.LeaseFinanceId AND CD.IsLease = 1
WHERE LIS.IsSchedule = 1 AND LIS.IsLessorOwned = 1 AND LIS.IncomeDate >= CD.AsOfDate
)
UPDATE #ContractDetails
SET NBV += CD.NBV
FROM #ContractDetails C
JOIN 
	(SELECT 
		CD.ContractId,
		((CASE WHEN CD.LeaseContractType = @LeaseContractTypeValues_Operating THEN 
				LIS.FinanceBeginNetBookValue_Amount
		  ELSE 
				LIS.BeginNetBookValue_Amount 
		  END) 
		  - 
		 LIS.DeferredSellingProfitIncome_Amount
		 ) AS NBV
	FROM #ContractDetails CD
	INNER JOIN CTE_LeaseIncomeIdPostNonAccrual LI ON CD.ContractId = LI.ContractId AND RowNumber = 1
	INNER JOIN LeaseIncomeSchedules LIS ON LI.LISId = LIS.Id
		AND LIS.IsSchedule = 1 AND LIS.IsLessorOwned = 1 AND LIS.IncomeDate >= CD.AsOfDate
) CD ON C.ContractId = CD.ContractId
;

--GET NBV For Loan
UPDATE #ContractDetails
	SET NBV += LoanNBV
FROM #ContractDetails CD
JOIN (
	SELECT CD.ContractId,
		(LIS.BeginNetBookValue_Amount + LIS.PrincipalAdded_Amount) AS LoanNBV,
		ROW_NUMBER() OVER (PARTITION BY CD.ContractId ORDER BY LIS.IncomeDate) AS RowNumber
	FROM #ContractDetails CD
	INNER JOIN LoanIncomeSchedules LIS ON CD.LoanFinanceId = LIS.LoanFinanceId AND CD.IsLease = 0
	WHERE LIS.IsSchedule = 1 AND LIS.IsLessorOwned = 1 AND LIS.IncomeDate >= CD.AsOfDate
	GROUP BY CD.ContractId, BeginNetBookValue_Amount, PrincipalAdded_Amount, LIS.IncomeDate
) LoanNBV ON CD.ContractId = LoanNBV.ContractId
WHERE RowNumber = 1

--GetBlendedItemBalances
--AsOfDate <= CommencementDate AND IsLease = 1
INSERT INTO #BlendedDetails
SELECT ContractId,
	LeaseContractType,
	AssetId,
	AssetComponentType,
	SUM(ExpenseBlendedItemAmount) - SUM(IncomeBlendedItemAmount) AS Amount
FROM
(
	SELECT 
		CD.ContractId,
		CD.LeaseContractType,
		LA.AssetId,
		CASE WHEN BI.SystemConfigType = @SystemConfigBlendedItemTypeValues_ReclassifiedFinanceComponent THEN 
			@AssetComponentTypeValues_Finance 
		ELSE	
			@UnknownValue 
		END AS AssetComponentType,
		CASE WHEN BI.Type = @BlendedItemTypeValues_Income THEN ISNULL(SUM(BI.Amount_Amount),0) ELSE 0 END AS IncomeBlendedItemAmount,
		CASE WHEN BI.Type <> @BlendedItemTypeValues_Income THEN ISNULL(SUM(BI.Amount_Amount),0) ELSE 0 END AS ExpenseBlendedItemAmount
	FROM #ContractDetails CD
	INNER JOIN LeaseBlendedItems LBI ON CD.LeaseFinanceId = LBI.LeaseFinanceId AND CD.AsOfDate <= CD.CommencementDate AND CD.IsLease = 1
	INNER JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1
	LEFT JOIN LeaseAssets LA ON BI.LeaseAssetId = LA.Id AND LA.IsActive = 1
	LEFT JOIN BlendedItems ChildBlendedItem ON BI.Id = ChildBlendedItem.RelatedBlendedItemId AND ChildBlendedItem.IsActive=1
	WHERE BI.BookRecognitionMode NOT IN (@BlendedItemBookRecognitionModeValues_RecognizeImmediately, @BlendedItemBookRecognitionModeValues_Capitalize)
	AND BI.SystemConfigType <> @SystemConfigBlendedItemTypeValues_ReclassifiedLeaseComponent
	AND ChildBlendedItem.Id IS NULL
	GROUP BY CD.ContractId, CD.LeaseContractType, LA.AssetId, LA.IsLeaseAsset, BI.Type, BI.SystemConfigType
) AS LeaseBlendedItemDetails
GROUP BY ContractId, AssetComponentType, LeaseContractType, AssetId

--AsOfDate <= CommencementDate AND IsLease = 0
INSERT INTO #BlendedDetails
SELECT 
	ContractId,
	'_' AS LeaseContractType, 
	CAST(NULL AS BIGINT) AS AssetId,
	AssetComponentType,
	SUM(ExpenseBlendedItemAmount) - SUM(IncomeBlendedItemAmount) AS Amount
FROM (
	SELECT 
		CD.ContractId,
		@UnknownValue AS AssetComponentType,
		CASE WHEN BI.Type = @BlendedItemTypeValues_Income THEN ISNULL(SUM(BI.Amount_Amount),0) ELSE 0 END AS IncomeBlendedItemAmount,
		CASE WHEN BI.Type <> @BlendedItemTypeValues_Income THEN ISNULL(SUM(BI.Amount_Amount),0) ELSE 0 END AS ExpenseBlendedItemAmount
	FROM #ContractDetails CD
	INNER JOIN LoanBlendedItems LBI ON CD.LoanFinanceId = LBI.LoanFinanceId AND CD.AsOfDate <= CD.CommencementDate AND CD.IsLease = 0
	INNER JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1
	LEFT JOIN BlendedItems ChildBlendedItem ON BI.Id = ChildBlendedItem.RelatedBlendedItemId AND ChildBlendedItem.IsActive=1
	WHERE BI.BookRecognitionMode NOT IN (@BlendedItemBookRecognitionModeValues_RecognizeImmediately, @BlendedItemBookRecognitionModeValues_Capitalize)
	AND ChildBlendedItem.Id IS NULL
	GROUP BY CD.ContractId, BI.Type
) AS LoanBlendedItemDetails
GROUP BY ContractId, AssetComponentType;

--AsOfDate > CommencementDate AND IsLease = 1
WITH CTE_LeaseBlendedIncomeDetails AS
(
	SELECT 
		CD.ContractId, BIS.BlendedItemId, CD.AsOfDate, SUM(BIS.Income_Amount) AS Income, CD.LeaseContractType
	FROM #ContractDetails CD
	INNER JOIN LeaseFinances LF ON LF.ContractId = CD.ContractId
	INNER JOIN BlendedIncomeSchedules BIS ON LF.Id = BIS.LeaseFinanceId AND BIS.IsSchedule = 1 AND IsLease = 1
	WHERE BIS.IncomeDate <= DATEADD(DAY,-1,CD.AsofDate) AND CD.AsOfDate > CD.CommencementDate
	GROUP BY CD.ContractId, BIS.BlendedItemId, CD.AsOfDate, CD.LeaseContractType
)
INSERT INTO #BlendedDetails
SELECT 
	ContractId,
	LeaseContractType,
	AssetId,
	AssetComponentType,
	CASE WHEN BookRecognitionMode = @BlendedItemBookRecognitionModeValues_Accrete THEN 
		SUM(ExpenseIncomeAmount - ExpenseBlendedItemAmount) - SUM(IncomeIncomeAmount-IncomeBlendedItemAmount)
	ELSE 
		SUM(ExpenseBlendedItemAmount - ExpenseIncomeAmount) - SUM(IncomeBlendedItemAmount - IncomeIncomeAmount)
	END AS Amount
FROM 
	(SELECT 
		BID.ContractId,
		BID.LeaseContractType,
		LA.AssetId AS AssetId,
		CASE WHEN BI.SystemConfigType = @SystemConfigBlendedItemTypeValues_ReclassifiedFinanceComponent THEN 
			@AssetComponentTypeValues_Finance 
		ELSE 
			@UnknownValue 
		END AS AssetComponentType,
		BI.BookRecognitionMode,
		CASE WHEN BI.Type = @BlendedItemTypeValues_Income THEN 
			ISNULL(SUM(CASE WHEN (BI.Occurrence = @BlendedItemOccurrenceValues_Recurring OR BI.BookRecognitionMode =	@BlendedItemBookRecognitionModeValues_Accrete) THEN 
					BlendedItemDetails.Amount_Amount
				ELSE BI.Amount_Amount END),0) 
		ELSE 
			0 
		END AS IncomeBlendedItemAmount,
		CASE WHEN BI.Type <> @BlendedItemTypeValues_Income THEN 
			ISNULL(SUM(CASE WHEN (BI.Occurrence = @BlendedItemOccurrenceValues_Recurring OR BI.BookRecognitionMode = @BlendedItemBookRecognitionModeValues_Accrete) THEN 
					BlendedItemDetails.Amount_Amount
				ELSE BI.Amount_Amount END),0) 
		ELSE 
			0 
		END AS ExpenseBlendedItemAmount,
		CASE WHEN BI.Type = @BlendedItemTypeValues_Income THEN ISNULL(SUM(BID.Income),0) ELSE 0 END AS IncomeIncomeAmount,
		CASE WHEN BI.Type <> @BlendedItemTypeValues_Income THEN ISNULL(SUM(BID.Income),0) ELSE 0 END AS ExpenseIncomeAmount
	FROM CTE_LeaseBlendedIncomeDetails BID
	INNER JOIN BlendedItems BI ON BID.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1
	LEFT JOIN BlendedItemDetails ON BI.Id = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
	AND BlendedItemDetails.DueDate <= DATEADD(DAY,-1,AsofDate)
	LEFT JOIN LeaseAssets LA ON BI.LeaseAssetId = LA.Id
	LEFT JOIN BlendedItems ChildBlendedItem ON BI.Id = ChildBlendedItem.RelatedBlendedItemId AND ChildBlendedItem.IsActive=1
	WHERE BI.BookRecognitionMode NOT IN (@BlendedItemBookRecognitionModeValues_RecognizeImmediately, @BlendedItemBookRecognitionModeValues_Capitalize)
	AND BI.SystemConfigType <> @SystemConfigBlendedItemTypeValues_ReclassifiedLeaseComponent
	AND ChildBlendedItem.Id IS NULL
	GROUP BY BID.ContractId, BID.LeaseContractType, LA.AssetId, LA.Id, LA.IsLeaseAsset, BI.Type, BI.SystemConfigType, BI.BookRecognitionMode
) AS LeaseBlendedDetails
GROUP BY ContractId, AssetComponentType, BookRecognitionMode, LeaseContractType, AssetId;

--AsOfDate > CommencementDate AND IsLease = 0
WITH CTE_LoanBlendedIncomeDetails AS
(
	SELECT 
		CD.ContractId, BIS.BlendedItemId, CD.AsOfDate, SUM(BIS.Income_Amount) AS Income
	FROM #ContractDetails CD
	INNER JOIN LoanFinances LF ON LF.ContractId = CD.ContractId
	INNER JOIN BlendedIncomeSchedules BIS ON LF.Id = BIS.LoanFinanceId AND BIS.IsSchedule = 1 AND IsLease = 0
	WHERE BIS.IncomeDate <= DATEADD(DAY,-1,CD.AsofDate) AND CD.AsOfDate > CD.CommencementDate
	GROUP BY CD.ContractId, BIS.BlendedItemId, CD.AsOfDate
)
INSERT INTO #BlendedDetails
SELECT 
	ContractId,
	'_',
	CAST(NULL AS BIGINT) AssetId,
	AssetComponentType,
	CASE WHEN BookRecognitionMode = @BlendedItemBookRecognitionModeValues_Accrete
	THEN SUM(ExpenseIncomeAmount - ExpenseBlendedItemAmount) - SUM(IncomeIncomeAmount-IncomeBlendedItemAmount)
	ELSE SUM(ExpenseBlendedItemAmount - ExpenseIncomeAmount) - SUM(IncomeBlendedItemAmount - IncomeIncomeAmount)
	END AS Amount
FROM (
	SELECT 
		BID.ContractId,
		@UnknownValue AS AssetComponentType,
		BookRecognitionMode,
		CASE WHEN BI.Type = @BlendedItemTypeValues_Income THEN ISNULL(SUM(CASE WHEN (BI.Occurrence = @BlendedItemOccurrenceValues_Recurring OR BI.BookRecognitionMode = @BlendedItemBookRecognitionModeValues_Accrete)
		THEN BlendedItemDetails.Amount_Amount
		ELSE BI.Amount_Amount END),0)
		ELSE 0
		END AS IncomeBlendedItemAmount,
		CASE WHEN BI.Type <> @BlendedItemTypeValues_Income
		THEN ISNULL(SUM(CASE WHEN (BI.Occurrence = @BlendedItemOccurrenceValues_Recurring OR BI.BookRecognitionMode = @BlendedItemBookRecognitionModeValues_Accrete)
		THEN BlendedItemDetails.Amount_Amount
		ELSE BI.Amount_Amount
		END),0) ELSE 0
		END AS ExpenseBlendedItemAmount,
		CASE WHEN BI.Type = @BlendedItemTypeValues_Income THEN ISNULL(SUM(BID.Income),0) ELSE 0 END AS IncomeIncomeAmount,
		CASE WHEN BI.Type <> @BlendedItemTypeValues_Income THEN ISNULL(SUM(BID.Income),0) ELSE 0 END AS ExpenseIncomeAmount
	FROM CTE_LoanBlendedIncomeDetails BID
	INNER JOIN BlendedItems BI ON BID.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1
	INNER JOIN BlendedItemDetails ON BI.Id = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
	AND BlendedItemDetails.DueDate <= DATEADD(DAY,-1,AsofDate)
	WHERE BI.BookRecognitionMode NOT IN (@BlendedItemBookRecognitionModeValues_RecognizeImmediately, @BlendedItemBookRecognitionModeValues_Capitalize)
	GROUP BY BID.ContractId, BI.Type, BookRecognitionMode
) AS LoanBlendedDetails
GROUP BY ContractId, AssetComponentType, BookRecognitionMode;

--Valid ReceivableTypes
SELECT Id, Name
INTO #ValidReceivableTypes
FROM ReceivableTypes
WHERE Name IN (@ReceivableTypeValues_CapitalLeaseRental, @ReceivableTypeValues_LeaseFloatRateAdj, @ReceivableTypeValues_OperatingLeaseRental, @ReceivableTypeValues_LoanInterest, @ReceivableTypeValues_LoanPrincipal)
SELECT ReceiptApplicationId INTO #ApplicationIdsToExclude FROM Receipts_Extract WHERE JobStepInstanceId = @JobStepInstanceId
;

--Cash Posted Amount
;WITH CTE_CashPostedAmount AS
(
	SELECT
		CD.ContractId,
		CASE WHEN CD.LeaseContractType = @LeaseContractTypeValues_Operating AND 
			(RT.Name = @ReceivableTypeValues_OperatingLeaseRental OR RT.Name = @ReceivableTypeValues_LeaseFloatRateAdj) THEN 
			ISNULL(SUM(RARD.NonLeaseComponentAmountApplied_Amount),0)
		ELSE
			ISNULL(SUM(RARD.AmountApplied_Amount),0)
		END AS CashPostedAmount
	FROM #ContractDetails CD
	INNER JOIN Receivables Rec ON CD.ContractId = Rec.EntityId 
		AND Rec.EntityType = @ReceivableEntityTypeValues_CT AND Rec.IsActive=1 AND Rec.IsDummy = 0 AND Rec.FunderId IS NULL
	INNER JOIN ReceivableCodes RC ON Rec.ReceivableCodeId = RC.Id
	INNER JOIN #ValidReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN ReceivableDetails RD ON Rec.Id = RD.ReceivableId AND RD.IsActive=1 
	INNER JOIN ReceiptApplicationReceivableDetails RARD ON RD.Id = RARD.ReceivableDetailId AND RARD.IsActive=1
	INNER JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
	INNER JOIN Receipts R ON RA.ReceiptId = R.Id
	LEFT JOIN #ApplicationIdsToExclude RecAppToExclude ON RA.Id = RecAppToExclude.ReceiptApplicationId
	LEFT JOIN LeasePaymentSchedules ON Rec.PaymentScheduleId = LeasePaymentSchedules.Id 
		AND LeasePaymentSchedules.IsActive = 1 AND CD.IsLease = 1 
		AND LeasePaymentSchedules.PaymentType IN (@LeasePaymentTypeValues_FixedTerm, @LeasePaymentTypeValues_DownPayment, @LeasePaymentTypeValues_MaturityPayment, @LeasePaymentTypeValues_CustomerGuaranteedResidual, @LeasePaymentTypeValues_ThirdPartyGuaranteedResidual) AND LeasePaymentSchedules.EndDate >= CD.AsofDate
	LEFT JOIN LoanPaymentSchedules ON Rec.PaymentScheduleId = LoanPaymentSchedules.Id 
		AND LoanPaymentSchedules.IsActive = 1 AND LoanPaymentSchedules.PaymentType IN (@LeasePaymentTypeValues_FixedTerm, @LeasePaymentTypeValues_DownPayment) AND CD.IsLease = 0 AND LoanPaymentSchedules.EndDate >= CD.AsofDate
	WHERE R.ReceiptClassification NOT IN (@ReceiptClassificationValues_NonCash, @ReceiptClassificationValues_NonAccrualNonDSLNonCash)
	AND R.Status = @ReceiptStatusValues_Posted
	AND RecAppToExclude.ReceiptApplicationId IS NULL
	AND (LoanPaymentSchedules.Id IS NOT NULL OR LeasePaymentSchedules.Id IS NOT NULL)
	GROUP BY CD.ContractId, RT.Name, CD.LeaseContractType
)
UPDATE #ContractDetails
SET CashPostedAmount = ReceiptCashPostedInfo.CashPostedAmount
FROM #ContractDetails C
JOIN (
	SELECT ContractId, SUM(CashPostedAmount) AS CashPostedAmount FROM CTE_CashPostedAmount GROUP BY ContractId
) AS ReceiptCashPostedInfo ON C.ContractId = ReceiptCashPostedInfo.ContractId


--Receivable Balances
;WITH CTE_ReceivableBalance AS (
	SELECT 
		C.ContractId,
		CASE WHEN C.LeaseContractType = @LeaseContractTypeValues_Operating AND 
			(RT.Name = @ReceivableTypeValues_OperatingLeaseRental OR RT.Name = @ReceivableTypeValues_LeaseFloatRateAdj) THEN 
			ISNULL(SUM(RD.NonLeaseComponentBalance_Amount),0)
		ELSE
			ISNULL(SUM(RD.Balance_Amount),0)
		END AS ReceivableBalance
	FROM #ContractDetails C
	INNER JOIN Receivables R ON C.ContractId = R.EntityId AND R.EntityType = @ReceivableEntityTypeValues_CT 
		AND R.IsActive = 1 AND R.IsDummy = 0 AND R.FunderId IS NULL
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN #ValidReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId AND RD.IsActive = 1 
	LEFT JOIN LeasePaymentSchedules ON R.PaymentScheduleId = LeasePaymentSchedules.Id AND LeasePaymentSchedules.IsActive = 1 
		AND C.IsLease = 1 AND LeasePaymentSchedules.PaymentType IN (@LeasePaymentTypeValues_FixedTerm, @LeasePaymentTypeValues_DownPayment, @LeasePaymentTypeValues_MaturityPayment, @LeasePaymentTypeValues_CustomerGuaranteedResidual, @LeasePaymentTypeValues_ThirdPartyGuaranteedResidual) AND LeasePaymentSchedules.EndDate < C.AsofDate
	LEFT JOIN LoanPaymentSchedules ON R.PaymentScheduleId = LoanPaymentSchedules.Id AND LoanPaymentSchedules.IsActive = 1 
		AND LoanPaymentSchedules.PaymentType IN (@LeasePaymentTypeValues_FixedTerm, @LeasePaymentTypeValues_DownPayment) 
		AND C.IsLease = 0 AND LoanPaymentSchedules.EndDate < C.AsofDate
	WHERE (LoanPaymentSchedules.Id IS NOT NULL OR LeasePaymentSchedules.Id IS NOT NULL)
	GROUP BY C.ContractId, RT.Name, C.LeaseContractType
)
UPDATE #ContractDetails
	SET ReceivableBalance = RD.ReceivableBalance
FROM #ContractDetails C
JOIN (
	SELECT ContractId, SUM(ReceivableBalance) AS ReceivableBalance FROM CTE_ReceivableBalance GROUP BY ContractId
) RD ON C.ContractId = RD.ContractId;

SELECT 
	ContractId,
	IsLease,
	NBV,
	ReceivableBalance,
	CashPostedAmount,
	LeaseContractType
FROM #ContractDetails
SELECT * FROM #AssetInfo
SELECT * FROM #BlendedDetails
--Drop Temp Tables
DROP TABLE #ContractDetails
DROP TABLE #AssetInfo
DROP TABLE #BlendedDetails
DROP TABLE #ValidReceivableTypes
END

GO
