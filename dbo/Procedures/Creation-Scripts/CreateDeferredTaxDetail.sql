SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateDeferredTaxDetail]
(
@DefTaxContractDetails DefTaxContractDetailTableType READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #ProcessedContracts
(
Id					BIGINT,
SequenceNumber		NVARCHAR(200),
ProcessedTillDate   DATE
)
CREATE TABLE #ErrorContracts
(
ContractId					BIGINT,
SequenceNumber		NVARCHAR(200),
ErrorNumber			NVARCHAR(MAX),
ErrorMessage		NVARCHAR(MAX)
)
BEGIN TRY
BEGIN TRANSACTION
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #AllContractDetails
(
DueDate						DATE,
DeferredTaxDueDate			DATE,
ClassificationContractType	NVARCHAR(32),
ContractType				NVARCHAR(28),
DeactivateOldRecords		BIT,
OpenPeriodStartDate			DATE,
GLTemplateId				BIGINT,
IsTaxLease					BIT,
SyndicationType				NVARCHAR(32),
IsReProcessInClosedPeriod	BIT,
ReProcessDate				DATE,
IsFirstDateSetToReprocess	BIT,
LatestDate					DATE,
CurrencyISO					NVARCHAR(3),
ContractId					BIGINT,
CommencementDate			DATE,
ContractChargeOffDate	    DATE,
LeaseIncomeFirstDate		DATE,
IsProcessedAlready			BIT,
DateToCheckBlendedItem		DATE,
DateToTakeOldDeferredTax	DATE,
LegalEntityISO				NVARCHAR(3)
)
CREATE TABLE #LeaseContractDetails
(
DueDate						DATE,
DeferredTaxDueDate			DATE,
ClassificationContractType	NVARCHAR(32),
ContractType				NVARCHAR(28),
DeactivateOldRecords		BIT,
OpenPeriodStartDate			DATE,
GLTemplateId				BIGINT,
IsTaxLease					BIT,
SyndicationType				NVARCHAR(32),
IsReProcessInClosedPeriod	BIT,
ReProcessDate				DATE,
IsFirstDateSetToReprocess	BIT,
LatestDate					DATE,
CurrencyISO					NVARCHAR(3),
ContractId					BIGINT,
CommencementDate			DATE,
ContractChargeOffDate	    DATE,
LeaseIncomeFirstDate		DATE,
IsProcessedAlready			BIT,
DateToCheckBlendedItem		DATE,
DateToTakeOldDeferredTax	DATE,
LegalEntityISO				NVARCHAR(3)
)
CREATE TABLE #LeaseFinances
(
Id					BIGINT,
ContractId			BIGINT,
IsCurrent			BIT,
LegalEntityId		BIGINT,
CommencementDate	DATE
)
CREATE TABLE #LeaseIncomeSchedules
(
Id						BIGINT,
IncomeDate				DATE,
IncomeType				NVARCHAR(100),
Income_Amount			DECIMAL(16,2),
RentalIncome_Amount		DECIMAL(16,2),
Payment_Amount			DECIMAL(16,2),
LeaseFinanceId			BIGINT,
ContractId				BIGINT,
IsAccounting			BIT,
IsSchedule				BIT
)
CREATE TABLE #AssetIncomeSchedules
(
Income_Amount			DECIMAL(16,2),
LeaseIncome_Amount			DECIMAL(16,2),
FinanceIncome_Amount			DECIMAL(16,2),
RentalIncome_Amount		DECIMAL(16,2),
LeaseRentalIncome_Amount		DECIMAL(16,2),
FinanceRentalIncome_Amount		DECIMAL(16,2),
Payment_Amount			DECIMAL(16,2),
LeasePayment_Amount			DECIMAL(16,2),
FinancePayment_Amount			DECIMAL(16,2),
LeaseIncomeScheduleId	BIGINT,
AssetId					BIGINT,
IsActive				BIT
)
CREATE TABLE #LeaseAssets
(
Id						BIGINT,
LeaseFinanceId			BIGINT,
AssetId					BIGINT,
ContractId				BIGINT,
Amount_Amount			DECIMAL(16,2),
Total_Amount			DECIMAL(16,2),
ProRateValue			DECIMAL(16,10),
EffectiveFromDate		DATE,
IsOriginal				BIT,
NoofAsset				INT,
)
CREATE TABLE #BlendedIncomeSchedules
(
IncomeDate				DATE,
Income_Amount			DECIMAL(16,2),
Income_Currency			NVARCHAR(10),
LeaseFinanceId			BIGINT,
BlendedItemId			BIGINT
)
CREATE TABLE #TaxIncomeTaxIncomeSchedules
(
ContractId BIGINT,
LeaseFinanceId BIGINT,
IncomeType NVARCHAR(100),
IncomeDate DATE,
RentalIncome_Amount DECIMAL(16,4),
RentalIncome_Currency NVARCHAR(6),
InterimRent_Amount DECIMAL(16,4),
InterimRent_Currency NVARCHAR(6),
OTPRent_Amount DECIMAL(16,4),
OTPRent_Currency NVARCHAR(6),
AssetId BIGINT
)
CREATE TABLE #TaxIncomeBookIncomeSchedules
(
ContractId BIGINT,
LeaseFinanceId BIGINT,
IncomeType NVARCHAR(100),
IncomeDate DATE,
RentalIncome_Amount DECIMAL(16,4),
RentalIncome_Currency NVARCHAR(6),
InterimRent_Amount DECIMAL(16,4),
InterimRent_Currency NVARCHAR(6),
OTPRent_Amount DECIMAL(16,4),
OTPRent_Currency NVARCHAR(6),
AssetId BIGINT
)
CREATE TABLE #TaxDepEntities
(
Id						BIGINT,
EntityType				NVARCHAR(100),
AssetId					BIGINT,
TaxDepTemplateId		BIGINT,
ContractId				BIGINT,
BlendedItemId			BIGINT,
)
CREATE TABLE #TaxDepAmortizations
(
Id							BIGINT,
TaxDepEntityId				BIGINT,
TaxDepreciationTemplateId	BIGINT,
ContractId					BIGINT
)
CREATE TABLE #TaxDepAmortizationDetails
(
Id							BIGINT,
DepreciationDate			DATE,
DepreciationAmount_Amount	DECIMAL(16,2),
DepreciationAmount_Currency	NVARCHAR(10),
EndNetBookValue_Amount		DECIMAL(16,2),
EndNetBookValue_Currency	NVARCHAR(10),
TaxDepAmortizationId		BIGINT,
TaxDepreciationTemplateDetailId BIGINT
)
CREATE TABLE #BlendedItems
(
Amount_Amount				DECIMAL(16,2),
Amount_Currency				NVARCHAR(10),
Type						NVARCHAR(100),
DueDate						DATE,
IsAssetBased				BIT,
Id							BIGINT,
LeaseAssetId				BIGINT,
TaxRecognitionMode			NVARCHAR(100),
BookRecognitionMode			NVARCHAR(100),
IsFAS91						BIT,
IsETC						BIT,
ContractId					BIGINT
)
CREATE TABLE #DeferredTaxes
(
Id					BIGINT,
ContractId			BIGINT,
Date				DATE,
IsGLPosted			BIT,
IsReprocess			BIT,
IsAccounting		BIT,
IsScheduled			BIT,
DefTaxLiabBalance_Amount	DECIMAL(16,2),
YTDDeferredTax_Amount		DECIMAL(16,2),
MTDDeferredTax_Amount		DECIMAL(16,2),
AccumDefTaxLiabBalance_Amount DECIMAL(16,2),
DefTaxLiabBalance_Currency	NVARCHAR(6),
TaxDepreciationSystem		NVARCHAR(100)
)
CREATE TABLE #AllBlendedItemDetail
(
ContractId				BIGINT,
Amount_Amount			DECIMAL(16,2),
Amount_Currency			NVARCHAR(10),
Type					NVARCHAR(100),
BlendedIncomeDueDate	DATE,
TaxRecognitionMode		NVARCHAR(100),
Id						BIGINT,
IsAssetBased			BIT,
IsFAS91					BIT
)
CREATE TABLE #TaxIncomeTaxNonAssetBasedBlendedItemDetail
(
ContractId				BIGINT,
Amount_Amount			DECIMAL(16,4),
Amount_Currency			NVARCHAR(10),
Type					NVARCHAR(100),
BlendedIncomeDueDate	DATE,
System					NVARCHAR(100),
TaxBook					NVARCHAR(100),
BlendedItemId			BIGINT,
TaxDepRateId			BIGINT
)
CREATE TABLE #AllBlendedItemIncomeDetails
(
ContractId				BIGINT,
Income_Amount			DECIMAL(16,4),
Income_Currency			NVARCHAR(10),
Type					NVARCHAR(100),
BlendedIncomeDueDate	DATE,
Id						BIGINT,
IsAssetBased			BIT,
)
CREATE TABLE #TaxIncomeBookNonAssetBasedBlendedItemDetail
(
ContractId				BIGINT,
Amount_Amount			DECIMAL(16,4),
Amount_Currency			NVARCHAR(10),
Type					NVARCHAR(100),
BlendedIncomeDueDate	DATE,
System					NVARCHAR(100),
TaxBook					NVARCHAR(100),
BlendedItemId			BIGINT,
)
CREATE TABLE #TaxIncomeTaxAssetBasedAmortizeBlendedItemDetail
(
ContractId				BIGINT,
Amount_Amount			DECIMAL(16,4),
Amount_Currency			NVARCHAR(10),
Type					NVARCHAR(100),
BlendedIncomeDueDate	DATE,
System					NVARCHAR(100),
TaxBook					NVARCHAR(100),
BlendedItemId			BIGINT,
AssetId					BIGINT,
TaxDepRateId			BIGINT
)
CREATE TABLE #DeferredTaxDetailEntity
(
ContractId							BIGINT,
AssetId								BIGINT NULL,
TaxBookName							NVARCHAR(100) NULL,
TaxDepreciationSystem				NVARCHAR(100) NULL,
FiscalYear							NVARCHAR(100) NULL,
IncomeDate							DATE NULL,
TaxableIncomeTax_Amount				DECIMAL(16, 4) NULL,
TaxableIncomeTax_Currency			NVARCHAR(3) NULL,
TaxableIncomeBook_Amount			DECIMAL(16, 4) NULL,
TaxableIncomeBook_Currency			NVARCHAR(3) NULL,
BookDepreciation_Amount				DECIMAL(16, 4) NULL,
BookDepreciation_Currency			NVARCHAR(3) NULL,
TaxDepreciation_Amount				DECIMAL(16, 4) NULL,
TaxDepreciation_Currency			NVARCHAR(3) NULL,
TaxIncome_Amount					DECIMAL(16, 4) NULL,
TaxIncome_Currency					NVARCHAR(3) NULL,
BookIncome_Amount					DECIMAL(16, 4) NULL,
BookIncome_Currency					NVARCHAR(3) NULL,
IncomeTaxExpense_Amount				DECIMAL(16, 4) NULL,
IncomeTaxExpense_Currency			NVARCHAR(3) NULL,
IncomeTaxPayable_Amount				DECIMAL(16, 4) NULL,
IncomeTaxPayable_Currency			NVARCHAR(3) NULL,
DefTaxLiabBalance_Amount			DECIMAL(16, 2) NULL,
DefTaxLiabBalance_Currency			NVARCHAR(3) NULL,
MTDDeferredTax_Amount				DECIMAL(16, 2) NULL,
MTDDeferredTax_Currency				NVARCHAR(3) NULL,
YTDDeferredTax_Amount				DECIMAL(16, 2) NULL,
YTDDeferredTax_Currency				NVARCHAR(3) NULL,
AccumDefTaxLiabBalance_Amount		DECIMAL(16, 2) NULL,
AccumDefTaxLiabBalance_Currency		NVARCHAR(3) NULL,
CreatedById							BIGINT NULL,
CreatedTime							DATETIMEOFFSET(7) NULL,
ContractCurrency					NVARCHAR(10) NULL,
FITRate								DECIMAL(16, 10) NULL,
MonthToCalculate					INT,
YearToCalculate						INT,
IsGLPosted							BIT,
IsReprocess							BIT,
IsAccounting						BIT,
IsScheduled							BIT,
IsLeveragedLease					BIT,
IsForCalculation					BIT,
IncomeType							NVARCHAR(100),
GLTemplateId						BIGINT,
SystemRowNumber						INT
)
CREATE TABLE #AssetValueHistories
(
Id						BIGINT,
Value_Amount			DECIMAL(16,2),
Value_Currency			NVARCHAR(10),
AssetId					BIGINT,
IncomeDate				DATE,
SourceModule			NVARCHAR(50),
ContractId				BIGINT,
IsLessorOwned			BIT,
)
CREATE TABLE #InsertedDeferredTax
(
Id BIGINT,
Date DATE,
ContractId BIGINT
)
INSERT INTO #AllContractDetails(ContractId, DueDate)
SELECT ContractId, DueDate FROM @DefTaxContractDetails
WHERE IsToDeactivateDefTax = 0
;
WITH CTE_Contracts AS
(
SELECT
C.Id,
C.CurrencyId,
C.ContractType,
C.SyndicationType,
SequenceNumber,
CC.ISO,
C.ChargeOffStatus
FROM Contracts C
JOIN #AllContractDetails DTC ON C.Id = DTC.ContractId
JOIN Currencies CR ON C.CurrencyId = CR.Id
JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
)
UPDATE #AllContractDetails
SET CurrencyISO = CT.ISO,ContractType = CT.ContractType, SyndicationType = CT.SyndicationType
FROM CTE_Contracts CT
JOIN #AllContractDetails CD ON CT.Id = CD.ContractId
;
WITH CTE_ChargeOffContracts AS
(
SELECT
MAx(ChargeOffDate) ChargeOffDate,
CO.ContractId
FROM ChargeOffs CO
JOIN #AllContractDetails CD ON CO.ContractId = CD.ContractId
WHERE CO.IsRecovery = 0
GROUP BY
CO.ContractId
)
UPDATE #AllContractDetails
SET ContractChargeOffDate = COC.ChargeOffDate
FROM CTE_ChargeOffContracts COC
INNER JOIN #AllContractDetails CD ON CD.ContractId = COC.ContractId
;
INSERT INTO #DeferredTaxes
(ContractId,Date,DefTaxLiabBalance_Amount,DefTaxLiabBalance_Currency,IsAccounting,IsGLPosted,TaxDepreciationSystem,
IsReprocess,IsScheduled,AccumDefTaxLiabBalance_Amount,MTDDeferredTax_Amount,YTDDeferredTax_Amount,Id)
SELECT
DeferredTaxes.ContractId,
Date,
DefTaxLiabBalance_Amount,
DefTaxLiabBalance_Currency,
IsAccounting,
IsGLPosted,
TaxDepreciationSystem,
IsReprocess,
IsScheduled,
AccumDefTaxLiabBalance_Amount,
MTDDeferredTax_Amount,
YTDDeferredTax_Amount,
Id
FROM  DeferredTaxes
JOIN #AllContractDetails DTC ON DTC.ContractId = DeferredTaxes.ContractId
;
WITH CTE_DeferredTax AS
(
SELECT
DT.ContractId
,MIN(Date) Date
FROM #DeferredTaxes DT
WHERE IsReprocess = 1 AND IsScheduled = 1
GROUP BY
DT.ContractId
)
UPDATE #AllContractDetails
SET ReProcessDate = CT.Date
FROM #AllContractDetails CD
JOIN CTE_DeferredTax CT ON CD.ContractId = CT.ContractId
;
INSERT INTO #LeaseContractDetails
SELECT * FROM #AllContractDetails WHERE ContractType <> 'LeveragedLease'
;
DELETE FROM #AllContractDetails WHERE ContractType <> 'LeveragedLease'
;
INSERT INTO #LeaseFinances (Id, IsCurrent, ContractId, LegalEntityId)
SELECT
Id,
IsCurrent,
CD.ContractId,
LegalEntityId
FROM LeaseFinances LF
JOIN #LeaseContractDetails CD ON LF.ContractId = CD.ContractId
;
WITH CTE_CommencementDate AS
(
SELECT LFD.CommencementDate, ContractId
FROM #LeaseFinances LF JOIN LeaseFinanceDetails LFD
ON LF.Id = LFD.Id AND LF.IsCurrent = 1
)
UPDATE #LeaseFinances
SET CommencementDate = LFD.CommencementDate
FROM #LeaseFinances LF
JOIN CTE_CommencementDate LFD ON LF.ContractId = LFD.ContractId
;
UPDATE #LeaseContractDetails
SET ClassificationContractType = LFD.LeaseContractType,
GLTemplateId = DeferredTaxGLTemplateId, IsTaxLease = LFD.IsTaxLease, CommencementDate = LFD.CommencementDate
FROM #LeaseContractDetails CD
JOIN #LeaseFinances CLF ON CD.ContractId = CLF.ContractId AND IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON CLF.Id = LFD.Id
;
WITH CTE_Contracts AS
(
SELECT
LF.ContractId,
LE.CurrencyId,
CC.ISO
FROM #LeaseFinances LF
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN Currencies CR ON LE.TaxDepBasisCurrencyId = CR.Id
JOIN CurrencyCodes CC ON CR.CurrencyCodeId = CC.Id
WHERE LF.IsCurrent = 1
)
UPDATE #LeaseContractDetails
SET LegalEntityISO = CT.ISO
FROM CTE_Contracts CT
JOIN #LeaseContractDetails CD ON CT.ContractId = CD.ContractId
;
INSERT INTO #LeaseIncomeSchedules (Id, IncomeDate, IncomeType, Income_Amount, RentalIncome_Amount, Payment_Amount, LeaseFinanceId, ContractId, IsAccounting, IsSchedule)
SELECT
LeaseIncomeSchedules.Id	,
IncomeDate				,
IncomeType				,
Income_Amount			,
RentalIncome_Amount		,
Payment_Amount			,
LeaseFinanceId			,
CD.ContractId			,
IsAccounting			,
IsSchedule
FROM LeaseIncomeSchedules
JOIN #LeaseFinances ON LeaseIncomeSchedules.LeaseFinanceId = #LeaseFinances.Id
JOIN #LeaseContractDetails CD ON #LeaseFinances.ContractId = CD.ContractId
WHERE IncomeDate <= CD.DueDate
;
INSERT INTO #AssetIncomeSchedules(Income_Amount,LeaseIncome_Amount,FinanceIncome_Amount, RentalIncome_Amount,LeaseRentalIncome_Amount
                                  ,FinanceRentalIncome_Amount, Payment_Amount,LeasePayment_Amount,FinancePayment_Amount, LeaseIncomeScheduleId
								  ,AssetId, IsActive)
SELECT
AIS.Income_Amount		,
AIS.LeaseIncome_Amount		,
AIS.FinanceIncome_Amount		,
AIS.RentalIncome_Amount	,
AIS.LeaseRentalIncome_Amount	,
AIS.FinanceRentalIncome_Amount	,
AIS.Payment_Amount		,
AIS.LeasePayment_Amount		,
AIS.FinancePayment_Amount		,
AIS.LeaseIncomeScheduleId,
AIS.AssetId				,
AIS.IsActive
FROM #LeaseIncomeSchedules JOIN AssetIncomeSchedules AIS
ON #LeaseIncomeSchedules.Id = AIS.LeaseIncomeScheduleId
JOIN #LeaseContractDetails CD ON #LeaseIncomeSchedules.ContractId = CD.ContractId
WHERE IncomeDate <= CD.DueDate
;
SELECT
LeaseAssets.Id				,
LeaseFinanceId				,
AssetId						,
ContractId					,
(CASE WHEN Rent_Amount = 0.00 THEN NBV_Amount ELSE Rent_Amount END) Amount_Amount,
CAST(0.00 AS DECIMAL(16,2))	Total_Amount,
CAST(0.00 AS DECIMAL(16,10)) ProRateValue,
CAST(NULL AS DATE) PayoffEffectiveDate,
CAST(NULL AS DATE) AS CalculatedEffectiveDate
INTO #LeaseAssetTemp
FROM LeaseAssets JOIN #LeaseFinances
ON LeaseAssets.LeaseFinanceId = #LeaseFinances.Id
AND LeaseAssets.IsActive = 1 AND #LeaseFinances.IsCurrent = 1
;
SELECT
LA.Id						,
PO.LeaseFinanceId			,
AssetId						,
ContractId					,
(CASE WHEN Rent_Amount = 0.00 THEN LA.NBV_Amount ELSE Rent_Amount END) as Amount_Amount,
CAST(0.00 AS DECIMAL(16,2))	as Total_Amount,
CAST(0.00 AS DECIMAL(16,10)) as ProRateValue,
PO.PayoffEffectiveDate,
PO.PayoffEffectiveDate CalculatedEffectiveDate
INTO #PayoffAssetTemp
FROM Payoffs PO
JOIN #LeaseFinances LF ON PO.LeaseFinanceId = LF.Id
JOIN PayoffAssets POA ON PO.Id = POA.PayoffId
JOIN LeaseAssets LA ON POA.LeaseAssetID = LA.Id
AND LA.IsActive = 1 AND PO.Status = 'Activated'
;
INSERT INTO #LeaseAssets (Id, LeaseFinanceId, AssetId, ContractId, Amount_Amount, Total_Amount, ProRateValue, EffectiveFromDate, IsOriginal, NoofAsset)
SELECT Id, LeaseFinanceId, AssetId, ContractId, Amount_Amount, Total_Amount, ProRateValue, CAST(NULL AS DATE), 1, CAST(0 AS INT) FROM #LeaseAssetTemp
UNION
SELECT Id, LeaseFinanceId, AssetId, ContractId, Amount_Amount, Total_Amount, ProRateValue, CAST(NULL AS DATE), 1, CAST(0 AS INT) FROM #PayoffAssetTemp
;
SELECT
MIN(CalculatedEffectiveDate) CalculatedEffectiveDate,ContractId
INTO #DateToCreateAssets
FROM #PayoffAssetTemp WHERE CalculatedEffectiveDate IS NOT NULL
GROUP BY ContractId
;
WHILE ((Select Count(*) From #DateToCreateAssets) > 0)
BEGIN
;WITH CTE_Assets AS
(
SELECT
DISTINCT PO.AssetId, DO.ContractId,DO.CalculatedEffectiveDate
FROM #PayoffAssetTemp PO JOIN #DateToCreateAssets DO
ON PO.ContractId = DO.ContractId
WHERE PO.PayoffEffectiveDate <= DO.CalculatedEffectiveDate
)
INSERT INTO #LeaseAssets (Id, LeaseFinanceId, AssetId, ContractId, Amount_Amount, Total_Amount, ProRateValue, EffectiveFromDate, IsOriginal, NoofAsset)
SELECT
Id, LeaseFinanceId, LA.AssetId, LA.ContractId, Amount_Amount, Total_Amount, ProRateValue, CA.CalculatedEffectiveDate, 0, CAST(0 AS INT)
FROM #LeaseAssets LA
JOIN CTE_Assets CA ON LA.ContractId = CA.ContractId
WHERE IsOriginal = 1 AND LA.AssetId NOT IN (SELECT AssetId FROM CTE_Assets WHERE ContractId = LA.ContractId)
;
UPDATE #PayoffAssetTemp
SET CalculatedEffectiveDate = NULL
FROM #PayoffAssetTemp PO JOIN #DateToCreateAssets DO
ON PO.PayoffEffectiveDate = DO.CalculatedEffectiveDate AND PO.ContractId = DO.ContractId
;
TRUNCATE TABLE #DateToCreateAssets
;
INSERT INTO #DateToCreateAssets
SELECT
MIN(CalculatedEffectiveDate) CalculatedEffectiveDate,ContractId
FROM #PayoffAssetTemp WHERE CalculatedEffectiveDate IS NOT NULL
GROUP BY ContractId
;
END
;
WITH CTE_DeferredTaxDate AS
(
SELECT
DT.ContractId,
MAX(Date) Date
FROM #DeferredTaxes DT
WHERE IsAccounting = 1
GROUP BY DT.ContractId
)
,CTE_MinFirstDate AS
(
SELECT
MIN(Date) Date,
DT.ContractId
FROM #DeferredTaxes DT JOIN #LeaseContractDetails CD
ON DT.ContractId = CD.ContractId AND DT.Date < ReProcessDate
AND DT.IsAccounting = 1
GROUP BY DT.ContractId
)
,CTE_MaxFirstDate AS
(
SELECT
MAX(Date) Date,
DT.ContractId
FROM #DeferredTaxes DT JOIN #LeaseContractDetails CD
ON DT.ContractId = CD.ContractId AND DT.Date < ReProcessDate
AND DT.IsAccounting = 1 AND IsScheduled = 1
GROUP BY DT.ContractId
)
,CTE_LeaseIncomeSchedules AS
(
SELECT
LIS.ContractId
,MIN(LIS.IncomeDate) IncomeDate
FROM #LeaseIncomeSchedules LIS
WHERE LIS.IncomeType <> 'InterimRent' AND IncomeType <> 'InterimInterest'
GROUP BY LIS.ContractId
)
UPDATE #LeaseContractDetails
SET DeferredTaxDueDate =  CASE WHEN DT.Date IS NULL THEN CAST(DATEADD(DAY, -1, LIS.IncomeDate) AS DATE) ELSE DT.Date  END,
LatestDate = CASE WHEN (ReProcessDate IS NOT NULL AND DT.Date IS NULL) THEN CAST(NULL AS DATE) ELSE  DT.Date END,
IsFirstDateSetToReprocess = CASE WHEN (ReProcessDate IS NOT NULL AND MFT.Date IS NULL) THEN 1 ELSE 0 END,
DateToTakeOldDeferredTax =  CASE WHEN (ReProcessDate IS NOT NULL) THEN MFD.Date ELSE DT.Date END,
IsProcessedAlready =  CASE WHEN (ReProcessDate IS NOT NULL AND MFT.Date IS NULL) OR (DT.Date IS NULL) THEN 0 ELSE 1 END
FROM #LeaseContractDetails CD
LEFT JOIN CTE_DeferredTaxDate DT ON CD.ContractId = DT.ContractId
LEFT JOIN CTE_MinFirstDate MFT ON CD.ContractId = MFT.ContractId
LEFT JOIN CTE_MaxFirstDate MFD ON CD.ContractId = MFD.ContractId
LEFT JOIN CTE_LeaseIncomeSchedules LIS ON CD.ContractId = LIS.ContractId
;
UPDATE #LeaseContractDetails
SET DeferredTaxDueDate = CASE WHEN ReProcessDate IS NOT NULL THEN CAST(DATEADD(DAY, -1, ReProcessDate) AS DATE) ELSE DeferredTaxDueDate END
;
DELETE #AssetIncomeSchedules FROM #AssetIncomeSchedules AIS
JOIN #LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
JOIN #LeaseContractDetails CD ON LIS.ContractId = CD.ContractId
WHERE LIS.IncomeDate <= CD.DateToTakeOldDeferredTax;
;
DELETE #LeaseIncomeSchedules FROM #LeaseIncomeSchedules LIS
JOIN #LeaseContractDetails CD ON LIS.ContractId = CD.ContractId
WHERE LIS.IncomeDate <= CD.DateToTakeOldDeferredTax;
;
SELECT
DT.ContractId, DTD.AssetId, DT.Date, DTD.DefTaxLiabBalance_Amount, DTD.MTDDeferredTax_Amount, DTD.YTDDeferredTax_Amount,
DTD.AccumDefTaxLiabBalance_Amount, CAST(1 AS BIT) IsForCalculation ,DATEPART(yyyy,DT.Date) YearToCalculate, DATEPART(m,DT.Date) MonthToCalculate
INTO #DeferredTaxLatestValue
FROM #DeferredTaxes DT
JOIN #LeaseContractDetails CD ON DT.ContractId = CD.ContractId
JOIN DeferredTaxDetails DTD ON DT.Id = DTD.DeferredTaxId
WHERE ((DT.Date = ISNULL(CD.DateToTakeOldDeferredTax, CD.DeferredTaxDueDate))
OR (DT.Date = CD.CommencementDate AND CD.IsFirstDateSetToReprocess = 1))
AND DT.IsAccounting = 1
;
INSERT INTO #DeferredTaxDetailEntity (ContractId,AssetId,IncomeDate,ContractCurrency,YearToCalculate,MonthToCalculate,IncomeType
,IsAccounting,IsScheduled,IsGLPosted,IsReprocess,IsForCalculation,IsLeveragedLease
,TaxBookName,TaxDepreciationSystem,FiscalYear,GLTemplateId)
SELECT
DISTINCT LF.ContractId,AIS.AssetId,LIS.IncomeDate,CD.CurrencyISO,DATEPART(yyyy,LIS.IncomeDate),DATEPART(m,LIS.IncomeDate),LIS.IncomeType,
CAST(1 AS BIT),CAST(1 AS BIT),CAST(0 AS BIT),CAST(0 AS BIT),CAST(0 AS BIT),CAST(0 AS BIT),'_','_',YEAR(LIS.IncomeDate), CD.GLTemplateId
FROM #LeaseContractDetails CD
JOIN #LeaseFinances LF ON CD.ContractId = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
JOIN #LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId
JOIN #AssetIncomeSchedules AIS ON LIS.Id = AIS.LeaseIncomeScheduleId
WHERE LIS.IncomeDate > CD.DeferredTaxDueDate AND LIS.IncomeDate <= CD.DueDate
ORDER BY
LIS.IncomeDate, AIS.AssetId
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeBook_Amount = 0.00, BookDepreciation_Amount = 0.00, TaxDepreciation_Amount = 0.00, IncomeTaxExpense_Amount = 0.00, IncomeTaxPayable_Amount = 0.00,
YTDDeferredTax_Amount = 0.00, AccumDefTaxLiabBalance_Amount = 0.00, TaxIncome_Amount = 0.00, BookIncome_Amount = 0.00, DefTaxLiabBalance_Amount = 0.00,
MTDDeferredTax_Amount = 0.00, TaxableIncomeTax_Amount = 0.00,
TaxableIncomeBook_Currency = ContractCurrency, BookDepreciation_Currency = ContractCurrency, TaxDepreciation_Currency = ContractCurrency,
IncomeTaxExpense_Currency = ContractCurrency, IncomeTaxPayable_Currency	= ContractCurrency, YTDDeferredTax_Currency = ContractCurrency,
AccumDefTaxLiabBalance_Currency	= ContractCurrency,	TaxIncome_Currency = ContractCurrency, BookIncome_Currency = ContractCurrency,
DefTaxLiabBalance_Currency = ContractCurrency, MTDDeferredTax_Currency = ContractCurrency, TaxableIncomeTax_Currency = ContractCurrency,
CreatedById = @CreatedById, CreatedTime = @CreatedTime, SystemRowNumber = 1
;
WITH CTE_DeferredTaxDetailMinDate AS
(
SELECT MIN(IncomeDate) IncomeDate,ContractId FROM #DeferredTaxDetailEntity GROUP BY ContractId
)
UPDATE #LeaseContractDetails
SET LeaseIncomeFirstDate = IncomeDate,
DateToCheckBlendedItem = CASE WHEN IsProcessedAlready = 0 OR DeferredTaxDueDate <=CommencementDate  THEN CommencementDate ELSE IncomeDate END
FROM #LeaseContractDetails DT JOIN CTE_DeferredTaxDetailMinDate DTM
ON DT.ContractId = DTM.ContractId
;
WITH CTE_DueDateMisMatch AS
(
SELECT DTD.ContractId, DTD.IncomeDate, CD.LeaseIncomeFirstDate FROM #DeferredTaxDetailEntity DTD
JOIN #LeaseContractDetails CD ON DTD.ContractId = CD.ContractId
WHERE DTD.IncomeDate < CD.LeaseIncomeFirstDate
)
UPDATE #DeferredTaxDetailEntity
SET #DeferredTaxDetailEntity.IncomeDate = LeaseIncomeFirstDate
FROM #DeferredTaxDetailEntity DTD JOIN CTE_DueDateMisMatch D
ON DTD.ContractId = D.ContractId AND DTD.IncomeDate = D.IncomeDate
;
DELETE FROM #LeaseIncomeSchedules WHERE IsAccounting = 0 OR IsSchedule = 0
;
DELETE FROM #AssetIncomeSchedules WHERE IsActive = 0
;
WITH CTE_AssetTotalAmount AS
(
SELECT SUM(Amount_Amount) TotalAmount_Amount, ContractId, EffectiveFromDate FROM #LeaseAssets GROUP BY ContractId, EffectiveFromDate
)
UPDATE #LeaseAssets SET Total_Amount = TotalAmount_Amount
FROM #LeaseAssets LA JOIN CTE_AssetTotalAmount CA
ON LA.ContractId = CA.ContractId AND ISNULL(LA.EffectiveFromDate,GETDATE()) = ISNULL(CA.EffectiveFromDate,GETDATE())
;
/*Identify Invalid Leases */
INSERT INTO #ErrorContracts (ContractId,Sequencenumber,ErrorMessage,ErrorNumber)
SELECT
contracts.Id,
contracts.SequenceNumber,
CAST('Lease Rent or NBV of Asset(s) in the Lease is zero.' AS NVARCHAR(MAX)) AS ErrorNumber,
NULL AS ErrorMessage
FROM #LeaseAssets
join contracts on #LeaseAssets.contractId=contracts.Id
where Total_Amount = 0.00 group by contracts.Id,contracts.Sequencenumber
/*Revert inserted Records in temp Tables*/
delete #LeaseAssets where ContractId in (select ContractId from #ErrorContracts)
delete #AllContractDetails where ContractId in (select ContractId from #ErrorContracts)
delete #DeferredTaxes where ContractId in (select ContractId from #ErrorContracts)
delete #LeaseContractDetails where ContractId in (select ContractId from #ErrorContracts)
delete #LeaseFinances where ContractId in (select ContractId from #ErrorContracts)
delete #AssetIncomeSchedules where LeaseIncomeScheduleId in (select Id from  #LeaseIncomeSchedules where ContractId in (select ContractId from #ErrorContracts))
delete #LeaseIncomeSchedules where ContractId in (select ContractId from #ErrorContracts)
delete #DateToCreateAssets where ContractId in (select ContractId from #ErrorContracts)
delete #DeferredTaxDetailEntity where ContractId in (select ContractId from #ErrorContracts)
UPDATE #LeaseAssets SET ProRateValue = (Amount_Amount/Total_Amount) FROM #LeaseAssets LA WHERE Total_Amount > 0.00
;
UPDATE #LeaseAssets
SET EffectiveFromDate = CD.CommencementDate
FROM #LeaseAssets LA
JOIN #LeaseContractDetails CD ON LA.ContractId = CD.ContractId
AND LA.EffectiveFromDate IS NULL
;
WITH CTE_TotalAsset AS
(
SELECT COUNT(*) AssetCount, ContractId, EffectiveFromDate FROM #LeaseAssets GROUP BY ContractId, EffectiveFromDate
)
UPDATE #LeaseAssets
SET NoofAsset = AssetCount
FROM #LeaseAssets LA
JOIN CTE_TotalAsset CT ON LA.ContractId = CT.ContractId
AND CT.EffectiveFromDate = LA.EffectiveFromDate
;
UPDATE #LeaseAssets SET Total_Amount = 1, ProRateValue = 1 /CONVERT(DECIMAL(16,2), NoofAsset) FROM #LeaseAssets LA WHERE Total_Amount = 0.00
;
SELECT
DISTINCT ContractId, IncomeDate, CAST(NULL AS DATE) ProRateDateToCompare INTO #ProrateDateToCompare
FROM #DeferredTaxDetailEntity;
;
WITH CTE_ProrateDateToCompare AS
(
SELECT
DTD.ContractId,
DTD.IncomeDate,
MAX(LA.EffectiveFromDate) ProRateDateToCompare
FROM #ProrateDateToCompare DTD
JOIN #LeaseAssets LA ON DTD.ContractId = LA.ContractId
AND LA.EffectiveFromDate < DTD.IncomeDate
GROUP BY
DTD.ContractId,
DTD.IncomeDate
)
UPDATE #ProrateDateToCompare
SET ProRateDateToCompare = CPD.ProRateDateToCompare
FROM #ProrateDateToCompare PD
JOIN CTE_ProrateDateToCompare CPD ON PD.ContractId = CPD.ContractId
AND PD.IncomeDate = CPD.IncomeDate
;
WITH CTE_MinProRateDate AS
(
SELECT ContractId, MIN(EffectiveFromDate) ProRateDateToCompare FROM #LeaseAssets GROUP BY ContractId
)
UPDATE #ProrateDateToCompare
SET ProRateDateToCompare = MP.ProRateDateToCompare
FROM #ProrateDateToCompare PDC
JOIN CTE_MinProRateDate MP ON PDC.ContractId = MP.ContractId
WHERE PDC.ProRateDateToCompare IS NULL
;
INSERT INTO #BlendedIncomeSchedules (IncomeDate, Income_Amount, Income_Currency, LeaseFinanceId, BlendedItemId)
SELECT
IncomeDate			,
Income_Amount		,
Income_Currency		,
LeaseFinanceId		,
BlendedItemId
FROM BlendedIncomeSchedules BIS
JOIN #LeaseFinances LF ON BIS.LeaseFinanceId = LF.Id AND BIS.IsSchedule = 1 AND BIS.IsAccounting = 1
JOIN #LeaseContractDetails CD ON LF.ContractId = CD.ContractId
WHERE IncomeDate <= CD.DueDate AND BIS.AdjustmentEntry = 0
;
INSERT INTO #BlendedItems (Amount_Amount, Amount_Currency, Type, DueDate, IsAssetBased, Id, LeaseAssetId, TaxRecognitionMode, BookRecognitionMode, IsFAS91, IsETC, ContractId)
SELECT
Amount_Amount		,
Amount_Currency		,
Type				,
BI.DueDate			,
IsAssetBased		,
BI.Id				,
LeaseAssetId		,
TaxRecognitionMode	,
BookRecognitionMode	,
IsFAS91				,
IsETC				,
CD.ContractId
FROM BlendedItems BI
JOIN LeaseBlendedItems LBI ON BI.Id = LBI.BlendedItemId  AND BI.IsActive = 1
JOIN #LeaseFinances LF ON LF.Id = LBI.LeaseFinanceId
JOIN #LeaseContractDetails CD ON LF.ContractId = CD.ContractId
WHERE BI.DueDate <= CD.DueDate AND LF.IsCurrent = 1 AND BI.IsETC = 0
;
INSERT INTO #TaxDepEntities (Id, EntityType, AssetId,	TaxDepTemplateId, ContractId, BlendedItemId)
SELECT
TD.Id				,
TD.EntityType		,
TD.AssetId			,
TaxDepTemplateId	,
TD.ContractId		,
BlendedItemId
FROM TaxDepEntities TD
JOIN #LeaseAssets LA ON TD.AssetId = LA.AssetId
AND TD.EntityType = 'Asset' AND TD.IsActive = 1
UNION
SELECT
TDE.Id				,
TDE.EntityType		,
TDE.AssetId			,
TDE.TaxDepTemplateId,
TDE.ContractId		,
BlendedItemId
FROM TaxDepEntities TDE
JOIN #BlendedItems BI
ON TDE.IsActive = 1 AND TDE.EntityType = 'BlendedItem'
AND TDE.BlendedItemId = BI.Id AND BI.ContractId = TDE.ContractId
;
WITH CTE_MAXAssetId AS
(
SELECT
MAX(AVH.Id) Id,
AVH.AssetId,
CD.ContractId
FROM AssetValueHistories AVH
INNER JOIN #LeaseAssets ON #LeaseAssets.AssetId = AVH.AssetId
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = #LeaseAssets.ContractId
WHERE (((CD.ClassificationContractType = 'DirectFinance' OR CD.ClassificationContractType = 'ConditionalSales')
AND (AVH.SourceModule = 'OTPDepreciation' OR AVH.SourceModule = 'FixedTermDepreciation'
OR AVH.SourceModule = 'InventoryBookDepreciation' OR  AVH.SourceModule = 'PayableInvoice')) OR (CD.ClassificationContractType <> 'DirectFinance'))
AND IsAccounted = 1 AND IsSchedule = 1 AND IsLessorOwned = 1
AND IncomeDate <= CD.DueDate
GROUP BY AVH.AssetId, CD.ContractId, AVH.IncomeDate
)
INSERT INTO #AssetValueHistories (Id, Value_Amount,	Value_Currency,	AssetId, IncomeDate, SourceModule, ContractId, IsLessorOwned)
SELECT
AVH.Id,
Value_Amount		,
Value_Currency		,
AVH.AssetId			,
AVH.IncomeDate		,
AVH.SourceModule	,
ContractId			,
AVH.IsLessorOwned
FROM AssetValueHistories AVH
INNER JOIN CTE_MAXAssetId MA ON AVH.Id = MA.Id
;
INSERT INTO #TaxIncomeTaxIncomeSchedules
SELECT DISTINCT
DT.ContractId
,CAST(0 AS BIGINT)
,DT.IncomeType
,DT.IncomeDate
,CAST(0.00 AS DECIMAL(16,2))
,CD.CurrencyISO
,CAST(0.00 AS DECIMAL(16,2))
,CD.CurrencyISO
,CAST(0.00 AS DECIMAL(16,2))
,CD.CurrencyISO
,DT.AssetId
FROM #DeferredTaxDetailEntity DT
JOIN #LeaseContractDetails CD ON DT.ContractId = CD.ContractId
ORDER BY IncomeDate, AssetId
;
INSERT INTO #TaxDepAmortizations (Id, TaxDepEntityId, TaxDepreciationTemplateId, ContractId)
SELECT
TaxDepAmortizations.Id		,
TaxDepEntityId				,
TaxDepreciationTemplateId	,
ContractId
FROM TaxDepAmortizations JOIN #TaxDepEntities
ON TaxDepAmortizations.TaxDepEntityId = #TaxDepEntities.Id AND TaxDepAmortizations.IsActive = 1
;
INSERT INTO #TaxDepAmortizationDetails (Id, DepreciationDate, DepreciationAmount_Amount, DepreciationAmount_Currency, EndNetBookValue_Amount, EndNetBookValue_Currency, TaxDepAmortizationId, TaxDepreciationTemplateDetailId)
SELECT
TaxDepAmortizationDetails.Id,
DepreciationDate			,
DepreciationAmount_Amount	,
DepreciationAmount_Currency,
EndNetBookValue_Amount		,
EndNetBookValue_Currency	,
TaxDepAmortizationId		,
TaxDepreciationTemplateDetailId
FROM TaxDepAmortizationDetails
JOIN #TaxDepAmortizations ON #TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId
JOIN #LeaseContractDetails CD ON #TaxDepAmortizations.ContractId = CD.ContractId
WHERE TaxDepAmortizationDetails.DepreciationDate <= CD.DueDate
;
SELECT
DATEPART(yyyy,DT.Date) YearToCalculate,
DATEPART(m,DT.Date) MonthToCalculate,
DT.TaxDepreciationSystem,
DT.Date,
DTD.AssetId,
ISNULL(DTD.DefTaxLiabBalance_Amount,0.00) DefTaxLiabBalance_Amount,
DT.Id,
DT.ContractId
INTO #DeferredTaxDetail_Adj
FROM #DeferredTaxes DT
INNER JOIN DeferredTaxClearances DTC ON DT.Id = DTC.DeferredTaxId
INNER JOIN DeferredTaxDetails DTD ON DT.Id = DTD.DeferredTaxId
JOIN #LeaseContractDetails CD ON CD.ContractId = DT.ContractId
WHERE DTC.Type = 'ADJ' AND IsAccounting = 1 AND IsScheduled = 0
AND DT.Date > ISNULL(CD.DateToTakeOldDeferredTax, CAST(DATEADD(DAY, -1, CD.CommencementDate) AS DATE))
ORDER BY Date DESC
;
WITH CTE_MinDateBI AS
(
SELECT MIN(DueDate) DueDate,ContractId FROM #BlendedItems GROUP BY ContractId
)
UPDATE #LeaseContractDetails
SET DateToCheckBlendedItem = CASE WHEN IsProcessedAlready = 0 THEN BI.DueDate ELSE DateToCheckBlendedItem END
FROM #LeaseContractDetails DT JOIN CTE_MinDateBI BI
ON DT.ContractId = BI.ContractId
;
UPDATE DeferredTaxes
SET IsAccounting = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes
JOIN #LeaseContractDetails CD ON DeferredTaxes.ContractId = CD.ContractId
AND Date >= CD.ReProcessDate AND IsScheduled = 1
AND Date >=  CD.OpenPeriodStartDate AND IsAccounting = 1
AND CD.ContractType <> 'LeveragedLease' AND (SyndicationType = 'FullSale' OR IsTaxLease = 0)
;
UPDATE DeferredTaxes
SET IsScheduled = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes
JOIN #LeaseContractDetails CD ON DeferredTaxes.ContractId = CD.ContractId
AND Date >= CD.ReProcessDate AND CD.ContractType <> 'LeveragedLease'
AND (SyndicationType = 'FullSale' OR IsTaxLease = 0)
;
UPDATE DeferredTaxes
SET IsReprocess = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes
JOIN #LeaseContractDetails CD ON DeferredTaxes.ContractId = CD.ContractId
AND Date >= CD.ReProcessDate AND Date < CD.OpenPeriodStartDate
AND CD.ContractType <> 'LeveragedLease' AND (SyndicationType = 'FullSale' OR IsTaxLease = 0)
;
SELECT
AFRI.CustomerIncomeAmount_Amount
,AFRI.CustomerIncomeAmount_Currency
,AFRI.CustomerReceivableAmount_Amount
,AFRI.CustomerReceivableAmount_Currency
,LF.ContractId
,LFRI.IncomeDate
,AFRI.AssetId
INTO #LeaseFloatRateIncomeResult
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON C.ContractId = LF.ContractId
INNER JOIN LeaseFloatRateIncomes LFRI ON LFRI.LeaseFinanceId = LF.Id
INNER JOIN AssetFloatRateIncomes AFRI ON LFRI.Id = AFRI.LeaseFloatRateIncomeId
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
WHERE LFRI.IsAccounting = 1 AND LFRI.IsScheduled = 1
AND (LFRI.IncomeDate > CD.DeferredTaxDueDate  AND LFRI.IncomeDate <= CD.DueDate)
;
SELECT
SUM(Amount_Amount) ResidualAmount,
LF.ContractId
INTO #LeasePaymentScheduleResidualAmount
FROM LeasePaymentSchedules LPS
JOIN #LeaseFinances Lf ON LPS.LeaseFinanceDetailId = LF.Id AND LF.IsCurrent = 1
WHERE (LPS.PaymentType = 'CustomerGuaranteedResidual'
OR LPS.PaymentType ='ThirdPartyGuaranteedResidual') AND LPS.IsActive = 1
GROUP BY
LF.ContractId
;
WITH CTE_LastPaymentDetail AS
(
SELECT
MAX(IncomeDate) IncomeDate,
ContractId
FROM #LeaseIncomeSchedules
GROUP BY
ContractId
)
UPDATE #LeaseIncomeSchedules
SET RentalIncome_Amount = RentalIncome_Amount - ISNULL(#LeasePaymentScheduleResidualAmount.ResidualAmount,0.00)
FROM #LeaseIncomeSchedules
JOIN #LeasePaymentScheduleResidualAmount ON #LeaseIncomeSchedules.ContractId = #LeasePaymentScheduleResidualAmount.ContractId
;
WITH CTE_AISFixedTermAmountDetails AS
(
SELECT
DISTINCT
CD.ContractId
,LF.Id LeaseFinanceId
,LIS.IncomeType
,LIS.IncomeDate
,AIS.Payment_Amount
,AIS.LeasePayment_Amount
,AIS.FinancePayment_Amount
,AIS.AssetId
,LIS.Id
,AIS.RentalIncome_Amount
,AIS.LeaseRentalIncome_Amount
,AIS.FinanceRentalIncome_Amount
FROM #LeaseFinances LF
INNER JOIN #LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id
INNER JOIN #AssetIncomeSchedules AIS ON AIS.LeaseIncomeScheduleId = LIS.Id
INNER JOIN #TaxDepEntities TDE ON AIS.AssetId = TDE.AssetId AND TDE.EntityType = 'Asset'
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
WHERE (LIS.IncomeDate > CD.DeferredTaxDueDate  AND LIS.IncomeDate <= CD.DueDate)
AND (LIS.IncomeType = 'FixedTerm' OR (IncomeType = 'InterimRent' OR IncomeType = 'InterimInterest')
OR (IncomeType = 'OverTerm' OR IncomeType = 'Supplemental'))
)

UPDATE #TaxIncomeTaxIncomeSchedules
SET IncomeType = AIS.IncomeType,
RentalIncome_Amount = CASE WHEN AIS.IncomeType = 'FixedTerm' THEN (AIS.LeasePayment_Amount + AIS.FinancePayment_Amount) ELSE TIT.RentalIncome_Amount END,
/* Actual Formula */
--InterimRent_Amount = CASE WHEN (AIS.IncomeType = 'InterimRent' OR  AIS.IncomeType = 'InterimInterest') THEN
--CASE WHEN (AIS.IncomeType = 'InterimRent') THEN (AIS.LeaseRentalIncome_Amount + AIS.FinanceRentalIncome_Amount) 
--                                           ELSE (AIS.LeaseIncome_Amount + AIS.FinanceIncome_Amount)  END
--ELSE TIT.InterimRent_Amount END,

/* Changing the Existing code to SKU */
InterimRent_Amount = CASE WHEN (AIS.IncomeType = 'InterimRent' OR  AIS.IncomeType = 'InterimInterest') THEN (AIS.LeasePayment_Amount + AIS.FinancePayment_Amount) ELSE InterimRent_Amount END,

OTPRent_Amount = CASE WHEN (AIS.IncomeType = 'OverTerm' OR  AIS.IncomeType = 'Supplemental') THEN
                  (AIS.LeaseRentalIncome_Amount + AIS.FinanceRentalIncome_Amount) 
				 ELSE 
				 OTPRent_Amount END
FROM #TaxIncomeTaxIncomeSchedules TIT
JOIN  CTE_AISFixedTermAmountDetails AIS ON TIT.ContractId = AIS.ContractId
AND TIT.IncomeDate = AIS.IncomeDate AND TIT.AssetId = AIS.AssetId
;
UPDATE #TaxIncomeTaxIncomeSchedules
SET #TaxIncomeTaxIncomeSchedules.RentalIncome_Amount =
#TaxIncomeTaxIncomeSchedules.RentalIncome_Amount + ISNULL(CustomerReceivableAmount_Amount,0.00)
FROM #TaxIncomeTaxIncomeSchedules
INNER JOIN #LeaseFloatRateIncomeResult
ON #TaxIncomeTaxIncomeSchedules.IncomeDate = #LeaseFloatRateIncomeResult.IncomeDate
AND #TaxIncomeTaxIncomeSchedules.ContractId = #LeaseFloatRateIncomeResult.ContractId
AND #TaxIncomeTaxIncomeSchedules.AssetId = #LeaseFloatRateIncomeResult.AssetId
;
WITH CTE_InterimRentMismatch AS
(
SELECT
DISTINCT LIS.ContractId, LIS.IncomeDate InterimRentIncomeDate
FROM #LeaseIncomeSchedules LIS
JOIN #DeferredTaxDetailEntity DTD ON LIS.ContractId = DTD.ContractId
WHERE (LIS.IncomeType = 'InterimRent' OR LIS.IncomeType = 'InterimInterest')  AND
LIS.IncomeDate NOT IN (SELECT IncomeDate FROM #DeferredTaxDetailEntity WHERE ContractId = LIS.ContractId)
)
,CTE_MinDate AS
(
SELECT
AB.ContractId,
CAB.InterimRentIncomeDate,
MIN(AB.IncomeDate) IncomeDate
FROM #DeferredTaxDetailEntity AB
JOIN CTE_InterimRentMismatch CAB ON AB.ContractId = CAB.ContractId AND AB.IncomeDate > CAB.InterimRentIncomeDate
GROUP BY
AB.ContractId,
CAB.InterimRentIncomeDate
)
UPDATE #LeaseIncomeSchedules
SET IncomeDate = MD.IncomeDate
FROM #LeaseIncomeSchedules LIS
JOIN CTE_MinDate MD ON LIS.ContractId = MD.ContractId
AND LIS.IncomeDate = MD.InterimRentIncomeDate
AND (LIS.IncomeType = 'InterimRent' OR LIS.IncomeType = 'InterimInterest')
;
WITH CTE_InterimRentAmount AS
(
SELECT
ROUND(SUM(LA.ProRateValue * ISNULL(LIS.Payment_Amount,0)), 4) InterimRent_Amount
,LA.AssetId
,CD.LeaseIncomeFirstDate IncomeDate
,CD.ContractId
FROM #LeaseContractDetails CD
INNER JOIN #LeaseAssets LA ON LA.ContractId = CD.ContractId
INNER JOIN #LeaseIncomeSchedules LIS ON LIS.ContractId = CD.ContractId
INNER JOIN #ProrateDateToCompare PD ON CD.ContractId = PD.ContractId AND CD.LeaseIncomeFirstDate = PD.IncomeDate
WHERE (IncomeType = 'InterimRent' OR IncomeType = 'InterimInterest')
AND CD.IsProcessedAlready = 0 AND LIS.IncomeDate <= CD.DueDate
AND (LA.EffectiveFromDate = PD.ProRateDateToCompare)
GROUP BY
LA.AssetId
,CD.ContractId
,CD.LeaseIncomeFirstDate
)
UPDATE #TaxIncomeTaxIncomeSchedules
SET InterimRent_Amount = ISNULL(TIT.InterimRent_Amount, 0) + ISNULL(AIS.InterimRent_Amount, 0)
FROM #TaxIncomeTaxIncomeSchedules TIT
JOIN  CTE_InterimRentAmount AIS ON TIT.ContractId = AIS.ContractId
AND TIT.IncomeDate = AIS.IncomeDate AND TIT.AssetId = AIS.AssetId
;
INSERT INTO #AllBlendedItemDetail (ContractId, Amount_Amount, Amount_Currency, Type, BlendedIncomeDueDate, TaxRecognitionMode, Id, IsAssetBased, IsFAS91)
SELECT
C.ContractId
,BI.Amount_Amount
,BI.Amount_Currency
,BI.Type
,BI.DueDate BlendedIncomeDueDate
,BI.TaxRecognitionMode
,BI.Id
,BI.IsAssetBased
,IsFAS91
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON LF.ContractId = C.ContractId AND LF.IsCurrent = 1
INNER JOIN LeaseBlendedItems LBI on LF.Id = LBI.LeaseFinanceId
INNER JOIN #BlendedItems BI ON LBI.BlendedItemId = BI.Id
WHERE ((BI.Type = 'Income' AND BI.TaxRecognitionMode = '_')  OR
(BI.Type = 'Income' AND BI.TaxRecognitionMode <> '_' AND BI.DueDate <= C.DueDate) OR
(BI.Type != 'Income' AND BI.TaxRecognitionMode  <> '_' AND BI.DueDate <= C.DueDate))
AND ((BI.IsFAS91 = 1 AND BI.TaxRecognitionMode = 'RecognizeImmediately' AND
(BI.DueDate < C.ContractChargeOffDate OR C.ContractChargeOffDate IS NULL)) OR
(BI.IsFAS91 = 1 AND BI.TaxRecognitionMode <> 'RecognizeImmediately') OR BI.IsFAS91 = 0)
AND (BI.DueDate >= C.DateToCheckBlendedItem OR BI.TaxRecognitionMode = 'Amortize')
GROUP BY
C.ContractId
,BI.Amount_Amount
,BI.Amount_Currency
,BI.Type
,BI.DueDate
,BI.TaxRecognitionMode
,BI.Id
,BI.IsAssetBased
,IsFAS91
;
WITH CTE_ASBlendedItemMismatch AS
(
SELECT
DISTINCT ABD.ContractId, BlendedIncomeDueDate
FROM #AllBlendedItemDetail ABD
JOIN #DeferredTaxDetailEntity DTD ON ABD.ContractId = DTD.ContractId
WHERE ABD.BlendedIncomeDueDate NOT IN (SELECT IncomeDate FROM #DeferredTaxDetailEntity WHERE ContractId = ABD.ContractId)
)
,CTE_MinDate AS
(
SELECT
AB.ContractId,
CAB.BlendedIncomeDueDate,
MIN(AB.IncomeDate) IncomeDate
FROM #DeferredTaxDetailEntity AB
JOIN CTE_ASBlendedItemMismatch CAB ON AB.ContractId = CAB.ContractId AND AB.IncomeDate > CAB.BlendedIncomeDueDate
GROUP BY
AB.ContractId,
CAB.BlendedIncomeDueDate
)
UPDATE #AllBlendedItemDetail
SET BlendedIncomeDueDate = MD.IncomeDate
FROM #AllBlendedItemDetail AB
JOIN CTE_MinDate MD ON AB.ContractId = MD.ContractId
AND AB.BlendedIncomeDueDate = MD.BlendedIncomeDueDate
;
WITH CTE_AmortizeBlendedItemDetail AS
(
SELECT
ContractId
,Amount_Amount
,Amount_Currency
,Type
,BlendedIncomeDueDate
,TaxRecognitionMode
,Id
,IsFAS91
FROM #AllBlendedItemDetail
WHERE TaxRecognitionMode = 'Amortize'
AND IsAssetBased = 0
GROUP BY
ContractId
,Amount_Amount
,Amount_Currency
,Type
,BlendedIncomeDueDate
,TaxRecognitionMode
,Id
,IsFAS91
)
INSERT INTO #TaxIncomeTaxNonAssetBasedBlendedItemDetail (ContractId, BlendedIncomeDueDate, Amount_Amount, Amount_Currency, Type,  System, TaxBook, BlendedItemId,TaxDepRateId)
SELECT
ABID.ContractId
,TDAD.DepreciationDate BlendedIncomeDueDate
,TDAD.DepreciationAmount_Amount Amount_Amount
,TDAD.DepreciationAmount_Currency Amount_Currency
,ABID.Type
,CAST('_' AS NVARCHAR(100))
,CAST('_' AS NVARCHAR(100))
,TDE.BlendedItemId
,TDTD.TaxDepRateId
FROM #LeaseContractDetails CD
INNER JOIN CTE_AmortizeBlendedItemDetail ABID ON ABID.ContractId  =CD.Contractid
INNER JOIN #TaxDepEntities TDE ON TDE.EntityType = 'BlendedItem' AND TDE.BlendedItemId = ABID.Id AND CD.ContractId = TDE.ContractId
INNER JOIN #TaxDepAmortizations TDA ON TDA.TaxDepEntityId = TDE.Id
INNER JOIN #TaxDepAmortizationDetails TDAD ON TDAD.TaxDepAmortizationId = TDA.Id
INNER JOIN TaxDepTemplateDetails TDTD ON TDTD.Id = TDAD.TaxDepreciationTemplateDetailId AND  TDTD.TaxBook = 'Federal'
WHERE TDAD.DepreciationAmount_Currency = CD.CurrencyISO
AND (TDAD.DepreciationDate > CD.DeferredTaxDueDate AND TDAD.DepreciationDate <= CD.DueDate)
AND ((ABID.IsFAS91 = 1 AND CD.ContractChargeOffDate IS NULL OR (TDAD.DepreciationDate < CD.ContractChargeOffDate)) OR ABID.IsFAS91 = 0)
GROUP BY
ABID.ContractId
,TDAD.DepreciationDate
,TDAD.DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,ABID.Type
,TDE.BlendedItemId
,TDTD.TaxDepRateId
;
INSERT INTO #TaxIncomeTaxNonAssetBasedBlendedItemDetail (ContractId, BlendedIncomeDueDate, Amount_Amount, Amount_Currency, Type,  System, TaxBook, BlendedItemId)
SELECT
BT.ContractId
,BlendedIncomeDueDate
,Amount_Amount
,Amount_Currency
,Type
,CAST('_' AS NVARCHAR(100))
,CAST('_' AS NVARCHAR(100))
,BT.Id
FROM #AllBlendedItemDetail BT
JOIN #LeaseContractDetails CD ON CD.ContractId = BT.ContractId
WHERE BlendedIncomeDueDate > CD.DeferredTaxDueDate AND TaxRecognitionMode <> 'Amortize'
AND IsAssetBased = 0
GROUP BY
BT.ContractId
,BlendedIncomeDueDate
,Amount_Amount
,Amount_Currency
,Type
,BT.Id
;
SELECT
ContractId
,BlendedIncomeDueDate
,ISNULL(System,'_') System
,ISNULL(TaxBook,'_') TaxBook
,CAST(0.00 AS DECIMAL(16,2)) IncomeAmount_Amount
,Amount_Currency IncomeAmount_Currency
,CAST(0.00 AS DECIMAL(16,2)) IDCExAmount_Amount
,Amount_Currency IDCExAmount_Currency
INTO #TaxIncomeTaxNonAssetBasedBlendedItemDetail_Temp
FROM #TaxIncomeTaxNonAssetBasedBlendedItemDetail
GROUP BY
ContractId
,BlendedIncomeDueDate
,ISNULL(System,'_')
,ISNULL(TaxBook,'_')
,Amount_Currency
,Amount_Currency
;
WITH CTE_IncomeBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Amount_Amount) IncomeAmount_Amount
,Amount_Currency
,BlendedIncomeDueDate
,System
,TaxBook
FROM #TaxIncomeTaxNonAssetBasedBlendedItemDetail
WHERE Type = 'Income'
GROUP BY
ContractId
,Amount_Currency
,BlendedIncomeDueDate
,System
,TaxBook
)
UPDATE #TaxIncomeTaxNonAssetBasedBlendedItemDetail_Temp
SET IncomeAmount_Amount = ISNULL(IBID.IncomeAmount_Amount,0.00),
IncomeAmount_Currency = ISNULL(IBID.Amount_Currency,IncomeAmount_Currency)
FROM #TaxIncomeTaxNonAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IncomeBlendedItemDetails IBID ON C.ContractId = IBID.ContractId
AND C.BlendedIncomeDueDate = IBID.BlendedIncomeDueDate AND C.System = IBID.System AND C.TaxBook = IBID.TaxBook
;
WITH CTE_IDCExBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Amount_Amount) IDCExAmount_Amount
,Amount_Currency
,BlendedIncomeDueDate
,System
,TaxBook
FROM #TaxIncomeTaxNonAssetBasedBlendedItemDetail
WHERE (Type = 'IDC' OR Type = 'Expense')
GROUP BY
ContractId
,Amount_Currency
,BlendedIncomeDueDate
,System
,TaxBook
)
UPDATE #TaxIncomeTaxNonAssetBasedBlendedItemDetail_Temp
SET IDCExAmount_Amount = ISNULL(IDCEBID.IDCExAmount_Amount,0.00),
IDCExAmount_Currency = ISNULL(IDCEBID.Amount_Currency,IncomeAmount_Currency)
FROM #TaxIncomeTaxNonAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IDCExBlendedItemDetails IDCEBID ON C.ContractId = IDCEBID.ContractId
AND C.BlendedIncomeDueDate = IDCEBID.BlendedIncomeDueDate AND C.System = IDCEBID.System AND C.TaxBook = IDCEBID.TaxBook
;
WITH CTE_TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets AS
(
SELECT
ROW_NUMBER() OVER(PARTITION BY BlendedIncomeDueDate,System ORDER BY (ISNULL(IncomeAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ProRateValue) DESC) AS IncomeAmountRowNumber
,ROW_NUMBER() OVER(PARTITION BY BlendedIncomeDueDate,System ORDER BY (ISNULL(IDCExAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ProRateValue) DESC) AS IDCExRowNumber
,C.ContractId
,C.BlendedIncomeDueDate
,ANVD.Amount_Amount
,ANVD.ProRateValue
,ANVD.AssetId
,System
,TaxBook
,(ANVD.ProRateValue * ISNULL(IncomeAmount_Amount,CAST(0.00 AS DECIMAL(16,2)))) IncomeAmount_Amount
,ISNULL(C.IncomeAmount_Currency,CD.CurrencyISO) IncomeAmount_Currency
,ISNULL(IncomeAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) OriginalIncomeAmount_Amount
,(ANVD.ProRateValue * ISNULL(IDCExAmount_Amount,CAST(0.00 AS DECIMAL(16,2)))) IDCExAmount_Amount
,ISNULL(C.IDCExAmount_Currency,CD.CurrencyISO) IDCExAmount_Currency
,ISNULL(IDCExAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) OriginalIDCExAmount_Amount
,DATEPART(yyyy,C.BlendedIncomeDueDate) YearToCalculate
,DATEPART(m,C.BlendedIncomeDueDate) MonthToCalculate
FROM #TaxIncomeTaxNonAssetBasedBlendedItemDetail_Temp C
JOIN #LeaseContractDetails CD ON CD.ContractId = C.ContractId
JOIN #LeaseAssets ANVD ON C.ContractId = ANVD.ContractId
JOIN #ProrateDateToCompare PD ON CD.ContractId = PD.ContractId
AND PD.IncomeDate = C.BlendedIncomeDueDate AND PD.ProRateDateToCompare = ANVD.EffectiveFromDate
)
,CTE_BlendedItemSUMValues AS
(
SELECT
ContractId
,BlendedIncomeDueDate
,OriginalIncomeAmount_Amount
,SUM(IncomeAmount_Amount) SUMIncomeAmount_Amount
,(OriginalIncomeAmount_Amount - SUM(IncomeAmount_Amount)) IncomeAmountDifference
,OriginalIDCExAmount_Amount
,SUM(IDCExAmount_Amount) SUMIDCExAmount_Amount
,(OriginalIDCExAmount_Amount - SUM(IDCExAmount_Amount)) ExAmountDifference
FROM CTE_TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets
GROUP BY
ContractId
,BlendedIncomeDueDate
,OriginalIncomeAmount_Amount
,OriginalIDCExAmount_Amount
)
SELECT
BI.BlendedIncomeDueDate
,AssetId
,System
,TaxBook
,CASE WHEN IncomeAmountRowNumber = 1 THEN IncomeAmount_Amount - IncomeAmountDifference ELSE IncomeAmount_Amount END AS IncomeAmount_Amount
,IncomeAmount_Currency
,CASE WHEN IDCExAmount_Amount = 1 THEN IDCExAmount_Amount - ExAmountDifference ELSE IDCExAmount_Amount END AS IDCExAmount_Amount
,IDCExAmount_Currency
,BI.ContractId
INTO #TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets
FROM CTE_TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets BI
JOIN CTE_BlendedItemSUMValues BS ON BI.ContractId = BS.ContractId
AND BS.BlendedIncomeDueDate = BI.BlendedIncomeDueDate
;
DROP TABLE #TaxIncomeTaxNonAssetBasedBlendedItemDetail_Temp
;
SELECT
*
INTO #TaxIncomeTaxAssetBasedBlendedItemDetail
FROM
(
SELECT
DISTINCT
BID.ContractId
,BID.Amount_Amount
,BID.Amount_Currency
,BID.Type
,BID.BlendedIncomeDueDate
,BID.TaxRecognitionMode
,BID.Id
,LA.AssetId
FROM #AllBlendedItemDetail BID
JOIN #BlendedItems BI ON BID.Id = BI.Id
JOIN #LeaseAssets LA ON BI.LeaseAssetId = LA.Id
WHERE BID.IsAssetBased = 1 AND BI.IsETC = 0
) UR
;
WITH CTE_AmortizeAssetBlendedItemDetail AS
(
SELECT
ContractId
,Amount_Amount
,Amount_Currency
,Type
,BlendedIncomeDueDate
,TaxRecognitionMode
,Id
,AssetId
FROM #TaxIncomeTaxAssetBasedBlendedItemDetail
WHERE TaxRecognitionMode = 'Amortize'
GROUP BY
ContractId
,Amount_Amount
,Amount_Currency
,Type
,BlendedIncomeDueDate
,TaxRecognitionMode
,Id
,AssetId
)
INSERT INTO #TaxIncomeTaxAssetBasedAmortizeBlendedItemDetail (ContractId, BlendedIncomeDueDate, Amount_Amount, Amount_Currency, Type,  System, TaxBook, BlendedItemId, AssetId, TaxDepRateId)
SELECT
ABID.ContractId
,TDAD.DepreciationDate BlendedIncomeDueDate
,TDAD.DepreciationAmount_Amount Amount_Amount
,TDAD.DepreciationAmount_Currency Amount_Currency
,ABID.Type
,CAST('_' AS NVARCHAR(100))
,CAST('_' AS NVARCHAR(100))
,TDE.BlendedItemId
,ABID.AssetId
,TaxDepRateId
FROM #TaxDepAmortizationDetails TDAD
INNER JOIN #TaxDepAmortizations TDA ON TDAD.TaxDepAmortizationId = TDA.Id
INNER JOIN #TaxDepEntities TDE ON TDA.TaxDepEntityId = TDE.Id AND TDE.EntityType = 'BlendedItem'
INNER JOIN TaxDepTemplateDetails TDTD ON TDTD.Id = TDAD.TaxDepreciationTemplateDetailId AND  TDTD.TaxBook = 'Federal'
INNER JOIN CTE_AmortizeAssetBlendedItemDetail ABID ON TDE.BlendedItemId = ABID.Id
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = TDE.ContractId
WHERE TDAD.DepreciationAmount_Currency = CD.CurrencyISO
AND (TDAD.DepreciationDate > CD.DeferredTaxDueDate AND TDAD.DepreciationDate <= CD.DueDate)
GROUP BY
ABID.ContractId
,TDAD.DepreciationDate
,TDAD.DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,ABID.Type
,TDTD.TaxBook
,TDE.BlendedItemId,ABID.AssetId
,TaxDepRateId
;
SELECT
ContractId
,BlendedIncomeDueDate
,CAST(0.00 AS DECIMAL(16,2)) IncomeAmount_Amount
,CAST(0.00 AS DECIMAL(16,2)) IDCExAmount_Amount
,AssetId
INTO #TaxIncomeTaxAssetBasedBlendedItemDetail_Temp
FROM #TaxIncomeTaxAssetBasedAmortizeBlendedItemDetail
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
;
WITH CTE_IncomeBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Amount_Amount) IncomeAmount_Amount
,BlendedIncomeDueDate
,AssetId
FROM #TaxIncomeTaxAssetBasedAmortizeBlendedItemDetail
WHERE Type = 'Income'
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
)
UPDATE #TaxIncomeTaxAssetBasedBlendedItemDetail_Temp
SET IncomeAmount_Amount = ISNULL(IBID.IncomeAmount_Amount,0.00)
FROM #TaxIncomeTaxAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IncomeBlendedItemDetails IBID ON C.ContractId = IBID.ContractId
AND C.BlendedIncomeDueDate = IBID.BlendedIncomeDueDate AND C.AssetId = IBID.AssetId
;
WITH CTE_IDCExBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Amount_Amount) IDCExAmount_Amount
,BlendedIncomeDueDate
,AssetId
FROM #TaxIncomeTaxAssetBasedAmortizeBlendedItemDetail
WHERE (Type = 'IDC' OR Type = 'Expense')
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
)
UPDATE #TaxIncomeTaxAssetBasedBlendedItemDetail_Temp
SET IDCExAmount_Amount = ISNULL(IDCEBID.IDCExAmount_Amount,0.00)
FROM #TaxIncomeTaxAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IDCExBlendedItemDetails IDCEBID ON C.ContractId = IDCEBID.ContractId
AND C.BlendedIncomeDueDate = IDCEBID.BlendedIncomeDueDate AND C.AssetId = IDCEBID.AssetId
;
INSERT INTO #TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets
SELECT
BlendedIncomeDueDate
,AssetId
,CAST('_' AS NVARCHAR(10)) System
,CAST('_' AS NVARCHAR(10)) TaxBook
,IncomeAmount_Amount
,CD.CurrencyISO IncomeAmount_Currency
,IDCExAmount_Amount
,CD.CurrencyISO IDCExAmount_Currency
,CD.ContractId
FROM #TaxIncomeTaxAssetBasedBlendedItemDetail_Temp JOIN #LeaseContractDetails CD
ON #TaxIncomeTaxAssetBasedBlendedItemDetail_Temp.ContractId = CD.ContractId
;
SELECT
ContractId
,BlendedIncomeDueDate
,AssetId
,SUM(IncomeAmount_Amount) IncomeAmount_Amount
,IncomeAmount_Currency
,SUM(IDCExAmount_Amount) IDCExAmount_Amount
,IDCExAmount_Currency
,TaxBook
,System
INTO #TaxIncomeTaxBlendedItemDetails
FROM #TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
,IncomeAmount_Currency
,IDCExAmount_Currency
,TaxBook
,System
;
WITH CTE_TaxNBV AS
(
SELECT
C.ContractId
,LA.AssetId
,TDAD.DepreciationDate
,SUM(TDAD.EndNetBookValue_Amount) DepreciationAmount_Amount
,TDAD.EndNetBookValue_Currency DepreciationAmount_Currency
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON LF.ContractId = C.ContractId
INNER JOIN #LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
INNER JOIN #TaxDepEntities TDE ON TDE.AssetId = LA.AssetId  AND TDE.EntityType = 'Asset'
INNER JOIN #TaxDepAmortizations TDA ON TDE.TaxDepTemplateId = TDA.TaxDepEntityId
INNER JOIN #TaxDepAmortizationDetails TDAD ON TDA.Id = TDAD.TaxDepreciationTemplateDetailId
INNER JOIN TaxDepTemplates TDT ON TDE.TaxDepTemplateId = TDT.Id
INNER JOIN TaxDepTemplateDetails TDTD ON TDTD.TaxDepTemplateId = TDT.Id AND TDTD.TaxBook = 'Federal'
INNER JOIN #AssetValueHistories AV ON AV.AssetId = LA.AssetId AND AV.Value_Currency = TDAD.DepreciationAmount_Currency AND AV.ContractId = C.ContractId AND AV.IsLessorOwned = 1
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
WHERE (TDAD.DepreciationDate > CD.DeferredTaxDueDate 	AND TDAD.DepreciationDate <= CD.DueDate) AND LF.IsCurrent = 1
GROUP BY
C.ContractId
,LA.AssetId
,TDAD.DepreciationDate
,TDAD.EndNetBookValue_Currency
)
,CTE_Proceeds AS
(
SELECT
LF.ContractId
,SUM(ASR.Amount_Amount) ASAmount_Amount
,ASR.Amount_Currency
,ASR.DueDate
,ASD.AssetId
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON LF.ContractId = C.ContractId
INNER JOIN AssetSaleReceivables ASR ON ASR.ContractId = C.ContractId AND ASR.IsActive =1
INNER JOIN AssetSales ASS ON  ASR.AssetSaleId = ASS.Id
INNER JOIN AssetSaleDetails ASD ON ASS.Id = ASD.AssetSaleId
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
WHERE (ASR.DueDate > CD.DeferredTaxDueDate AND ASR.DueDate <= CD.DueDate) AND LF.IsCurrent = 1
AND ASS.Status = 'Completed'
AND ASD.IsActive = 1
GROUP BY
LF.ContractId
,ASR.Amount_Currency
,ASR.DueDate
,ASD.AssetId
)
SELECT
P.ContractId
,(ISNULL(ASAmount_Amount,0) - ISNULL(DepreciationAmount_Amount,0)) ASAmount_Amount
,ISNULL(Amount_Currency, DepreciationAmount_Currency) Amount_Currency
,ISNULL(DueDate,DepreciationDate) DueDate
,P.AssetId
INTO #ASRTaxNBVResult
FROM CTE_Proceeds P
JOIN CTE_TaxNBV TNBV ON P.ContractId = TNBV.ContractId
AND P.DueDate = TNBV.DepreciationDate AND p.AssetId = TNBV.AssetId
ORDER BY DueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeTax_Amount = ROUND(ISNULL(RentalIncome_Amount,0) + ISNULL(InterimRent_Amount,0) + ISNULL(OTPRent_Amount,0),4)
FROM #DeferredTaxDetailEntity TIT
JOIN #TaxIncomeTaxIncomeSchedules ADR ON ADR.ContractId = TIT.ContractId
AND ADR.AssetId = TIT.AssetId AND TIT.IncomeDate = ADR.IncomeDate
JOIN #LeaseContractDetails CD ON CD.ContractId = TIT.ContractId
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeTax_Amount = ROUND(TaxableIncomeTax_Amount + ISNULL(IncomeAmount_Amount,0) - ISNULL(IDCExAmount_Amount,0),4),
TaxDepreciationSystem = CASE WHEN ADR.System IS NOT NULL THEN ADR.System ELSE TIT.TaxDepreciationSystem END,
TaxBookName = CASE WHEN ADR.TaxBook IS NOT NULL THEN ADR.System ELSE TIT.TaxBookName END
FROM #DeferredTaxDetailEntity TIT
JOIN #TaxIncomeTaxBlendedItemDetails ADR ON ADR.ContractId = TIT.ContractId
AND ADR.AssetId = TIT.AssetId AND TIT.IncomeDate = ADR.BlendedIncomeDueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeTax_Amount = ROUND(TaxableIncomeTax_Amount + ISNULL(ASAmount_Amount,0), 4)
FROM #DeferredTaxDetailEntity TIT
JOIN #ASRTaxNBVResult ADR ON ADR.ContractId = TIT.ContractId
AND ADR.AssetId = TIT.AssetId AND TIT.IncomeDate = ADR.DueDate
;
INSERT INTO #TaxIncomeBookIncomeSchedules
SELECT DISTINCT
C.ContractId
,CAST(0 AS BIGINT)
,C.IncomeType
,C.IncomeDate
,CAST(0.00 AS DECIMAL(16,2))
,C.RentalIncome_Currency
,CAST(0.00 AS DECIMAL(16,2))
,C.RentalIncome_Currency
,CAST(0.00 AS DECIMAL(16,2))
,C.RentalIncome_Currency
,C.AssetId
FROM #TaxIncomeTaxIncomeSchedules C
;
DROP TABLE #TaxIncomeTaxIncomeSchedules;
WITH CTE_AISFixedTermAmountDetails AS
(
SELECT
DISTINCT
CD.ContractId
,LF.Id LeaseFinanceId
,LIS.IncomeType
,LIS.IncomeDate
,AIS.AssetId
,LIS.Id
,AIS.LeaseRentalIncome_Amount
,AIS.FinanceRentalIncome_Amount
,AIS.LeaseIncome_Amount
,AIS.FinanceIncome_Amount
,ClassificationContractType
FROM #LeaseFinances LF
INNER JOIN #LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id
INNER JOIN #AssetIncomeSchedules AIS ON AIS.LeaseIncomeScheduleId = LIS.Id
INNER JOIN #TaxDepEntities TDE ON AIS.AssetId = TDE.AssetId  AND TDE.EntityType = 'Asset'
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
WHERE (LIS.IncomeDate > CD.DeferredTaxDueDate  AND LIS.IncomeDate <= CD.DueDate)
AND (LIS.IncomeType = 'FixedTerm' OR (IncomeType = 'InterimRent' OR IncomeType = 'InterimInterest') OR (IncomeType = 'OverTerm' OR IncomeType = 'Supplemental'))
)
UPDATE #TaxIncomeBookIncomeSchedules
SET IncomeType = AIS.IncomeType,
RentalIncome_Amount = CASE WHEN AIS.IncomeType = 'FixedTerm' THEN
--CASE WHEN ClassificationContractType = 'DirectFinance' OR ClassificationContractType = 'ConditionalSales' THEN 
--      (AIS.LeaseIncome_Amount + AIS.FinanceIncome_Amount)
--	  ELSE (AIS.LeaseRentalIncome_Amount + AIS.FinanceRentalIncome_Amount) END 
CASE WHEN ClassificationContractType = 'DirectFinance' OR ClassificationContractType = 'ConditionalSales' THEN (AIS.LeaseIncome_Amount + AIS.FinanceIncome_Amount)  ELSE (AIS.LeaseRentalIncome_Amount + AIS.FinanceRentalIncome_Amount) END
ELSE (TIT.RentalIncome_Amount) END,
InterimRent_Amount = CASE WHEN (AIS.IncomeType = 'InterimRent' OR  AIS.IncomeType = 'InterimInterest') THEN
CASE WHEN (AIS.IncomeType = 'InterimRent') THEN 
    (AIS.LeaseRentalIncome_Amount + AIS.FinanceRentalIncome_Amount) 
 ELSE (AIS.LeaseIncome_Amount + AIS.FinanceIncome_Amount)  END
ELSE TIT.InterimRent_Amount END,
OTPRent_Amount = CASE WHEN (AIS.IncomeType = 'OverTerm' OR  AIS.IncomeType = 'Supplemental') THEN (AIS.LeaseRentalIncome_Amount + AIS.FinanceRentalIncome_Amount) ELSE TIT.OTPRent_Amount END,
AssetId = AIS.AssetId
FROM #TaxIncomeBookIncomeSchedules TIT
JOIN  CTE_AISFixedTermAmountDetails AIS ON TIT.ContractId = AIS.ContractId
AND TIT.IncomeDate = AIS.IncomeDate AND TIT.AssetId = AIS.AssetId
;
UPDATE #TaxIncomeBookIncomeSchedules
SET #TaxIncomeBookIncomeSchedules.RentalIncome_Amount = #TaxIncomeBookIncomeSchedules.RentalIncome_Amount + ISNULL(CustomerIncomeAmount_Amount,0.00)
FROM #TaxIncomeBookIncomeSchedules
INNER JOIN #LeaseFloatRateIncomeResult ON #TaxIncomeBookIncomeSchedules.IncomeDate = #LeaseFloatRateIncomeResult.IncomeDate
AND #TaxIncomeBookIncomeSchedules.ContractId = #LeaseFloatRateIncomeResult.ContractId
AND #TaxIncomeBookIncomeSchedules.AssetId = #LeaseFloatRateIncomeResult.AssetId
;
WITH CTE_InterimRentAmount AS
(
SELECT
SUM(#LeaseAssets.ProRateValue * ISNULL(LIS.Payment_Amount,0)) InterimRent_Amount
,#LeaseAssets.AssetId
,CD.LeaseIncomeFirstDate IncomeDate
,CD.ContractId
FROM #LeaseContractDetails CD
INNER JOIN #LeaseAssets ON #LeaseAssets.ContractId = CD.ContractId
INNER JOIN #LeaseIncomeSchedules LIS ON LIS.ContractId = CD.ContractId
INNER JOIN #ProrateDateToCompare PD ON CD.ContractId = PD.ContractId AND CD.LeaseIncomeFirstDate = PD.IncomeDate
WHERE (IncomeType = 'InterimRent' OR IncomeType = 'InterimInterest')
AND CD.IsProcessedAlready = 0 AND LIS.IncomeDate <= CD.DueDate
AND (#LeaseAssets.EffectiveFromDate = PD.ProRateDateToCompare)
GROUP BY
#LeaseAssets.AssetId
,CD.ContractId
,CD.LeaseIncomeFirstDate
)
UPDATE #TaxIncomeBookIncomeSchedules
SET InterimRent_Amount = ISNULL(TIT.InterimRent_Amount, 0) + ISNULL(AIS.InterimRent_Amount, 0)
FROM #TaxIncomeBookIncomeSchedules TIT
JOIN  CTE_InterimRentAmount AIS ON TIT.ContractId = AIS.ContractId
AND TIT.IncomeDate = AIS.IncomeDate AND TIT.AssetId = AIS.AssetId
;
INSERT INTO #AllBlendedItemIncomeDetails (ContractId, Income_Amount, Income_Currency, Type, BlendedIncomeDueDate, IsAssetBased, Id)
SELECT ContractId, ISNULL(Income_Amount, 0.00) , Income_Currency, Type, BlendedIncomeDueDate, IsAssetBased, Id FROM
(
SELECT
C.ContractId
,BIS.Income_Amount Income_Amount
,BIS.Income_Currency
,BI.Type
,BIS.IncomeDate BlendedIncomeDueDate
,BI.IsAssetBased
,BI.Id
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON LF.ContractId = C.ContractId AND LF.IsCurrent = 1
INNER JOIN LeaseBlendedItems LBI ON LBI.LeaseFinanceId = LF.Id
INNER JOIN #BlendedItems BI ON LBI.BlendedItemId = BI.Id
INNER JOIN #BlendedIncomeSchedules BIS ON BIS.BlendedItemId = BI.Id
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
WHERE (BIS.IncomeDate > CD.DeferredTaxDueDate AND BIS.IncomeDate <= CD.DueDate) AND BI.BookRecognitionMode <> 'Accrete'
UNION ALL
SELECT
C.ContractId
,BI.Amount_Amount Income_Amount
,BI.Amount_Currency Income_Currency
,BI.Type
,BI.DueDate BlendedIncomeDueDate
,BI.IsAssetBased
,BI.Id
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON LF.ContractId = C.ContractId AND LF.IsCurrent = 1
INNER JOIN LeaseBlendedItems LBI ON LBI.LeaseFinanceId = LF.Id
INNER JOIN #BlendedItems BI ON LBI.BlendedItemId = BI.Id
WHERE
(BI.DueDate >= C.DateToCheckBlendedItem AND BI.DueDate <= C.DueDate) AND BI.BookRecognitionMode = 'RecognizeImmediately'
) UR
GROUP BY
ContractId, Income_Amount, Income_Currency, Type, BlendedIncomeDueDate, IsAssetBased, Id
;
WITH CTE_ASBlendedItemMismatch AS
(
SELECT
DISTINCT ABD.ContractId, BlendedIncomeDueDate
FROM #AllBlendedItemIncomeDetails ABD
JOIN #DeferredTaxDetailEntity DTD ON ABD.ContractId = DTD.ContractId
WHERE ABD.BlendedIncomeDueDate NOT IN (SELECT IncomeDate FROM #DeferredTaxDetailEntity WHERE ContractId = ABD.ContractId)
)
,CTE_MinDate AS
(
SELECT
AB.ContractId,
CAB.BlendedIncomeDueDate,
MIN(AB.IncomeDate) IncomeDate
FROM #DeferredTaxDetailEntity AB
JOIN CTE_ASBlendedItemMismatch CAB ON AB.ContractId = CAB.ContractId AND AB.IncomeDate > CAB.BlendedIncomeDueDate
GROUP BY
AB.ContractId,
CAB.BlendedIncomeDueDate
)
UPDATE #AllBlendedItemIncomeDetails
SET BlendedIncomeDueDate = MD.IncomeDate
FROM #AllBlendedItemIncomeDetails AB
JOIN CTE_MinDate MD ON AB.ContractId = MD.ContractId
AND AB.BlendedIncomeDueDate = MD.BlendedIncomeDueDate
;
SELECT
ContractId
,BlendedIncomeDueDate
,CAST(0.00 AS DECIMAL(16,2)) IncomeAmount_Amount
,CAST(0.00 AS DECIMAL(16,2)) IDCExAmount_Amount
INTO #TaxIncomeBookNonAssetBasedBlendedItemDetail_Temp
FROM #AllBlendedItemIncomeDetails
GROUP BY
ContractId
,BlendedIncomeDueDate
;
WITH CTE_IncomeBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Income_Amount) IncomeAmount_Amount
,BlendedIncomeDueDate
FROM #AllBlendedItemIncomeDetails
WHERE Type = 'Income' AND IsAssetBased = 0
GROUP BY
ContractId
,BlendedIncomeDueDate
)
UPDATE #TaxIncomeBookNonAssetBasedBlendedItemDetail_Temp
SET IncomeAmount_Amount = ISNULL(IBID.IncomeAmount_Amount,0.00)
FROM #TaxIncomeBookNonAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IncomeBlendedItemDetails IBID ON C.ContractId = IBID.ContractId
AND C.BlendedIncomeDueDate = IBID.BlendedIncomeDueDate
;
WITH CTE_IDCExBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Income_Amount) IDCExAmount_Amount
,BlendedIncomeDueDate
FROM #AllBlendedItemIncomeDetails
WHERE (Type = 'IDC' OR Type = 'Expense') AND IsAssetBased = 0
GROUP BY
ContractId
,BlendedIncomeDueDate
)
UPDATE #TaxIncomeBookNonAssetBasedBlendedItemDetail_Temp
SET IDCExAmount_Amount = ISNULL(IDCEBID.IDCExAmount_Amount,0.00)
FROM #TaxIncomeBookNonAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IDCExBlendedItemDetails IDCEBID ON C.ContractId = IDCEBID.ContractId
AND C.BlendedIncomeDueDate = IDCEBID.BlendedIncomeDueDate
;
WITH CTE_TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets AS
(
SELECT
ROW_NUMBER() OVER(PARTITION BY BlendedIncomeDueDate ORDER BY (ISNULL(IncomeAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ProRateValue) DESC) AS IncomeAmountRowNumber
,ROW_NUMBER() OVER(PARTITION BY BlendedIncomeDueDate ORDER BY (ISNULL(IDCExAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ProRateValue) DESC) AS IDCExRowNumber
,C.ContractId
,C.BlendedIncomeDueDate
,ANVD.Amount_Amount
,ANVD.ProRateValue
,ANVD.AssetId
,(ANVD.ProRateValue * ISNULL(IncomeAmount_Amount,CAST(0.00 AS DECIMAL(16,2)))) IncomeAmount_Amount
,ISNULL(IncomeAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) OriginalIncomeAmount_Amount
,(ANVD.ProRateValue * ISNULL(IDCExAmount_Amount,CAST(0.00 AS DECIMAL(16,2)))) IDCExAmount_Amount
,ISNULL(IDCExAmount_Amount,CAST(0.00 AS DECIMAL(16,2))) OriginalIDCExAmount_Amount
,DATEPART(yyyy,C.BlendedIncomeDueDate) YearToCalculate
,DATEPART(m,C.BlendedIncomeDueDate) MonthToCalculate
FROM #TaxIncomeBookNonAssetBasedBlendedItemDetail_Temp C
JOIN #LeaseContractDetails CD ON CD.ContractId = C.ContractId
JOIN #LeaseAssets ANVD  ON C.ContractId = ANVD.ContractId
JOIN #ProrateDateToCompare PD ON CD.ContractId = PD.ContractId
AND PD.IncomeDate = C.BlendedIncomeDueDate AND PD.ProRateDateToCompare = ANVD.EffectiveFromDate
)
,CTE_BlendedItemSUMValues AS
(
SELECT
ContractId
,BlendedIncomeDueDate
,OriginalIncomeAmount_Amount
,SUM(IncomeAmount_Amount) SUMIncomeAmount_Amount
,(OriginalIncomeAmount_Amount - SUM(IncomeAmount_Amount)) IncomeAmountDifference
,OriginalIDCExAmount_Amount
,SUM(IDCExAmount_Amount) SUMIDCExAmount_Amount
,(OriginalIDCExAmount_Amount - SUM(IDCExAmount_Amount)) ExAmountDifference
FROM CTE_TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets
GROUP BY
ContractId
,BlendedIncomeDueDate
,OriginalIncomeAmount_Amount
,OriginalIDCExAmount_Amount
)
SELECT
BI.ContractId
,BI.BlendedIncomeDueDate
,AssetId
,CASE WHEN IncomeAmountRowNumber = 1 THEN IncomeAmount_Amount - IncomeAmountDifference ELSE IncomeAmount_Amount END AS IncomeAmount_Amount
,CD.CurrencyISO IncomeAmount_Currency
,CASE WHEN IDCExAmount_Amount = 1 THEN IDCExAmount_Amount - ExAmountDifference ELSE IDCExAmount_Amount END AS IDCExAmount_Amount
,CD.CurrencyISO IDCExAmount_Currency
INTO #TaxIncomeBookNonAssetBasedBlendedItemDetailWithAssets
FROM CTE_TaxIncomeTaxNonAssetBasedBlendedItemDetailWithAssets BI
JOIN CTE_BlendedItemSUMValues BS ON BI.ContractId = BS.ContractId
AND BS.BlendedIncomeDueDate = BI.BlendedIncomeDueDate
JOIN #LeaseContractDetails CD ON CD.ContractId = BI.ContractId
;
DROP TABLE #TaxIncomeBookNonAssetBasedBlendedItemDetail_Temp
;
SELECT
*
INTO #TaxIncomeBookAssetBasedBlendedItemDetail
FROM
(
SELECT
BIID.ContractId
,BIA.TaxCredit_Amount Income_Amount
,BIID.Income_Currency
,BIID.Type
,BIID.BlendedIncomeDueDate
,BIID.IsAssetBased
,BIID.Id
,LA.AssetId
FROM #AllBlendedItemIncomeDetails BIID
JOIN #BlendedItems BI ON BIID.Id = BI.Id
JOIN BlendedItemAssets BIA ON BIA.BlendedItemId = BI.Id
JOIN #LeaseAssets LA ON BIA.LeaseAssetId = LA.Id
WHERE BIID.IsAssetBased = 1 AND BI.IsETC = 1
UNION
SELECT
BIID.ContractId
,BIID.Income_Amount
,BIID.Income_Currency
,BIID.Type
,BIID.BlendedIncomeDueDate
,BIID.IsAssetBased
,BIID.Id
,LA.AssetId
FROM #AllBlendedItemIncomeDetails BIID
JOIN #BlendedItems BI ON BIID.Id = BI.Id
JOIN #LeaseAssets LA ON BI.LeaseAssetId = LA.Id
WHERE BIID.IsAssetBased  = 1 AND BI.IsETC = 0
) UR
;
SELECT
ContractId
,BlendedIncomeDueDate
,CAST(0.00 AS DECIMAL(16,2)) IncomeAmount_Amount
,CAST(0.00 AS DECIMAL(16,2)) IDCExAmount_Amount
,AssetId
INTO #TaxIncomeBookAssetBasedBlendedItemDetail_Temp
FROM #TaxIncomeBookAssetBasedBlendedItemDetail
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
;
WITH CTE_IncomeBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Income_Amount) IncomeAmount_Amount
,BlendedIncomeDueDate
,AssetId
FROM #TaxIncomeBookAssetBasedBlendedItemDetail
WHERE Type = 'Income'
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
)
UPDATE #TaxIncomeBookAssetBasedBlendedItemDetail_Temp
SET IncomeAmount_Amount = ISNULL(IBID.IncomeAmount_Amount,0.00)
FROM #TaxIncomeBookAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IncomeBlendedItemDetails IBID ON C.ContractId = IBID.ContractId
AND C.BlendedIncomeDueDate = IBID.BlendedIncomeDueDate AND C.AssetId = IBID.AssetId
;
WITH CTE_IDCExBlendedItemDetails AS
(
SELECT
ContractId
,SUM(Income_Amount) IDCExAmount_Amount
,BlendedIncomeDueDate
,AssetId
FROM #TaxIncomeBookAssetBasedBlendedItemDetail
WHERE (Type = 'IDC' OR Type = 'Expense')
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
)
UPDATE #TaxIncomeBookAssetBasedBlendedItemDetail_Temp
SET IDCExAmount_Amount = ISNULL(IDCEBID.IDCExAmount_Amount,0.00)
FROM #TaxIncomeBookAssetBasedBlendedItemDetail_Temp C
JOIN CTE_IDCExBlendedItemDetails IDCEBID ON C.ContractId = IDCEBID.ContractId
AND C.BlendedIncomeDueDate = IDCEBID.BlendedIncomeDueDate AND C.AssetId = IDCEBID.AssetId
;
INSERT INTO #TaxIncomeBookNonAssetBasedBlendedItemDetailWithAssets
SELECT
CD.ContractId
,BlendedIncomeDueDate
,AssetId
,IncomeAmount_Amount
,CD.CurrencyISO IncomeAmount_Currency
,IDCExAmount_Amount
,CD.CurrencyISO IDCExAmount_Currency
FROM #TaxIncomeBookAssetBasedBlendedItemDetail_Temp JOIN #LeaseContractDetails
ON #TaxIncomeBookAssetBasedBlendedItemDetail_Temp.ContractId = #LeaseContractDetails.ContractId
JOIN #LeaseContractDetails CD ON CD.ContractId = #TaxIncomeBookAssetBasedBlendedItemDetail_Temp.ContractId
;
SELECT
ContractId
,BlendedIncomeDueDate
,AssetId
,SUM(IncomeAmount_Amount) IncomeAmount_Amount
,IncomeAmount_Currency
,SUM(IDCExAmount_Amount) IDCExAmount_Amount
,IDCExAmount_Currency
INTO #TaxIncomeBookBlendedItemDetails
FROM #TaxIncomeBookNonAssetBasedBlendedItemDetailWithAssets
GROUP BY
ContractId
,BlendedIncomeDueDate
,AssetId
,IncomeAmount_Currency
,IDCExAmount_Currency
;
WITH CTE_BookNBV AS
(
SELECT
CD.ContractId
,AV.IncomeDate
,SUM(AV.Value_Amount) Value_Amount
,AV.Value_Currency
,AV.AssetId
FROM #LeaseContractDetails CD
INNER JOIN BookDepreciations BD ON BD.ContractId = CD.ContractId
INNER JOIN #LeaseAssets LA ON LA.ContractId = CD.ContractId
INNER JOIN #TaxDepEntities TDE ON LA.AssetId = TDE.AssetId AND TDE.EntityType = 'Asset'
INNER JOIN #AssetValueHistories AV ON AV.AssetId = TDE.AssetId AND AV.Value_Currency = CD.CurrencyISO AND AV.ContractId = CD.ContractId
WHERE (AV.IncomeDate > CD.DeferredTaxDueDate AND AV.IncomeDate <= CD.DueDate)
AND TDE.ContractId = CD.ContractId
AND AV.IsLessorOwned = 1
GROUP BY
CD.ContractId
,AV.IncomeDate
,AV.Value_Currency
,AV.AssetId
)
,CTE_Proceeds AS
(
SELECT
LF.ContractId
,SUM(ASR.Amount_Amount) ASAmount_Amount
,ASR.Amount_Currency
,ASR.DueDate
,LA.AssetId
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON LF.ContractId = C.ContractId AND LF.IsCurrent = 1
INNER JOIN AssetSaleReceivables ASR ON ASR.ContractId = C.ContractId AND ASR.IsActive =1
INNER JOIN #LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
INNER JOIN AssetSales ASS ON  ASR.AssetSaleId = ASS.Id
INNER JOIN AssetSaleDetails ASD ON ASS.Id = ASD.AssetSaleId
INNER JOIN #TaxDepEntities TDE ON LA.AssetId = TDE.AssetId AND TDE.EntityType = 'Asset'
INNER JOIN #LeaseContractDetails CD ON CD.ContractId =LF.ContractId
WHERE (ASR.DueDate > CD.DeferredTaxDueDate AND ASR.DueDate <= CD.DueDate)
AND ASS.Status = 'Completed'
AND ASD.IsActive = 1
AND LF.IsCurrent = 1
GROUP BY
LF.ContractId
,ASR.Amount_Currency
,ASR.DueDate
,LA.AssetId
)
SELECT
P.ContractId
,(ISNULL(ASAmount_Amount,0) - ISNULL(Value_Amount,0)) ASAmount_Amount
,ISNULL(Amount_Currency, Value_Currency) Amount_Currency
,ISNULL(DueDate,IncomeDate) DueDate
,P.AssetId
INTO #ASRTaxIncomeBookNBVResult
FROM CTE_Proceeds P
JOIN CTE_BookNBV BNBV ON P.ContractId = BNBV.ContractId
AND P.DueDate = BNBV.IncomeDate AND P.AssetId = BNBV.AssetId
ORDER BY P.DueDate
;
SELECT
CD.ContractId
,SUM(WDAS.WriteDownAmount_Amount) Amount_Amount
,WDAS.WriteDownAmount_Currency Amount_Currency
,WD.WriteDownDate DueDate
,WD.IsRecovery IsRecovery
,CAST('WriteDown' AS NVARCHAR(50)) Entity
INTO #WriteDownAndChargeOffAndValuationAllowanceDetails
FROM #LeaseContractDetails CD
INNER JOIN #LeaseFinances LF ON CD.ContractId = LF.ContractId AND LF.IsCurrent = 1
INNER JOIN #LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
INNER JOIN WriteDownAssetDetails WDAS ON LA.AssetId = WDAS.AssetId
INNER JOIN WriteDowns WD ON WDAS.WriteDownId = WD.Id
WHERE (WD.WriteDownDate > ISNULL(CD.DateToTakeOldDeferredTax, CAST(DATEADD(DAY, -1, CD.CommencementDate) AS DATE)) AND WD.WriteDownDate <= CD.DueDate) AND
WDAS.IsActive = 1 AND WD.IsActive = 1 AND LF.IsCurrent = 1
AND WD.Status = 'Approved'
GROUP BY
CD.ContractId
,WDAS.WriteDownAmount_Currency
,WD.WriteDownDate
,WD.IsRecovery
;
INSERT INTO #WriteDownAndChargeOffAndValuationAllowanceDetails
SELECT
CO.ContractId
,SUM(ChargeOffAmount_Amount) Amount_Amount
,ChargeOffAmount_Currency Amount_Currency
,ChargeOffDate DueDate
,CO.IsRecovery
,CAST('ChargeOff' AS NVARCHAR(50)) Entity
FROM #LeaseContractDetails C
INNER JOIN ChargeOffs CO ON CO.ContractId = C.ContractId
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = CO.ContractId
WHERE (CO.ChargeOffDate > ISNULL(CD.DateToTakeOldDeferredTax, CAST(DATEADD(DAY, -1, CD.CommencementDate) AS DATE)) AND CO.ChargeOffDate <= CD.DueDate)
AND CO.IsActive = 1 AND CO.Status = 'Approved'
GROUP BY
CO.ContractId
,ChargeOffAmount_Currency
,ChargeOffDate
,CO.IsRecovery
;
INSERT INTO #WriteDownAndChargeOffAndValuationAllowanceDetails
SELECT
VA.ContractId
,SUM(Allowance_Amount) Amount_Amount
,Allowance_Currency Amount_Currency
,PostDate DueDate
,CAST(0 AS BIT) IsRecovery
,CAST('ValuationAllowance' AS NVARCHAR(50)) Entity
FROM #LeaseContractDetails C
INNER JOIN ValuationAllowances VA ON VA.ContractId = C.ContractId AND VA.IsActive = 1
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = VA.ContractId
WHERE (VA.PostDate > ISNULL(CD.DateToTakeOldDeferredTax, CAST(DATEADD(DAY, -1, CD.CommencementDate) AS DATE)) AND VA.PostDate <= CD.DueDate)
GROUP BY
VA.ContractId
,Allowance_Currency
,PostDate
;
WITH CTE_WDCOVAMismatch AS
(
SELECT
DISTINCT WDCOVAD.ContractId, WDCOVAD.DueDate WDCOVADDueDate
FROM #WriteDownAndChargeOffAndValuationAllowanceDetails WDCOVAD
JOIN #DeferredTaxDetailEntity DTD ON WDCOVAD.ContractId = DTD.ContractId
WHERE WDCOVAD.DueDate NOT IN (SELECT IncomeDate FROM #DeferredTaxDetailEntity WHERE ContractId = WDCOVAD.ContractId)
)
,CTE_MinDate AS
(
SELECT
AB.ContractId,
CAB.WDCOVADDueDate,
MIN(AB.IncomeDate) IncomeDate
FROM #DeferredTaxDetailEntity AB
JOIN CTE_WDCOVAMismatch CAB ON AB.ContractId = CAB.ContractId AND AB.IncomeDate > CAB.WDCOVADDueDate
GROUP BY
AB.ContractId,
CAB.WDCOVADDueDate
)
UPDATE #WriteDownAndChargeOffAndValuationAllowanceDetails
SET DueDate = MD.IncomeDate
FROM #WriteDownAndChargeOffAndValuationAllowanceDetails LIS
JOIN CTE_MinDate MD ON LIS.ContractId = MD.ContractId
AND LIS.DueDate = MD.WDCOVADDueDate
;
WITH CTE_AmountDetailWithAssets AS
(
SELECT
ROW_NUMBER() OVER(PARTITION BY C.DueDate ORDER BY (ISNULL(C.Amount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ProRateValue) DESC) AS AmountRowNumber
,C.ContractId
,C.DueDate
,ANVD.AssetId
,(ISNULL(C.Amount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ANVD.ProRateValue) Amount_Amount
,ISNULL(C.Amount_Amount,CAST(0.00 AS DECIMAL(16,2))) OriginalAmount_Amount
,IsRecovery
,Entity
FROM #WriteDownAndChargeOffAndValuationAllowanceDetails C
JOIN #LeaseContractDetails CD ON CD.ContractId = C.ContractId
JOIN #LeaseAssets ANVD  ON C.ContractId = ANVD.ContractId
JOIN #ProrateDateToCompare PD ON CD.ContractId = PD.ContractId
AND PD.IncomeDate = C.DueDate AND PD.ProRateDateToCompare = ANVD.EffectiveFromDate
)
,CTE_SUMValues AS
(
SELECT
ContractId
,DueDate
,OriginalAmount_Amount
,SUM(Amount_Amount) SUMIncomeAmount_Amount
,(OriginalAmount_Amount - SUM(Amount_Amount)) AmountDifference
,Entity
,IsRecovery
FROM CTE_AmountDetailWithAssets
GROUP BY
ContractId
,DueDate
,OriginalAmount_Amount
,Entity
,IsRecovery
)
SELECT
BI.ContractId
,BI.DueDate
,AssetId
,CASE WHEN AmountRowNumber = 1 THEN Amount_Amount - AmountDifference ELSE Amount_Amount END AS Amount_Amount
,CD.CurrencyISO IncomeAmount_Currency
,BI.IsRecovery
,BI.Entity
INTO #WriteDownAndChargeOffAndValuationAllowanceDetailWithAssets
FROM CTE_AmountDetailWithAssets BI
JOIN #LeaseContractDetails CD ON CD.ContractId = BI.ContractId
JOIN CTE_SUMValues BS ON BI.ContractId = BS.ContractId AND BS.DueDate = BI.DueDate
AND BI.Entity = BS.Entity AND BI.IsRecovery = BS.IsRecovery
;
SELECT
VART.DueDate
,VART.ContractId
,VART.AssetId
,SUM(VART.Amount_Amount) ValuationAllowance_Amount
,VART.IncomeAmount_Currency ValuationAllowance_Currency
INTO #ValuationAllowanceResult
FROM #WriteDownAndChargeOffAndValuationAllowanceDetailWithAssets VART
WHERE Entity = 'ValuationAllowance'
GROUP BY
VART.DueDate
,VART.ContractId
,VART.AssetId
,VART.IncomeAmount_Currency
;
SELECT
COWAD.ContractId
,COWAD.DueDate
,COWAD.AssetId
,SUM(COWAD.Amount_Amount) ChargeOffAmount_Amount
,COWAD.IncomeAmount_Currency ChargeOffAmount_Currency
INTO #ChargeOffResult
FROM #WriteDownAndChargeOffAndValuationAllowanceDetailWithAssets COWAD
WHERE Entity = 'ChargeOff'
GROUP BY
COWAD.ContractId
,COWAD.DueDate
,COWAD.AssetId
,COWAD.IncomeAmount_Currency
;
SELECT
ContractId
,SUM(Amount_Amount) GrossWriteDownAmount_Amount
,IncomeAmount_Currency WriteDownAmount_Currency
,DueDate WriteDownDate
,CAST(0.00 AS Decimal(16,2)) RecoveryAmount_Amount
,CAST(NULL AS NVARCHAR(10)) RecoveryAmount_Currency
,AssetId
INTO #WriteDownDetailResult
FROM #WriteDownAndChargeOffAndValuationAllowanceDetailWithAssets
WHERE Entity = 'WriteDown'
GROUP BY
ContractId
,IncomeAmount_Currency
,DueDate
,AssetId
;
WITH CTE_ChargeOffAndWriteDownRecovery AS
(
SELECT
ContractId
,CASE WHEN Entity = 'WriteDown' THEN ISNULL(Amount_Amount,0.00) ELSE CAST(0.00 AS Decimal(16,2)) END AS WriteDownAmount_Amount
,CASE WHEN Entity = 'ChargeOff' THEN ISNULL(Amount_Amount,0.00) ELSE CAST(0.00 AS Decimal(16,2)) END AS ChargeOffAmount_Amount
,IncomeAmount_Currency IncomeAmount_Currency
,DueDate
,AssetId
FROM #WriteDownAndChargeOffAndValuationAllowanceDetailWithAssets
WHERE (Entity = 'WriteDown' OR Entity = 'ChargeOff') AND IsRecovery = 1
)
,CTE_RecoveryDetails AS
(
SELECT
ContractId
,SUM(ISNULL(WriteDownAmount_Amount,0)) - (SUM(ISNULL(ChargeOffAmount_Amount,0))  * -1) RecoveryAmount_Amount
,IncomeAmount_Currency RecoveryAmount_Currency
,DueDate
,AssetId
FROM CTE_ChargeOffAndWriteDownRecovery
GROUP BY
ContractId
,IncomeAmount_Currency
,DueDate
,AssetId
)
UPDATE #WriteDownDetailResult
SET RecoveryAmount_Amount = RD.RecoveryAmount_Amount
FROM #WriteDownDetailResult WD JOIN CTE_RecoveryDetails RD
ON WD.ContractId = RD.ContractId AND WD.AssetId = RD.AssetId AND WD.WriteDownDate = RD.DueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeBook_Amount = ROUND(ISNULL(RentalIncome_Amount,0) + ISNULL(InterimRent_Amount,0) + ISNULL(OTPRent_Amount,0),4)
FROM #DeferredTaxDetailEntity TIT
JOIN #TaxIncomeBookIncomeSchedules ADR ON ADR.ContractId = TIT.ContractId
AND ADR.AssetId = TIT.AssetId AND TIT.IncomeDate = ADR.IncomeDate
JOIN #LeaseContractDetails CD ON CD.ContractId = TIT.ContractId
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeBook_Amount = ROUND(TaxableIncomeBook_Amount + ISNULL(IncomeAmount_Amount,0) - ISNULL(IDCExAmount_Amount,0),4)
FROM #DeferredTaxDetailEntity TIT
JOIN #TaxIncomeBookBlendedItemDetails ADR ON ADR.ContractId = TIT.ContractId
AND ADR.AssetId = TIT.AssetId AND TIT.IncomeDate = ADR.BlendedIncomeDueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeBook_Amount = ROUND(TaxableIncomeBook_Amount + ISNULL(ASAmount_Amount,0),4)
FROM #DeferredTaxDetailEntity TIT
JOIN #ASRTaxNBVResult ADR ON ADR.ContractId = TIT.ContractId
AND ADR.AssetId = TIT.AssetId AND TIT.IncomeDate = ADR.DueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeBook_Amount = ROUND(TaxableIncomeBook_Amount - ValuationAllowance_Amount,4)
FROM #DeferredTaxDetailEntity TIT
JOIN #ValuationAllowanceResult ADR ON ADR.ContractId = TIT.ContractId
AND ADR.AssetId = TIT.AssetId AND TIT.IncomeDate = ADR.DueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeBook_Amount = ROUND(TaxableIncomeBook_Amount - CO.ChargeOffAmount_Amount,4)
FROM #DeferredTaxDetailEntity TIT
JOIN #ChargeOffResult CO ON CO.ContractId = TIT.ContractId
AND CO.AssetId = TIT.AssetId AND TIT.IncomeDate = CO.DueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeBook_Amount = ROUND(TaxableIncomeBook_Amount + RecoveryAmount_Amount - GrossWriteDownAmount_Amount,4)
FROM #DeferredTaxDetailEntity TIT
JOIN #WriteDownDetailResult WD ON WD.ContractId = TIT.ContractId
AND WD.AssetId = TIT.AssetId AND TIT.IncomeDate = WD.WriteDownDate
;
SELECT
DISTINCT CD.ContractId, RFT.ActualProceeds_Amount Amount_Amount, LPS.EndDate DueDate
INTO #ReceivableForTransfers
FROM ReceivableForTransfers RFT
JOIN #LeaseContractDetails CD ON RFT.ContractId = CD.ContractId
JOIN LeasePaymentSchedules LPS ON RFT.LeasePaymentId = LPS.Id
WHERE LPS.EndDate > CD.DeferredTaxDueDate AND LPS.EndDate <= CD.DueDate
;
WITH CTE_AmountDetailWithAssets AS
(
SELECT
ROW_NUMBER() OVER(PARTITION BY C.DueDate ORDER BY (ISNULL(C.Amount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ProRateValue) DESC) AS AmountRowNumber
,C.ContractId
,C.DueDate
,ANVD.AssetId
,(ISNULL(C.Amount_Amount,CAST(0.00 AS DECIMAL(16,2))) * ANVD.ProRateValue) Amount_Amount
,ISNULL(C.Amount_Amount,CAST(0.00 AS DECIMAL(16,2))) OriginalAmount_Amount
FROM #ReceivableForTransfers C
JOIN #LeaseContractDetails CD ON CD.ContractId = C.ContractId
JOIN #LeaseAssets ANVD  ON C.ContractId = ANVD.ContractId
JOIN #ProrateDateToCompare PD ON CD.ContractId = PD.ContractId
AND PD.IncomeDate = C.DueDate AND PD.ProRateDateToCompare = ANVD.EffectiveFromDate
)
,CTE_SUMValues AS
(
SELECT
ContractId
,DueDate
,OriginalAmount_Amount
,SUM(Amount_Amount) SUMIncomeAmount_Amount
,(OriginalAmount_Amount - SUM(Amount_Amount)) AmountDifference
FROM CTE_AmountDetailWithAssets
GROUP BY
ContractId
,DueDate
,OriginalAmount_Amount
)
SELECT
BI.ContractId
,BI.DueDate
,AssetId
,CASE WHEN AmountRowNumber = 1 THEN Amount_Amount - AmountDifference ELSE Amount_Amount END AS Amount_Amount
,CD.CurrencyISO IncomeAmount_Currency
INTO #ReceivableForTransferWithAssets
FROM CTE_AmountDetailWithAssets BI
JOIN #LeaseContractDetails CD ON CD.ContractId = BI.ContractId
JOIN CTE_SUMValues BS ON BI.ContractId = BS.ContractId AND BS.DueDate = BI.DueDate
;
UPDATE #DeferredTaxDetailEntity
SET TaxableIncomeTax_Amount = ROUND(TaxableIncomeTax_Amount + Amount_Amount,4),
TaxableIncomeBook_Amount = ROUND(TaxableIncomeBook_Amount + Amount_Amount,4)
FROM #DeferredTaxDetailEntity TIT
JOIN #ReceivableForTransferWithAssets WD ON WD.ContractId = TIT.ContractId
AND WD.AssetId = TIT.AssetId AND TIT.IncomeDate = WD.DueDate
;
WITH CTE_BookDepreciation AS
(
SELECT
C.ContractId
,AVH.Value_Amount
,AVH.Value_Currency
,AVH.IncomeDate
,AVH.AssetId
FROM #LeaseContractDetails C
INNER JOIN #LeaseFinances LF ON LF.ContractId = C.ContractId
INNER JOIN #LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
INNER JOIN #AssetValueHistories AVH ON LA.AssetId = AVH.AssetId AND C.ContractId = AVH.ContractId
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
WHERE (AVH.IncomeDate > CD.DeferredTaxDueDate AND AVH.IncomeDate <= CD.DueDate)
AND (AVH.SourceModule ='FixedTermDepreciation' OR AVH.SourceModule ='OTPDepreciation')
AND AVH.IsLessorOwned = 1
GROUP BY
C.ContractId
,AVH.Value_Amount
,AVH.Value_Currency
,AVH.IncomeDate
,AVH.AssetId
)
,CTE_BookDepreciationResult AS
(
SELECT
BD.ContractId
,SUM(BD.Value_Amount) Value_Amount
,BD.Value_Currency
,BD.IncomeDate
,BD.AssetId
FROM CTE_BookDepreciation BD
GROUP BY
BD.ContractId
,BD.Value_Currency
,BD.IncomeDate
,BD.AssetId
)
UPDATE #DeferredTaxDetailEntity
SET BookDepreciation_Amount = ISNULL(Value_Amount,0.00) * -1,
BookDepreciation_Currency = ISNULL(Value_Currency,ContractCurrency)
FROM #DeferredTaxDetailEntity TIT
JOIN CTE_BookDepreciationResult CD ON CD.ContractId = TIT.ContractId
AND CD.AssetId = TIT.AssetId AND TIT.IncomeDate = CD.IncomeDate
;
INSERT INTO #DeferredTaxDetailEntity
SELECT
ContractId
,AssetId
,TaxBookName
,TaxDepreciationSystem
,FiscalYear
,IncomeDate
,TaxableIncomeTax_Amount
,TaxableIncomeTax_Currency
,TaxableIncomeBook_Amount
,TaxableIncomeBook_Currency
,BookDepreciation_Amount
,BookDepreciation_Currency
,TaxDepreciation_Amount
,TaxDepreciation_Currency
,TaxIncome_Amount
,TaxIncome_Currency
,BookIncome_Amount
,BookIncome_Currency
,IncomeTaxExpense_Amount
,IncomeTaxExpense_Currency
,IncomeTaxPayable_Amount
,IncomeTaxPayable_Currency
,DefTaxLiabBalance_Amount
,DefTaxLiabBalance_Currency
,MTDDeferredTax_Amount
,MTDDeferredTax_Currency
,YTDDeferredTax_Amount
,YTDDeferredTax_Currency
,AccumDefTaxLiabBalance_Amount
,AccumDefTaxLiabBalance_Currency
,CreatedById
,CreatedTime
,ContractCurrency
,FITRate
,MonthToCalculate
,YearToCalculate
,IsGLPosted
,IsReprocess
,IsAccounting
,IsScheduled
,IsLeveragedLease
,IsForCalculation
,IncomeType
,GLTemplateId
,(SystemRowNumber + 1)
FROM #DeferredTaxDetailEntity WHERE ContractCurrency = 'CAD'
;
SELECT
LA.ContractId
,TDAD.DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,TDAD.DepreciationDate
,TDE.AssetId
,TDR.System
,TDTD.TaxBook
INTO #TaxDepreciationResult_Temp
FROM TaxDepAmortizationDetails TDAD
INNER JOIN TaxDepAmortizations TDA ON TDAD.TaxDepAmortizationId = TDA.Id AND IsAccounting = 1 AND TDAD.IsSchedule = 1
INNER JOIN TaxDepEntities TDE ON TDA.TaxDepEntityId = TDE.Id AND TDE.EntityType = 'Asset'
INNER JOIN TaxDepTemplateDetails TDTD ON TDTD.Id = TDAD.TaxDepreciationTemplateDetailId AND  TDTD.TaxBook = 'Federal'
INNER JOIN #LeaseAssets LA ON LA.AssetId = TDE.AssetId
INNER JOIN #LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
INNER JOIN #LeaseContractDetails CD ON LF.ContractId = CD.ContractId
LEFT JOIN #AssetValueHistories AV ON AV.AssetId = TDE.AssetId
AND AV.Value_Currency = TDAD.DepreciationAmount_Currency AND AV.ContractId = LA.ContractId AND AV.IsLessorOwned = 1
LEFT JOIN TaxDepRates TDR ON TDR.Id = TDTD.TaxDepRateId AND TDR.IsActive = 1
AND ((CD.CurrencyISO = 'USD' AND CD.LegalEntityISO = 'USD'
AND AV.Value_Currency = 'USD' AND TDAD.DepreciationAmount_Currency = 'USD' AND TDR.System = 'GDS')
OR (CD.CurrencyISO = 'CAD' AND CD.LegalEntityISO = 'CAD'
AND AV.Value_Currency = 'CAD' AND TDAD.DepreciationAmount_Currency = 'CAD' AND (TDR.System = 'ADS' OR TDR.System = 'WDV'))
OR ((CD.CurrencyISO <> 'USD' OR CD.LegalEntityISO <> 'USD') AND TDR.System = 'ADS' AND TDAD.DepreciationAmount_Currency = 'USD'))
WHERE TDE.AssetId IS NOT NULL
GROUP BY
LA.ContractId
,TDAD.DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,TDAD.DepreciationDate
,TDE.AssetId
,TDR.System
,TDTD.TaxBook
;
WITH CTE_ADSRowNum AS
(
SELECT
ROW_NUMBER() OVER(PARTITION BY TDAD.ContractId,TDAD.DepreciationDate,TDAD.AssetId ORDER BY TDAD.System ASC) AS TaxDepRowNumber
,TDAD.ContractId
,SUM(TDAD.DepreciationAmount_Amount) DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,TDAD.DepreciationDate
,TDAD.AssetId
,TDAD.System
,TDAD.TaxBook
FROM #TaxDepreciationResult_Temp TDAD
WHERE System IS NOT NULL AND TaxBook IS NOT NULL AND TDAD.System  = 'ADS'
GROUP BY
TDAD.ContractId
,TDAD.DepreciationAmount_Currency
,TDAD.DepreciationDate
,TDAD.AssetId
,TDAD.System
,TDAD.TaxBook
)
DELETE #TaxDepreciationResult_Temp FROM #TaxDepreciationResult_Temp TD
JOIN CTE_ADSRowNum AR ON TD.ContractId = AR.ContractId AND TD.TaxBook = AR.TaxBook AND TD.DepreciationAmount_Currency = AR.DepreciationAmount_Currency
AND TD.System = AR.System AND TD.AssetId = AR.AssetId AND TD.DepreciationDate = AR.DepreciationDate AND AR.TaxDepRowNumber = 2;
;
SELECT
ROW_NUMBER() OVER(PARTITION BY TDAD.ContractId,TDAD.DepreciationDate,TDAD.AssetId ORDER BY TDAD.System ASC) AS TaxDepRowNumber
,TDAD.ContractId
,SUM(TDAD.DepreciationAmount_Amount) DepreciationAmount_Amount
,TDAD.DepreciationAmount_Currency
,TDAD.DepreciationDate
,TDAD.AssetId
,TDAD.System
,TDAD.TaxBook
INTO #TaxDepreciationResult
FROM #TaxDepreciationResult_Temp TDAD
WHERE System IS NOT NULL AND TaxBook IS NOT NULL
GROUP BY
TDAD.ContractId
,TDAD.DepreciationAmount_Currency
,TDAD.DepreciationDate
,TDAD.AssetId
,TDAD.System
,TDAD.TaxBook
;
UPDATE #DeferredTaxDetailEntity
SET TaxBookName = CD.TaxBook,
TaxDepreciationSystem = CD.System,
TaxDepreciation_Amount = ISNULL(DepreciationAmount_Amount,0.00),
TaxDepreciation_Currency = ISNULL(DepreciationAmount_Currency,ContractCurrency)
FROM #DeferredTaxDetailEntity TIT
JOIN #TaxDepreciationResult CD ON CD.ContractId = TIT.ContractId
AND CD.AssetId = TIT.AssetId AND TIT.IncomeDate = CD.DepreciationDate
AND CD.TaxDepRowNumber = TIT.SystemRowNumber
;
WITH CTE_Duplicates AS
(
SELECT
MIN(SystemRowNumber) SystemRowNumber, ContractId, AssetId, IncomeDate, TaxDepreciationSystem
FROM #DeferredTaxDetailEntity
GROUP BY ContractId, AssetId, IncomeDate, TaxDepreciationSystem
)
DELETE #DeferredTaxDetailEntity
FROM #DeferredTaxDetailEntity DT
JOIN CTE_Duplicates CD ON DT.ContractId = CD.ContractId AND DT.AssetId = CD.AssetId
AND DT.IncomeDate = CD.IncomeDate AND DT.SystemRowNumber <> CD.SystemRowNumber
AND DT.TaxDepreciationSystem = CD.TaxDepreciationSystem
;
--DELETE #DeferredTaxDetailEntity
--FROM #DeferredTaxDetailEntity TIT
--JOIN #TaxDepreciationResult CD ON CD.ContractId = TIT.ContractId
--AND CD.AssetId = TIT.AssetId AND TIT.IncomeDate = CD.DepreciationDate
--AND TIT.TaxDepreciationSystem <> CD.System
--;
UPDATE #DeferredTaxDetailEntity
SET TaxBookName = 'Federal', TaxDepreciationSystem = 'GDS'
WHERE ContractCurrency = 'USD' AND ((TaxBookName IS NULL OR TaxBookName = '' OR TaxBookName = '_')
OR (TaxDepreciationSystem IS NULL OR TaxDepreciationSystem = '' OR TaxDepreciationSystem = '_'))
;
UPDATE #DeferredTaxDetailEntity
SET TaxBookName = 'Federal', TaxDepreciationSystem = 'ADS'
WHERE ((TaxBookName IS NULL OR TaxBookName = '' OR TaxBookName = '_')
OR (TaxDepreciationSystem IS NULL OR TaxDepreciationSystem = '' OR TaxDepreciationSystem = '_'))
;
WITH CTE_LegalEntityFITRate AS
(
SELECT
C.ContractId
,CTR.TaxRate CorporateTaxRate
,DATEPART(yyyy,CTR.EffectiveDate) EffectiveDateYear
FROM #LeaseContractDetails C
JOIN #LeaseFinances LF ON C.ContractId = LF.ContractId
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN CorporateTaxRates CTR ON LE.Id = CTR.LegalEntityId
WHERE CTR.IsActive = 1 AND LF.IsCurrent = 1
)
,CTE_LegalEntityMaxFITRate AS
(
SELECT
ROW_NUMBER() OVER(PARTITION BY ContractId, EffectiveDateYear ORDER BY ContractId ASC) RowNumber
,ContractId
,CorporateTaxRate
,EffectiveDateYear
FROM CTE_LegalEntityFITRate
)
UPDATE #DeferredTaxDetailEntity
SET FITRate = CorporateTaxRate
FROM #DeferredTaxDetailEntity DT
JOIN CTE_LegalEntityMaxFITRate FIT ON DT.ContractId = FIT.ContractId
AND FIT.EffectiveDateYear =  DT.YearToCalculate AND RowNumber = 1
;
UPDATE #DeferredTaxDetailEntity
SET BookIncome_Amount = ROUND((TaxableIncomeBook_Amount - BookDepreciation_Amount),4),
BookDepreciation_Currency = ISNULL(TaxableIncomeBook_Currency,BookDepreciation_Currency),
TaxIncome_Amount = ROUND((TaxableIncomeTax_Amount - TaxDepreciation_Amount),4),
TaxDepreciation_Currency = ISNULL(TaxableIncomeTax_Currency,TaxDepreciation_Currency)
;
UPDATE #DeferredTaxDetailEntity
SET	IncomeTaxExpense_Amount = ISNULL(ROUND((BookIncome_Amount * (FITRate / 100)),4), 0.00),
IncomeTaxPayable_Amount = ISNULL(ROUND((TaxIncome_Amount * (FITRate / 100)),4), 0.00),
IncomeTaxExpense_Currency = ISNULL(BookDepreciation_Currency, IncomeTaxExpense_Amount),
IncomeTaxPayable_Currency = ISNULL(TaxDepreciation_Currency, IncomeTaxExpense_Amount)
;
UPDATE #DeferredTaxDetailEntity
SET DefTaxLiabBalance_Amount = ROUND((IncomeTaxPayable_Amount - IncomeTaxExpense_Amount), 2)
;
WITH CTE_MinDate AS
(
SELECT
AB.ContractId,
CAB.Date OldDate,
MIN(AB.IncomeDate) NewDate
FROM #DeferredTaxDetailEntity AB
JOIN #DeferredTaxDetail_Adj CAB ON AB.ContractId = CAB.ContractId AND AB.IncomeDate > CAB.Date
GROUP BY
AB.ContractId,
CAB.Date
)
UPDATE #DeferredTaxDetail_Adj
SET Date = MD.NewDate
FROM #DeferredTaxDetail_Adj LIS
JOIN CTE_MinDate MD ON LIS.ContractId = MD.ContractId
AND LIS.Date = MD.OldDate
;
WITH CTE_DeferredTaxDetailEntity AS
(
SELECT
ContractId, AssetId, Date, SUM(DefTaxLiabBalance_Amount) DefTaxLiabBalance_Amount
FROM #DeferredTaxDetail_Adj
GROUP BY ContractId, AssetId, Date
)
UPDATE #DeferredTaxDetailEntity
SET DefTaxLiabBalance_Amount = ROUND((DT.DefTaxLiabBalance_Amount -  DTA.DefTaxLiabBalance_Amount), 2)
FROM #DeferredTaxDetailEntity DT
JOIN CTE_DeferredTaxDetailEntity DTA ON DT.ContractId = DTA.ContractId AND DT.AssetId = DTA.AssetId
AND  DTA.Date = DT.IncomeDate
;
UPDATE #LeaseContractDetails
SET OpenPeriodStartDate = GLFinancialOpenPeriods.FromDate, GLTemplateId = DeferredTaxGLTemplateId
FROM #LeaseContractDetails CT
INNER JOIN LeveragedLeases ON CT.ContractId = LeveragedLeases.ContractId AND LeveragedLeases.IsCurrent = 1
INNER JOIN GLFinancialOpenPeriods ON LeveragedLeases.LegalEntityId = GLFinancialOpenPeriods.LegalEntityId AND GLFinancialOpenPeriods.IsCurrent = 1
;
WITH CTE_IsReProcessInClosedPeriod AS
(
SELECT
MIN(Date) Date,
CT.ContractId
FROM #LeaseContractDetails CT
JOIN  DeferredTaxes ON IsReprocess = 1 AND IsScheduled = 1
AND DeferredTaxes.ContractId = CT.ContractId
GROUP BY
CT.ContractId
)
UPDATE #LeaseContractDetails
SET IsReProcessInClosedPeriod  =  CASE WHEN DT.Date < OpenPeriodStartDate THEN 1 ELSE 0 END
FROM #LeaseContractDetails CT
JOIN  CTE_IsReProcessInClosedPeriod DT ON DT.ContractId = CT.ContractId
;
WITH CTE_IncomeDate AS
(
SELECT
LF.ContractId,
MIN(CAST(DATEADD(DAY, -1, LLA.IncomeDate) AS DATE)) AS DATE
FROM #LeaseContractDetails C
INNER JOIN LeveragedLeases LF ON LF.ContractId = C.ContractId AND LF.IsCurrent = 1
INNER JOIN LeveragedLeaseAmorts LLA ON LLA.LeveragedLeaseId = LF.Id
INNER JOIN #LeaseContractDetails CD ON CD.ContractId = LF.ContractId
AND LLA.IsAccounting = 1 AND LLA.IncomeDate <= CD.DueDate
GROUP BY LF.ContractId
)
UPDATE #LeaseContractDetails
SET DeferredTaxDueDate = CASE WHEN DeferredTaxDueDate IS NULL THEN CD.DATE ELSE DeferredTaxDueDate END
FROM #LeaseContractDetails CT
JOIN CTE_IncomeDate CD ON CT.ContractId = CD.ContractId
UPDATE #LeaseContractDetails SET DeactivateOldRecords =CASE WHEN ReProcessDate IS NULL THEN 0 ELSE 1 END
;
WITH CTE_LeverageLease AS
(
SELECT
LLA.IncomeDate
,SUM(LLA.DeferredTaxesAccrued_Amount) DiffTaxLiabBalance_Amount
,LLA.DeferredTaxesAccrued_Currency DiffTaxLiabBalance_Currency
,SUM(LLA.DeferredTaxesAccrued_Amount) YTDDeferredTax_Amount
,LLA.DeferredTaxesAccrued_Currency YTDDeferredTax_Currency
,SUM(LLA.DeferredTaxes_Amount) AccumDefTaxLiabBalance_Amount
,LLA.DeferredTaxes_Currency AccumDefTaxLiabBalance_Currency
,LL.ContractId
,0 AS 'RowNumber'
,DATEPART(yyyy,LLA.IncomeDate) YearToCalculate
,DATEPART(m,IncomeDate) MonthToCalculate
,LL.DeferredTaxGLTemplateId GlTemplateId
FROM LeveragedLeases LL
JOIN LeveragedLeaseAmorts LLA ON LL.Id = LLA.LeveragedLeaseId
JOIN #AllContractDetails CD ON CD.ContractId = LL.ContractId
WHERE LLA.IsSchedule = 1 AND LLA.IsAccounting = 1 AND LL.IsCurrent = 1
AND LLA.IncomeDate <= CD.DueDate
GROUP BY
LLA.IncomeDate
,LLA.DeferredTaxesAccrued_Currency
,LLA.DeferredTaxesAccrued_Currency
,LLA.DeferredTaxes_Currency
,LL.ContractId
,LL.DeferredTaxGLTemplateId
)
INSERT INTO #DeferredTaxDetailEntity
SELECT DISTINCT
IEP1.ContractId
,0 AssetId
,CAST('_' AS NVARCHAR)
,CAST('_' AS NVARCHAR)
,DATEPART(yyyy,IEP1.IncomeDate) Year
,IEP1.IncomeDate
,0.00 TaxableIncomeTax_Amount
,CD.CurrencyISO TaxableIncomeTax_Currency
,0.00 TaxableIncomeBook_Amount
,CD.CurrencyISO TaxableIncomeBook_Currency
,0.00 BookDepreciation_Amount
,CD.CurrencyISO BookDepreciation_Currency
,0.00  TaxDepreciationAmount_Amount
,CD.CurrencyISO TaxDepreciationAmount_Currency
,0.00 TaxIncome_Amount
,IEP1.DiffTaxLiabBalance_Currency TaxIncome_Currency
,0.00 BookIncome_Amount
,IEP1.DiffTaxLiabBalance_Currency BookIncome_Currency
,0.00 IncomeTaxExpense_Amount
,IEP1.DiffTaxLiabBalance_Currency IncomeTaxExpense_Currency
,0.00 IncomeTaxPayable_Amount
,IEP1.DiffTaxLiabBalance_Currency IncomeTaxPayable_Currency
,IEP1.DiffTaxLiabBalance_Amount
,IEP1.DiffTaxLiabBalance_Currency DiffTaxLiabBalance_Currency
,0.00 MTDDeferredTax_Amount
,IEP1.DiffTaxLiabBalance_Currency MTDDeferredTax_Currency
,0.00 YTDDeferredTax_Amount
,IEP1.DiffTaxLiabBalance_Currency YTDDeferredTax_Currency
,0.00
,IEP1.DiffTaxLiabBalance_Currency AccumDefTaxLiabBalance_Currency
,@CreatedById CreatedById
,@CreatedTime CreatedTime
,CD.CurrencyISO
,0.00
,IEP1.YearToCalculate
,IEP1.MonthToCalculate
,0 IsGLPosted
,0 IsReprocess
,CASE WHEN (CD.IsReProcessInClosedPeriod = 1 AND IEP1.IncomeDate < CD.OpenPeriodStartDate) THEN 0 ELSE 1 END IsAccounting
,1 IsScheduled
,1
,0
,NULL
,IEP1.GlTemplateId
,1
FROM CTE_LeverageLease IEP1
JOIN #AllContractDetails CD ON CD.ContractId =IEP1.ContractId
WHERE IEP1.IncomeDate > CD.DeferredTaxDueDate OR CD.DeferredTaxDueDate IS NULL
ORDER BY ContractId, IncomeDate
;
WITH CTE_MTDDeferredTax_Amount AS
(
Select
Entity1.ContractId,Entity1.IncomeDate, Entity1.AssetId, ROUND(SUM(Entity2.DefTaxLiabBalance_Amount), 2) MTDDeferredTax_Amount, Entity1.TaxDepreciationSystem
FROM  #DeferredTaxDetailEntity Entity1
JOIN #DeferredTaxDetailEntity Entity2 ON Entity1.MonthToCalculate = Entity2.MonthToCalculate AND Entity1.TaxDepreciationSystem = Entity2.TaxDepreciationSystem
AND Entity1.YearToCalculate = Entity2.YearToCalculate AND Entity1.AssetId = Entity2.AssetId AND Entity1.IncomeDate >= Entity1.IncomeDate
GROUP BY Entity1.ContractId, Entity1.AssetId, Entity1.IncomeDate, Entity1.TaxDepreciationSystem
)
UPDATE #DeferredTaxDetailEntity
SET MTDDeferredTax_Amount = MTD.MTDDeferredTax_Amount
FROM #DeferredTaxDetailEntity DT
JOIN CTE_MTDDeferredTax_Amount MTD ON DT.ContractId = MTD.ContractId
AND DT.IncomeDate = MTD.IncomeDate AND DT.AssetId = MTD.AssetId
AND DT.TaxDepreciationSystem = MTD.TaxDepreciationSystem
;
WITH CTE_YTDDeferredTax_Amount AS
(
Select
Entity1.ContractId, Entity1.AssetId, Entity1.IncomeDate, ROUND(SUM(Entity2.DefTaxLiabBalance_Amount), 2) YTDDeferredTax_Amount, Entity1.TaxDepreciationSystem
FROM  #DeferredTaxDetailEntity Entity1
JOIN #DeferredTaxDetailEntity Entity2 ON Entity1.YearToCalculate = Entity2.YearToCalculate
AND Entity1.IncomeDate >= Entity2.IncomeDate AND Entity1.AssetId = Entity2.AssetId
AND Entity1.TaxDepreciationSystem = Entity2.TaxDepreciationSystem
GROUP BY Entity1.ContractId, Entity1.AssetId, Entity1.IncomeDate, Entity1.TaxDepreciationSystem
)
UPDATE #DeferredTaxDetailEntity
SET YTDDeferredTax_Amount = YTD.YTDDeferredTax_Amount
FROM #DeferredTaxDetailEntity DT
JOIN CTE_YTDDeferredTax_Amount YTD ON DT.ContractId = YTD.ContractId
AND DT.IncomeDate = YTD.IncomeDate AND DT.AssetId = YTD.AssetId
AND DT.TaxDepreciationSystem = YTD.TaxDepreciationSystem
;
WITH CTE_AccumDefTaxLiabBalance_Amount AS
(
Select
Entity1.ContractId, Entity1.AssetId, Entity1.IncomeDate, ROUND(SUM(Entity2.DefTaxLiabBalance_Amount), 2) AccumDefTaxLiabBalance_Amount, Entity1.TaxDepreciationSystem
FROM  #DeferredTaxDetailEntity Entity1
JOIN #DeferredTaxDetailEntity Entity2 ON Entity1.IncomeDate >= Entity2.IncomeDate AND Entity1.AssetId = Entity2.AssetId
AND Entity1.TaxDepreciationSystem = Entity2.TaxDepreciationSystem
GROUP BY Entity1.ContractId, Entity1.AssetId, Entity1.IncomeDate, Entity1.TaxDepreciationSystem
)
UPDATE #DeferredTaxDetailEntity
SET AccumDefTaxLiabBalance_Amount = Acc.AccumDefTaxLiabBalance_Amount
FROM #DeferredTaxDetailEntity DT
JOIN CTE_AccumDefTaxLiabBalance_Amount Acc ON DT.ContractId = Acc.ContractId
AND DT.IncomeDate = Acc.IncomeDate AND DT.AssetId = Acc.AssetId
AND DT.TaxDepreciationSystem = Acc.TaxDepreciationSystem
;
UPDATE #DeferredTaxDetailEntity
SET YTDDeferredTax_Amount = ROUND((DTD.YTDDeferredTax_Amount + ISNULL(DT.YTDDeferredTax_Amount,0.00)), 2)
FROM #DeferredTaxDetailEntity DTD
JOIN #DeferredTaxLatestValue DT ON DTD.ContractId = DT.ContractId
AND DTD.AssetId = DT.AssetId AND DT.YearToCalculate = DTD.YearToCalculate
;
UPDATE #DeferredTaxDetailEntity
SET	AccumDefTaxLiabBalance_Amount = ROUND((DTD.AccumDefTaxLiabBalance_Amount + ISNULL(DT.AccumDefTaxLiabBalance_Amount,0.00)), 2)
FROM #DeferredTaxDetailEntity DTD
JOIN #DeferredTaxLatestValue DT ON DTD.ContractId = DT.ContractId AND DTD.AssetId = DT.AssetId
;
UPDATE DeferredTaxes
SET IsAccounting = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes DT JOIN #LeaseContractDetails DTD
ON DT.ContractId = DTD.ContractId AND DT.Date >= DTD.DeferredTaxDueDate
AND IsAccounting = 1 AND IsScheduled = 1 AND DeactivateOldRecords = 1
AND SyndicationType <> 'FullSale'
;
UPDATE DeferredTaxes
SET IsScheduled = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes DT JOIN #LeaseContractDetails DTD
ON DT.ContractID = DTD.ContractId AND DT.Date > DTD.DeferredTaxDueDate
AND IsScheduled = 1  AND DeactivateOldRecords = 1 AND SyndicationType <> 'FullSale'
;
UPDATE DeferredTaxes
SET IsReprocess = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes DT JOIN #LeaseContractDetails DTD
ON DT.ContractID = DTD.ContractId AND DT.Date > DTD.DeferredTaxDueDate
AND DeactivateOldRecords = 1 AND SyndicationType <> 'FullSale'
;
UPDATE DeferredTaxes
SET IsAccounting = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes DT
JOIN @DefTaxContractDetails DTD ON DT.ContractId = DTD.ContractId
AND IsAccounting = 1 AND IsScheduled = 1 AND DTD.IsToDeactivateDefTax = 1
;
UPDATE DeferredTaxes
SET IsScheduled = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes DT
JOIN @DefTaxContractDetails DTD ON DT.ContractID = DTD.ContractId
AND IsScheduled = 1 AND DTD.IsToDeactivateDefTax = 1
;
UPDATE DeferredTaxes
SET IsReprocess = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes DT
JOIN @DefTaxContractDetails DTD
ON DT.ContractID = DTD.ContractId AND DTD.IsToDeactivateDefTax = 1
;
SELECT
TaxBookName
,TaxDepreciationSystem
,FiscalYear
,IncomeDate
,ROUND(SUM(TaxableIncomeTax_Amount),4) TaxableIncomeTax_Amount
,TaxableIncomeTax_Currency
,ROUND(SUM(TaxableIncomeBook_Amount),4) TaxableIncomeBook_Amount
,TaxableIncomeBook_Currency
,ROUND(SUM(BookDepreciation_Amount),4) BookDepreciation_Amount
,BookDepreciation_Currency
,ROUND(SUM(TaxDepreciation_Amount),4) TaxDepreciation_Amount
,TaxDepreciation_Currency
,ROUND(SUM(TaxIncome_Amount),4)	TaxIncome_Amount
,TaxIncome_Currency
,ROUND(SUM(BookIncome_Amount),4) BookIncome_Amount
,BookIncome_Currency
,ROUND(SUM(IncomeTaxExpense_Amount),4) IncomeTaxExpense_Amount
,IncomeTaxExpense_Currency
,ROUND(SUM(IncomeTaxPayable_Amount),4) IncomeTaxPayable_Amount
,IncomeTaxPayable_Currency
,ROUND(SUM(DefTaxLiabBalance_Amount),2) DefTaxLiabBalance_Amount
,DefTaxLiabBalance_Currency
,ROUND(SUM(MTDDeferredTax_Amount),2) MTDDeferredTax_Amount
,MTDDeferredTax_Currency
,ROUND(SUM(YTDDeferredTax_Amount),2) YTDDeferredTax_Amount
,YTDDeferredTax_Currency
,ROUND(SUM(AccumDefTaxLiabBalance_Amount),2) AccumDefTaxLiabBalance_Amount
,AccumDefTaxLiabBalance_Currency
,CreatedById
,CreatedTime
,IsGLPosted
,IsReprocess
,IsAccounting
,IsScheduled
,GLTemplateId
,ContractId
INTO #DeferredTaxEntity
FROM #DeferredTaxDetailEntity WHERE IsForCalculation  = 0
GROUP BY
TaxBookName
,TaxDepreciationSystem
,FiscalYear
,IncomeDate
,TaxableIncomeTax_Currency
,TaxableIncomeBook_Currency
,BookDepreciation_Currency
,TaxDepreciation_Currency
,TaxIncome_Currency
,BookIncome_Currency
,IncomeTaxExpense_Currency
,IncomeTaxPayable_Currency
,DefTaxLiabBalance_Currency
,MTDDeferredTax_Currency
,YTDDeferredTax_Currency
,AccumDefTaxLiabBalance_Currency
,CreatedById
,CreatedTime
,IsGLPosted
,IsReprocess
,IsAccounting
,IsScheduled
,GLTemplateId
,ContractId
;
INSERT INTO DeferredTaxes
(TaxBookName,TaxDepreciationSystem,FiscalYear,Date,TaxableIncomeTax_Amount,TaxableIncomeTax_Currency,TaxableIncomeBook_Amount,
TaxableIncomeBook_Currency,BookDepreciation_Amount,BookDepreciation_Currency,TaxDepreciation_Amount,TaxDepreciation_Currency,
TaxIncome_Amount,TaxIncome_Currency,BookIncome_Amount,BookIncome_Currency, IncomeTaxExpense_Amount,IncomeTaxExpense_Currency,
IncomeTaxPayable_Amount,IncomeTaxPayable_Currency,DefTaxLiabBalance_Amount,DefTaxLiabBalance_Currency,MTDDeferredTax_Amount,
MTDDeferredTax_Currency,YTDDeferredTax_Amount, YTDDeferredTax_Currency,AccumDefTaxLiabBalance_Amount,AccumDefTaxLiabBalance_Currency,
CreatedById,CreatedTime,IsGLPosted,IsReprocess,IsAccounting,IsScheduled,GLTemplateId,ContractId
)
OUTPUT INSERTED.ID,INSERTED.Date,INSERTED.ContractId INTO #InsertedDeferredTax(Id,Date,ContractId)
SELECT
TaxBookName
,TaxDepreciationSystem
,FiscalYear
,IncomeDate
,TaxableIncomeTax_Amount
,TaxableIncomeTax_Currency
,TaxableIncomeBook_Amount
,TaxableIncomeBook_Currency
,BookDepreciation_Amount
,BookDepreciation_Currency
,TaxDepreciation_Amount
,TaxDepreciation_Currency
,TaxIncome_Amount
,TaxIncome_Currency
,BookIncome_Amount
,BookIncome_Currency
,IncomeTaxExpense_Amount
,IncomeTaxExpense_Currency
,IncomeTaxPayable_Amount
,IncomeTaxPayable_Currency
,DefTaxLiabBalance_Amount
,DefTaxLiabBalance_Currency
,MTDDeferredTax_Amount
,MTDDeferredTax_Currency
,YTDDeferredTax_Amount
,YTDDeferredTax_Currency
,AccumDefTaxLiabBalance_Amount
,AccumDefTaxLiabBalance_Currency
,CreatedById
,CreatedTime
,IsGLPosted
,IsReprocess
,IsAccounting
,IsScheduled
,GLTemplateId
,ContractId
FROM #DeferredTaxEntity
ORDER BY ContractId, IncomeDate
;
INSERT INTO [DeferredTaxDetails]
(TaxableIncomeTax_Amount,TaxableIncomeTax_Currency,TaxableIncomeBook_Amount,TaxableIncomeBook_Currency,BookDepreciation_Amount,
BookDepreciation_Currency,TaxDepreciation_Amount,TaxDepreciation_Currency,TaxIncome_Amount,TaxIncome_Currency,BookIncome_Amount,
BookIncome_Currency,IncomeTaxExpense_Amount,IncomeTaxExpense_Currency,IncomeTaxPayable_Amount,IncomeTaxPayable_Currency,
DefTaxLiabBalance_Amount,DefTaxLiabBalance_Currency,MTDDeferredTax_Amount,MTDDeferredTax_Currency,YTDDeferredTax_Amount,
YTDDeferredTax_Currency,AccumDefTaxLiabBalance_Amount,AccumDefTaxLiabBalance_Currency,CreatedById,CreatedTime,AssetId,DeferredTaxId)
SELECT
ROUND(TaxableIncomeTax_Amount, 4) TaxableIncomeTax_Amount
,TaxableIncomeTax_Currency
,ROUND(TaxableIncomeBook_Amount, 4)	TaxableIncomeBook_Amount
,TaxableIncomeBook_Currency
,ROUND(BookDepreciation_Amount, 4) BookDepreciation_Amount
,BookDepreciation_Currency
,ROUND(TaxDepreciation_Amount, 4) TaxDepreciation_Amount
,TaxDepreciation_Currency
,ROUND(TaxIncome_Amount, 4) TaxIncome_Amount
,TaxIncome_Currency
,ROUND(BookIncome_Amount, 4) BookIncome_Amount
,BookIncome_Currency
,ROUND(IncomeTaxExpense_Amount, 4) IncomeTaxExpense_Amount
,IncomeTaxExpense_Currency
,ROUND(IncomeTaxPayable_Amount, 4) IncomeTaxPayable_Amount
,IncomeTaxPayable_Currency
,ROUND(DefTaxLiabBalance_Amount, 2) DefTaxLiabBalance_Amount
,DefTaxLiabBalance_Currency
,ROUND(MTDDeferredTax_Amount, 2) MTDDeferredTax_Amount
,MTDDeferredTax_Currency
,ROUND(YTDDeferredTax_Amount, 2) YTDDeferredTax_Amount
,YTDDeferredTax_Currency
,ROUND(AccumDefTaxLiabBalance_Amount, 2) AccumDefTaxLiabBalance_Amount
,AccumDefTaxLiabBalance_Currency
,CreatedById
,CreatedTime
,AssetId
,IDT.Id
FROM #DeferredTaxDetailEntity DTR
JOIN #InsertedDeferredTax IDT ON DTR.IncomeDate = IDT.Date AND DTR.ContractId = IDT.ContractId
AND DTR.IsForCalculation  = 0 AND AssetId > 0
ORDER BY DTR.ContractId, IncomeDate, AssetId
;
INSERT INTO #ProcessedContracts (Id,SequenceNumber,ProcessedTillDate)
SELECT
DT.ContractId,
C.SequenceNumber,
MAX(Date) AS ProcessedTillDate
FROM Contracts C
JOIN #InsertedDeferredTax DT
ON C.Id = DT.ContractId
group by DT.ContractId,
C.SequenceNumber
;
INSERT INTO #ProcessedContracts (Id,SequenceNumber,ProcessedTillDate)
SELECT
DISTINCT
C.Id ContractId,
C.SequenceNumber,
DT.DueDate AS ProcessedTillDate
FROM @DefTaxContractDetails DT
JOIN Contracts C ON DT.ContractId = C.Id
WHERE DT.IsToDeactivateDefTax = 1
;
COMMIT TRANSACTION
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION
INSERT INTO #ErrorContracts (SequenceNumber,ErrorMessage,ErrorNumber)
SELECT
null,
CAST(ERROR_MESSAGE() AS NVARCHAR(MAX)),
CAST(ERROR_NUMBER() AS NVARCHAR(MAX))
END CATCH
SELECT DISTINCT SequenceNumber,DATEPART(YYYY,ProcessedTillDate) as RuntillYear
FROM #ProcessedContracts
SELECT * FROM #ErrorContracts
SET NOCOUNT OFF
END

GO
