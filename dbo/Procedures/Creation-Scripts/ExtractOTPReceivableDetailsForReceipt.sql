SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ExtractOTPReceivableDetailsForReceipt]
(
	@CreatedById										BIGINT,
	@CreatedTime										DATETIMEOFFSET,
	@JobStepInstanceId									BIGINT,
	@ReceivableTypeValues_OverTermRental				NVARCHAR(40),
	@ReceivableTypeValues_Supplemental					NVARCHAR(40),
	@AccountingTreatmentValues_CashBased				NVARCHAR(12),
	@OperatingContractType								NVARCHAR(10),
	@AssetValueSourceModuleValues_OTPDepreciation	    NVARCHAR(20),
	@AssetValueSourceModuleValues_ResidualRecapture	    NVARCHAR(20)
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;

SELECT 
	AVH.Id,
	RRDE.ReceiptApplicationReceivableDetailId
INTO #AVHIds	
FROM AssetValueHistories AVH 
INNER JOIN ReceiptReceivableDetails_Extract  RRDE 
	ON RRDE.AssetId = AVH.AssetId 
	AND AVH.IsAccounted = 1 AND AVH.IsSchedule = 1  
	AND AVH.SourceModule IN (@AssetValueSourceModuleValues_OTPDepreciation, @AssetValueSourceModuleValues_ResidualRecapture) 
	AND RRDE.JobStepInstanceId = @JobStepInstanceId

SELECT 
	AVH.AssetId,
	Value_Amount,
	IncomeDate,
	IsLeaseComponent,
	ReceiptApplicationReceivableDetailId
INTO #AVHRecords
FROM AssetValueHistories AVH 
INNER JOIN #AVHIds  RRDE ON AVH.Id = RRDE.Id

DROP TABLE IF EXISTS #AVHIds 

SELECT   
	AVH.AssetId,
	SUM(AVH.Value_Amount) AS TotalDepreciationAmount,
    RRDE.PaymentScheduleId
INTO #AVH
FROM LeaseAssets 
INNER JOIN LeaseFinances 
	ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id and IsCurrent = 1
INNER JOIN ReceiptReceivableDetails_Extract  RRDE 
	ON RRDE.AssetId = LeaseAssets.AssetId 
	AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
INNER JOIN #AVHRecords AVH 
	ON  RRDE.AssetId = AVH.AssetId AND RRDE.ReceiptApplicationReceivableDetailId = AVH.ReceiptApplicationReceivableDetailId
INNER JOIN LeasePaymentSchedules 
	ON LeasePaymentSchedules.Id = RRDE.PaymentScheduleId 
	AND AVH.IncomeDate BETWEEN LeasePaymentSchedules.StartDate AND LeasePaymentSchedules.EndDate
	AND LeasePaymentSchedules.IsActive = 1
    AND (RRDE.LeaseContractType!=@OperatingContractType OR LeaseAssets.IsFailedSaleLeaseback=1 OR AVH.IsLeaseComponent=0)
WHERE JobStepInstanceId = @JobStepInstanceId
    AND ReceivableType IN (@ReceivableTypeValues_OverTermRental,@ReceivableTypeValues_Supplemental)
    AND AccountingTreatment = @AccountingTreatmentValues_CashBased AND FunderId IS NULL
	AND RRDE.IsAdjustmentReceivableDetail = 0
GROUP BY AVH.AssetId,RRDE.PaymentScheduleId

SELECT ReceiptReceivableDetails_Extract.* 
INTO #RARD
FROM ReceiptReceivableDetails_Extract 
LEFT JOIN RentSharingDetails ON ReceiptReceivableDetails_Extract.ReceivableId = RentSharingDetails.ReceivableId AND RentSharingDetails.IsActive = 1
WHERE JobStepInstanceId = @JobStepInstanceId
	AND ReceivableType IN (@ReceivableTypeValues_OverTermRental,@ReceivableTypeValues_Supplemental)
	AND AccountingTreatment = @AccountingTreatmentValues_CashBased AND FunderId IS NULL
	AND RentSharingDetails.Id IS NULL
	AND (AmountApplied - PrevAmountAppliedForReApplication) <> 0.00

SELECT    
	 RARD.ReceiptApplicationReceivableDetailId,
	 SUM(AssetIncomeSchedules.RentalIncome_Amount) AS TotalRentalAmount  
INTO #AssetIncome  
FROM #RARD RARD  
	INNER JOIN LeasePaymentSchedules ON LeasePaymentSchedules.Id = RARD.PaymentScheduleId    
	INNER JOIN LeaseFinances AllLeases ON  RARD.ContractId = AllLeases.ContractId    
	INNER JOIN LeaseIncomeSchedules ON AllLeases.Id = LeaseIncomeSchedules.LeaseFinanceId AND LeaseIncomeSchedules.IsSchedule = 1 AND LeaseIncomeSchedules.IsAccounting = 1    
	INNER JOIN AssetIncomeSchedules ON LeaseIncomeSchedules.Id = AssetIncomeSchedules.LeaseIncomeScheduleId   
		AND AssetIncomeSchedules.AssetId = RARD.AssetId    
		AND AssetIncomeSchedules.IsActive = 1 AND LeaseIncomeSchedules.IncomeDate BETWEEN LeasePaymentSchedules.StartDate AND LeasePaymentSchedules.EndDate   
 GROUP BY   
	RARD.ReceiptApplicationReceivableDetailId 

INSERT INTO [dbo].[ReceiptOTPReceivables_Extract]
    ([ContractId]
	,[ReceivableDetailId]         
    ,[AssetId]
	,[AssetComponentType]
	,[Balance]
    ,[ReceiptApplicationReceivableDetailId]
    ,[AmountApplied]
	,[AmountAppliedForDepreciation]
    ,[ReceiptId]
    ,[ReceivableId]
    ,[ReceivableDueDate]
	,[ReceivableIncomeType]
    ,[ReceivableBalance]
    ,[PaymentScheduleId]
    ,[LeaseFinanceId]
    ,[LegalEntityId]
    ,[InstrumentTypeId]
    ,[CostCenterId]
    ,[BranchId]
	,[SequenceNumber]
    ,[IsNonAccrual]
    ,[NonAccrualDate]
    ,[LineofBusinessId]
    ,[IncomeGLTemplateId]
    ,[TotalRentalAmount]
    ,[TotalDepreciationAmount]
    ,[JobStepInstanceId]  
	,[CreatedById]
    ,[CreatedTime]
	,[IsReApplication]
	,[IsAdjustmentReceivableDetail])
SELECT
	LeaseFinances.ContractId,
	RARD.ReceivableDetailId,
	RARD.AssetId,
	RARD.AssetComponentType,
	RARD.ReceivableDetailBalance,
	RARD.ReceiptApplicationReceivableDetailId,
	RARD.AmountApplied - RARD.PrevAmountAppliedForReApplication, 
	RARD.AmountApplied,
	RARD.ReceiptId,
	RARD.ReceivableId,
	RARD.DueDate,
	RARD.IncomeType,
	RARD.ReceivableBalance,
	RARD.PaymentScheduleId,
	LeaseFinances.Id,
	LeaseFinances.LegalEntityId,
	LeaseFinances.InstrumentTypeId,
	LeaseFinances.CostCenterId,
	LeaseFinances.BranchId,
	RARD.SequenceNumber,
	RARD.IsNonAccrual,
	RARD.NonAccrualDate,
	LeaseFinances.LineofBusinessId,
	LeaseFinanceDetails.OTPIncomeGLTemplateId,
	#AssetIncome.TotalRentalAmount, 
	ISNULL(#AVH.TotalDepreciationAmount,0.00) AS TotalDepreciationAmount,		
	@JobStepInstanceId,
	@CreatedById,
	@CreatedTime,
	RARD.IsReApplication,
	RARD.IsAdjustmentReceivableDetail
FROM #RARD as RARD
INNER JOIN LeaseFinances ON LeaseFinances.ContractId =  RARD.ContractId and LeaseFinances.IsCurrent = 1
INNER JOIN LeaseAssets ON LeaseAssets.AssetId = RARD.AssetId AND LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
INNER JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id = LeaseFinances.Id
INNER JOIN #AssetIncome ON RARD.ReceiptApplicationReceivableDetailId = #AssetIncome.ReceiptApplicationReceivableDetailId
LEFT JOIN #AVH ON RARD.AssetId = #AVH.AssetId AND RARD.PaymentScheduleId = #AVH.PaymentScheduleId

DROP TABLE IF EXISTS #AVH
DROP TABLE IF EXISTS #RARD
DROP TABLE IF EXISTS #AVHRecords
DROP TABLE IF EXISTS #AssetIncome

END

GO
