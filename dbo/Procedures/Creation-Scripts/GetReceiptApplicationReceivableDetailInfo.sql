SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetReceiptApplicationReceivableDetailInfo]
(
	@ReceiptId				BIGINT,
	@ApplicationId			BIGINT,
	@ReceivableDetailIds	ReceivableDetailIdCollection READONLY,
	@IsForInvoice			BIT,
	@IsCash					BIT,
	@IsReceiptApplication	BIT,
	@IsWithHoldingTaxApplicable BIT
)
AS
BEGIN
SET NOCOUNT ON
SET  Transaction isolation level read uncommitted
CREATE TABLE #ReceivableDetailInfo
(
	ReceivableDetailId BIGINT PRIMARY KEY,
	ReceivableId BIGINT,
	AssetId BIGINT,
	Amount_Amount DECIMAL(16,2),
	Balance_Amount DECIMAL(16,2),
	LeaseComponentBalance_Amount DECIMAL(16,2),
	NonLeaseComponentBalance_Amount DECIMAL(16,2),
	LeaseComponentAmount_Amount DECIMAL(16,2),
	NonLeaseComponentAmount_Amount DECIMAL(16,2),
	EffectiveBalance_Amount DECIMAL(16,2),
	IsDummy BIT,
	TotalBalance_Amount DECIMAL(16,2),
	CustomerId BIGINT,
	LegalEntityId BIGINT,
	DueDate DATE,
	FunderId BIGINT,
	IsGLPosted BIT,
	EntityType NVARCHAR(2),
	EntityId BIGINT,
	SourceId BIGINT,
	SourceTable NVARCHAR(25),
	PaymentScheduleId BIGINT,
	IncomeType NVARCHAR(16),
	TotalBookBalance_Amount DECIMAL(16,2),
	EffectiveBookBalance_Amount DECIMAL(16,2),
	ReceivableCodeId BIGINT,
	Currency NVARCHAR(5),
	AdjustmentBasisReceivableDetailId BIGINT,
	AssetComponentType NVARCHAR(7),
	IsLeaseAsset BIT,
	ReceivableDetailIsActive BIT,
	IsTaxAssessed BIT,
	TaxType NVARCHAR(30)
);    
;WITH CTE_AssetDetails AS    
(    
	Select Distinct IsLeaseAsset,Rd.Id As ReceivableDetailId
	from @ReceivableDetailIds ReceivableDetailIds
	JOIN ReceivableDetails Rd ON ReceivableDetailIds.ReceivableDetailId=Rd.Id
	JOIN Receivables R ON Rd.ReceivableId=R.Id
	JOIN LeaseFinances LF ON R.EntityId=LF.ContractId AND R.EntityType='CT'
	JOIN LeaseAssets LA ON LA.AssetId=Rd.AssetId AND LF.Id=LA.LeaseFinanceId
	Where LF.IsCurrent =1 AND LA.IsActive=1 OR LA.TerminationDate IS NOT NULL
)    
INSERT INTO #ReceivableDetailInfo    
SELECT      
 ReceivableDetails.Id AS ReceivableDetailId,    
 Receivables.Id AS ReceivableId,    
 ReceivableDetails.AssetId AS AssetId,    
 ReceivableDetails.Amount_Amount,    
	ReceivableDetails.Balance_Amount,
	ReceivableDetails.LeaseComponentBalance_Amount,
	ReceivableDetails.NonLeaseComponentBalance_Amount,
	ReceivableDetails.LeaseComponentAmount_Amount,
	ReceivableDetails.NonLeaseComponentAmount_Amount,
 ReceivableDetails.EffectiveBalance_Amount,    
 Receivables.IsDummy,    
 Receivables.TotalBalance_Amount,    
 Receivables.CustomerId,    
 Receivables.LegalEntityId,    
 Receivables.DueDate AS DueDate,    
 Receivables.FunderId,    
 Receivables.IsGLPosted,    
 Receivables.EntityType,    
 Receivables.EntityId,    
 Receivables.SourceId,    
 Receivables.SourceTable,    
 CASE WHEN Receivables.sourceTable NOT IN ('SundryRecurring','LoanPaydown', 'CPUSchedule')    
 THEN Receivables.PaymentScheduleId    
 ELSE    
 NULL    
 END AS PaymentScheduleId,    
 Receivables.IncomeType,    
 Receivables.TotalBookBalance_Amount,    
 ReceivableDetails.EffectiveBookBalance_Amount,    
 Receivables.ReceivableCodeId,    
 ReceivableDetails.Amount_Currency,    
 ReceivableDetails.AdjustmentBasisReceivableDetailId,    
 ReceivableDetails.AssetComponentType,    
 ISNULL(AssetDetails.IsLeaseAsset,CAST(0 AS BIT)) as IsLeaseAsset  ,
 ReceivableDetails.IsActive AS ReceivableDetailIsActive,
 ReceivableDetails.IsTaxAssessed AS IsTaxAssessed,
 Receivables.ReceivableTaxType AS TaxType	
FROM @ReceivableDetailIds ReceivableDetailIds    
JOIN ReceivableDetails ON ReceivableDetailIds.ReceivableDetailId = ReceivableDetails.Id    
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id    
LEFT JOIN CTE_AssetDetails AssetDetails ON ReceivableDetails.Id=AssetDetails.ReceivableDetailId  

CREATE TABLE #AppliedCancelledInvoices
(
	ReceivableDetailId BIGINT,
	ReceivableInvoiceId BIGINT
);
    
CREATE TABLE #PreviousApplications    
(    
 	ReceivableDetailId					BIGINT,  
 	AmountApplied_Amount					DECIMAL(16,2),  
 	ReceivedAmount_Amount					DECIMAL(16,2),  
 	TaxApplied_Amount					DECIMAL(16,2),  
 	TotalPreviousReceivedTowardsInterest			DECIMAL(16, 2),
 	PreviousReceivedTowardsInterest				DECIMAL(16, 2),
 	AdjustedWithholdingTax					DECIMAL(16, 2),
	LeaseComponentAmountApplied_Amount 			DECIMAL(16,2),
	NonLeaseComponentAmountApplied_Amount 			DECIMAL(16,2)
);    

DECLARE @ReceiptStatus NVARCHAR(500)= (SELECT Status FROM Receipts WHERE Id = @ReceiptId);

IF @IsWithHoldingTaxApplicable = 0
BEGIN
	IF @ReceiptId IS NOT NULL AND @ReceiptId != 0
	BEGIN
		INSERT INTO #PreviousApplications
		SELECT ReceiptApplicationReceivableDetails.ReceivableDetailId,
			SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountApplied_Amount,
			0.00 AS Received_Amount,
			SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied_Amount,
			0.00 AS TotalPreviousReceivedTowardsInterest,
			0.00 AS PreviousReceivedTowardsInterest,
			0.00 AS AdjustedWithholdingTax,
			SUM(ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount) AS LeaseComponentAmountApplied_Amount,
			SUM(ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount) AS NonLeaseComponentAmountApplied_Amount
		FROM ReceiptApplications
		JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		JOIN #ReceivableDetailInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetailInfo.ReceivableDetailId
		JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
		WHERE ReceiptApplications.ReceiptId = @ReceiptId
		AND ReceiptApplicationReceivableDetails.IsActive = 1
		AND (Receipts.Status = 'Posted' OR Receipts.Status = 'ReadyForPosting')
		GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId;
	END
END
  
CREATE TABLE #WHTWaiverAmountDetails(ReceivableDetailId BIGINT, AdjustedWHTWaivedAmount DECIMAL(16,2), WithholdingTaxRate DECIMAL(5,2))  
    
DECLARE @HasWHTWaiverReceipts BIT;  
  
IF @IsWithHoldingTaxApplicable = 1
BEGIN
	INSERT INTO #WHTWaiverAmountDetails  
	SELECT   
		RARD.ReceivableDetailId  
		,SUM(ISNULL(RARD.AdjustedWithholdingTax_Amount,0.00)) AdjustedWHTWaivedAmount  
		,MAX(ISNULL(rWHT.TaxRate,0.00)) WithholdingTaxRate  
	FROM @ReceivableDetailIds ReceivableDetailIds    
	JOIN ReceivableDetails RD ON ReceivableDetailIds.ReceivableDetailId = RD.Id    
	JOIN ReceiptApplicationReceivableDetails RARD ON RD.Id = RARD.ReceivableDetailId  
	JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id  
	JOIN Receipts R ON RA.ReceiptId = R.Id  
	JOIN ReceiptTypes RT ON R.TypeId = RT.Id  
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails rdWHT ON RD.Id = rdWHT.ReceivableDetailId  
	LEFT JOIN ReceivableWithholdingTaxDetails rWHT ON rdWHT.ReceivableWithholdingTaxDetailId = rWHT.Id  
	WHERE R.Status IN ('Posted','Completed','Pending','Submitted') AND RARD.IsActive = 1  
	AND R.ReceiptClassification IN ('NonCash','NonAccrualNonDSLNonCash') AND RT.ReceiptTypeName = 'WithholdingTaxWaiver'  
	GROUP BY RARD.ReceivableDetailId   
END

IF EXISTS(SELECT * FROM #WHTWaiverAmountDetails WHERE AdjustedWHTWaivedAmount>0)  
SET @HasWHTWaiverReceipts = 1  
ELSE SET @HasWHTWaiverReceipts = 0  
  

IF @IsWithHoldingTaxApplicable = 1
BEGIN

IF @ReceiptId IS NOT NULL AND @ReceiptId != 0    
BEGIN    
     
 SELECT     
  ReceiptApplicationReceivableDetails.ReceivableDetailId,    
  SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AmountApplied_Amount,    
  SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount) ReceivedAmount_Amount,  
  SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) TaxApplied_Amount,    
  CASE WHEN @IsCash = 0 THEN    
    CASE WHEN Receipts.ReceiptClassification = 'Cash' THEN    
    SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount + ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)    
   ELSE    
    SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount)    
   END    
  ELSE    
   CASE WHEN Receipts.ReceiptClassification = 'NonCash' THEN    
    CASE WHEN MAX(RT.ReceiptTypeName) = 'WithholdingTaxWaiver'
        THEN SUM(ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)
        ELSE SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount - ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)
        END
   ELSE    
    SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount)    
   END    
  END AS TotalPreviousReceivedTowardsInterest,    
  SUM(ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount) AdjustedWithholdingTax,    
		SUM(ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount) AS LeaseComponentAmountApplied_Amount,
		SUM(ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount) AS NonLeaseComponentAmountApplied_Amount,
		IsNonCash = CASE WHEN Receipts.ReceiptClassification = 'NonCash' THEN 1 ELSE 0 END,
  SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount) PreviousReceivedTowardsInterest,  
  ReceiptApplications.ReceiptId  
 INTO #TempPreviousApplications    
 FROM ReceiptApplications    
 JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId    
 JOIN #ReceivableDetailInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetailInfo.ReceivableDetailId    
 JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id    
 JOIN ReceiptTypes RT ON Receipts.TypeId = RT.Id
 WHERE (@ReceiptId IS NOT NULL AND ReceiptApplications.ReceiptId = @ReceiptId)    
 AND ReceiptApplicationReceivableDetails.IsActive = 1    
 AND (Receipts.Status = 'Posted' OR Receipts.Status = 'ReadyForPosting')    
 GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId, Receipts.ReceiptClassification, ReceiptApplications.ReceiptId;    
    
 INSERT INTO #TempPreviousApplications    
 SELECT     
  ReceiptApplicationReceivableDetails.ReceivableDetailId,    
  0.00 AmountApplied_Amount,  
  0.00 ReceivedAmount_Amount,    
  0.00 TaxApplied_Amount,    
  CASE WHEN @IsCash = 0 THEN    
     CASE WHEN Receipts.ReceiptClassification = 'Cash' THEN    
    SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount + ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)    
   ELSE    
    SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount)    
 END  
  ELSE    
   CASE WHEN Receipts.ReceiptClassification = 'NonCash' THEN    
   
    CASE WHEN MAX(RT.ReceiptTypeName) = 'WithholdingTaxWaiver'
        THEN SUM(ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)
        ELSE SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount - ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)
        END
   ELSE    
    SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount)    
   END    
  END AS TotalPreviousReceivedTowardsInterest,    
  0.00 AdjustedWithholdingTax,    
		0.00 LeaseComponentAmountApplied_Amount,
		0.00 NonLeaseComponentAmountApplied_Amount,
  IsNonCash = CASE WHEN Receipts.ReceiptClassification = 'NonCash' THEN 1 ELSE 0 END,    
  0.00 AS PreviousReceivedTowardsInterest,  
  ReceiptApplications.ReceiptId    
 FROM ReceiptApplications    
 JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId    
 JOIN #ReceivableDetailInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetailInfo.ReceivableDetailId    
 JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id    
 JOIN ReceiptTypes RT ON Receipts.TypeId = RT.Id
 WHERE (@ReceiptId IS NOT NULL AND ReceiptApplications.ReceiptId <> @ReceiptId)    
 AND ReceiptApplicationReceivableDetails.IsActive = 1    
 AND (Receipts.Status = 'Posted' OR Receipts.Status = 'ReadyForPosting' OR Receipts.Status = 'Pending'   
  OR Receipts.Status = 'Completed' OR Receipts.Status = 'Submitted')    
  GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId, Receipts.ReceiptClassification, ReceiptApplications.ReceiptId;    
    
 INSERT INTO #PreviousApplications    
 SELECT     
	#TempPreviousApplications.ReceivableDetailId,    
	AmountApplied_Amount=    
	SUM(    
	CASE     
	WHEN @IsReceiptApplication = 0 AND #TempPreviousApplications.IsNonCash=1 THEN TotalPreviousReceivedTowardsInterest    
	ELSE #TempPreviousApplications.AmountApplied_Amount - #TempPreviousApplications.AdjustedWithholdingTax    
	END    
	),    
	SUM(#TempPreviousApplications.ReceivedAmount_Amount) AS ReceivedAmount_Amount,  
	SUM(#TempPreviousApplications.TaxApplied_Amount) AS TaxApplied_Amount,    
	SUM(#TempPreviousApplications.TotalPreviousReceivedTowardsInterest) AS TotalPreviousReceivedTowardsInterest,  
	SUM(#TempPreviousApplications.PreviousReceivedTowardsInterest) AS PreviousReceivedTowardsInterest,    
	SUM(#TempPreviousApplications.AdjustedWithholdingTax) AS AdjustedWithHoldingTax, 
	SUM(#TempPreviousApplications.LeaseComponentAmountApplied_Amount) AS LeaseComponentAmountApplied_Amount,
	SUM(#TempPreviousApplications.NonLeaseComponentAmountApplied_Amount) AS NonLeaseComponentAmountApplied_Amount
 FROM #TempPreviousApplications    
 GROUP BY #TempPreviousApplications.ReceivableDetailId;    
    
 SET @ReceiptStatus = (SELECT Status FROM Receipts WHERE Id = @ReceiptId)    
END    
ELSE    
BEGIN    
 INSERT INTO #PreviousApplications    
 SELECT    
	TMP.ReceivableDetailId,    
	0.00 AmountApplied_Amount,   
	0.00 ReceivedAmount_Amount,   
	0.00 TaxApplied_Amount,    
	SUM(TMP.TotalPreviousReceivedTowardsInterest),   
	0.00 PreviousReceivedTowardsInterest,   
	0.00 AdjustedWithHoldingTax, 
	0.00 LeaseComponentAmountApplied_Amount,
	0.00 NonLeaseComponentAmountApplied_Amount
 FROM    
 (    
  SELECT     
   ReceiptApplicationReceivableDetails.ReceivableDetailId,    
   CASE WHEN @IsCash = 0 THEN    
  CASE WHEN Receipts.ReceiptClassification = 'Cash' THEN    
  SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount + ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)    
 ELSE    
  SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount)    
 END  
   ELSE    
    CASE WHEN Receipts.ReceiptClassification = 'NonCash' THEN    
     SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount - ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount)    
    ELSE    
     SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount)    
    END    
  END AS TotalPreviousReceivedTowardsInterest    
  FROM ReceiptApplications    
  JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId    
  JOIN #ReceivableDetailInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetailInfo.ReceivableDetailId    
  JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id    
  WHERE ReceiptApplicationReceivableDetails.IsActive = 1    
  AND (Receipts.Status = 'Posted' OR Receipts.Status = 'ReadyForPosting' OR Receipts.Status = 'Pending'   
 OR Receipts.Status = 'Completed' OR Receipts.Status = 'Submitted')    
  GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId,Receipts.ReceiptClassification    
 ) TMP    
 GROUP BY TMP.ReceivableDetailId;    
    
END    
    
END

IF @ReceiptStatus = 'Reversed'
BEGIN
	INSERT INTO #AppliedCancelledInvoices
	SELECT 
		ReceivableDetail.ReceivableDetailId,
		ReceiptApplicationReceivableDetails.ReceivableInvoiceId
	FROM #ReceivableDetailInfo ReceivableDetail
	JOIN ReceiptApplicationReceivableDetails ON ReceivableDetail.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId AND ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId AND ReceiptApplicationReceivableDetails.IsActive = 1
	JOIN ReceivableInvoices ON ReceiptApplicationReceivableDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 0
	WHERE ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL
END

;WITH CTE_ContractIds (ContractId) AS    
(    
 SELECT EntityId ContractId FROM #ReceivableDetailInfo WHERE EntityType = 'CT' GROUP BY EntityId    
)    
SELECT     
 ChargeOffs.ContractId,Min(ChargeOffs.ChargeOffDate) ChargeOffDate    
INTO #ChargeOffs    
FROM CTE_ContractIds Contract    
JOIN ChargeOffs ON Contract.ContractId = ChargeOffs.ContractId AND ChargeOffs.IsActive=1    
AND ChargeOffs.Status='Approved' AND ChargeOffs.ReceiptId IS NULL    
GROUP BY ChargeOffs.ContractId  

SELECT 
	#ReceivableDetailInfo.ReceivableDetailId
INTO #AdjustedReceivableDetails
FROM #ReceivableDetailInfo
JOIN ReceivableDetails ON #ReceivableDetailInfo.ReceivableDetailId = ReceivableDetails.AdjustmentBasisReceivableDetailId
WHERE ReceivableDetails.AdjustmentBasisReceivableDetailId IS NOT NULL
    
IF @IsForInvoice = 0    
BEGIN    
 SELECT     
  #ReceivableDetailInfo.AssetId AS AssetId,    
  #ReceivableDetailInfo.ReceivableId AS ReceivableId,    
  #ReceivableDetailInfo.ReceivableDetailId AS ReceivableDetailId,    
  InvoiceInfo.ReceivableInvoiceId AS ReceivableInvoiceId,    
  InvoiceInfo.InvoiceNumber AS InvoiceNumber,    
  #ReceivableDetailInfo.CustomerId AS CustomerId,    
  Contracts.Id AS ContractId,    
  Discountings.Id AS DiscountingId,    
  #ReceivableDetailInfo.DueDate AS DueDate,    
  Parties.PartyName AS CustomerName,    
  Parties.PartyNumber AS CustomerNumber,    
  Contracts.SequenceNumber AS SequenceNumber,    
  ReceivableTypes.Name AS ReceivableType,    
  #ReceivableDetailInfo.Amount_Amount AS ReceivableAmount,    
  #ReceivableDetailInfo.Balance_Amount AS ReceivableBalance,    
		#ReceivableDetailInfo.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		#ReceivableDetailInfo.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		#ReceivableDetailInfo.LeaseComponentAmount_Amount AS LeaseComponentAmount,
		#ReceivableDetailInfo.NonLeaseComponentAmount_Amount AS NonLeaseComponentAmount,
  #ReceivableDetailInfo.EffectiveBalance_Amount AS EffectiveReceivableBalance,    
  #ReceivableDetailInfo.TotalBalance_Amount AS TotalReceivableBalance,    
  ISNULL(TaxDetails.Amount_Amount, 0.0) AS TaxAmount,    
  ISNULL(TaxDetails.Balance_Amount, 0.0) AS TaxBalance,    
  ISNULL(TaxDetails.EffectiveBalance_Amount, 0.0) AS EffectiveTaxBalance,    
  ISNULL(#PreviousApplications.AmountApplied_Amount, 0.0) AS PreviousReceivableApplication,    
  ISNULL(#PreviousApplications.ReceivedAmount_Amount, 0.0) AS PreviousReceivedAmount,    
  ISNULL(#PreviousApplications.TaxApplied_Amount, 0.0) AS PreviousTaxApplication,    
  ISNULL(#PreviousApplications.TotalPreviousReceivedTowardsInterest, 0.0) AS TotalPreviousReceivedTowardsInterest,    
  ISNULL(#PreviousApplications.PreviousReceivedTowardsInterest, 0.0) AS PreviousReceivedTowardsInterest,  
  ISNULL(#PreviousApplications.AdjustedWithHoldingTax, 0.0) AS AdjustedWithHoldingTax,    
		ISNULL(#PreviousApplications.LeaseComponentAmountApplied_Amount, 0.0) AS PrevLeaseComponentAppliedAmount,
		ISNULL(#PreviousApplications.NonLeaseComponentAmountApplied_Amount, 0.0) AS PrevNonLeaseComponentAppliedAmount,
  ISNULL(WHT.AdjustedWHTWaivedAmount, 0.0) AS AdjustedWHTWaivedAmount,    
  ISNULL(WHT.WithholdingTaxRate,0.00) WithholdingTaxRate,  
  @HasWHTWaiverReceipts HasWHTWaiverReceipts,  
  #ReceivableDetailInfo.Currency AS Currency,    
  ReceivableTypes.Id AS ReceivableTypeId,    
  ReceivableCodes.Id AS ReceivableCodeId,    
  ReceivableCodes.AccountingTreatment AS AccountingTreatment,    
  LegalEntities.TaxRemittancePreference AS LegalEntityTaxRemittancePreference,    
  Contracts.SalesTaxRemittanceMethod AS ContractTaxRemittancePreference,    
  ReceivableCodes.GLTemplateId AS GLTemplateId,    
  ReceivableCodes.SyndicationGLTemplateId AS SyndicationGLTemplateId,    
  #ReceivableDetailInfo.FunderId AS FunderId,    
  #ReceivableDetailInfo.IsGLPosted AS IsGLPosted,    
  ISNULL(TaxDetails.IsGLPosted, CAST(0 AS BIT)) AS IsTaxGLPosted,   
  ISNULL(TaxDetails.IsCashBased, CAST(0 AS BIT)) AS IsTaxCashBased,
  ReceivableTypes.IsRental AS IsRental,    
  GLTransactionTypes.Name AS GLTransactionType,    
  Funders.PartyName AS FunderName,    
  Contracts.ContractType AS ContractType,    
  Contracts.SyndicationType AS SyndicationType,    
  ReceivableCodes.Name AS ReceivableCodeName,    
  #ReceivableDetailInfo.EntityType AS ReceivableEntityType,    
  #ReceivableDetailInfo.SourceId AS SourceId,    
  #ReceivableDetailInfo.SourceTable AS SourceTable,    
  Contracts.ChargeOffStatus AS ChargeOffStatus,    
  #ReceivableDetailInfo.PaymentScheduleId AS PaymentScheduleId,    
  #ReceivableDetailInfo.IncomeType AS IncomeType,    
  ISNULL(#ReceivableDetailInfo.TotalBookBalance_Amount, 0.0) AS GLBookBalance,    
  ISNULL(#ReceivableDetailInfo.EffectiveBookBalance_Amount, 0.0) AS GLEffectiveBookBalance,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeasePaymentSchedules.PaymentType ELSE LoanPaymentSchedules.PaymentType END AS PaymentType,    
  LegalEntities.LateFeeApproach AS LegalEntityLateFeeApproach,    
  LegalEntities.Id AS LegalEntityId,    
  LegalEntities.LegalEntityNumber AS LegalEntityNumber,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.InstrumentTypeId ELSE LoanFinances.InstrumentTypeId END AS InstrumentTypeId,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.LineofBusinessId ELSE LoanFinances.LineofBusinessId END AS LineofBusinessId,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.CostCenterId ELSE LoanFinances.CostCenterId END AS CostCenterId,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.BranchId ELSE LoanFinances.BranchId END AS BranchId,    
  Parties.IsIntercompany AS IsIntercompany,    
  CASE WHEN #ReceivableDetailInfo.AdjustmentBasisReceivableDetailId IS NOT NULL OR AdjustmentReceivableDetail.ReceivableDetailId IS NOT NULL
		THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsAdjustmentDetail,    
  LeasePaymentSchedules.LeaseFinanceDetailId AS ReceivableLeaseFinanceId,    
  #ReceivableDetailInfo.AssetComponentType,    
  #ChargeOffs.ChargeOffDate AS ChargeOffDate,    
  ISNULL(Contracts.IsNonAccrual,CAST(0 AS BIT)) AS IsNonAccrual,    
  Contracts.NonAccrualDate,    
  LeasePaymentSchedules.StartDate PaymentScheduleStartDate,    
  CASE WHEN  ReceivableTypes.Name ='LeaseFloatRateAdj' THEN LeaseFinanceDetails.FloatIncomeGLTemplateId    
  ELSE   LeaseFinanceDetails.LeaseIncomeGLTemplateId END IncomeGLTemplateId,    
  LeaseFinanceDetails.LeaseContractType,    
  Contracts.AccountingStandard,    
  LeaseFinances.AcquisitionId,    
  Contracts.DealProductTypeId,    
  ISNULL(#ReceivableDetailInfo.IsLeaseAsset,CAST(0 AS BIT)) AS IsLeaseAsset,    
  ISNULL(Contracts.DoubtfulCollectability,CAST(0 AS BIT)) AS DoubtfulCollectability,
  #ReceivableDetailInfo.ReceivableDetailIsActive,
  ISNULL(InvoiceInfo.IsActive,CAST(1 AS BIT))  AS ReceivableInvoiceIsActive, 
  #ReceivableDetailInfo.IsTaxAssessed,
  #ReceivableDetailInfo.TaxType,
  #ReceivableDetailInfo.Amount_Amount AS CreatedAmount,
  ISNULL(TaxDetails.Amount_Amount, 0.0) AS CreatedTaxAmount 
 FROM #ReceivableDetailInfo    
 JOIN ReceivableCodes ON #ReceivableDetailInfo.ReceivableCodeId = ReceivableCodes.Id AND #ReceivableDetailInfo.IsDummy=0    
 JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id    
 JOIN GLTransactionTypes ON ReceivableTypes.GLTransactionTypeId = GLTransactionTypes.Id    
 JOIN Parties ON #ReceivableDetailInfo.CustomerId = Parties.Id    
 JOIN Customers ON #ReceivableDetailInfo.CustomerId = Customers.Id    
 JOIN LegalEntities ON #ReceivableDetailInfo.LegalEntityId = LegalEntities.Id    
 LEFT JOIN #PreviousApplications ON #ReceivableDetailInfo.ReceivableDetailId = #PreviousApplications.ReceivableDetailId    
 LEFT JOIN #WHTWaiverAmountDetails WHT ON  #ReceivableDetailInfo.ReceivableDetailId = WHT.ReceivableDetailId 
 LEFT JOIN #AdjustedReceivableDetails AdjustmentReceivableDetail ON #ReceivableDetailInfo.ReceivableDetailId = AdjustmentReceivableDetail.ReceivableDetailId 
 LEFT JOIN    
 (SELECT #ReceivableDetailInfo.ReceivableDetailId,    
 ReceivableTaxDetails.IsGLPosted,    
 ReceivableTaxes.IsCashBased,
 SUM(ReceivableTaxDetails.Amount_Amount) Amount_Amount,    
 SUM(ReceivableTaxDetails.Balance_Amount) Balance_Amount,    
 SUM(ReceivableTaxDetails.EffectiveBalance_Amount) EffectiveBalance_Amount    
 FROM #ReceivableDetailInfo    
 INNER JOIN ReceivableTaxDetails ON ReceivableTaxDetails.ReceivableDetailId = #ReceivableDetailInfo.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1    
 INNER JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive = 1    
 GROUP BY #ReceivableDetailInfo.ReceivableDetailId,ReceivableTaxDetails.IsGLPosted, ReceivableTaxes.IsCashBased)    
 AS TaxDetails  ON #ReceivableDetailInfo.ReceivableDetailId = TaxDetails.ReceivableDetailId    
 LEFT JOIN Contracts ON #ReceivableDetailInfo.EntityId = Contracts.Id AND #ReceivableDetailInfo.EntityType = 'CT'    
 LEFT JOIN Discountings ON #ReceivableDetailInfo.EntityId = Discountings.Id AND #ReceivableDetailInfo.EntityType = 'DT'    
 LEFT JOIN Parties AS Funders ON #ReceivableDetailInfo.FunderId = Funders.Id    
 LEFT JOIN #ChargeOffs ON #ChargeOffs.ContractId=Contracts.Id    
 LEFT JOIN
	(
		SELECT ReceivableDetails.ReceivableDetailId AS ReceivableDetailId,
		ReceivableInvoiceDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
		ReceivableInvoices.Number AS InvoiceNumber,
		ReceivableInvoices.IsActive
		FROM #ReceivableDetailInfo ReceivableDetails
		JOIN ReceivableInvoiceDetails ON ReceivableDetails.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId
		JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
		AND ReceivableInvoices.IsDummy = 0
		LEFT JOIN #AppliedCancelledInvoices ON ReceivableDetails.ReceivableDetailId = #AppliedCancelledInvoices.ReceivableDetailId
		WHERE ((#AppliedCancelledInvoices.ReceivableInvoiceId = ReceivableInvoices.Id) OR (ReceivableInvoiceDetails.IsActive = 1 AND ReceivableInvoices.IsActive = 1))
	) AS InvoiceInfo ON #ReceivableDetailInfo.ReceivableDetailId = InvoiceInfo.ReceivableDetailId    
 LEFT JOIN LeasePaymentSchedules ON Contracts.ContractType = 'Lease' AND #ReceivableDetailInfo.PaymentScheduleId = LeasePaymentSchedules.Id    
 LEFT JOIN LoanPaymentSchedules ON Contracts.ContractType = 'Loan' AND #ReceivableDetailInfo.PaymentScheduleId = LoanPaymentSchedules.Id    
 LEFT JOIN LeaseFinances ON Contracts.ContractType = 'Lease' AND LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1    
 LEFT JOIN LeaseFinanceDetails ON Contracts.ContractType = 'Lease' AND LeaseFinances.Id=LeaseFinanceDetails.Id    
 LEFT JOIN LoanFinances ON (Contracts.ContractType = 'Loan' OR Contracts.ContractType = 'ProgressLoan') AND LoanFinances.ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1    
END    
ELSE    
BEGIN    
 SELECT     
  #ReceivableDetailInfo.AssetId AS AssetId,    
  #ReceivableDetailInfo.ReceivableId AS ReceivableId,    
  #ReceivableDetailInfo.ReceivableDetailId AS ReceivableDetailId,    
  InvoiceInfo.ReceivableInvoicesId AS ReceivableInvoiceId,    
  InvoiceInfo.ReceivableInvoiceNumber AS InvoiceNumber,    
  #ReceivableDetailInfo.CustomerId AS CustomerId,    
  Contracts.Id AS ContractId,    
  Discountings.Id AS DiscountingId,    
  #ReceivableDetailInfo.DueDate AS DueDate,    
  Parties.PartyName AS CustomerName,    
  Parties.PartyNumber AS CustomerNumber,    
  Contracts.SequenceNumber AS SequenceNumber,    
  ReceivableTypes.Name AS ReceivableType,    
  InvoiceInfo.OriginalAmount_Amount AS ReceivableAmount,    
  InvoiceInfo.Balance_Amount AS ReceivableBalance,    
		#ReceivableDetailInfo.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		#ReceivableDetailInfo.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		#ReceivableDetailInfo.LeaseComponentAmount_Amount AS LeaseComponentAmount,
		#ReceivableDetailInfo.NonLeaseComponentAmount_Amount AS NonLeaseComponentAmount,
  InvoiceInfo.EffectiveBalance_Amount AS EffectiveReceivableBalance,    
  #ReceivableDetailInfo.TotalBalance_Amount AS TotalReceivableBalance,    
  InvoiceInfo.OriginalTaxAmount_Amount AS TaxAmount,    
  InvoiceInfo.TaxBalance_Amount AS TaxBalance,    
  InvoiceInfo.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,    
  ISNULL(#PreviousApplications.AmountApplied_Amount, 0.0) AS PreviousReceivableApplication,   
 ISNULL(#PreviousApplications.ReceivedAmount_Amount, 0.0) AS PreviousReceivedAmount,   
  ISNULL(#PreviousApplications.TaxApplied_Amount, 0.0) AS PreviousTaxApplication,    
  ISNULL(#PreviousApplications.TotalPreviousReceivedTowardsInterest, 0.0) AS TotalPreviousReceivedTowardsInterest,    
  ISNULL(#PreviousApplications.PreviousReceivedTowardsInterest, 0.0) AS PreviousReceivedTowardsInterest,  
  ISNULL(#PreviousApplications.AdjustedWithHoldingTax, 0.0) AS AdjustedWithHoldingTax,    
		ISNULL(#PreviousApplications.LeaseComponentAmountApplied_Amount, 0.0) AS PrevLeaseComponentAppliedAmount,
		ISNULL(#PreviousApplications.NonLeaseComponentAmountApplied_Amount, 0.0) AS PrevNonLeaseComponentAppliedAmount,
  ISNULL(WHT.AdjustedWHTWaivedAmount, 0.0) AS AdjustedWHTWaivedAmount,    
  ISNULL(WHT.WithholdingTaxRate,0.00) WithholdingTaxRate,  
  @HasWHTWaiverReceipts HasWHTWaiverReceipts,  
  #ReceivableDetailInfo.Currency AS Currency,    
  ReceivableTypes.Id AS ReceivableTypeId,    
  ReceivableCodes.Id AS ReceivableCodeId,    
  ReceivableCodes.AccountingTreatment AS AccountingTreatment,    
  LegalEntities.TaxRemittancePreference AS LegalEntityTaxRemittancePreference,    
  Contracts.SalesTaxRemittanceMethod AS ContractTaxRemittancePreference,    
  ReceivableCodes.GLTemplateId AS GLTemplateId,    
  ReceivableCodes.SyndicationGLTemplateId AS SyndicationGLTemplateId,    
  #ReceivableDetailInfo.FunderId AS FunderId,    
  #ReceivableDetailInfo.IsGLPosted AS IsGLPosted,    
  ISNULL(TaxDetails.IsGLPosted, CAST(0 AS BIT)) AS IsTaxGLPosted,    
  ISNULL(TaxDetails.IsCashBased, CAST(0 AS BIT)) AS IsTaxCashBased,
  ReceivableTypes.IsRental AS IsRental,    
  GLTransactionTypes.Name AS GLTransactionType,    
  Funders.PartyName AS FunderName,    
  Contracts.ContractType AS ContractType,    
  Contracts.SyndicationType AS SyndicationType,    ReceivableCodes.Name AS ReceivableCodeName,    
  #ReceivableDetailInfo.EntityType AS ReceivableEntityType,    
  #ReceivableDetailInfo.SourceId AS SourceId,    
  #ReceivableDetailInfo.SourceTable AS SourceTable,    
  Contracts.ChargeOffStatus AS ChargeOffStatus,    
  #ReceivableDetailInfo.PaymentScheduleId AS PaymentScheduleId,    
  #ReceivableDetailInfo.IncomeType AS IncomeType,    
  ISNULL(#ReceivableDetailInfo.TotalBookBalance_Amount, 0.0) AS GLBookBalance,    
  ISNULL(#ReceivableDetailInfo.EffectiveBookBalance_Amount, 0.0) AS GLEffectiveBookBalance,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeasePaymentSchedules.PaymentType ELSE LoanPaymentSchedules.PaymentType END AS PaymentType,    
  LegalEntities.LateFeeApproach AS LegalEntityLateFeeApproach,    
  LegalEntities.Id AS LegalEntityId,    
  LegalEntities.LegalEntityNumber AS LegalEntityNumber,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.InstrumentTypeId ELSE LoanFinances.InstrumentTypeId END AS InstrumentTypeId,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.LineofBusinessId ELSE LoanFinances.LineofBusinessId END AS LineofBusinessId,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.CostCenterId ELSE LoanFinances.CostCenterId END AS CostCenterId,    
  CASE WHEN Contracts.ContractType = 'Lease' THEN LeaseFinances.BranchId ELSE LoanFinances.BranchId END AS BranchId,    
  Parties.IsIntercompany AS IsIntercompany,    
  CASE WHEN #ReceivableDetailInfo.AdjustmentBasisReceivableDetailId IS NOT NULL OR AdjustmentReceivableDetail.ReceivableDetailId IS NOT NULL
		THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsAdjustmentDetail,    
  LeasePaymentSchedules.LeaseFinanceDetailId AS ReceivableLeaseFinanceId,    
  #ReceivableDetailInfo.AssetComponentType,    
  ISNULL(InvoiceInfo.InvoiceTypeName,'_') AS InvoiceType,    
  InvoiceInfo.RemitToName AS RemitTo,    
  InvoiceInfo.BillToeName AS BillToe,    
  #ChargeOffs.ChargeOffDate AS ChargeOffDate,    
  ISNULL(Contracts.IsNonAccrual,CAST(0 AS BIT)) AS IsNonAccrual,    
  Contracts.NonAccrualDate,    
  LeasePaymentSchedules.StartDate PaymentScheduleStartDate,    
  CASE WHEN  ReceivableTypes.Name ='LeaseFloatRateAdj' THEN LeaseFinanceDetails.FloatIncomeGLTemplateId    
  ELSE   LeaseFinanceDetails.LeaseIncomeGLTemplateId END IncomeGLTemplateId,    
  LeaseFinanceDetails.LeaseContractType,    
  Contracts.AccountingStandard,    
  LeaseFinances.AcquisitionId,    
  Contracts.DealProductTypeId,    
  ISNULL(#ReceivableDetailInfo.IsLeaseAsset,CAST(0 AS BIT)) AS IsLeaseAsset,    
  ISNULL(Contracts.DoubtfulCollectability,CAST(0 AS BIT)) AS DoubtfulCollectability,
  #ReceivableDetailInfo.ReceivableDetailIsActive,
   ISNULL(InvoiceInfo.IsActive,CAST(0 AS BIT)) AS ReceivableInvoiceIsActive, 
  #ReceivableDetailInfo.IsTaxAssessed,
  InvoiceInfo.ReceivableInvoiceDueDate AS InvoiceDueDate,
  #ReceivableDetailInfo.TaxType,
  #ReceivableDetailInfo.Amount_Amount AS CreatedAmount,
  ISNULL(TaxDetails.Amount_Amount, 0.0) AS CreatedTaxAmount 
 FROM    
 #ReceivableDetailInfo    
 JOIN ReceivableCodes ON #ReceivableDetailInfo.ReceivableCodeId = ReceivableCodes.Id    
 JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id    
 JOIN GLTransactionTypes ON ReceivableTypes.GLTransactionTypeId = GLTransactionTypes.Id    
 JOIN Parties ON #ReceivableDetailInfo.CustomerId = Parties.Id    
 JOIN LegalEntities ON #ReceivableDetailInfo.LegalEntityId = LegalEntities.Id    
 LEFT JOIN    
 (SELECT #ReceivableDetailInfo.ReceivableDetailId AS ReceivableDetailId,    
 ReceivableInvoiceDetails.ReceivableInvoiceId AS ReceivableInvoiceId,    
 ReceivableInvoices.Number AS InvoiceNumber, 
 ReceivableInvoices.IsActive,
 RemitToes.Name AS RemitToName,    
 BillToes.Name AS BillToeName,    
 InvoiceTypes.Name AS InvoiceTypeName,    
 ReceivableInvoiceDetails.InvoiceAmount_Amount As OriginalAmount_Amount,    
 ReceivableInvoiceDetails.Balance_Amount As Balance_Amount,    
 ReceivableInvoiceDetails.EffectiveBalance_Amount As EffectiveBalance_Amount,    
 ReceivableInvoiceDetails.InvoiceTaxAmount_Amount As OriginalTaxAmount_Amount,    
 ReceivableInvoiceDetails.TaxBalance_Amount As TaxBalance_Amount,    
 ReceivableInvoiceDetails.EffectiveTaxBalance_Amount  As EffectiveTaxBalance_Amount,    
 ReceivableInvoices.Id As  ReceivableInvoicesId,    
 ReceivableInvoices.Number As  ReceivableInvoiceNumber,
 ReceivableInvoices.DueDate AS ReceivableInvoiceDueDate
 FROM #ReceivableDetailInfo    
 JOIN ReceivableInvoiceDetails ON #ReceivableDetailInfo.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId    
 JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id    
 AND ReceivableInvoices.IsDummy = 0    
 JOIN BillToes ON ReceivableInvoices.BillToId = BillToes.Id    
 JOIN RemitToes ON ReceivableInvoices.RemitToId = RemitToes.Id    
 JOIN ReceivableCategories ON ReceivableInvoiceDetails.ReceivableCategoryId = ReceivableCategories.Id    
 LEFT JOIN #AppliedCancelledInvoices ON #ReceivableDetailInfo.ReceivableDetailId = #AppliedCancelledInvoices.ReceivableDetailId
		LEFT JOIN InvoiceTypes ON ReceivableCategories.InvoiceTypeId = InvoiceTypes.Id
		WHERE ((#AppliedCancelledInvoices.ReceivableInvoiceId = ReceivableInvoices.Id) OR (ReceivableInvoiceDetails.IsActive = 1 AND ReceivableInvoices.IsActive = 1))
	) AS InvoiceInfo ON #ReceivableDetailInfo.ReceivableDetailId = InvoiceInfo.ReceivableDetailId
 LEFT JOIN #PreviousApplications ON #ReceivableDetailInfo.ReceivableDetailId = #PreviousApplications.ReceivableDetailId 
 LEFT JOIN #WHTWaiverAmountDetails WHT ON  #ReceivableDetailInfo.ReceivableDetailId = WHT.ReceivableDetailId  
 LEFT JOIN #AdjustedReceivableDetails AdjustmentReceivableDetail ON #ReceivableDetailInfo.ReceivableDetailId = AdjustmentReceivableDetail.ReceivableDetailId 
 LEFT JOIN Contracts ON #ReceivableDetailInfo.EntityId = Contracts.Id AND #ReceivableDetailInfo.EntityType = 'CT'    
 LEFT JOIN Discountings ON #ReceivableDetailInfo.EntityId = Discountings.Id AND #ReceivableDetailInfo.EntityType = 'DT'    
 LEFT JOIN Parties AS Funders ON #ReceivableDetailInfo.FunderId = Funders.Id    
 LEFT JOIN #ChargeOffs ON #ChargeOffs.ContractId=Contracts.Id    
 LEFT JOIN    
 (SELECT #ReceivableDetailInfo.ReceivableDetailId,    
 ReceivableTaxDetails.IsGLPosted,    
 ReceivableTaxes.IsCashBased,
 SUM(ReceivableTaxDetails.Amount_Amount) Amount_Amount,    
 SUM(ReceivableTaxDetails.Balance_Amount) Balance_Amount,    
 SUM(ReceivableTaxDetails.EffectiveBalance_Amount) EffectiveBalance_Amount    
 FROM #ReceivableDetailInfo    
 INNER JOIN ReceivableTaxDetails ON ReceivableTaxDetails.ReceivableDetailId = #ReceivableDetailInfo.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1    
 INNER JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive = 1    
 GROUP BY #ReceivableDetailInfo.ReceivableDetailId,ReceivableTaxDetails.IsGLPosted, ReceivableTaxes.IsCashBased)    
 AS TaxDetails ON #ReceivableDetailInfo.ReceivableDetailId = TaxDetails.ReceivableDetailId    
 LEFT JOIN LeasePaymentSchedules ON Contracts.ContractType = 'Lease' AND #ReceivableDetailInfo.PaymentScheduleId = LeasePaymentSchedules.Id    
 LEFT JOIN LoanPaymentSchedules ON Contracts.ContractType = 'Loan' AND #ReceivableDetailInfo.PaymentScheduleId = LoanPaymentSchedules.Id    
 LEFT JOIN LeaseFinances ON Contracts.ContractType = 'Lease' AND LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1    
 LEFT JOIN LoanFinances ON (Contracts.ContractType = 'Loan' OR Contracts.ContractType = 'ProgressLoan') AND LoanFinances.ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1    
 LEFT JOIN LeaseFinanceDetails ON Contracts.ContractType = 'Lease' AND LeaseFinances.Id=LeaseFinanceDetails.Id    
END    
DROP TABLE #ReceivableDetailInfo;    
DROP TABLE #PreviousApplications;    
DROP TABLE #WHTWaiverAmountDetails ;
DROP TABLE #AdjustedReceivableDetails;
DROP TABLE #AppliedCancelledInvoices;
DROP TABLE #ChargeOffs;

END

GO
