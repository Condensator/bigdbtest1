SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ValidateReceiptMigration]  
(  
 @CreatedById BIGINT,
 @CreatedTime DATETIMEOFFSET,
 @ContractTypeValues_Lease NVARCHAR(20),
 @ContractTypeValues_Loan NVARCHAR(20),
 @ReceivableEntityTypeValues_CT NVARCHAR(20),
 @IncomeTypeValues_None NVARCHAR(20),
 @ReceivableTypeValues_Sundry NVARCHAR(20),
 @ReceivableTypeValues_SundrySeparate NVARCHAR(20),
 @ReceivableTypeValues_SecurityDeposit NVARCHAR(20),
 @ReceivableTypeValues_InsurancePremiumAdmin NVARCHAR(20),
 @ReceivableTypeValues_InsurancePremium NVARCHAR(20),
 @ReceivableTypeValues_CPIBaseRental NVARCHAR(20),
 @ReceivableTypeValues_CPIOverage NVARCHAR(20),
 @ReceivableTypeValues_PropertyTaxEscrow NVARCHAR(20),
 @ReceivableTypeValues_PropertyTax NVARCHAR(20),
 @ReceivableTypeValues_Scrape NVARCHAR(20),
 @ReceivableTypeValues_LeasePayOff NVARCHAR(20),
 @ReceivableTypeValues_BuyOut NVARCHAR(20),
 @ReceivableTypeValues_AssetSale NVARCHAR(20),
 @LegalEntityStatusValues_Inactive NVARCHAR(20),
 @ContractStatusValues_Commenced NVARCHAR(20),
 @ContractStatusValues_Uncommenced NVARCHAR(20),
 @JobStepInstanceId BIGINT
)
AS  

BEGIN
DECLARE @ValidRecordsCount BIGINT;  
 
CREATE TABLE #UpdatedRMEIds
(
UpdatedIds INT NOT NULL
)

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (RME.LegalEntityNumber IS NOT NULL AND (LE.LegalEntityNumber IS NULL OR LE.[Status]=@LegalEntityStatusValues_Inactive)) 
	THEN 'Legal Entity Number provided is either invalid or inactive'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME LEFT OUTER JOIN LegalEntities AS LE
ON RME.LegalEntityNumber = LE.LegalEntityNumber AND RME.JobStepInstanceId = @JobStepInstanceId 
WHERE RME.IsValid=1 AND RME.IsProcessed=0

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (C.SequenceNumber IS NULL )
	THEN 'Contract Sequence Number provided is invalid or blank.'
	WHEN (RME.ContractSequenceNumber IS NOT NULL AND (C.[Status] NOT IN (@ContractStatusValues_Commenced,@ContractStatusValues_Uncommenced) )) 
	THEN 'Status of the Contract must either be commenced or uncommenced'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME LEFT OUTER JOIN Contracts AS C
ON RME.ContractSequenceNumber = C.SequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId 
WHERE RME.IsValid=1 AND RME.IsProcessed=0

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

DECLARE @AllowInterCompanyTransfer AS BIT;
SET @AllowInterCompanyTransfer = (SELECT CASE WHEN Value='True' THEN 1 ELSE 0 END AS Value FROM GlobalParameters WHERE Name='AllowInterCompanyTransfer' AND Category = 'Receipt');
IF(@AllowInterCompanyTransfer IS NULL)BEGIN SET @AllowInterCompanyTransfer=0 END;

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (@AllowInterCompanyTransfer = 0 AND LE.Id!=LF.LegalEntityId)
	THEN 'Legal Entity provided should match with the Contract Legal Entity when value for allow inter-company transfer(Global Parameter) is set to false'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
LEFT OUTER JOIN LegalEntities LE ON RME.LegalEntityNumber=LE.LegalEntityNumber
LEFT OUTER JOIN Contracts C ON RME.ContractSequenceNumber = C.SequenceNumber
LEFT OUTER JOIN LeaseFinances LF ON C.Id=LF.ContractId
WHERE RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (@AllowInterCompanyTransfer = 0 AND LE.Id!=LF.LegalEntityId)
	THEN 'Legal Entity provided should match with the Contract Legal Entity when value for allow inter-company transfer(Global Parameter) is set to false'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
LEFT OUTER JOIN LegalEntities LE ON RME.LegalEntityNumber=LE.LegalEntityNumber
LEFT OUTER JOIN Contracts C ON RME.ContractSequenceNumber = C.SequenceNumber
LEFT OUTER JOIN LoanFinances LF ON C.Id=LF.ContractId
WHERE RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
	CASE 
	WHEN (RME.PostDate NOT BETWEEN GLFOP.FROMDate AND GLFOP.ToDate)
	THEN 'Post Date of the receipt must fall within the GL Financial Open Period of the LegalEntity'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
LEFT OUTER JOIN LegalEntities LE ON RME.LegalEntityNumber=LE.LegalEntityNumber
LEFT OUTER JOIN GLFinancialOpenPeriods GLFOP ON LE.Id=GLFOP.LegalEntityId
WHERE RME.IsValid=1 AND RME.IsProcessed=0 AND GLFOP.IsCurrent=1
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract 
SET
ErrorMessage=
	CASE 
	WHEN (RME.IsPureUnallocatedCash=1 AND RRDME.ReceiptMigrationId IS NOT NULL)
	THEN 'Receipt with IsPureUnallocatedCash set to true must not have any receivables linked to it'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
LEFT OUTER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId
WHERE RME.IsValid=1 AND RME.IsProcessed=0 AND RRDME.ReceiptMigrationId IS NOT NULL
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
	CASE 
	WHEN (RME.ReceiptAmount_Amount<0)
	THEN 'Receipt Amount should be greater than zero.'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
	FROM ReceiptMigration_Extract RME 
WHERE RME.IsPureUnallocatedCash =0 
AND RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds) AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

SELECT RME.ReceiptMigrationId AS ReceiptId,
ErrorMessage=
	CASE 
	WHEN ((RME.TotalAmountToApply_Amount) != ISNULL(SUM(RRDME.AmountToApply_Amount),0.00))
	OR ((RME.TotalTaxAmountToApply_Amount) != ISNULL(SUM(RRDME.TaxAmountToApply_Amount),0.00))
	THEN 'Total Amount to Apply/ Total Tax Amount to apply in receipt level must be equal to the sum of Amount to Apply/ Tax Amount to Apply against each receivable.'
	END
INTO #ReceiptsWithInvalidAmountToApplyForMigration
FROM ReceiptMigration_Extract RME 
LEFT JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId
WHERE RME.IsPureUnallocatedCash =0 
AND  RME.IsValid=1 AND RME.IsProcessed=0 
AND RRDME.ReceiptMigrationId IS NOT NULL
AND RME.JobStepInstanceId = @JobStepInstanceId 
AND RRDME.JobStepInstanceId= @JobStepInstanceId
GROUP BY RME.ReceiptMigrationId,RME.TotalAmountToApply_Amount,RME.TotalTaxAmountToApply_Amount

UPDATE ReceiptMigration_Extract 
SET
ErrorMessage= 'Total Amount to Apply/ Total Tax Amount to apply in receipt level must be equal to the sum of Amount to Apply/ Tax Amount to Apply against each receivable'
OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
LEFT  JOIN #ReceiptsWithInvalidAmountToApplyForMigration RIAAM ON RME.ReceiptMigrationId=RIAAM.ReceiptId
WHERE RIAAM.ErrorMessage IS NOT NULL
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract 
SET
ErrorMessage=
	CASE 
	WHEN (RME.ReceiptAmount_Amount < RME.TotalAmountToApply_Amount+RME.TotalTaxAmountToApply_Amount)
	THEN 'Receipt Amount must be greater than or equal to the sum of Total amount to apply and Total Tax amount to apply'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
WHERE RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract 
SET
ErrorMessage=
	CASE 
	WHEN (RME.ReceiptAmount_Amount > RME.TotalAmountToApply_Amount+RME.TotalTaxAmountToApply_Amount AND RME.CashTypeName IS NULL)
	THEN 'Cash Type is mandatory when the Receipt Balance is greater than zero.'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
WHERE RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds) 
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (CC.Id != C.CurrencyId)
	THEN 'Receipt Currency does not match with the Contract Currency.'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME
LEFT OUTER JOIN Currencies CC ON RME.CurrencyCode=CC.[Name]
LEFT OUTER JOIN Contracts AS C ON RME.ContractSequenceNumber = C.SequenceNumber
WHERE RME.IsValid=1 AND RME.IsProcessed=0 AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (RME.ReceiptGLTemplateName IS NOT NULL AND(GLT.[Name] IS NULL))
	THEN 'Receipt GL Tempate provided does not exist in the system'
	WHEN (RME.ReceiptGLTemplateName IS NULL)
	THEN 'Receipt GL Tempate must be provided'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME
LEFT OUTER JOIN GLTemplates GLT ON RME.ReceiptGLTemplateName=GLT.[Name]
WHERE RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds) AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (GLT.GLConfigurationId!=LE.GLConfigurationId)
	THEN 'Receipt GL Tempate provided must be of Type ReceiptCash and the GL Configuration must match that of the Receipt and Contract Legal Entity'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME
LEFT OUTER JOIN GLTemplates GLT ON RME.ReceiptGLTemplateName=GLT.[Name]
LEFT OUTER JOIN Contracts AS C ON RME.ContractSequenceNumber = C.SequenceNumber
LEFT OUTER JOIN LeaseFinances LF ON C.Id=LF.ContractId
LEFT OUTER JOIN LegalEntities LE ON LF.LegalEntityId=LE.Id
WHERE RME.IsValid=1 AND RME.IsProcessed=0 AND RME.ReceiptGLTemplateName IS NOT NULL
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds) AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

UPDATE ReceiptMigration_Extract 
SET
ErrorMessage=
	CASE 
	WHEN (RME.IsPureUnallocatedCash=0 AND RRDME.ReceiptMigrationId IS NULL)
	THEN 'There must be atleast one receivable associated to the receipt if IsPureUnallocatedCash is false'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
LEFT OUTER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId
WHERE RME.IsValid=1 AND RME.IsProcessed=0 AND RRDME.ReceiptMigrationId IS NULL
AND RME.JobStepInstanceId = @JobStepInstanceId 
AND RRDME.JobStepInstanceId= @JobStepInstanceId

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds

SELECT  ReceiptId,COUNT(ReceivableId) AS ReceivableCount
INTO #ReceiptReceivableMappingForMigration
FROM
(
SELECT   RMED.ReceiptMigrationId AS ReceiptId
   ,R.Id AS ReceivableId  
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId    AND RD.EffectiveBalance_Amount != 0.00
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Lease 
   AND C.SequenceNumber IS NOT NULL
   LEFT JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId   
   LEFT JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate AND RT.Name = RRDME.ReceivableType AND RRDME.JobStepInstanceId= @JobStepInstanceId
   INNER JOIN LeaseFinances LF ON C.Id=LF.ContractId
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId   AND RTXD.EffectiveBalance_Amount != 0.00
   INNER JOIN LeasePaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType
   AND LPS.PaymentNumber=RRDME.PaymentNumber
   RIGHT JOIN ReceiptMigration_Extract RMED ON RME.ReceiptMigrationId=RMED.ReceiptMigrationId AND RME.JobStepInstanceId = @JobStepInstanceId 
   WHERE RMED.IsValid=1 AND RMED.IsProcessed=0 AND RT.Name != @ReceivableTypeValues_CPIBaseRental
   UNION ALL
	SELECT   RMED.ReceiptMigrationId AS ReceiptId
   ,R.Id AS ReceivableId  
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId    AND RD.EffectiveBalance_Amount != 0.00
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Lease 
   AND C.SequenceNumber IS NOT NULL
   LEFT JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId   
   LEFT JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate AND RT.Name = RRDME.ReceivableType AND RRDME.JobStepInstanceId= @JobStepInstanceId
   INNER JOIN LeaseFinances LF ON C.Id=LF.ContractId
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId   AND RTXD.EffectiveBalance_Amount != 0.00
   INNER JOIN CPUPaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType
   AND LPS.PaymentNumber=RRDME.PaymentNumber
   RIGHT JOIN ReceiptMigration_Extract RMED ON RME.ReceiptMigrationId=RMED.ReceiptMigrationId AND RME.JobStepInstanceId = @JobStepInstanceId 
   WHERE RMED.IsValid=1 AND RMED.IsProcessed=0 AND RT.Name = @ReceivableTypeValues_CPIBaseRental
   UNION ALL
   SELECT   RMED.ReceiptMigrationId  AS ReceiptId
   ,R.Id AS ReceivableId  
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId    AND RD.EffectiveBalance_Amount != 0.00
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Loan 
   AND C.SequenceNumber IS NOT NULL
   LEFT JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId 
   LEFT JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate AND RT.[Name]=RRDME.ReceivableType AND RRDME.JobStepInstanceId= @JobStepInstanceId
   INNER JOIN LoanFinances LF ON C.Id=LF.ContractId
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId   AND RTXD.EffectiveBalance_Amount != 0.00
   INNER JOIN LoanPaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType
   AND LPS.PaymentNumber=RRDME.PaymentNumber
   RIGHT JOIN ReceiptMigration_Extract RMED ON RME.ReceiptMigrationId=RMED.ReceiptMigrationId AND RME.JobStepInstanceId = @JobStepInstanceId 
   WHERE RMED.IsValid=1 AND RMED.IsProcessed=0
   UNION ALL
   SELECT   
  RMED.ReceiptMigrationId AS ReceiptId,
   R.Id AS ReceivableId
   FROM Receivables R  
   LEFT JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId  AND RD.EffectiveBalance_Amount != 0.00
   LEFT JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   LEFT JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   LEFT JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id  
   LEFT JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Lease 
   AND C.SequenceNumber IS NOT NULL
   LEFT JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId    
   LEFT JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate AND RT.Name = RRDME.ReceivableType AND RRDME.JobStepInstanceId= @JobStepInstanceId
   AND RRDME.PaymentNumber IS NULL
   LEFT JOIN LeaseFinances LF ON C.Id=LF.ContractId
   AND RT.[Name]=RRDME.ReceivableType 
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId   AND RTXD.EffectiveBalance_Amount != 0.00
   RIGHT JOIN ReceiptMigration_Extract RMED ON RME.ReceiptMigrationId=RMED.ReceiptMigrationId AND RME.JobStepInstanceId = @JobStepInstanceId 
   WHERE RMED.IsValid=1 AND RMED.IsProcessed=0
   AND R.IncomeType=@IncomeTypeValues_None
   AND RRDME.ReceivableType IN (@ReceivableTypeValues_Sundry,@ReceivableTypeValues_SecurityDeposit,@ReceivableTypeValues_InsurancePremiumAdmin,@ReceivableTypeValues_InsurancePremium
   ,@ReceivableTypeValues_SundrySeparate,@ReceivableTypeValues_CPIOverage,@ReceivableTypeValues_PropertyTaxEscrow,@ReceivableTypeValues_PropertyTax,@ReceivableTypeValues_Scrape
   ,@ReceivableTypeValues_LeasePayOff,@ReceivableTypeValues_BuyOut,@ReceivableTypeValues_AssetSale)
   GROUP BY RMED.ReceiptMigrationId,R.Id
      )
   AS #ReceiptReceivableMappingForMigration
   GROUP BY ReceiptId
      
   UPDATE ReceiptMigration_Extract 
SET
ErrorMessage=
	CASE 
	WHEN (RME.IsPureUnallocatedCash=0 AND RRMM.ReceivableCount = 0 )
	THEN 'No receivables found for the given criteria with effective balance.'
	END
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
LEFT JOIN #ReceiptReceivableMappingForMigration RRMM ON RME.ReceiptMigrationId=RRMM.ReceiptId
WHERE RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds
 
   SELECT   RME.ReceiptMigrationId  AS ReceiptId,RME.JobStepInstanceId 
   INTO #ReceiptsWithDSLReceivables
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId    AND RD.EffectiveBalance_Amount != 0.00
   INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType=@ReceivableEntityTypeValues_CT AND C.ContractType=@ContractTypeValues_Lease
   AND C.SequenceNumber IS NOT NULL
   LEFT JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber  
   LEFT JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId 
   AND R.DueDate = RRDME.DueDate
   INNER JOIN LoanFinances LF ON C.Id=LF.ContractId
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id  AND RT.[Name]=RRDME.ReceivableType
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId  
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId   
   AND RTXD.EffectiveBalance_Amount != 0.00
   INNER JOIN LoanPaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id 
   AND LPS.PaymentType = RRDME.PaymentType
   AND LPS.PaymentNumber=RRDME.PaymentNumber
   WHERE RME.IsValid=1 AND RME.IsProcessed=0 AND R.IsDSL=1 AND RME.JobStepInstanceId=@JobStepInstanceId
   GROUP BY RME.ReceiptMigrationId,RME.JobStepInstanceId
   
   UPDATE ReceiptMigration_Extract 
SET
ErrorMessage= 'Posting receipt towards DSL Receivables is not supported.'
	OUTPUT INSERTED.Id INTO #UpdatedRMEIds
FROM ReceiptMigration_Extract RME 
INNER JOIN #ReceiptsWithDSLReceivables RRMM ON RME.ReceiptMigrationId=RRMM.ReceiptId AND RME.JobStepInstanceId=RRMM.JobStepInstanceId
WHERE RME.IsValid=1 AND RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId 
DELETE FROM #UpdatedRMEIds
 
SELECT   
   RRDME.ReceiptMigrationId AS ReceiptId
   ,RRDME.Id
   ,(ISNULL(R.TotalEffectiveBalance_Amount,0.00)) AS TotalEffectiveBalance
   ,(RRDME.AmountToApply_Amount) AS TotalAmountToApply_Amount
   ,(ISNULL(RTX.EffectiveBalance_Amount,0.00)) AS TotalEffectiveTaxBalance 
   ,(RRDME.TaxAmountToApply_Amount) AS TotalTaxAmountToApply_Amount
   ,@JobStepInstanceId AS JobStepInstanceId
   INTO #SundryPostingAmountDetailsForMigrations
   FROM Receivables R  
   INNER JOIN ReceivableDetails RD ON R.Id=RD.ReceivableId   
   AND RD.EffectiveBalance_Amount != 0.00
   INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id
   INNER JOIN GLTemplates GLT ON RC.GLTemplateId=GLT.Id
   INNER JOIN GLTransactionTypes GLTT ON GLT.GLTransactionTypeId=GLTT.Id
   INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id  
   INNER JOIN Contracts C ON R.EntityId = C.Id 
   AND R.EntityType=@ReceivableEntityTypeValues_CT AND R.IncomeType=@IncomeTypeValues_None
   AND C.SequenceNumber IS NOT NULL
   INNER JOIN ReceiptMigration_Extract RME ON C.SequenceNumber=RME.ContractSequenceNumber AND RME.JobStepInstanceId = @JobStepInstanceId 
   INNER JOIN ReceiptReceivableDetailMigration_Extract RRDME ON RME.ReceiptMigrationId=RRDME.ReceiptMigrationId
   AND R.DueDate = RRDME.DueDate
   AND RT.[Name]=RRDME.ReceivableType
   AND RRDME.JobStepInstanceId= @JobStepInstanceId
   AND RRDME.ReceivableType IN  (@ReceivableTypeValues_Sundry,@ReceivableTypeValues_SecurityDeposit,@ReceivableTypeValues_InsurancePremiumAdmin,@ReceivableTypeValues_InsurancePremium  
   ,@ReceivableTypeValues_SundrySeparate,@ReceivableTypeValues_CPIOverage,@ReceivableTypeValues_PropertyTaxEscrow,@ReceivableTypeValues_PropertyTax,@ReceivableTypeValues_Scrape  
   ,@ReceivableTypeValues_LeasePayOff,@ReceivableTypeValues_BuyOut,@ReceivableTypeValues_AssetSale)
   LEFT JOIN ReceivableTaxes RTX ON R.Id = RTX.ReceivableId
   LEFT JOIN ReceivableTaxDetails RTXD ON RD.Id=RTXD.ReceivableDetailId
   AND RTXD.EffectiveBalance_Amount != 0.00
   WHERE RD.IsActive=1
   AND RME.IsValid=1
   AND RME.IsProcessed != 1
   GROUP BY RRDME.ReceiptMigrationId,RRDME.Id
   ,RRDME.AmountToApply_Amount,RRDME.TaxAmountToApply_Amount
   ,R.Id
   ,R.TotalEffectiveBalance_Amount
   ,RTX.EffectiveBalance_Amount

SELECT 
   RRDME.ReceiptMigrationId AS ReceiptId
   ,RRDME.AmountToApply_Amount AS TotalAmountToApply_Amount
   ,RRDME.TaxAmountToApply_Amount AS TotalTaxAmountToApply_Amount
,SUM(SPADMs.TotalEffectiveBalance) AS TotalEffectiveBalance
,SUM(SPADMs.TotalEffectiveTaxBalance) AS TotalEffectiveTaxAmount
INTO #SundryPostingAmountDetailsForMigration
FROM ReceiptReceivableDetailMigration_Extract rrdme
JOIN #SundryPostingAmountDetailsForMigrations SPADMs ON RRDME.Id=SPADMs.id AND SPADMs.ReceiptId=RRDME.receiptmigrationid
WHERE RRDME.JobStepInstanceId= @JobStepInstanceId
GROUP BY RRDME.ReceiptMigrationId,RRDME.Id,RRDME.AmountToApply_Amount,RRDME.TaxAmountToApply_Amount

UPDATE ReceiptMigration_Extract SET  
ErrorMessage=  
 CASE   
 WHEN ((SPADM.TotalAmountToApply_Amount != 0.00 AND (SPADM.TotalEffectiveBalance !=  SPADM.TotalAmountToApply_Amount)) OR 
 (SPADM.TotalTaxAmountToApply_Amount != 0.00 AND(SPADM.TotalEffectiveTaxAmount !=  SPADM.TotalTaxAmountToApply_Amount)))  
 THEN 'Partial posting against multiple non-rental receivables is not supported.'  
 END  
 OUTPUT INSERTED.Id INTO #UpdatedRMEIds  
FROM ReceiptMigration_Extract RME   
LEFT JOIN #SundryPostingAmountDetailsForMigration SPADM ON RME.ReceiptMigrationId=SPADM.ReceiptId  
WHERE RME.IsValid=1 AND RME.IsProcessed=0  
AND RME.JobStepInstanceId = @JobStepInstanceId 

UPDATE ReceiptMigration_Extract SET IsValid=0 WHERE ErrorMessage IS NOT NULL AND Id in (SELECT Id FROM #UpdatedRMEIds)
AND JobStepInstanceId = @JobStepInstanceId   

DELETE FROM #UpdatedRMEIds 

SELECT RME.ReceiptMigrationId, RME.JobStepInstanceId, LE.LegalEntityNumber, BA.Id BankAccountId, BA.LegalEntityAccountNumber, ISNULL(BA.AccountType,'') AccountType, BB.ID BankBranchId, BB.[BankName], BB.[Name] BranchName
INTO #ReceiptsLegalEnityBankAccountsForMigration
FROM ReceiptMigration_Extract RME
INNER JOIN LegalEntities LE ON RME.LegalEntityNumber=LE.LegalEntityNumber AND LE.Status='Active'
INNER JOIN LegalEntityBankAccounts LEBA ON LEBA.LegalEntityId=LE.Id AND LEBA.IsActive=1
INNER JOIN Currencies CC ON RME.CurrencyCode=CC.[Name] AND CC.IsActive=1
LEFT JOIN BankAccounts BA ON LEBA.BankAccountId=BA.Id AND  BA.LegalEntityAccountNumber = RME.BankAccountNumber AND BA.IsActive=1
LEFT JOIN BankBranches BB ON BA.BankBranchId=BB.ID AND  BB.[BankName] = RME.[BankAccountBankName] AND BB.[Name]=RME.[BankAccountBranchName]
WHERE (BA.CurrencyId IS NULL  OR CC.Id = BA.CurrencyId )
AND RME.JobStepInstanceId = @JobStepInstanceId 
AND RME.IsValid=1 
And RME.IsProcessed=0

SELECT ReceiptMigrationId,Count(BankBranchId) BankAccountCount
INTO #ReceiptsWithInvalidBankAccountsForMigration
FROM #ReceiptsLegalEnityBankAccountsForMigration
GROUP BY ReceiptMigrationId,JobStepInstanceId,LegalEntityNumber

UPDATE ReceiptMigration_Extract SET
ErrorMessage=
CASE 
	WHEN (BankAccountCount=0)
	THEN
	'Bank account provided is either invalid or not linked to the Receipt Legal Entity.'
	WHEN (BankAccountCount>1)
	THEN
	'Multiple bank accounts for the Legal Entity Number, Currency Code and last 4 digits of the bank account number provided.'
	END
,IsValid=0
FROM ReceiptMigration_Extract RME
INNER JOIN #ReceiptsWithInvalidBankAccountsForMigration RIBAM ON RME.ReceiptMigrationId=RIBAM.ReceiptMigrationId
WHERE RME.IsValid=1 
And RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 
AND BankAccountCount <>1  

DROP TABLE #ReceiptsWithInvalidBankAccountsForMigration

UPDATE ReceiptMigration_Extract SET
ErrorMessage='Bank account linked to the Receipt Legal Entity is invalid, account type must be either Receiving or Both.'
,IsValid=0
FROM ReceiptMigration_Extract RME
INNER JOIN #ReceiptsLegalEnityBankAccountsForMigration RLEBAM ON RME.ReceiptMigrationId=RLEBAM.ReceiptMigrationId  AND RLEBAM.BankAccountId IS NOT NULL
WHERE RME.IsValid=1 
And RME.IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 
AND AccountType NOT IN ('Both','Receiving')

DROP TABLE #ReceiptsLegalEnityBankAccountsForMigration

DROP TABLE #UpdatedRMEIds
 
SELECT @ValidRecordsCount = IsNull(COUNT(Id), 0) FROM ReceiptMigration_Extract RME WHERE IsValid=1 AND IsProcessed=0
AND RME.JobStepInstanceId = @JobStepInstanceId 

IF(@ValidRecordsCount>0)
RETURN 1

ELSE
RETURN 0

END

GO
