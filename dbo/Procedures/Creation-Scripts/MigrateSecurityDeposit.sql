SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateSecurityDeposit]
(
	@UserId BIGINT ,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT,
	@ToolIdentifier INT
)
AS
--DECLARE @UserId BIGINT, @ModuleIterationStatusId BIGINT, @CreatedTime DATETIMEOFFSET = NULL
--DECLARE @ProcessedRecords BIGINT 
--DECLARE @FailedRecords BIGINT  
--SET @UserId = 1
--SELECT @ModuleIterationStatusId=IsNull(MAX(ModuleIterationStatusId),0) from stgProcessingLog;
--SET @CreatedTime =  SYSDATETIMEOFFSET()
BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON
DECLARE @Status NVARCHAR(20)
DECLARE @TypeSecurityDeposit NVARCHAR(20)
DECLARE @GlobalParamValue nvarchar(5)
SET @GlobalParamValue = ISNULL((SELECT Value FROM GlobalParameters WHERE Category = 'Sundry' AND name = 'DoNotAssessTaxForTaxExemptSundries') , 0)
SET @Status = 'Active'
SET @TypeSecurityDeposit = 'SecurityDeposit'
DECLARE @Counter INT = 0;
	DECLARE @TakeCount INT = 50000;
	DECLARE @SkipCount INT = 0;
	DECLARE @MaxSecurityDepositId INT = 0;
	DECLARE @MaxErrorStagingRootEntityId INT = 0;
	SET @FailedRecords = 0;
	SET @ProcessedRecords = 0;
	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgSecurityDeposit WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier));
	SET @MaxSecurityDepositId = 0;
	DECLARE @BatchCount INT = 0
	DECLARE @CurrentBusinessDate DATE;

	SELECT TOP 1 @CurrentBusinessDate=[BU].[CurrentBusinessDate] FROM [BusinessUnits] AS [BU] WHERE [BU].[IsDefault] = 1
	SET @MaxErrorStagingRootEntityId= 0;
	SET @SkipCount = 0;
	DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , @ToolIdentifier
SELECT *,0 [IsVATApplicable],0 [IsSameCountry] INTO #TempSecurityDeposit
	FROM stgSecurityDeposit WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL)

	SELECT stgSecurityDepositAllocation.* INTO #TempSecurityDepositAllocation
	FROM stgSecurityDepositAllocation JOIN #TempSecurityDeposit ON #TempSecurityDeposit.Id = stgSecurityDepositAllocation.SecurityDepositId

		CREATE TABLE #ErrorLogs 
		(
			Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
			StagingRootEntityId BIGINT,
			Result NVARCHAR(10),
			Message NVARCHAR(MAX)
		);		
		CREATE TABLE #FailedProcessingLogs 
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[SecurityDepositId] BIGINT NOT NULL
		);
		CREATE TABLE #ServicingDetails 
		(
			[SecurityDepositId] BIGINT NOT NULL,
			[IsOwnedEditable] BIT NOT NULL,
			[IsPrivateLabelEditable] BIT NOT NULL,
		);	
		SELECT 
			DISTINCT LineofBusinessId
			,LegalEntityId 
		INTO #LegalEntityLOB
		FROM GLOrgStructureConfigs where IsActive=1	
		SELECT
			DISTINCT
			LegalEntityId
			,CostCenterId
			,LineofBusinessId
		INTO #GLOrgStructureConfigs
		FROM
		GLOrgStructureConfigs WHERE IsActive=1
UPDATE #TempSecurityDeposit SET R_ContractId = Contracts.Id
From #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN Contracts WITH (NOLOCK)  ON UPPER(Contracts.SequenceNumber) = UPPER(SD.ContractSequencenumber) AND SD.EntityType = 'CT' AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_ContractId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error', 'Invalid ContractSequenceNumber : '+ISNULL(SD.ContractSequencenumber,'NULL')+' for Security Deposit {Id : '+CONVERT(VARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.EntityType = 'CT' AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_ContractId Is NULL;
UPDATE #TempSecurityDeposit SET R_CountryId = Countries.Id, IsVATApplicable = CASE WHEN Countries.TaxSourceType !='VAT' AND Countries.IsVATApplicable !=1 THEN 0 ELSE 1 END
From #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN Countries WITH (NOLOCK)  ON UPPER(Countries.ShortName) = UPPER(SD.Country) AND SD.EntityType = 'CT' AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_CountryId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error', 'Invalid Country : '+ISNULL(SD.Country,'NULL')+' for Security Deposit {Id : '+CONVERT(VARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.EntityType = 'CT' AND SD.IsMigrated = 0 AND SD.IsVATApplicable=1 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
AND R_CountryId Is NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error', 'VAT Amount should be zero for Non VAT country : '+ISNULL(SD.Country,'NULL')+' for Security Deposit {Id : '+CONVERT(VARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.EntityType = 'CT' AND SD.IsMigrated = 0 AND SD.ProjectedVATAmount_Amount!=0 AND SD.IsVATApplicable != 1 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier);

UPDATE #TempSecurityDeposit SET IsSameCountry = CASE WHEN SD.Country = Countries.ShortName THEN 1 ELSE 0 END
From #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN Contracts WITH (NOLOCK) ON SD.R_ContractId = Contracts.Id
INNER JOIN Countries ON Contracts.CountryId = Countries.Id AND SD.EntityType = 'CT' AND SD.IsVATApplicable = 1 AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error', 'Country: '+ISNULL(SD.Country,'NULL')+ ' is not as given in Contract : '+CONVERT(VARCHAR,SD.R_ContractId)+' for Security Deposit {Id : '+CONVERT(VARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.EntityType = 'CT' AND SD.IsMigrated = 0 AND IsSameCountry=0 AND SD.IsVATApplicable = 1 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) ;

UPDATE #TempSecurityDeposit SET R_CountryId = Countries.Id, IsVATApplicable = CASE WHEN Countries.TaxSourceType !='VAT' AND Countries.IsVATApplicable !=1 THEN 0 ELSE 1 END
From #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN Countries WITH (NOLOCK)  ON UPPER(Countries.ShortName) = UPPER(SD.Country) AND SD.EntityType = 'CU' AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_CountryId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error', 'Invalid Country : '+ISNULL(SD.Country,'NULL')+' for Security Deposit {Id : '+CONVERT(VARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.EntityType = 'CU' AND SD.IsMigrated = 0 AND SD.IsVATApplicable=1 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_CountryId Is NULL;

INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error', 'VAT Amount should be zero for Non VAT country : '+ISNULL(SD.Country,'NULL')+' for Security Deposit {Id : '+CONVERT(VARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.EntityType = 'CU' AND SD.IsMigrated = 0 AND SD.ProjectedVATAmount_Amount!=0 AND SD.IsVATApplicable != 1 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier);


UPDATE #TempSecurityDeposit SET R_LineOfBusinessId = CASE WHEN SD.EntityType = 'CU' THEN LineofBusinesses.Id ELSE ContractLOB.Id END
From #TempSecurityDeposit SD WITH (NOLOCK)  
LEFT JOIN LineofBusinesses WITH (NOLOCK)  ON UPPER(LineofBusinesses.Name) = UPPER(SD.LineofBusinessName) AND LineofBusinesses.IsActive = 1
LEFT JOIN Contracts WITH (NOLOCK)  ON UPPER(Contracts.SequenceNumber) = UPPER(SD.ContractSequencenumber) AND SD.EntityType = 'CT'
LEFT JOIN LineofBusinesses ContractLOB WITH (NOLOCK)  ON ContractLOB.Id = Contracts.LineofBusinessId 
	AND UPPER(ContractLOB.Name) = UPPER(SD.LineofBusinessName)
	AND ContractLOB.IsActive = 1 
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LineOfBusinessId Is NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid LineofBusinessName : '+ISNULL(SD.LineofBusinessName,'NULL')+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LineOfBusinessId IS NULL;
UPDATE #TempSecurityDeposit SET R_LegalEntityId = CASE WHEN SD.EntityType = 'CU' THEN #LegalEntityLOB.LegalEntityId ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.LegalEntityId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.LegalEntityId ELSE Loan.LegalEntityId END END
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
LEFT JOIN LineofBusinesses WITH (NOLOCK)  ON UPPER(LineofBusinesses.Name) = UPPER(SD.LineofBusinessName) AND LineofBusinesses.IsActive = 1
LEFT JOIN LegalEntities WITH (NOLOCK)  ON UPPER(LegalEntities.LegalEntityNumber) = UPPER(SD.LegalEntityNumber) AND LegalEntities.Status = @Status
LEFT JOIN #LegalEntityLOB WITH (NOLOCK)  ON #LegalEntityLOB.LegalEntityId = LegalEntities.Id AND LineofBusinesses.Id = #LegalEntityLOB.LineofBusinessId
LEFT JOIN Contracts WITH (NOLOCK)  ON UPPER(SD.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SD.EntityType = 'CT'
LEFT JOIN LoanFinances Loan WITH (NOLOCK)  ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 AND Loan.LegalEntityId = LegalEntities.Id
LEFT JOIN LeaseFinances Lease WITH (NOLOCK)  ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1 AND Lease.LegalEntityId = LegalEntities.Id
LEFT JOIN LeveragedLeases LeveragedLease WITH (NOLOCK)  ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1 AND LeveragedLease.LegalEntityId = LegalEntities.Id
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LegalEntityId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid LegalEntityNumber : '+ISNULL(SD.LegalEntityNumber,'NULL')+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LegalEntityId IS NULL;
UPDATE #TempSecurityDeposit SET R_CostCenterId = CASE WHEN SD.EntityType = 'CU' THEN #GLOrgStructureConfigs.CostCenterId ELSE ContractCostCenter.Id END
From #TempSecurityDeposit SD WITH (NOLOCK)  
LEFT JOIN LineofBusinesses WITH (NOLOCK)  ON UPPER(LineofBusinesses.Name) = UPPER(SD.LineofBusinessName) AND LineofBusinesses.IsActive = 1
LEFT JOIN LegalEntities WITH (NOLOCK)  ON UPPER(LegalEntities.LegalEntityNumber) = UPPER(SD.LegalEntityNumber) AND LegalEntities.Status = @Status
LEFT JOIN CostCenterConfigs WITH (NOLOCK)  ON SD.CostCenterName = CostCenterConfigs.CostCenter AND CostCenterConfigs.IsActive = 1
LEFT JOIN #GLOrgStructureConfigs WITH (NOLOCK)  ON #GLOrgStructureConfigs.LegalEntityId = LegalEntities.Id AND LineofBusinesses.Id = #GLOrgStructureConfigs.LineofBusinessId AND CostCenterConfigs.Id=#GLOrgStructureConfigs.CostCenterId
LEFT JOIN Contracts WITH (NOLOCK)  ON UPPER(SD.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SD.EntityType = 'CT'
LEFT JOIN CostCenterConfigs ContractCostCenter WITH (NOLOCK)  ON Contracts.CostCenterId = ContractCostCenter.Id AND  SD.CostCenterName = ContractCostCenter.CostCenter AND ContractCostCenter.IsActive=1
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_CostCenterId IS NULL;
INSERT INTO #ErrorLogs 
SELECT SD.Id, 'Error','Invalid CostCenterName : '+IsNULL(SD.CostCenterName,'NULL')+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.R_CostCenterId Is NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #TempSecurityDeposit SET R_InstrumentTypeId = CASE WHEN SD.EntityType='CU' THEN InstrumentTypes.Id ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.InstrumentTypeId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.InstrumentTypeId ELSE Loan.InstrumentTypeId END END 
From #TempSecurityDeposit SD WITH (NOLOCK)  
LEFT JOIN InstrumentTypes WITH (NOLOCK)  ON UPPER(InstrumentTypes.Code) = UPPER(SD.InstrumentTypeCode) AND InstrumentTypes.IsActive = 1
LEFT JOIN Contracts WITH (NOLOCK)  ON UPPER(SD.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SD.EntityType = 'CT'
LEFT JOIN LoanFinances Loan WITH (NOLOCK)  ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 AND Loan.InstrumentTypeId = InstrumentTypes.Id
LEFT JOIN LeaseFinances Lease WITH (NOLOCK)  ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1 AND Lease.InstrumentTypeId = InstrumentTypes.Id
LEFT JOIN LeveragedLeases LeveragedLease WITH (NOLOCK)  ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1 AND LeveragedLease.InstrumentTypeId = InstrumentTypes.Id
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_InstrumentTypeId IS NULL ;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid InstrumentTypeCode : '+ISNULL(SD.InstrumentTypeCode,'NULL')+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
WHERE SD.R_InstrumentTypeId IS NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #TempSecurityDeposit SET R_CurrencyId = Currencies.Id
From #TempSecurityDeposit SD WITH (NOLOCK)  
INNER JOIN CurrencyCodes WITH (NOLOCK)  ON CurrencyCodes.ISO = SD.CurrencyCode 
INNER JOIN Currencies WITH (NOLOCK)  ON Currencies.CurrencyCodeId = CurrencyCodes.Id AND Currencies.IsActive = 1
WHERE SD.R_CurrencyId Is NULL AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier);
INSERT INTO #ErrorLogs
SELECT SD.Id,'Error','Invalid CurrencyCode : '+SD.CurrencyCode+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
WHERE SD.R_CurrencyId Is NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #TempSecurityDeposit SET R_CustomerId = Customers.Id
From #TempSecurityDeposit SD WITH (NOLOCK)  
INNER JOIN Parties WITH (NOLOCK)  ON UPPER(Parties.PartyNumber) = UPPER(SD.CustomerPartyNumber) 
INNER JOIN Customers WITH (NOLOCK)  ON Customers.Id = Parties.Id
WHERE Customers.Status = @Status AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_CustomerId Is NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid CustomerNumber : '+SD.CustomerPartyNumber+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.R_CustomerId Is NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','CustomerNumber : '+SD.CustomerPartyNumber+' does not belong to the Contract: '+IsNull(SD.ContractSequencenumber,'Null') +' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
INNER JOIN Contracts WITH (NOLOCK)  ON Contracts.Id = R_ContractId
INNER JOIN LoanFinances WITH (NOLOCK)  ON LoanFinances.ContractId = R_ContractId AND Contracts.ContractType!='Lease' AND LoanFinances.IsCurrent = 1
WHERE SD.R_CustomerId IS NOT NULL AND EntityType = 'CT' AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND R_ContractId IS NOT NULL 
AND (LoanFinances.Id IS NOT NULL AND LoanFinances.CustomerId ! = R_CustomerId);
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','CustomerNumber : '+SD.CustomerPartyNumber+' does not belong to the Contract: '+IsNull(SD.ContractSequencenumber,'Null')+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN Contracts WITH (NOLOCK)  ON Contracts.Id = R_ContractId
INNER JOIN LeaseFinances WITH (NOLOCK)  ON LeaseFinances.ContractId = R_ContractId AND Contracts.ContractType = 'Lease' AND LeaseFinances.IsCurrent =1
WHERE SD.R_CustomerId IS NOT NULL AND EntityType = 'CT' AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND R_ContractId IS NOT NULL 
AND LeaseFinances.Id IS NOT NULL AND LeaseFinances.CustomerId ! = R_CustomerId
UPDATE #TempSecurityDeposit SET R_BillToId =  CASE WHEN SD.EntityType = 'CU' THEN BillToes.Id ELSE ContractBillToes.Id END
FROM #TempSecurityDeposit SD 
LEFT JOIN Parties WITH (NOLOCK)  ON UPPER(Parties.PartyNumber) = UPPER(SD.CustomerPartyNumber) AND SD.EntityType = 'CU'
LEFT JOIN BillToes WITH (NOLOCK)  ON BillToes.CustomerId = Parties.Id AND SD.BillToName = BillToes.Name AND BillToes.IsActive = 1 AND BillToes.IsActive = 1
LEFT JOIN Contracts WITH (NOLOCK)  ON UPPER(SD.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SD.EntityType = 'CT'
LEFT JOIN BillToes ContractBillToes WITH (NOLOCK)  ON ContractBillToes.Id = Contracts.BillToId AND SD.BillToName=ContractBillToes.Name AND ContractBillToes.IsActive = 1
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_BillToId Is NULL ;
INSERT INTO #ErrorLogs 
SELECT SD.Id, 'Error','Invalid BillToName : '+SD.BillToName+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
WHERE SD.R_BillToId Is NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #TempSecurityDeposit SET R_RemitToId = RemitToes.Id
From #TempSecurityDeposit SD WITH (NOLOCK) 
LEFT JOIN LegalEntities WITH (NOLOCK)  ON UPPER(SD.LegalEntityNumber) = UPPER(LegalEntities.LegalEntityNumber) AND LegalEntities.Status = @Status
LEFT JOIN LegalEntityRemitToes WITH (NOLOCK)  ON LegalEntities.Id = LegalEntityRemitToes.LegalEntityId
LEFT JOIN RemitToes WITH (NOLOCK)  ON SD.RemitToUniqueIdentifier = RemitToes.UniqueIdentifier AND LegalEntityRemitToes.RemitToId = RemitToes.Id  AND RemitToes.IsActive = 1
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_RemitToId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid RemitToUniqueIdentifier : '+SD.RemitToUniqueIdentifier+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with LegalEntityNumber: '+SD.LegalEntityNumber
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
WHERE SD.R_RemitToId Is NULL AND IsMigrated= 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) 
UPDATE #TempSecurityDeposit SET R_LocationId = Locations.Id
From #TempSecurityDeposit SD WITH (NOLOCK)  
LEFT JOIn Parties WITH (NOLOCK)  ON UPPER(Parties.PartyNumber) = UPPER(SD.CustomerPartyNumber) 
LEFT JOIN Locations WITH (NOLOCK)  ON Locations.CustomerId = Parties.Id AND UPPER(SD.LocationCode) = UPPER(Locations.Code) AND Locations.IsActive = 1 
WHERE  SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LocationId IS NULL;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid LocationCode : '+SD.LocationCode+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
WHERE SD.LocationCode IS NOT NULL AND SD.R_LocationId Is NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #TempSecurityDeposit SET R_ReceivableCodeId = ReceivableCodes.Id
From #TempSecurityDeposit SD WITH (NOLOCK) 
LEFT JOIN ReceivableCodes WITH (NOLOCK)  ON ReceivableCodes.Name = SD.ReceivableCodeName AND  ReceivableCodes.IsActive = 1
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_ReceivableCodeId IS NULL ;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid ReceivableCode : '+SD.ReceivableCodeName+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.ReceivableCodeName Is NOT NULL AND SD.R_ReceivableCodeId IS NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
INSERT INTO #ErrorLogs
SELECT DISTINCT SD.Id, 'Error','SecurityDepositAllocation should be provided for '+ 'Security Deposit {Id' +': '+CONVERT(NVARCHAR,SD.Id)+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK)  
LEFT JOIN #TempSecurityDepositAllocation sda WITH (NOLOCK)  ON SD.Id = sda.SecurityDepositId
WHERE sda.Id IS NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
INSERT INTO #ErrorLogs
SELECT DISTINCT SD.Id, 'Error','SecurityDepositAllocation of entity type "Unallocated" should be provided for '+ 'Security Deposit {Id' +': '+CONVERT(NVARCHAR,SD.Id)+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN (
SELECT sda.SecurityDepositId
FROM 
#TempSecurityDepositAllocation sda
WHERE sda.EntityType ='Unallocated'
GROUP BY sda.SecurityDepositId
HAVING COUNT(*) = 0
) AS T ON T.SecurityDepositId = SD.Id
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType ='CU'
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Amount in security deposit should match the sum of amount in security deposit allocation for '+ 'Security Deposit {Id' +': '+CONVERT(NVARCHAR,SD.Id)+'}'
FROM stgSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN
(
SELECT SUM(sda.Amount_Amount) Amount,sda.SecurityDepositId
FROM #TempSecurityDepositAllocation sda 
GROUP BY sda.SecurityDepositId
) AS T ON T.SecurityDepositId = SD.Id 
WHERE
T.Amount != SD.Amount_Amount AND SD.IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #TempSecurityDeposit SET R_ReceiptGLTemplateId = GLTemplates.Id
From #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN LegalEntities WITH (NOLOCK)  ON UPPER(SD.LegalEntityNumber) = UPPER(LegalEntities.LegalEntityNumber) AND LegalEntities.Status = @Status
INNER JOIN GLTemplates WITH (NOLOCK)  On UPPER(GLTemplates.Name) = UPPER(SD.ReceiptGLTemplateName) 
	AND GLTemplates.IsActive = 1
	AND GLTemplates.GLConfigurationId = LegalEntities.GLConfigurationId
INNER JOIN GLTransactionTypes WITH (NOLOCK)  ON GLTemplates.GLTransactionTypeId =  GLTransactionTypes.Id
	AND GLTransactionTypes.Name = 'ReceiptNonCash' 
WHERE SD.IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier) AND SD.R_ReceiptGLTemplateId IS NULL ;
INSERT INTO #ErrorLogs
SELECT SD.Id, 'Error','Invalid ReceiptGLTemplateName : '+SD.ReceiptGLTemplateName+' for Security Deposit {Id : '+CONVERT(NVARCHAR,SD.Id)+'}'
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.ReceiptGLTemplateName IS NOT NULL AND SD.R_ReceiptGLTemplateId Is NULL AND IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #TempSecurityDepositAllocation SET R_ContractId = Contracts.Id
From #TempSecurityDepositAllocation SDA WITH (NOLOCK)  
INNER JOIN #TempSecurityDeposit SD WITH (NOLOCK)  ON SD.Id = SDA.SecurityDepositId AND SDA.EntityType = 'Contract'
INNER JOIN Contracts WITH (NOLOCK)  ON  UPPER(Contracts.SequenceNumber) = UPPER(SDA.ContractSequencenumber)
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SDA.R_ContractId IS NULL;
INSERT INTO #ErrorLogs
SELECT SDA.SecurityDepositId, 'Error','Invalid ContractSequenceNumber : '+SDA.ContractSequencenumber+' for Security Deposit Allocation with Security Deposit {Id : '+CONVERT(NVARCHAR,SDA.SecurityDepositId)+'}'
FROM #TempSecurityDepositAllocation SDA WITH (NOLOCK) 
INNER JOIN #TempSecurityDeposit SD WITH (NOLOCK) ON SD.Id = SDA.SecurityDepositId
WHERE SDA.EntityType = 'Contract' AND SDA.ContractSequencenumber IS NOT NULL AND SDA.R_ContractId Is NULL AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
INSERT INTO #ServicingDetails(SecurityDepositId,IsOwnedEditable,IsPrivateLabelEditable)
SELECT SD.Id,CASE WHEN Contracts.SyndicationType != 'None' THEN 1 ELSE 0 END, 0
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
INNER JOIN Contracts WITH (NOLOCK)  ON SD.R_ContractId = Contracts.Id 
WHERE SD.EntityType ='CT' AND SD.IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
INSERT INTO #ServicingDetails(SecurityDepositId,IsOwnedEditable,IsPrivateLabelEditable)
SELECT SD.Id, 0, 0
FROM #TempSecurityDeposit SD WITH (NOLOCK) 
WHERE SD.EntityType ='CU' AND SD.R_CustomerId IS NOT NULL AND SD.IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier);
UPDATE #ServicingDetails SET IsPrivateLabelEditable = CASE WHEN servicingDetails.Id IS NULL AND Contracts.SyndicationType != 'None' THEN 1 ELSE 0 END
FROM #ServicingDetails WITH (NOLOCK) 
INNER JOIN #TempSecurityDeposit SD WITH (NOLOCK)  ON #ServicingDetails.SecurityDepositId = SD.Id
INNER JOIN Contracts WITH (NOLOCK)  ON SD.R_ContractId = Contracts.Id
INNER JOIN LeaseFinances WITH (NOLOCK)  ON Contracts.Id = LeaseFinances.ContractId
LEFT JOIN ReceivableForTransfers recForTrans WITH (NOLOCK)  ON recForTrans.ContractId = Contracts.Id AND recForTrans.ApprovalStatus != 'Inactive' 
LEFT JOIN ReceivableForTransferServicings servicingDetails WITH (NOLOCK)  on recForTrans.Id = servicingDetails.ReceivableForTransferId AND servicingDetails.IsActive = 1 AND servicingDetails.EffectiveDate <= SD.DueDate
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND (LeaseFinances.BookingStatus = 'Commenced' OR LeaseFinances.BookingStatus = 'FullyPaidOff')
UPDATE #ServicingDetails SET IsPrivateLabelEditable = CASE WHEN LeaseSyndicationServicingDetails.Id IS NULL AND Contracts.SyndicationType != 'None' THEN 1 ELSE 0 END
FROM #ServicingDetails WITH (NOLOCK)  
INNER JOIN #TempSecurityDeposit SD WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id
INNER JOIN Contracts WITH (NOLOCK)  ON SD.R_ContractId = Contracts.Id
INNER JOIN LeaseFinances WITH (NOLOCK) ON Contracts.Id = LeaseFinances.ContractId
LEFT JOIN LeaseSyndications WITH (NOLOCK) ON LeaseSyndications.Id = LeaseFinances.Id
LEFT JOIN LeaseSyndicationServicingDetails ON LeaseSyndications.Id = LeaseSyndicationServicingDetails.LeaseSyndicationId AND LeaseSyndicationServicingDetails.EffectiveDate <= SD.DueDate AND LeaseSyndicationServicingDetails.IsActive = 1
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND (LeaseFinances.BookingStatus != 'Commenced' AND LeaseFinances.BookingStatus != 'FullyPaidOff')
UPDATE #ServicingDetails SET IsPrivateLabelEditable = CASE WHEN servicingDetails.Id IS NULL AND Contracts.SyndicationType != 'None' THEN 1 ELSE 0 END
FROM #ServicingDetails WITH (NOLOCK) 
INNER JOIN #TempSecurityDeposit SD ON #ServicingDetails.SecurityDepositId = SD.Id
INNER JOIN Contracts WITH (NOLOCK) ON SD.R_ContractId = Contracts.Id
INNER JOIN LoanFinances WITH (NOLOCK) ON Contracts.Id = LoanFinances.ContractId
LEFT JOIN ReceivableForTransfers recForTrans WITH (NOLOCK) ON recForTrans.ContractId = Contracts.Id
LEFT JOIN ReceivableForTransferServicings servicingDetails WITH (NOLOCK) on recForTrans.Id = servicingDetails.ReceivableForTransferId AND recForTrans.ApprovalStatus != 'Inactive' AND servicingDetails.IsActive = 1 
AND servicingDetails.EffectiveDate <= SD.DueDate
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND (LoanFinances.Status != 'UnCommenced' AND LoanFinances.Status != 'Cancelled')
UPDATE #ServicingDetails SET IsPrivateLabelEditable = CASE WHEN LoanSyndicationServicingDetails.Id IS NULL AND Contracts.SyndicationType != 'None' THEN 1 ELSE 0 END
FROM #ServicingDetails WITH (NOLOCK) 
INNER JOIN #TempSecurityDeposit SD WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id
INNER JOIN Contracts WITH (NOLOCK) ON SD.R_ContractId = Contracts.Id
INNER JOIN LoanFinances WITH (NOLOCK) ON Contracts.Id = LoanFinances.ContractId
LEFT JOIN LoanSyndications WITH (NOLOCK) ON LoanSyndications.Id = LoanFinances.Id
LEFT JOIN LoanSyndicationServicingDetails WITH (NOLOCK) ON LoanSyndications.Id = LoanSyndicationServicingDetails.LoanSyndicationId AND LoanSyndicationServicingDetails.EffectiveDate <= SD.DueDate 
AND LoanSyndicationServicingDetails.IsActive = 1
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND (LoanFinances.Status = 'UnCommenced' OR LoanFinances.Status = 'Cancelled')
UPDATE #TempSecurityDeposit SET IsOwned = 1, IsServiced = 1 
FROM #TempSecurityDeposit SD WITH (NOLOCK)
INNER JOIN Contracts WITH (NOLOCK) ON SD.R_ContractId = Contracts.Id
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.R_ContractId IS NOT NULL
AND Contracts.SyndicationType = 'None'
UPDATE #TempSecurityDeposit SET IsOwned = 1, IsServiced = 1, IsCollected = 1, IsPrivateLabel = 0
FROM #TempSecurityDeposit SD WITH (NOLOCK)
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 AND #ServicingDetails.IsPrivateLabelEditable = 0)
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CU' AND SD.CustomerPartyNumber IS NOT NULL AND SD.R_CustomerId IS NOT NULL
UPDATE #TempSecurityDeposit SET IsServiced = servicing.IsServiced, IsCollected = servicing.IsCollected, IsPrivateLabel = servicing.IsPrivateLabel
FROM #TempSecurityDeposit SD WITH (NOLOCK) INNER JOIN
(SELECT SD.Id,MAX(ReceivableForTransferServicings.Id) AS ReceivableForTransferServicingId FROM #TempSecurityDeposit SD WITH (NOLOCK)
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN ReceivableForTransfers WITH (NOLOCK) ON SD.R_ContractId = ReceivableForTransfers.ContractId
INNER JOIN ReceivableForTransferServicings WITH (NOLOCK) ON ReceivableForTransfers.Id = ReceivableForTransferServicings.ReceivableForTransferId
INNER JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND SD.IsOwned = 0 AND ReceivableForTransfers.ContractId = SD.R_ContractId
AND ReceivableForTransfers.ApprovalStatus ='Approved' AND ReceivableForTransferServicings.IsActive = 1 AND SD.DueDate IS NOT NULL
AND ReceivableForTransferServicings.EffectiveDate <= SD.DueDate AND Contracts.SyndicationType != 'None' 
GROUP BY SD.Id
) AS T ON SD.Id = T.Id
INNER JOIN ReceivableForTransferServicings servicing WITH (NOLOCK) ON T.ReceivableForTransferServicingId = servicing.Id
UPDATE #TempSecurityDeposit SET IsServiced = servicing.IsServiced, IsCollected = servicing.IsCollected, IsPrivateLabel = servicing.IsPrivateLabel
FROM #TempSecurityDeposit SD WITH (NOLOCK) INNER JOIN
(SELECT SD.Id,MAX(LeaseSyndicationServicingDetails.Id) AS servicingDetailId FROM #TempSecurityDeposit SD
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN LeaseFinances WITH (NOLOCK) ON LeaseFinances.ContractId = SD.R_ContractId
INNER JOIN LeaseSyndications WITH (NOLOCK) ON LeaseFinances.Id = LeaseSyndications.Id
INNER JOIN LeaseSyndicationServicingDetails WITH (NOLOCK) ON LeaseSyndicationServicingDetails.LeaseSyndicationId = LeaseSyndications.Id
INNER JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND SD.IsOwned = 0
AND Contracts.SyndicationType != 'None' AND SD.DueDate IS NOT NULL
AND LeaseSyndicationServicingDetails.IsActive = 1 AND SD.DueDate >= LeaseSyndicationServicingDetails.EffectiveDate
GROUP BY SD.Id
) AS T ON SD.Id = T.Id
INNER JOIN LeaseSyndicationServicingDetails servicing ON T.servicingDetailId = servicing.Id
UPDATE #TempSecurityDeposit SET IsServiced = servicing.IsServiced, IsCollected = servicing.IsCollected, IsPrivateLabel = servicing.IsPrivateLabel
FROM #TempSecurityDeposit SD WITH (NOLOCK) INNER JOIN
(SELECT SD.Id,MAX(LoanSyndicationServicingDetails.Id) AS servicingDetailId FROM #TempSecurityDeposit SD
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN LoanFinances WITH (NOLOCK) ON LoanFinances.ContractId = SD.R_ContractId
INNER JOIN LoanSyndications WITH (NOLOCK) ON LoanFinances.Id = LoanSyndications.Id
INNER JOIN LoanSyndicationServicingDetails WITH (NOLOCK) ON LoanSyndicationServicingDetails.LoanSyndicationId = LoanSyndications.Id
INNER JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND SD.IsOwned = 0
AND LoanSyndicationServicingDetails.IsActive = 1 AND SD.DueDate IS NOT NULL AND SD.DueDate >= LoanSyndicationServicingDetails.EffectiveDate 
AND Contracts.SyndicationType != 'None'
GROUP BY SD.Id
) AS T ON SD.Id = T.Id
INNER JOIN LeaseSyndicationServicingDetails servicing WITH (NOLOCK) ON T.servicingDetailId = servicing.Id
UPDATE #TempSecurityDeposit SET IsServiced = 1, IsCollected = 1, IsPrivateLabel = 0
FROM #TempSecurityDeposit SD WITH (NOLOCK)
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN Contracts WITH (NOLOCK) ON SD.R_ContractId = Contracts.Id
LEFT JOIN ReceivableForTransfers recForTrans WITH (NOLOCK) ON recForTrans.ContractId = SD.R_ContractId
LEFT JOIN ReceivableForTransferServicings servicingDetails WITH (NOLOCK) ON recForTrans.Id = servicingDetails.ReceivableForTransferId AND SD.DueDate IS NOT NULL
AND recForTrans.ApprovalStatus = 'Approved'AND servicingDetails.IsActive = 1 AND servicingDetails.EffectiveDate <= SD.DueDate
LEFT JOIN LeaseFinances WITH (NOLOCK) ON LeaseFinances.ContractId = SD.R_ContractId
LEFT JOIN LeaseSyndications WITH (NOLOCK) ON LeaseFinances.Id = LeaseSyndications.Id
LEFT JOIN LoanFinances WITH (NOLOCK) ON LoanFinances.ContractId = SD.R_ContractId
LEFT JOIN LoanSyndications WITH (NOLOCK) ON LoanFinances.Id = LoanSyndications.Id
WHERE servicingDetails.Id IS NULL AND (LeaseSyndications.Id IS NULL AND LoanSyndications.Id IS NULL)
AND SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND Contracts.SyndicationType != 'None'
UPDATE #TempSecurityDeposit SET IsServiced = servicing.IsServiced, IsCollected = 1, IsPrivateLabel = servicing.IsPrivateLabel
FROM #TempSecurityDeposit SD WITH (NOLOCK) INNER JOIN
(SELECT SD.Id,MAX(ServicingDetails.Id) AS servicingDetailId FROM #TempSecurityDeposit SD WITH (NOLOCK)
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN LoanFinances WITH (NOLOCK) ON LoanFinances.ContractId = SD.R_ContractId
INNER JOIN ContractOriginations WITH (NOLOCK) ON LoanFinances.ContractOriginationId = ContractOriginations.Id
INNER JOIN ContractOriginationServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ContractOriginationId = ContractOriginations.Id
INNER JOIN ServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ServicingDetailId = ServicingDetails.Id
INNER JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND LoanFinances.IsCurrent = 1
AND Contracts.SyndicationType = 'None' AND ServicingDetails.IsActive = 1 AND SD.DueDate IS NOT NULL AND  SD.DueDate >= ServicingDetails.EffectiveDate
GROUP BY SD.Id
) AS T ON SD.Id = T.Id
INNER JOIN ServicingDetails servicing WITH (NOLOCK) ON T.servicingDetailId = servicing.Id
UPDATE #TempSecurityDeposit SET IsServiced = servicing.IsServiced, IsCollected = 1, IsPrivateLabel = servicing.IsPrivateLabel
FROM #TempSecurityDeposit SD WITH (NOLOCK) INNER JOIN
(SELECT SD.Id,MAX(ServicingDetails.Id) AS servicingDetailId FROM #TempSecurityDeposit SD
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN LeaseFinances WITH (NOLOCK) ON LeaseFinances.ContractId = SD.R_ContractId
INNER JOIN ContractOriginations WITH (NOLOCK) ON LeaseFinances.ContractOriginationId = ContractOriginations.Id
INNER JOIN ContractOriginationServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ContractOriginationId = ContractOriginations.Id
INNER JOIN ServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ServicingDetailId = ServicingDetails.Id
INNER JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND LeaseFinances.IsCurrent = 1
AND Contracts.SyndicationType = 'None' AND SD.DueDate IS NOT NULL AND ServicingDetails.IsActive = 1 AND SD.DueDate >= ServicingDetails.EffectiveDate
GROUP BY SD.Id
) AS T ON SD.Id = T.Id
INNER JOIN ServicingDetails servicing WITH (NOLOCK) ON T.servicingDetailId = servicing.Id
UPDATE #TempSecurityDeposit SET IsServiced = 1, IsCollected = 1, IsPrivateLabel = 0
FROM #TempSecurityDeposit SD WITH (NOLOCK)
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId
LEFT JOIN LeaseFinances WITH (NOLOCK) ON LeaseFinances.ContractId = SD.R_ContractId
LEFT JOIN ContractOriginations WITH (NOLOCK) ON LeaseFinances.ContractOriginationId = ContractOriginations.Id
LEFT JOIN ContractOriginationServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ContractOriginationId = ContractOriginations.Id
LEFT JOIN ServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ServicingDetailId = ServicingDetails.Id AND ServicingDetails.IsActive = 1 AND SD.DueDate IS NOT NULL AND SD.DueDate >= ServicingDetails.EffectiveDate
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL
AND Contracts.SyndicationType = 'None' AND ServicingDetails.Id IS NULL AND LeaseFinances.IsCurrent = 1
UPDATE #TempSecurityDeposit SET IsServiced = 1, IsCollected = 1, IsPrivateLabel = 0
FROM #TempSecurityDeposit SD WITH (NOLOCK)
INNER JOIN #ServicingDetails WITH (NOLOCK) ON #ServicingDetails.SecurityDepositId = SD.Id AND (#ServicingDetails.IsOwnedEditable = 0 OR #ServicingDetails.IsPrivateLabelEditable = 0)
INNER JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId
LEFT JOIN LoanFinances WITH (NOLOCK) ON LoanFinances.ContractId = SD.R_ContractId
LEFT JOIN ContractOriginations WITH (NOLOCK) ON ContractOriginations.Id = LoanFinances.ContractOriginationId
LEFT JOIN ContractOriginationServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ContractOriginationId = ContractOriginations.Id
LEFT JOIN ServicingDetails WITH (NOLOCK) ON ContractOriginationServicingDetails.ServicingDetailId = ServicingDetails.Id AND ServicingDetails.IsActive = 1 AND SD.DueDate IS NOT NULL AND SD.DueDate >= ServicingDetails.EffectiveDate
WHERE SD.IsMigrated = 0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CT' AND SD.ContractSequencenumber IS NOT NULL AND SD.R_ContractId IS NOT NULL AND LoanFinances.IsCurrent = 1
AND Contracts.SyndicationType = 'None' AND ServicingDetails.Id IS NULL
 UPDATE StgSecurityDeposit SET  
 R_LegalEntityId=#TempSecurityDeposit.R_LegalEntityId,        
 R_CustomerId=#TempSecurityDeposit.R_CustomerId,           
 R_InstrumentTypeId=#TempSecurityDeposit.R_InstrumentTypeId,     
 R_CurrencyId=#TempSecurityDeposit.R_CurrencyId,      
 R_CountryId=#TempSecurityDeposit.R_CountryId,
 R_LineOfBusinessId=#TempSecurityDeposit.R_LineOfBusinessId,     
 R_CostCenterId=#TempSecurityDeposit.R_CostCenterId,         
 R_BillToId=#TempSecurityDeposit.R_BillToId,             
 R_RemitToId=#TempSecurityDeposit.R_RemitToId,            
 R_LocationId=#TempSecurityDeposit.R_LocationId,           
 R_ReceiptGLTemplateId=#TempSecurityDeposit.R_ReceiptGLTemplateId,  
 R_ContractId=#TempSecurityDeposit.R_ContractId,           
 R_ReceivableCodeId=#TempSecurityDeposit.R_ReceivableCodeId  
FROM StgSecurityDeposit JOIN #TempSecurityDeposit ON #TempSecurityDeposit.Id = StgSecurityDeposit.Id

 UPDATE StgSecurityDepositAllocation SET  
 R_ContractId=#TempSecurityDepositAllocation.R_ContractId 
 FROM StgSecurityDepositAllocation JOIN #TempSecurityDepositAllocation ON #TempSecurityDepositAllocation.Id = StgSecurityDepositAllocation.Id


SELECT
	*
INTO #ErrorLogDetails
FROM #ErrorLogs ORDER BY StagingRootEntityId ;
	WHILE @SkipCount < @TotalRecordsCount
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		CREATE TABLE #CreatedSecurityDeposits
		(
			[Action] NVARCHAR(10) NOT NULL
			,[Id] BIGINT NOT NULL
			,[SecurityDepositId] BIGINT NOT NULL
		);
		CREATE TABLE #CreatedProcessingLogs
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL
		);		
		CREATE TABLE #CreatedReceivablesIds
		(
			InsertedId  BIGINT NOT NULL,
			SourceId BIGINT,			
		)
		SELECT
			TOP(@TakeCount) 
			Id AS SecurityDepositId
			,*
		INTO #SecurityDeposit
		FROM
		stgSecurityDeposit SD
		WHERE 
			IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)
			AND 
			Id > @MaxSecurityDepositId
			AND
			NOT Exists (SELECT * FROM #ErrorLogDetails WHERE StagingRootEntityId = SD.Id);		
		SELECT @MaxSecurityDepositId = MAX(SecurityDepositId) FROM #SecurityDeposit;
		SELECT @BatchCount = ISNULL(COUNT(SecurityDepositId),0) FROM #SecurityDeposit;
		MERGE SecurityDeposits AS SecurityDeposit
				USING ( SELECT * FROM #SecurityDeposit) AS SecurityDepositToMigrate
					ON 1 = 0
				WHEN NOT MATCHED 
				THEN
				INSERT
				(
					[DepositType]
					, [EntityType]
					, [Amount_Amount]
					, [Amount_Currency]
					,[ProjectedVATAmount_Amount]
					,[ProjectedVATAmount_Currency]
					,[CountryId]
					, [DueDate]
					, [InvoiceReceivableGroupingOption]
					, [PostDate]
					, [InvoiceComment]
					, [IsActive]
					, [CreatedById]
					, [CreatedTime]
					, [UpdatedById]
					, [UpdatedTime]
					, [CurrencyId]
					, [LineofBusinessId]
					, [InstrumentTypeId]
					, [ContractId]
					, [LegalEntityId]
					, [CustomerId]
					, [ReceivableCodeId]
					, [LocationId]
					, [BillToId]
					, [RemitToId]
					, [ReceiptGLTemplateId]
					, [HoldToMaturity]
					, [NumberOfMonthsRetained]
					, [HoldEndDate]
					, [CostCenterId]
					, [IsServiced]
					, [IsCollected]
					, [IsPrivateLabel]
					, [IsOwned]
					, [ActualVATAmount_Amount]
					, [ActualVATAmount_Currency]
				)
				VALUES
				(
					@TypeSecurityDeposit
					, [EntityType]
					, [Amount_Amount]
					, [Amount_Currency]
					,[ProjectedVATAmount_Amount]
					,[ProjectedVATAmount_Currency]
					,[R_CountryId]
					, [DueDate]
					, 'Category'
					, ISNULL(SecurityDepositToMigrate.PostDate, @CurrentBusinessDate)
					, [InvoiceComment]
					, 1
					, @UserId
					, @CreatedTime
					, null
					, null
					, [R_CurrencyId]
					, [R_LineofBusinessId]
					, [R_InstrumentTypeId]
					, [R_ContractId]
					, [R_LegalEntityId]
					, [R_CustomerId]
					, [R_ReceivableCodeId]
					, [R_LocationId]
					, [R_BillToId]
					, [R_RemitToId]
					, [R_ReceiptGLTemplateId]
					, [HoldToMaturity]
					, [NumberOfMonthsRetained]
					, [HoldEndDate]
					, [R_CostCenterId]
					, [IsServiced]
					, [IsCollected]
					, [IsPrivateLabel]
					, [IsOwned]
					, ISNULL([ActualVATAmount_Amount], 0.0)
					, ISNULL([ActualVATAmount_Currency], [Amount_Currency])
				)
				OUTPUT $action, Inserted.Id, SecurityDepositToMigrate.Id INTO #CreatedSecurityDeposits;
				MERGE SecurityDepositAllocations AS SDA
				USING (SELECT SecurityDepositAllocation.*, SecurityDepositIdMapping.Id CreatedSecurityDepositId
						FROM #CreatedSecurityDeposits SecurityDepositIdMapping
						JOIN stgSecurityDepositAllocation SecurityDepositAllocation ON SecurityDepositIdMapping.SecurityDepositId = SecurityDepositAllocation.SecurityDepositId) AS SecurityDepositAllocationDetail
				ON 1 = 0
				WHEN NOT MATCHED THEN
				INSERT
				(
					[EntityType]
					, [IsAllocation]
					, [Amount_Amount]
					, [Amount_Currency]
					, [GlDescription]
					, [IsActive]
					, [CreatedById]
					, [CreatedTime]
					, [UpdatedById]
					, [UpdatedTime]
					, [ContractId]
					, [SecurityDepositId]
				)
				VALUES
				(
					SecurityDepositAllocationDetail.[EntityType]
					, SecurityDepositAllocationDetail.[IsAllocation]
					, SecurityDepositAllocationDetail.Amount_Amount
					, SecurityDepositAllocationDetail.Amount_Currency
					, SecurityDepositAllocationDetail.[GlDescription]
					, 1
					, @UserId
					, @CreatedTime
					, NULL
					, NULL
					, R_ContractId
					, SecurityDepositAllocationDetail.CreatedSecurityDepositId
				);
		INSERT INTO Receivables
		 (
		 EntityType
		,EntityId
		,DueDate
		,IsDSL
		,IsActive
		,InvoiceComment
		,InvoiceReceivableGroupingOption
		,IsGLPosted
		,IncomeType
		--,PaymentScheduleId
		,IsCollected
		,IsServiced
		,IsDummy
		,CreatedById
		,CreatedTime
		,ReceivableCodeId
		,CustomerId
		--,FunderId
		,RemitToId
		,TaxRemitToId
		,LocationId
		,LegalEntityId
		,IsPrivateLabel
		,SourceId
		,SourceTable
		,TotalAmount_Amount
		,TotalAmount_Currency
		,TotalBalance_Amount
		,TotalBalance_Currency
		,TotalEffectiveBalance_Amount
		,TotalEffectiveBalance_Currency
		,TotalBookBalance_Amount
		,TotalBookBalance_Currency
		,ExchangeRate
		,AlternateBillingCurrencyId
		)	
		OUTPUT INSERTED.Id,inserted.SourceId INTO #CreatedReceivablesIds
		SELECT 
		 CASE WHEN #SecurityDeposit.EntityType = 'CT' THEN 'CT' ELSE 'CU' END	
		,CASE WHEN #SecurityDeposit.EntityType = 'CT' THEN #SecurityDeposit.R_ContractId ELSE #SecurityDeposit.R_CustomerId END	
		,#SecurityDeposit.DueDate
		,0
		,1
		,#SecurityDeposit.InvoiceComment
		,'Category' InvoiceReceivableGroupingOption
		,1
		,'_'
		,1
		,1
		,0
		,@UserId
		,@CreatedTime
		,#SecurityDeposit.R_ReceivableCodeId
		,#SecurityDeposit.R_CustomerId
		,#SecurityDeposit.R_RemitToId
		,#SecurityDeposit.R_RemitToId
		,#SecurityDeposit.R_LocationId
		,#SecurityDeposit.R_LegalEntityId
		,0
		,#CreatedSecurityDeposits.Id
		,'SecurityDeposit'
		,#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,0.00
		,#SecurityDeposit.Amount_Currency
		,1.00
		,#SecurityDeposit.R_CurrencyId
		FROM #SecurityDeposit
		INNER JOIN #CreatedSecurityDeposits ON #CreatedSecurityDeposits.SecurityDepositId = #SecurityDeposit.SecurityDepositId
		INSERT INTO ReceivableDetails
		(Amount_Amount
		,Amount_Currency
		,Balance_Amount
		,Balance_Currency
		,EffectiveBalance_Amount
		,EffectiveBalance_Currency
		,EffectiveBookBalance_Amount
		,EffectiveBookBalance_Currency
		,IsActive
		,IsTaxAssessed
		,StopInvoicing
		,BillToId
		,BilledStatus
		,CreatedById
		,CreatedTime
		,ReceivableId
		,AssetComponentType
		,LeaseComponentAmount_Amount
		,LeaseComponentAmount_Currency
		,NonLeaseComponentAmount_Amount
		,NonLeaseComponentAmount_Currency
		,LeaseComponentBalance_Amount
		,LeaseComponentBalance_Currency
		,NonLeaseComponentBalance_Amount
		,NonLeaseComponentBalance_Currency
		,PreCapitalizationRent_Amount
		,PreCapitalizationRent_Currency
		)
	SELECT
		#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,0.00
		,#SecurityDeposit.Amount_Currency
		,1
		,CASE WHEN (@GlobalParamValue='true' AND ReceivableCodes.IsTaxExempt = 'true') THEN 1 ELSE 0 END
		,0
		,#SecurityDeposit.R_BillToId
		,'NotInvoiced'
		,@UserId
		,@CreatedTime
		,#CreatedReceivablesIds.InsertedId
		,'_'
		,#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,0.00
		,#SecurityDeposit.Amount_Currency
		,#SecurityDeposit.Amount_Amount
		,#SecurityDeposit.Amount_Currency
		,0.00
		,#SecurityDeposit.Amount_Currency
		,0.00
		,#SecurityDeposit.Amount_Currency
		FROM #SecurityDeposit
		INNER JOIN #CreatedSecurityDeposits ON #CreatedSecurityDeposits.SecurityDepositId = #SecurityDeposit.SecurityDepositId
		INNER JOIN #CreatedReceivablesIds ON #CreatedSecurityDeposits.Id = #CreatedReceivablesIds.SourceId
		INNER JOIN ReceivableCodes ON ReceivableCodes.Id = #SecurityDeposit.R_ReceivableCodeId
		UPDATE SecurityDeposits SET ReceivableId = #CreatedReceivablesIds.InsertedId
		FROM SecurityDeposits 
		INNER JOIN #CreatedSecurityDeposits ON #CreatedSecurityDeposits.Id = SecurityDeposits.Id
		INNER JOIN #CreatedReceivablesIds ON #CreatedSecurityDeposits.Id = #CreatedReceivablesIds.SourceId
			CREATE TABLE #CreatedGLJournalIds
(
	MergeAction nvarchar(20),
	GLJournalId bigint,
	SecurityDepositId BigInt
)
MERGE INTO GLJournals
USING 
	(
		SELECT
			s.Id SecurityDepositId,NULL GLJournalId,s.legalEntityid,s.PostDate
		FROM 
		SecurityDeposits s
		JOIN #CreatedSecurityDeposits CreatedSecurityDepositIds on s.id = CreatedSecurityDepositIds.Id
	) AS CreatedSecurityDepositIds
	ON CreatedSecurityDepositIds.GLJournalId = GLJournals.Id
WHEN MATCHED
THEN UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT 
(
	 PostDate
	,IsManualEntry
	,IsReversalEntry
	,CreatedById
	,CreatedTime
	,LegalEntityId
)
VALUES 
(
	CreatedSecurityDepositIds.PostDate,
	0,
	0,
	@UserId,
	@CreatedTime,
	CreatedSecurityDepositIds.LegalEntityId
)
OUTPUT $ACTION, INSERTED.Id,CreatedSecurityDepositIds.SecurityDepositId INTO #CreatedGLJournalIds;
INSERT INTO GLJournalDetails 
	(	EntityId,
		EntityType,
		Amount_Amount,
		Amount_Currency,
		IsDebit,
		GLAccountNumber,
		Description,
		SourceId,
		IsActive,	
		CreatedById,
		CreatedTime,
		GLAccountId,
		GLTemplateDetailId,
		MatchingGLTemplateDetailId,
		GLJournalId,
		LineofBusinessId
	)
SELECT 
s.ContractId EntityId
,'Contract' EntityType
,s.Amount_Amount
,s.Amount_Currency
,Gei.IsDebit
,dbo.[GetGLAccountNumber](s.InstrumentTypeId,ISNULL(gdm.Id, gd.Id),c.ContractType,s.ContractId,s.LegalEntityId,s.LineofBusinessId,'',s.CostCenterId,s.CurrencyId,0,'') GLAccountNumber
,'Security Deposit - ' + c.sequencenumber Description
,s.Id SourceId
,1 IsActive
,@Userid CreatedById
,@CreatedTime CreatedTime
,gd.GLAccountId
,gd.Id GLTemplateDetailId
,gdm.Id MatchingGlTemplateId
,CreatedGLJournal.GLJournalId
,s.LineofBusinessId
FROM SecurityDeposits s
JOIN #CreatedGLJournalIds CreatedGLJournal ON s.Id = CreatedGLJournal.SecurityDepositId
AND s.EntityType='CT'
JOIN contracts c ON s.contractid = c.id
JOIN receivablecodes rc ON s.receivablecodeid = rc.id
JOIN glTemplates g ON rc.GLTemplateid = g.Id
JOIN GLTemplateDetails gd ON g.id= gd.GlTemplateId
JOIN GLEntryItems Gei ON gd.EntryItemid = Gei.Id
AND 
((Gei.Name ='SecurityDepositReceivable' and Gei.IsDebit = 1) 
 OR 
(Gei.Name ='SecurityDepositLiability' and Gei.IsDebit = 0 ))
LEFT JOIN GLMatchingEntryItems Gme on gei.id = gme.GlEntryItemId
LEFT JOIN GLTemplateDetails gdm on gme.MatchingEntryItemId = gdm.EntryItemId
UNION
SELECT 
s.CustomerId EntityId
,'Customer' EntityType
,s.Amount_Amount
,s.Amount_Currency
,Gei.IsDebit
,dbo.[GetGLAccountNumber](s.InstrumentTypeId,ISNULL(gdm.Id, gd.Id),'Customer',NULL,s.LegalEntityId,s.LineofBusinessId,'',s.CostCenterId,s.CurrencyId,0,'') GLAccountNumber
,'Security Deposit - ' + c.PartyNumber Description
,s.Id SourceId
,1 IsActive
,@Userid CreatedById
,@CreatedTime CreatedTime
,gd.GLAccountId
,gd.Id GLTemplateDetailId
,gdm.Id MatchingGlTemplateId
,CreatedGLJournal.GLJournalId
,s.LineofBusinessId
FROM SecurityDeposits s
JOIN #CreatedGLJournalIds CreatedGLJournal ON s.Id = CreatedGLJournal.SecurityDepositId
AND s.EntityType='CU'
JOIN parties c ON s.CustomerId = c.id
JOIN receivablecodes rc ON s.receivablecodeid = rc.id
JOIN glTemplates g ON rc.GLTemplateid = g.Id
JOIN GLTemplateDetails gd ON g.id= gd.GlTemplateId
JOIN GLEntryItems Gei ON gd.EntryItemid = Gei.Id
AND
((Gei.Name ='SecurityDepositReceivable' and Gei.IsDebit = 1)
 OR 
(Gei.Name ='SecurityDepositLiability' and Gei.IsDebit = 0 ))
LEFT JOIN GLMatchingEntryItems Gme ON gei.id = gme.GlEntryItemId
LEFT JOIN GLTemplateDetails gdm ON gme.MatchingEntryItemId = gdm.EntryItemId
DELETE FROM #CreatedGLJournalIds
MERGE INTO GLJournals
USING 
	(
		SELECT
			sda.Id SecurityDepositAllocationId,NULL GLJournalId,s.legalEntityid,s.PostDate
		FROM 
		SecurityDeposits s WITH (NOLOCK)
		JOIN #CreatedSecurityDeposits CreatedSecurityDepositIds on s.id = CreatedSecurityDepositIds.Id
		JOIN dbo.SecurityDepositAllocations sda WITH (NOLOCK) ON s.Id = sda.SecurityDepositId AND sda.EntityType ='Contract'
	) AS CreatedSecurityDepositIds
ON 1 = 0
WHEN NOT MATCHED THEN
INSERT 
(
	 PostDate
	,IsManualEntry
	,IsReversalEntry
	,CreatedById
	,CreatedTime
	,LegalEntityId
)
VALUES 
(
	CreatedSecurityDepositIds.PostDate,
	0,
	0,
	@UserId,
	@CreatedTime,
	CreatedSecurityDepositIds.LegalEntityId
)
OUTPUT $ACTION, INSERTED.Id,CreatedSecurityDepositIds.SecurityDepositAllocationId INTO #CreatedGLJournalIds;
SELECT DISTINCT gd.*,s.Id AS SecurityDepositId,gi.IsDebit
INTO #GLTemplateDetails
FROM SecurityDeposits s WITH (NOLOCK)
JOIN #CreatedSecurityDeposits CreatedSecurityDepositIds on s.id = CreatedSecurityDepositIds.Id
JOIN SecurityDepositAllocations sda WITH (NOLOCK) ON s.Id = sda.SecurityDepositId AND sda.EntityType ='Contract'
JOIN ReceivableCodes rc ON rc.Id = s.ReceivableCodeId
JOIN GLTemplateDetails gd ON gd.GLTemplateId = rc.GLTemplateId AND gd.IsActive = 1
JOIN GLEntryItems gi ON gi.Id = gd.EntryItemId AND gi.IsActive =1
AND
((gi.Name ='SecurityDepositLiability' and gi.IsDebit = 1)
 OR 
(gi.Name ='SecurityDepositLiabilityContract' and gi.IsDebit = 0 ))
SELECT DISTINCT MatchingAccountId.GLAccountId, #GLTemplateDetails.Id,#GLTemplateDetails.SecurityDepositId, MatchingAccountId.Id AS MatchingGLTemplateDetailId
INTO #GLMatchingEntryItems
FROM GLTemplateDetails matchingGlTemplateDetail 
INNER JOIN GLEntryItems matchingEntryItem ON matchingEntryItem.Id = matchingGlTemplateDetail.EntryItemId
INNER JOIN #GLTemplateDetails ON #GLTemplateDetails.GLTemplateId = matchingGlTemplateDetail.GLTemplateId AND #GLTemplateDetails.GLAccountId IS NULL
INNER JOIN GLMatchingEntryItems ON #GLTemplateDetails.EntryItemId = GLMatchingEntryItems.GLEntryItemId
INNER JOIN GLEntryItems ON GLEntryItems.Id = GLMatchingEntryItems.MatchingEntryItemId
INNER JOIN GLTemplateDetails MatchingAccountId ON GLEntryItems.Id = MatchingAccountId.EntryItemId AND MatchingAccountId.GLTemplateId = #GLTemplateDetails.GLTemplateId
WHERE
matchingEntryItem.IsActive = 1 AND MatchingAccountId.GLAccountId IS NOT NULL
INSERT INTO GLJournalDetails 
	(	EntityId,
		EntityType,
		Amount_Amount,
		Amount_Currency,
		IsDebit,
		GLAccountNumber,
		Description,
		SourceId,
		IsActive,	
		CreatedById,
		CreatedTime,
		GLAccountId,
		GLTemplateDetailId,
		MatchingGLTemplateDetailId,
		GLJournalId,
		LineofBusinessId
	)
SELECT DISTINCT
 CASE WHEN s.EntityType='CU' THEN p.Id ELSE s.ContractId END
,CASE WHEN s.EntityType='CU' THEN 'Customer' ELSE 'Contract' END
,sda.Amount_Amount
,sda.Amount_Currency
,gdm.IsDebit
,dbo.[GetGLAccountNumber](s.InstrumentTypeId,CASE WHEN gdm.GLAccountId IS NULL THEN glmei.MatchingGLTemplateDetailId ELSE gdm.Id END,c.ContractType,sda.ContractId,s.LegalEntityId,s.LineofBusinessId,'',s.CostCenterId,s.CurrencyId,0,'') GLAccountNumber
,'Security Deposit - ' + Convert(Nvarchar(max),p.PartyNumber) Description
,s.Id SourceId
,1 isActive
,@Userid CreatedById
,@CreatedTime CreatedByTime
,CASE WHEN gdm.GLAccountId IS NULL THEN glmei.GLAccountId ELSE gdm.GLAccountId END GLAccountId
,gdm.Id GLTemplateDetailId
,glmei.MatchingGLTemplateDetailId
,CreatedGLJournal.GLJournalId
,s.LineofBusinessId
FROM SecurityDeposits s WITH (NOLOCK)
JOIN #CreatedSecurityDeposits ON #CreatedSecurityDeposits.Id = s.Id
JOIN SecurityDepositAllocations sda ON sda.SecurityDepositId = s.Id AND sda.EntityType ='Contract'
JOIN contracts c ON sda.ContractId = c.id
JOIN Parties p ON p.Id = s.CustomerId
JOIN #CreatedGLJournalIds CreatedGLJournal ON sda.Id = CreatedGLJournal.SecurityDepositId
JOIN #GLTemplateDetails gdm ON gdm.SecurityDepositId = s.Id
LEFT JOIN #GLMatchingEntryItems glmei ON gdm.Id = glmei.Id AND gdm.SecurityDepositId = glmei.SecurityDepositId
				UPDATE stgSecurityDeposit SET IsMigrated = 1
				WHERE 			
					Exists (SELECT * FROM #CreatedSecurityDeposits where SecurityDepositId = stgSecurityDeposit.Id);
				MERGE stgProcessingLog AS ProcessingLog
				USING (SELECT SecurityDepositId
						FROM #CreatedSecurityDeposits) AS ProcessedSecurityDeposit
				ON (ProcessingLog.StagingRootEntityId = ProcessedSecurityDeposit.SecurityDepositId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)		
				WHEN MATCHED THEN
					UPDATE SET UpdatedTime = @CreatedTime,UpdatedById = @UserId
				WHEN NOT MATCHED THEN
				INSERT
					(
						StagingRootEntityId
						,CreatedById
						,CreatedTime
						,ModuleIterationStatusId
					)
				VALUES
					(
						ProcessedSecurityDeposit.SecurityDepositId
						,@UserId
						,@CreatedTime
						,@ModuleIterationStatusId
					)
				OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
				INSERT INTO  stgProcessingLogDetail
						(Message
						,Type
						,CreatedById
						,CreatedTime	
						,ProcessingLogId)
				SELECT
						'Successful'
						,'Information'
						,@UserId
						,@CreatedTime
						,Id
				FROM #CreatedProcessingLogs;				
				SET @SkipCount = @SkipCount + @TakeCount;
				DROP TABLE #CreatedSecurityDeposits
				DROP TABLE #CreatedProcessingLogs				
				DROP TABLE #SecurityDeposit
				DROP TABLE #CreatedReceivablesIds
				DROP TABLE #GLMatchingEntryItems
				DROP TABLE #GLTemplateDetails
				DROP TABLE #CreatedGLJournalIds

COMMIT TRANSACTION
END TRY
BEGIN CATCH
   SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateSecurityDeposits'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount;
	END;  
	ELSE IF (XACT_STATE()) = 1  
	BEGIN
		COMMIT TRANSACTION;
		RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
	END; 
	ELSE
	BEGIN
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
        SET @FailedRecords = @FailedRecords+@BatchCount;
	END;
END CATCH
END
		MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT DISTINCT StagingRootEntityId
					FROM #ErrorLogDetails ) AS ErrorSecurityDeposit
		ON (ProcessingLog.StagingRootEntityId = ErrorSecurityDeposit.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime,UpdatedById = @UserId
		WHEN NOT MATCHED THEN
		INSERT
			(
				StagingRootEntityId
				,CreatedById
				,CreatedTime
				,ModuleIterationStatusId
			)
			VALUES
			(
				ErrorSecurityDeposit.StagingRootEntityId
				,@UserId
				,@CreatedTime
				,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id, ErrorSecurityDeposit.StagingRootEntityId INTO #FailedProcessingLogs;
		INSERT INTO stgProcessingLogDetail
		(
			Message
			,Type
			,CreatedById
			,CreatedTime	
			,ProcessingLogId
		)
		SELECT
			#ErrorLogs.Message
			,'Error'
			,@UserId
			,@CreatedTime
			,#FailedProcessingLogs.Id
		FROM #ErrorLogs
		JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.SecurityDepositId;	
		SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails)
		SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;
		DROP TABLE #ErrorLogs
		DROP TABLE #ErrorLogDetails	
		DROP TABLE #FailedProcessingLogs
		DROP TABLE #LegalEntityLOB	
		DROP TABLE #GLOrgStructureConfigs		
		DROP TABLE #ServicingDetails
		DROP TABLE #TempSecurityDeposit
		DROP TABLE #TempSecurityDepositAllocation
		SET NOCOUNT OFF;
		SET XACT_ABORT OFF;
END

GO
