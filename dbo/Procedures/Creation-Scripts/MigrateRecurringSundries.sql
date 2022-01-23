SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateRecurringSundries]
(
	@UserId BIGINT ,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT,
	@ToolIdentifier INT
)
AS
IF OBJECT_ID('tempdb..#ErrorLogs') IS NOT NULL DROP TABLE #ErrorLogs
IF OBJECT_ID('tempdb..#FailedProcessingLogs') IS NOT NULL DROP TABLE #FailedProcessingLogs
IF OBJECT_ID('tempdb..#CreatedProcessingLogs') IS NOT NULL DROP TABLE #CreatedProcessingLogs
IF OBJECT_ID('tempdb..#ErrorLogDetails') IS NOT NULL DROP TABLE #ErrorLogDetails
IF OBJECT_ID('tempdb..#LegalEntityLOB') IS NOT NULL DROP TABLE #LegalEntityLOB
IF OBJECT_ID('tempdb..#CreatedRecurringSundries') IS NOT NULL DROP TABLE #CreatedRecurringSundries
IF OBJECT_ID('tempdb..#SundryRecurring') IS NOT NULL DROP TABLE #SundryRecurring
IF OBJECT_ID('tempdb..#GeneratedSundryRecurringPaymentSchedule') IS NOT NULL DROP TABLE #GeneratedSundryRecurringPaymentSchedule
IF OBJECT_ID('tempdb..#GeneratedNextPaymentDate') IS NOT NULL DROP TABLE #GeneratedNextPaymentDate
BEGIN
--DECLARE @CreatedTime DATETIMEOFFSET = NULL;
--DECLARE	@ProcessedRecords BIGINT = 0;
--DECLARE	@FailedRecords BIGINT =0;
--DECLARE @USERId BIGINT= 5; 
--DECLARE @ModuleIterationStatusId  BIGINT= 5;
DECLARE @SundryRecurring_Cursor CURSOR  
DECLARE @Ids BIGINT
DECLARE	@LastDueDate DATE
DECLARE @DueDay INT
DECLARE @Frequency NVARCHAR(20)
DECLARE @NumberOfDays INT
DECLARE @NumberOfPayments INT
DECLARE @SundryType NVARCHAR(30)
DECLARE @IsRegular BIT
DECLARE @PayableAmount DECIMAL(16,2)
DECLARE @ReceivableAmount DECIMAL(16,2)
DECLARE @InitialPayableAmount DECIMAL(16,2)
DECLARE @InitialAmount DECIMAL(16,2)
DECLARE @RegularAmount DECIMAL(16,2)
DECLARE @SundryRecurringId BIGINT
	SET NOCOUNT ON;
	SET XACT_ABORT ON
	IF(@CreatedTime IS NULL)
	SET @CreatedTime = SYSDATETIMEOFFSET();
	DECLARE @Counter INT = 0;
	DECLARE @TakeCount INT = 50000;
	DECLARE @SkipCount INT = 0;
	DECLARE @MaxSundryId INT = 0;
	DECLARE @BatchCount INT = 0
	DECLARE @IsCollected BIT = NULL;
	DECLARE	@IsServiced BIT = NULL ;
	DECLARE @IsPrivateLabel BIT = NULL;
	SET @FailedRecords = 0;
	SET @ProcessedRecords = 0;
	DECLARE @DoNotAssessTaxForTaxExemptSundries BIT = ISNULL((SELECT TOP 1 
																(CASE 
																	WHEN UPPER(Value) = 'TRUE' 
																		 THEN 1 
																	ELSE 0 END) 
															   FROM GlobalParameters 
															   WHERE Category = 'Sundry' 
																 AND Name = 'DoNotAssessTaxForTaxExemptSundries'),
															 0);
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module,@ToolIdentifier
SELECT * INTO #TempSundryRecurring
FROM StgSundryRecurring WHERE IsMigrated = 0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)

SELECT stgSundryRecurringPaymentDetail.* INTO #TempSundryRecurringPaymentDetail
FROM stgSundryRecurringPaymentDetail JOIN #TempSundryRecurring 
ON #TempSundryRecurring.Id =stgSundryRecurringPaymentDetail.SundryRecurringId 

	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgSundryRecurring
										WHERE IsMigrated = 0 AND (toolIdentifier = @ToolIdentifier OR toolIdentifier IS NULL));
	CREATE TABLE #ErrorLogs
	(
		Id BIGINT not null IDENTITY PRIMARY KEY,
		StagingRootEntityId BIGINT,
		Result NVARCHAR(10),
		Message NVARCHAR(MAX)
	);
	CREATE TABLE #TempSundryRecurringForPrivateLabel
		(
			Id BIGINT,
			IsCollected BIT,
			IsServiced BIT,
			IsPrivateLabel BIT
		);
	SELECT 
	DISTINCT LineofBusinessId
	        ,LegalEntityId 
	INTO #LegalEntityLOB
	FROM GLOrgStructureConfigs where IsActive=1	
	UPDATE #TempSundryRecurring SET R_CustomerId = Parties.Id
    FROM #TempSundryRecurring SR WITH(NOLOCK)
    LEFT JOIN Parties WITH(NOLOCK) ON UPPER(Parties.PartyNumber) = UPPER(SR.CustomerPartyNumber) AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	UPDATE #TempSundryRecurring  SET R_CustomerId = CASE WHEN Contracts.ContractType='Loan' THEN Loan.CustomerId
	WHEN Contracts.ContractType='Lease' THEN Lease.CustomerId 
	WHEN Contracts.ContractType='LeveragedLease' THEN LeveragedLease.CustomerId
	ELSE Loan.CustomerId END
	From #TempSundryRecurring SR 
	LEFT JOIN Contracts WITH(NOLOCK) ON UPPER(SR.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SR.EntityType = 'CT'
	LEFT JOIN LoanFinances Loan WITH(NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 
	LEFT JOIN LeaseFinances Lease WITH(NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1
	LEFT JOIN LeveragedLeases LeveragedLease WITH(NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_CustomerId IS NULL ;
	UPDATE #TempSundryRecurring SET R_ContractId = Contracts.Id
	From #TempSundryRecurring SR 
	INNER JOIN Contracts WITH(NOLOCK) ON UPPER(Contracts.SequenceNumber) = UPPER(SR.ContractSequencenumber) AND SR.EntityType = 'CT' AND SR.IsMigrated=0   AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	UPDATE #TempSundryRecurring SET R_InstrumentTypeId = CASE WHEN EntityType='CU' THEN InstrumentTypes.Id ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.InstrumentTypeId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.InstrumentTypeId ELSE Loan.InstrumentTypeId END END
	From #TempSundryRecurring SR 
	LEFT JOIN InstrumentTypes WITH(NOLOCK) ON UPPER(InstrumentTypes.Code) = UPPER(SR.InstrumentTypeCode) AND InstrumentTypes.IsActive = 1
	LEFT JOIN Contracts WITH(NOLOCK) ON UPPER(SR.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SR.EntityType = 'CT'
	LEFT JOIN LoanFinances Loan WITH(NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 
	LEFT JOIN LeaseFinances Lease WITH(NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1 
	LEFT JOIN LeveragedLeases LeveragedLease WITH(NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_InstrumentTypeId IS NULL ;
	--SELECT InstrumentTypes .Id, Contracts.ContractType,sr.ContractSequenceNumber fROM stgSundryRecurring  SR
	--LEFT JOIN InstrumentTypes ON UPPER(InstrumentTypes.Code) = UPPER(SR.InstrumentTypeCode) AND InstrumentTypes.IsActive = 1
	--LEFT JOIN Contracts ON UPPER(SR.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SR.EntityType = 'CT'
	--LEFT JOIN LoanFinances Loan ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 AND Loan.InstrumentTypeId = InstrumentTypes.Id
	--WHERE SR.IsMigrated=0
	INSERT INTO #ErrorLogs
		SELECT SR.Id, 'Error','ContractSequencenumber is not valid for SundryRecurring {Id : '+ISNULL(CONVERT(NVARCHAR,SR.Id),' ')+'} with EntityType {'+SR.EntityType+'}'
		FROM #TempSundryRecurring SR WITH(NOLOCK) 
		WHERE SR.R_ContractId IS NULL AND SR.IsMigrated=0 AND (SR.ToolIdentifier IS NULL OR SR.ToolIdentifier = @ToolIdentifier) AND SR.EntityType ='CT'; 
	INSERT INTO #ErrorLogs
		SELECT SR.Id, 'Error','Recurring Sundry can only be created for contract with status as Commenced  { Id : '+CONVERT(NVARCHAR,SR.Id)+'}' 
		FROM #TempSundryRecurring SR WITH (NOLOCK) 
		JOIN Contracts ON Contracts.Id = SR.R_ContractId
		LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
		LEFT JOIN LoanFinances ON LoanFinances.ContractId = Contracts.Id
		LEFT JOIN LeveragedLeases ON LeveragedLeases.ContractId = Contracts.Id
		WHERE  SR.EntityType = 'CT' AND ((LeaseFinances.Id IS NOT NULL AND LeaseFinances.BookingStatus != 'Commenced' AND LeaseFinances.IsCurrent=1)
		OR (LoanFinances.Id IS NOT NULL AND LoanFinances.Status != 'Commenced' AND LoanFinances.IsCurrent=1)
		OR (LeveragedLeases.Id IS NOT NULL AND LeveragedLeases.Status != 'Commenced' AND LeveragedLeases.IsCurrent=1))
	    AND SR.IsMigrated=0 AND (SR.ToolIdentifier IS NULL OR SR.ToolIdentifier = @ToolIdentifier) ;
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Cannot create Recurring Sundry for a syndicated contract with IsServiced = False and IsCollected = False {Id : '+ISNULL(CONVERT(NVARCHAR,SR.Id),' ')+'} with EntityType {'+SR.EntityType+'}'
	FROM #TempSundryRecurring SR WITH (NOLOCK)
	JOIN Contracts ON Contracts.Id = R_ContractId
	WHERE Contracts.SyndicationType != 'None' AND SR.IsServiced=0 AND SR.IsCollected =0 AND SR.EntityType = 'CT'
	AND SR.IsMigrated=0 AND (SR.ToolIdentifier IS NULL OR SR.ToolIdentifier = @ToolIdentifier); 
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Invalid InstrumentTypeCode : '+ISNULL(SR.InstrumentTypeCode,' ')+' for sundry recurring {Id : '+ISNULL(CONVERT(NVARCHAR,SR.Id),' ')+'} with EntityType {'+SR.EntityType+'}'
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	WHERE SR.R_InstrumentTypeId IS NULL  AND IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL); 
	UPDATE #TempSundryRecurring SET R_SundryRecurringPaymentDetailId = detail.Id
	From #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN #TempSundryRecurringPaymentDetail detail WITH(NOLOCK) ON detail.SundryRecurringId = SR.Id
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_SundryRecurringPaymentDetailId IS NULL AND SR.SundryType != 'PayableOnly';
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','At least one asset must be present for the asset based sundry recurring { Id : '+CONVERT(NVARCHAR,SR.Id)+'}' 
	FROM #TempSundryRecurring SR  WITH(NOLOCK)
	WHERE SR.R_SundryRecurringPaymentDetailId IS NULL AND IsMigrated=0   AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)AND SR.IsAssetBased=1 AND SR.SundryType != 'PayableOnly';
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Asset must not be present for the sundry as it is not set as IsAssetBased for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.R_SundryRecurringPaymentDetailId IS NOT NULL AND IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=0;
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Only lease based sundry can be Asset Based for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	JOIN Contracts WITH(NOLOCK) on Contracts.Id = SR.R_ContractId
	WHERE (SR.EntityType ='CT' AND SR.R_ContractId IS NOT NULL AND Contracts.ContractType !='Lease') AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1;
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Payable sundry can not be Asset Based for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1 AND SR.SundryType='PayableOnly';
	UPDATE #TempSundryRecurringPaymentDetail SET R_AssetId = Assets.Id
	From #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN #TempSundryRecurringPaymentDetail detail WITH(NOLOCK) ON detail.SundryRecurringId= SR.Id
	INNER JOIN LeaseFinances WITH(NOLOCK) ON LeaseFinances.ContractId = SR.R_ContractId
	INNER JOIN LeaseAssets WITH(NOLOCK) ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
	INNER JOIN Assets WITH(NOLOCK) ON LeaseAssets.AssetId = Assets.Id AND detail.AssetAlias = Assets.Alias
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1 
	AND SR.EntityType = 'CT' AND (Assets.Status = 'InvestorLeased' OR Assets.Status = 'Leased') AND Assets.FinancialType = 'Real';
	UPDATE #TempSundryRecurringPaymentDetail SET R_AssetId = Assets.Id
	From #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN #TempSundryRecurringPaymentDetail detail WITH(NOLOCK) ON detail.SundryRecurringId= SR.Id
	INNER JOIN Assets WITH(NOLOCK) ON Assets.CustomerId = SR.R_CustomerId AND detail.AssetAlias = Assets.Alias
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1 
	AND SR.EntityType = 'CU' AND Assets.Status = 'Inventory' AND Assets.FinancialType = 'Real';
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error',('Invalid Asset Alias:{' + ISNULL(detail.AssetAlias,'NULL') + '}  for sundry recurring Id {' + CONVERT(VARCHAR,SR.Id) + '}') 
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN #TempSundryRecurringPaymentDetail detail WITH(NOLOCK) ON detail.SundryRecurringId= SR.Id
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1 AND detail.R_AssetId IS NULL AND SR.EntityType = 'CU';
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error',('Invalid Asset Alias:{' + ISNULL(detail.AssetAlias,'NULL') + '}  for sundry recurring Id {' + CONVERT(VARCHAR,SR.Id) + '}') 
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN #TempSundryRecurringPaymentDetail detail WITH(NOLOCK) ON detail.SundryRecurringId= SR.Id
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1 AND detail.R_AssetId IS NULL AND SR.EntityType = 'CT' AND SR.R_ContractId IS NOT NULL;
	
	UPDATE #TempSundryRecurring SET R_LegalEntityId = CASE WHEN SR.EntityType = 'CU' THEN #LegalEntityLOB.LegalEntityId ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.LegalEntityId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.LegalEntityId ELSE Loan.LegalEntityId END END,
	R_LineofBusinessId=CASE WHEN SR.EntityType = 'CU' THEN LineofBusinesses.Id ELSE Contracts.LineOfBusinessId END
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN LineofBusinesses WITH(NOLOCK) ON UPPER(LineofBusinesses.Name) = UPPER(SR.LineofBusinessName) AND LineofBusinesses.IsActive = 1
	LEFT JOIN LegalEntities WITH(NOLOCK) ON UPPER(LegalEntities.LegalEntityNumber) = UPPER(SR.LegalEntityNumber)
	LEFT JOIN #LegalEntityLOB WITH(NOLOCK) ON #LegalEntityLOB.LegalEntityId = LegalEntities.Id AND LineofBusinesses.Id = #LegalEntityLOB.LineofBusinessId
	LEFT JOIN Contracts WITH(NOLOCK) ON UPPER(SR.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SR.EntityType = 'CT'
	LEFT JOIN LoanFinances Loan WITH(NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1
	LEFT JOIN LeaseFinances Lease WITH(NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1
	LEFT JOIN LeveragedLeases LeveragedLease WITH(NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND R_LegalEntityId IS NULL;
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error', 'Invalid LineOfBusiness Name : ' + ISNULL(SR.LineofBusinessName, ' ')  + ' with EntityType {' + SR.EntityType + '} for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR 
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_LineofBusinessId IS NULL AND SR.EntityType = 'CU';
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error', 'Invalid LineOfBusiness for ContractSequencenumber : ' + ISNULL(SR.ContractSequencenumber, ' ')  + ' with EntityType {' + SR.EntityType + '} for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR 
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_LineofBusinessId IS NULL AND SR.EntityType = 'CT';
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error', 'Invalid LegalEntityNumber : ' + ISNULL(SR.LegalEntityNumber, ' ') + ' for Contract {Id : ' + ISNULL(CONVERT(NVARCHAR, SR.R_ContractId), ' ') + '} with EntityType {' + SR.EntityType + '} for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_LegalEntityId IS NULL AND SR.EntityType = 'CU';
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error', 'Invalid LegalEntityNumber : ' + ISNULL(SR.LegalEntityNumber, ' ') + ' for Contract {Id : ' + ISNULL(CONVERT(NVARCHAR, SR.R_ContractId), ' ') + '} with EntityType {' + SR.EntityType + '} for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_LegalEntityId IS NULL AND SR.EntityType = 'CT' AND SR.R_ContractId IS NOT NULL;
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Entity Type must be either Contract or Customer for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.EntityType !='CT' AND SR.EntityType !='CU' AND SR.IsMigrated=0;
	UPDATE #TempSundryRecurring SET R_ReceivableCodeId = ReceivableCodes.Id, R_ReceivableGroupingOption=ReceivableCodes.DefaultInvoiceReceivableGroupingOption
	From #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN ReceivableCodes WITH(NOLOCK) ON SR.ReceivableCodeName = ReceivableCodes.Name AND ReceivableCodes.IsActive = 1
	AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL);
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Valid Receivable Code is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}'
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.SundryType !='PayableOnly' AND (SR.ReceivableCodeName IS NULL OR SR.R_ReceivableCodeId IS NULL)
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Customer Status must be either Active or Pending for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	INNER JOIN Parties WITH(NOLOCK) ON SR.CustomerPartyNumber= Parties.PartyNumber
	INNER JOIN Customers WITH(NOLOCK) ON Parties.Id = Customers.Id 
	WHERE Customers.Status != 'Active'
	AND Customers.Status!= 'Pending' AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL);
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Customer Status must be either Active or Pending for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Contracts WITH(NOLOCK) ON SR.R_ContractId = Contracts.Id
	WHERE SR.R_ContractId IS NOT NULL AND ((Contracts.ContractType = 'Lease' AND Contracts.ReferenceType = 'Assumed')
	OR Contracts.Status = 'Inactive'
	OR Contracts.Status= 'Cancelled')
	AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL);
	UPDATE #TempSundryRecurring SET R_CurrencyId = Currency.Id 
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	LEFT JOIN CurrencyCodes CurrencyCode WITH(NOLOCK) ON UPPER(SR.CurrencyCode) = UPPER(CurrencyCode.ISO) AND CurrencyCode.IsActive = 1
	LEFT JOIN Currencies Currency WITH(NOLOCK) ON CurrencyCode.Id = Currency.CurrencyCodeId AND Currency.IsActive = 1
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_CurrencyId IS NULL ;
	UPDATE #TempSundryRecurring SET R_BillToId = CASE WHEN SR.EntityType = 'CT' THEN ISNULL(LeaseAssets.BillToId,Contracts.BillToId) ELSE BillToes.Id END
	FROM #TempSundryRecurring SR WITH (NOLOCK)
	LEFT JOIN BillToes ON BillToes.CustomerId = SR.R_CustomerId AND BillToes.IsPrimary = 1 AND BillToes.IsActive = 1
	LEFT JOIN Contracts ON Contracts.Id = SR.R_ContractId
	LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
	LEFT JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id 
	WHERE SR.IsMigrated=0 AND (SR.ToolIdentifier IS NULL OR SR.ToolIdentifier = @ToolIdentifier) AND SR.BillToName IS NULL AND SR.IsAssetBased = 0 AND SR.SundryType != 'PayableOnly'
	UPDATE #TempSundryRecurringPaymentDetail SET R_BillToId = CASE WHEN SR.EntityType = 'CT' THEN ISNULL(LeaseAssets.BillToId,Contracts.BillToId) ELSE BillToes.Id END
	FROM #TempSundryRecurringPaymentDetail WITH (NOLOCK)
	JOIN #TempSundryRecurring SR ON SR.Id = #TempSundryRecurringPaymentDetail.SundryRecurringId
	LEFT JOIN BillToes ON BillToes.CustomerId = SR.R_CustomerId AND BillToes.IsPrimary = 1 AND BillToes.IsActive = 1
	LEFT JOIN Contracts ON Contracts.Id = SR.R_ContractId
	LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
	LEFT JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id 
	WHERE SR.IsMigrated=0 AND (SR.ToolIdentifier IS NULL OR SR.ToolIdentifier = @ToolIdentifier) AND #TempSundryRecurringPaymentDetail.BillToName IS NULL AND SR.IsAssetbased = 1 AND SR.SundryType != 'PayableOnly'
		
	UPDATE 
	#TempSundryRecurring SET R_BillToId = BillToes.Id
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN Parties WITH(NOLOCK) ON UPPER(Parties.PartyNumber) = UPPER(SR.CustomerPartyNumber)
	INNER JOIN BillToes WITH(NOLOCK) ON BillToes.CustomerId = Parties.Id AND SR.BillToName = BillToes.Name AND BillToes.IsActive = 1 
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_BillToId IS NULL AND SR.EntityType='CU' AND SR.SundryType != 'PayableOnly';
	UPDATE #TempSundryRecurring SET R_BillToId = BillToes.Id 
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Contracts WITH(NOLOCK) ON Contracts.SequenceNumber = SR.ContractSequenceNumber
	LEFT JOIN LeaseFinances LF WITH(NOLOCK) on Contracts.Id=LF.ContractId
	LEFT JOIN BillToes WITH(NOLOCK) ON SR.BillToName = BillToes.Name AND BillToes.IsActive = 1 AND LF.CustomerId=BillToes.CustomerId
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_BillToId IS NULL AND SR.EntityType='CT' AND SR.SundryType != 'PayableOnly';
	UPDATE #TempSundryRecurring SET R_BillToId = BillToes.Id 
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	LEFT JOIN Contracts WITH(NOLOCK) ON Contracts.SequenceNumber = SR.ContractSequenceNumber
	LEFT JOIN LoanFinances LF WITH(NOLOCK) on Contracts.Id=LF.ContractId
	LEFT JOIN BillToes WITH(NOLOCK) ON SR.BillToName = BillToes.Name AND BillToes.IsActive = 1  AND LF.CustomerId=BillToes.CustomerId
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_BillToId IS NULL AND SR.EntityType='CT' AND SR.SundryType != 'PayableOnly';	
	UPDATE #TempSundryRecurringPaymentDetail SET R_BillToId = BillToes.Id 
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN #TempSundryRecurringPaymentDetail WITH(NOLOCK) ON SR.Id = #TempSundryRecurringPaymentDetail.SundryRecurringId
	INNER JOIN BillToes WITH(NOLOCK) ON #TempSundryRecurringPaymentDetail.BillToName = BillToes.Name AND BillToes.IsActive = 1
	INNER JOIN Customers WITH(NOLOCK) ON Customers.Id = BillToes.CustomerId
	WHERE SR.IsMigrated=0 AND (SR.ToolIdentifier IS NULL OR SR.ToolIdentifier = @ToolIdentifier) 
	AND #TempSundryRecurringPaymentDetail.R_BillToId IS NULL AND SR.IsAssetBased=1 AND Customers.Id = R_CustomerId;


    INSERT INTO #ErrorLogs
	SELECT SR.Id
			 ,'Error'
			 ,'Invalid BillToName : '+ISNULL(SR.BillToName,'')+' for Sundry {Id : '+CONVERT(NVARCHAR,SR.Id)+'} with EntityType {'+SR.EntityType+'}' AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.R_BillToId IS NULL AND SR.IsMigrated=0 AND SR.IsAssetBased=0
	AND SR.SundryType !='PayableOnly' AND SR.EntityType = 'CU';
	INSERT INTO #ErrorLogs
	SELECT SR.Id
			 ,'Error'
			 ,'Invalid BillToName : '+ISNULL(SR.BillToName,'')+' for Sundry {Id : '+CONVERT(NVARCHAR,SR.Id)+'} with EntityType {'+SR.EntityType+'}' AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.R_BillToId IS NULL AND SR.IsMigrated=0 AND SR.IsAssetBased=0
	AND SR.SundryType !='PayableOnly' AND SR.EntityType = 'CT' AND SR.R_ContractId IS NOT NULL;

	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error','Invalid BillToName : '+ISNULL(#TempSundryRecurringPaymentDetail.BillToName,'')+' for sundry recurring{Id : '+CONVERT(NVARCHAR,SR.Id)+'} with EntityType {'+SR.EntityType+'}' AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	INNER JOIN #TempSundryRecurringPaymentDetail WITH(NOLOCK) ON SR.Id = #TempSundryRecurringPaymentDetail.SundryRecurringId
	WHERE #TempSundryRecurringPaymentDetail.R_BillToId IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1
	AND SR.SundryType !='PayableOnly' AND SR.EntityType = 'CU';
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error','Invalid BillToName : '+ISNULL(#TempSundryRecurringPaymentDetail.BillToName,'')+' for sundry recurring{Id : '+CONVERT(NVARCHAR,SR.Id)+'} with EntityType {'+SR.EntityType+'}' AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	INNER JOIN #TempSundryRecurringPaymentDetail WITH(NOLOCK) ON SR.Id = #TempSundryRecurringPaymentDetail.SundryRecurringId
	WHERE #TempSundryRecurringPaymentDetail.R_BillToId IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased=1
	AND SR.SundryType !='PayableOnly' AND SR.EntityType = 'CT' AND SR.R_ContractId IS NOT NULL;
	UPDATE #TempSundryRecurring SET R_ReceivableRemitToId = RemitToes.Id,R_ReceivableRemitToLegalEntityId= LegalEntityRemitTo.LegalEntityId
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN RemitToes WITH(NOLOCK) ON UPPER(RemitToes.UniqueIdentifier) = UPPER(SR.ReceivableRemitToUniqueIdentifier) AND RemitToes.IsActive=1
	LEFT JOIN LegalEntityRemitToes  LegalEntityRemitTo WITH(NOLOCK) ON RemitToes.Id = LegalEntityRemitTo.RemitToId AND SR.R_LegalEntityId= LegalEntityRemitTo.LegalEntityId
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND (SR.R_ReceivableRemitToId IS NULL OR SR.R_ReceivableRemitToLegalEntityId IS NULL)
    INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Receivable Remit to must belong to the selected Legal Entity for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.R_ReceivableRemitToId IS NOT NULL
	AND SR.R_ReceivableRemitToLegalEntityId IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.EntityType = 'CU'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Receivable Remit to must belong to the selected Legal Entity for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.R_ReceivableRemitToId IS NOT NULL
	AND SR.R_ReceivableRemitToLegalEntityId IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.EntityType = 'CT' AND SR.R_ContractId IS NOT NULL
	
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error', 'Valid Receivable Remit to is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}' AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE SR.R_ReceivableRemitToId IS NULL AND IsMigrated=0 AND SR.SundryType !='PayableOnly'  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL);
	UPDATE #TempSundryRecurring SET R_LocationId = Location.Id
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Locations Location WITH(NOLOCK) ON UPPER(SR.LocationCode) = UPPER(Location.Code)
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_LocationId IS NULL ;
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Location is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Contracts WITH(NOLOCK) ON Contracts.Id = SR.R_ContractId 
		WHERE SR.SundryType != 'PayableOnly'
		AND LocationCode IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.EntityType !='CT'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Location is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Contracts WITH(NOLOCK) ON Contracts.SequenceNumber = SR.ContractSequenceNumber 
	INNER JOIN LoanFinances WITH(NOLOCK) ON LoanFinances.Id= Contracts.Id
	INNER JOIN GlobalParameters WITH(NOLOCK) ON GlobalParameters.Category='SalesTax' AND Name='IsSalesTaxRequiredForLoan'
		WHERE LocationCode IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND GlobalParameters.Value='True'
		AND SR.EntityType ='CT' AND SR.SundryType ! ='PayableOnly'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Location is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	LEFT JOIN Contracts WITH(NOLOCK) ON Contracts.SequenceNumber = SR.ContractSequenceNumber
	INNER JOIN LeaseFinances WITH(NOLOCK) ON LeaseFinances.ContractId = Contracts.Id 
	INNER JOIN (
	Select Count(Id) AS Count ,LeaseFinanceId FROM LeaseAssets GROUP BY LeaseFinanceId) assets ON
	assets.LeaseFinanceId = LeaseFinances.Id
	WHERE LocationCode IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND LeaseFinances.ApprovalStatus='Pending'
		AND SR.EntityType ='CT' AND Assets.Count = 0 AND SR.SundryType ! ='PayableOnly'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Location must be an active and approved location present in the system' + ISNULL(' : ' + LocationCode, '') + ' for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Locations WITH(NOLOCK) ON SR.R_LocationId = Locations.Id
	WHERE SundryType != 'PayableOnly'
		AND LocationCode IS NOT NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND (SR.R_LocationId IS NULL
			OR Locations.IsActive = 0 
			OR (Locations.ApprovalStatus != 'Approved' AND Locations.ApprovalStatus != 'ReAssess'))
	INSERT INTO #ErrorLogs
	SELECT  SR.Id,'Error',('Vendor Party Number is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE (SR.SundryType = 'PayableOnly' OR SR.SundryType='PassThrough')
		AND SR.VendorPartyNumber IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Instrument Type is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE  
	 SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_InstrumentTypeId IS NULL AND SR.EntityType != 'CT'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Assign at asset level field should be false for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE  
	 SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsAssetBased = 0 AND SR.IsApplyAtAssetLevel = 1
	 INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Bill Past End Date field should be false for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE  
	 SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.IsRentalBased = 0 AND SR.BillPastEndDate= 1
	INSERT INTO #ErrorLogs
    SELECT DISTINCT SR.Id,'Error',(' BillPastEndDate Must be set to true for SundryRecurringpaymentSchedule  with SundryRecurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
    JOIN stgSundryRecurringPaymentSchedule ON SR.Id = stgSundryRecurringPaymentSchedule.SundryRecurringId
	JOIN Contracts ON Contracts.id = SR.R_contractId
	LEFT JOIN LeaseFinances ON LeaseFinances.contractId = Contracts.id
	LEFT JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id = Leasefinances.Id  AND LeaseFinances.IsCurrent = 1
	LEFT JOIN LoanFinances ON LoanFinances.ContractId  = Contracts.Id AND LoanFinances.IsCurrent = 1
	WHERE stgSundryRecurringPaymentSchedule.BillPastEndDate = 0  AND ((Contracts.ContractType = 'Lease' AND LeaseFinanceDetails.MaturityDate<stgSundryRecurringPaymentSchedule.DueDate)
	OR (Contracts.ContractType = 'LOAN' AND LoanFinances.MaturityDate<stgSundryRecurringPaymentSchedule.DueDate))
	AND SR.Ismigrated =0 AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	AND SR.IsRentalBased = 1 AND SR.GeneratePaymentSchedule = 0 AND SR.EntityType = 'CT'
	 INSERT INTO #ErrorLogs
	 SELECT  DISTINCT SR.Id,'Error',(' BillPastEndDate Must be set to false for SundryRecurringPaymentSchedule  with SundryRecurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	JOIN stgSundryRecurringPaymentSchedule ON SR.Id = stgSundryRecurringPaymentSchedule.SundryRecurringId
	JOIN Contracts ON Contracts.id = SR.R_contractId
	LEFT JOIN LeaseFinances ON LeaseFinances.contractId = Contracts.id
	LEFT JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id = Leasefinances.Id  AND LeaseFinances.IsCurrent = 1
	LEFT JOIN LoanFinances ON LoanFinances.ContractId  = Contracts.Id AND LoanFinances.IsCurrent = 1
	WHERE stgSundryRecurringPaymentSchedule.BillPastEndDate = 1  AND ((Contracts.ContractType = 'Lease' AND LeaseFinanceDetails.MaturityDate>=stgSundryRecurringPaymentSchedule.DueDate)
	OR (Contracts.ContractType = 'LOAN' AND LoanFinances.MaturityDate>=stgSundryRecurringPaymentSchedule.DueDate))
	AND SR.Ismigrated =0 AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	AND SR.IsRentalBased = 1 AND SR.GeneratePaymentSchedule = 0 AND SR.EntityType = 'CT'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('No.Of Payment Schedule records should match with NumberOfPayments field for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN 
	(
	Select COUNT(Id) AS Count,SundryRecurringId FROM
	stgSundryRecurringPaymentSchedule
	GROUP BY SundryRecurringId
	)AS schedule ON schedule.SundryRecurringId = SR.Id
	WHERE  
	 SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)  AND Isnull(Count,0)! =SR.NumberOfPayments AND SR.GeneratePaymentSchedule = 0
	UPDATE #TempSundryRecurring SET R_VendorId = Vendors.Id
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Parties WITH(NOLOCK) ON  UPPER(Parties.PartyNumber) = UPPER(SR.VendorPartyNumber)
	LEFT JOIN Vendors WITH(NOLOCK) ON Parties.Id = Vendors.Id
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND R_VendorId IS NULL;
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error', ('Vendor must be active' + ISNULL(' : ' + VendorPartyNumber, '') + ' for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Vendors WITH(NOLOCK) ON Vendors.Id=SR.R_VendorId 
	WHERE (SR.SundryType = 'PayableOnly'  OR SR.SundryType='PassThrough')
		AND (SR.R_VendorId IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
			OR Vendors.Status != 'Active')
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error', ('Vendor {' + ISNULL(VendorPartyNumber, ' ') + '} must be actively associated with Sundry''s Legal Entity {' + ISNULL(LegalEntityNumber, '') + '}' + ' for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
		FROM #TempSundryRecurring SR WITH(NOLOCK)
		LEFT JOIN VendorLegalEntities ON SR.R_vendorId = VendorLegalEntities.VendorId AND SR.R_LegalEntityId = VendorLegalEntities.LegalEntityId AND VendorLegalEntities.IsActive = 1
	WHERE (SR.SundryType = 'PayableOnly'  OR SR.SundryType='PassThrough')
		AND SR.R_vendorId IS NOT NULL AND VendorLegalEntities.VendorId IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND (VendorLegalEntities.IsActive IS NULL OR VendorLegalEntities.IsActive  = 0)
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Payable Code is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE (SR.SundryType = 'PayableOnly' OR SR.SundryType='PassThrough')
		AND SR.PayableCodeName IS NULL AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	UPDATE #TempSundryRecurring SET R_PayableCodeId = PayableCode.Id
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN PayableCodes PayableCode WITH(NOLOCK) ON UPPER(SR.PayableCodeName) = UPPER(PayableCode.Name) AND PayableCode.IsActive = 1
	INNER JOIN PayableTypes PayableType WITH(NOLOCK) ON PayableCode.PayableTypeId = PayableType.Id AND PayableType.IsActive = 1 AND PayableType.Name ='MiscAP'
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_PayableCodeId IS NULL ;
	INSERT INTO #ErrorLogs
		SELECT SR.Id
				,'Error'
				,('Payable Code must be of Type "Misc AP"' + ' : ' +IsNull(PayableCodeName,'Null') + ' for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
		FROM #TempSundryRecurring SR WITH(NOLOCK)
		WHERE (SR.SundryType = 'PayableOnly' OR SR.SundryType = 'PassThrough')
			AND SR.PayableCodeName IS NOT NULL AND SR.R_PayableCodeId IS NULL 
			AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Payable Remit To is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	WHERE (SR.SundryType = 'PayableOnly' OR SR.SundryType='PassThrough') AND IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.PayableRemitToUniqueIdentifier IS NULL 
	UPDATE #TempSundryRecurring SET R_PayableRemitToId = PayableRemitTo.Id, R_ReceiptType=PayableRemitTo.ReceiptType
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	LEFT JOIN RemitToes PayableRemitTo WITH(NOLOCK) ON UPPER(SR.PayableRemitToUniqueIdentifier) = UPPER(PayableRemitTo.UniqueIdentifier) AND PayableRemitTo.IsActive = 1
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND R_PayableRemitToId IS NULL;
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Valid Payable Remit To is required for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE (SR.SundryType = 'PayableOnly' OR SR.SundryType='PassThrough') AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.R_PayableRemitToId IS NULL AND SR.PayableRemitToUniqueIdentifier IS NOT NULL
	UPDATE #TempSundryRecurring SET R_CostCenterId = CASE WHEN EntityType='CU' THEN CostCenterConfig.Id ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.CostCenterId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.CostCenterId ELSE Loan.CostCenterId END END
	From #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN CostCenterConfigs CostCenterConfig WITH(NOLOCK) ON UPPER(CostCenterConfig.CostCenter) = UPPER(SR.CostCenterName) AND CostCenterConfig.IsActive = 1
	LEFT JOIN Contracts WITH(NOLOCK) ON UPPER(SR.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SR.EntityType = 'CT'
	LEFT JOIN LoanFinances Loan WITH(NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 
	LEFT JOIN LeaseFinances Lease WITH(NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1 
	LEFT JOIN LeveragedLeases LeveragedLease WITH(NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_CostCenterId IS NULL ;
	INSERT INTO #ErrorLogs
	SELECT SR.Id, 'Error','Invalid CostCenter Name : '+ISNULL(SR.CostCenterName,'NULL')+' for sundry recurring {Id : '+ISNULL(CONVERT(NVARCHAR,SR.Id),' ')+'} with EntityType {'+SR.EntityType+'}'
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE R_CostCenterId IS NULL AND SR.IsMigrated = 0 AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.EntityType = 'CU'
	UPDATE #TempSundryRecurring SET R_BranchId =Branch.Id
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Branches Branch ON Branch.BranchName = SR.BranchName
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_BranchId IS NULL AND SR.EntityType='CU' AND SR.BranchName IS NOT NULL;
	UPDATE #TempSundryRecurring SET R_BranchId =Branch.Id
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	LEFT JOIN Branches Branch ON Branch.LegalEntityId= SR.R_LegalEntityId
	WHERE SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.R_BranchId IS NULL AND SR.EntityType='CT';
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Number of Payment must be greater than zero for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR  WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND (SR.NumberOfPayments IS NULL OR SR.NumberOfPayments=0)
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Due Day must be zero for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.DueDay > 0 AND (SR.Frequency = 'Days' OR SR.Frequency = 'Weekly' OR SR.Frequency = 'BiWeekly')
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Number of Days must be zero for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.NumberOfDays > 0 AND SR.Frequency != 'Days'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Frequency should not be null for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.Frequency IS NULL
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Due Day should not be null for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.DueDay IS NULL AND Frequency!='Days'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('First Due Date should not be null for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.FirstDueDate IS NULL
		INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Due Day must be between 1 and 31 for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.DueDay NOT BETWEEN 1 AND 31 AND Frequency!='Days' AND Frequency ! = 'Weekly' AND Frequency !='BiWeekly'
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('First Due Date should not be null for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		AND SR.FirstDueDate IS NULL
	INSERT INTO #ErrorLogs
	SELECT SR.Id,'Error',('Number of Days must be 28 or 30 for sundry recurring { Id : ' + CONVERT(NVARCHAR, SR.Id) + '}') AS Message
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	WHERE IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.Frequency='Daily'
		AND (SR.NumberOfDays != 28 AND SR.NumberOfDays !=30) 
	UPDATE #TempSundryRecurring SET ReceivableAmount_Amount = Amount,PayableAmount_Amount= PayableAmount
	FROM #TempSundryRecurring SR WITH(NOLOCK)
	INNER JOIN 
	(
	SELECT SundryRecurringId,SUM(detail.Amount_Amount) AS Amount ,SUM(PayableAmount_Amount) AS PayableAmount 
	FROM #TempSundryRecurringPaymentDetail detail 
	GROUP BY SundryRecurringId
	) as details ON details.SundryRecurringId = SR.Id
	WHERE SR.SundryType='PassThrough' AND SR.IsApplyAtAssetLevel = 1 AND SR.IsMigrated = 0 AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.GeneratePaymentSchedule=1
	UPDATE #TempSundryRecurring SET RegularAmount_Amount = Amount
	FROM #TempSundryRecurring SR WITH(NOLOCK) 
	INNER JOIN 
	(
	SELECT SundryRecurringId,SUM(detail.Amount_Amount) AS Amount
	FROM #TempSundryRecurringPaymentDetail detail 
	GROUP BY SundryRecurringId
	) as details ON details.SundryRecurringId = SR.Id
	WHERE SR.SundryType !='PassThrough' AND SR.IsApplyAtAssetLevel = 1 AND SR.IsMigrated = 0 AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND SR.GeneratePaymentSchedule=1
		  INSERT INTO #ErrorLogs
		  SELECT Distinct sr.Id, 'Error','Schedule level amounts dont match up to the Header level amount for sundry recurring { Id :'+ISNULL(CONVERT(NVARCHAR,sr.Id),' ')+'} with SundryType {'+sr.SundryType+'}'	
		  FROM #TempSundryRecurring sr      
          INNER JOIN stgSundryRecurringPaymentSchedule srps ON sr.Id= srps.SundryRecurringId
          WHERE  (srps.Amount_Amount != CASE WHEN SR.SundryType ='ReceivableOnly' THEN sr.RegularAmount_Amount 
                                           WHEN SR.SundryType='PassThrough' THEN Sr.ReceivableAmount_Amount 
                                           ELSE 0.00 END
          OR srps.PayableAmount_Amount != CASE WHEN SR.SundryType ='PayableOnly' OR SR.SundryType='PassThrough' THEN sr.PayableAmount_Amount
                                           ELSE 0.00 END )AND sr.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND sr.GeneratePaymentSchedule=0 AND sr.IsRegular = 1 AND  sr.IsApplyAtAssetLevel=0 
	     INSERT INTO #ErrorLogs
		 SELECT Distinct sr.Id, 'Error','Detail level amounts dont match up to the Header level amount for sundry recurring { Id :'+ISNULL(CONVERT(NVARCHAR,sr.Id),' ')+'} with SundryType {'+sr.SundryType+'}'	
		 FROM #TempSundryRecurring sr WITH(NOLOCK)
         INNER JOIN (SELECT SUM(srpd.Amount_Amount) AS Amount,srpd.SundryRecurringId FROM #TempSundryRecurringPaymentDetail srpd GROUP BY srpd.SundryRecurringId) AS T
		 ON T.SundryRecurringId = sr.Id
         INNER JOIN stgSundryRecurringPaymentSchedule srps WITH(NOLOCK) ON srps.SundryRecurringId = sr.Id
         WHERE sr.SundryType ='ReceivableOnly'
         AND sr.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND sr.GeneratePaymentSchedule = 0 AND Sr.IsApplyAtAssetLevel = 1 AND sr.IsRegular = 1 
         AND (srps.Amount_Amount != sr.RegularAmount_Amount OR T.Amount != sr.RegularAmount_Amount)
		 INSERT INTO #ErrorLogs
		 SELECT sr.Id, 'Error','Payable Amount must be less than or equivalent to Receivable Amount { Id :'+ISNULL(CONVERT(NVARCHAR,sr.Id),' ')+'}' AS Message	
		 FROM #TempSundryRecurring sr WITH(NOLOCK) WHERE
		 sr.PayableAmount_Amount>sr.ReceivableAmount_Amount AND sr.SundryType = 'PassThrough' AND sr.IsMigrated =0 AND (sr.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
		 INSERT INTO #ErrorLogs
		 SELECT Distinct sr.Id, 'Error','Detail level amounts dont match up to the Header level amount for sundry recurring { Id :'+ISNULL(CONVERT(NVARCHAR,sr.Id),' ')+'} with SundryType {'+sr.SundryType+'}'	
		 FROM #TempSundryRecurring sr WITH(NOLOCK)
         INNER JOIN (SELECT SUM(srpd.Amount_Amount) AS Amount,SUM(srpd.PayableAmount_Amount) AS PAmount,srpd.SundryRecurringId FROM #TempSundryRecurringPaymentDetail srpd GROUP BY srpd.SundryRecurringId) AS T
		 ON T.SundryRecurringId = sr.Id
         INNER JOIN stgSundryRecurringPaymentSchedule srps WITH(NOLOCK) ON srps.SundryRecurringId = sr.Id
         WHERE sr.SundryType ='PassThrough'
         AND sr.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL) AND sr.GeneratePaymentSchedule = 0 AND Sr.IsApplyAtAssetLevel = 1 AND sr.IsRegular = 1 
         AND (srps.Amount_Amount != sr.ReceivableAmount_Amount OR T.Amount != sr.ReceivableAmount_Amount OR srps.PayableAmount_Amount != sr.PayableAmount_Amount OR T.PAmount != sr.PayableAmount_Amount) 
		INSERT INTO #ErrorLogs
	    SELECT SR.Id,'Error','Payment cannot be zero for all Fixed Payment(s) for sundry recurring { Id :'+ISNULL(CONVERT(NVARCHAR,SR.Id),' ')+'} with SundryType {'+SR.SundryType+'}'
		FROM #TempSundryRecurring SR WITH(NOLOCK)
		INNER JOIN 
		(
		SELECT SundryRecurringId,SUM(Amount_Amount) AS Amount, SUM(PayableAmount_Amount) AS PAmount
	    FROM stgSundryRecurringPaymentSchedule
		GROUP BY SundryRecurringId
		) AS schedule1 ON schedule1.SundryRecurringId = SR.Id 
    	WHERE (schedule1.Amount<=0.00 AND schedule1.PAmount<=0.00) AND SR.IsMigrated=0  AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
    SELECT * INTO #ErrorLogDetails
	FROM #ErrorLogs ORDER BY StagingRootEntityId ;
	INSERT INTO #TempSundryRecurringForPrivateLabel 
	SELECT SR.Id,IsCollected=Detail.IsCollected,IsServiced=Detail.IsServiced,IsPrivateLabel=Detail.IsPrivateLabel
	FROM #TempSundryRecurring SR
	INNER JOIN LoanFinances LF WITH(NOLOCK) ON SR.R_ContractId = LF.ContractId
	INNER JOIN ContractOriginations CO WITH(NOLOCK) ON CO.Id = LF.ContractOriginationId
	INNER JOIN ContractOriginationServicingDetails COSD WITH(NOLOCK) ON COSD.ContractOriginationId = CO.Id
	INNER JOIN ServicingDetails Detail WITH(NOLOCK) ON Detail.Id = COSD.ServicingDetailId 
	WHERE
	Detail.IsActive = 1 AND R_ContractId IS NOT NULL AND SR.IsMigrated=0   AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	INSERT INTO #TempSundryRecurringForPrivateLabel 
	SELECT SR.Id,IsCollected=Detail.IsCollected,IsServiced=Detail.IsServiced,IsPrivateLabel=Detail.IsPrivateLabel
	FROM #TempSundryRecurring SR
	INNER JOIN LeaseFinances LF WITH(NOLOCK) ON SR.R_ContractId = LF.ContractId
	INNER JOIN ContractOriginations CO WITH(NOLOCK) ON CO.Id = LF.ContractOriginationId
	INNER JOIN ContractOriginationServicingDetails COSD WITH(NOLOCK) ON COSD.ContractOriginationId = CO.Id
	INNER JOIN ServicingDetails Detail WITH(NOLOCK) ON Detail.Id = COSD.ServicingDetailId 
	WHERE
	Detail.IsActive = 1 AND R_ContractId IS NOT NULL AND SR.IsMigrated=0   AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)
	SET @MaxSundryId = 0;
	SET @SkipCount = 0;
	CREATE TABLE #FailedProcessingLogs 
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[SundryId] BIGINT NOT NULL
		);
		CREATE TABLE #CreatedProcessingLogs
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL
		);	
UPDATE StgSundryRecurring SET  
 R_CustomerId=#TempSundryRecurring.R_CustomerId,                       
 R_ContractId=#TempSundryRecurring.R_ContractId,                       
 R_InstrumentTypeId=#TempSundryRecurring.R_InstrumentTypeId,                 
 R_SundryRecurringPaymentDetailId=#TempSundryRecurring.R_SundryRecurringPaymentDetailId,   
 R_LegalEntityId=#TempSundryRecurring.R_LegalEntityId,                    
 R_LineofBusinessId=#TempSundryRecurring.R_LineofBusinessId,                 
 R_ReceivableCodeId=#TempSundryRecurring.R_ReceivableCodeId,                 
 R_ReceivableGroupingOption=#TempSundryRecurring.R_ReceivableGroupingOption,         
 R_CurrencyId=#TempSundryRecurring.R_CurrencyId,                       
 R_BillToId=#TempSundryRecurring.R_BillToId,                         
 R_ReceivableRemitToId=#TempSundryRecurring.R_ReceivableRemitToId,              
 R_ReceivableRemitToLegalEntityId=#TempSundryRecurring.R_ReceivableRemitToLegalEntityId,   
 R_LocationId=#TempSundryRecurring.R_LocationId,                       
 R_VendorId=#TempSundryRecurring.R_VendorId,                         
 R_PayableCodeId=#TempSundryRecurring.R_PayableCodeId,                    
 R_PayableRemitToId=#TempSundryRecurring.R_PayableRemitToId,                 
 R_ReceiptType=#TempSundryRecurring.R_ReceiptType,                      
 R_CostCenterId=#TempSundryRecurring.R_CostCenterId,                     
 R_BranchId=#TempSundryRecurring.R_BranchId 
 From StgSundryRecurring JOIN #TempSundryRecurring ON StgSundryRecurring.Id = #TempSundryRecurring.Id
    
 UPDATE StgSundryRecurringPaymentDetail SET  
 R_AssetId=#TempSundryRecurringPaymentDetail.R_AssetId,  
 R_BillToId = #TempSundryRecurringPaymentDetail.R_BillToId  
 FROM StgSundryRecurringPaymentDetail INNER JOIN #TempSundryRecurringPaymentDetail  
 ON #TempSundryRecurringPaymentDetail.Id = StgSundryRecurringPaymentDetail.Id  

	WHILE @SkipCount < @TotalRecordsCount
	BEGIN
    BEGIN TRY  
    BEGIN TRANSACTION
		CREATE TABLE #CreatedRecurringSundries
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[SundryId] BIGINT NOT NULL,
		);
	  CREATE TABLE #GeneratedSundryRecurringPaymentSchedule
		(
			Amount DECIMAL (16,2),
			PayableAmount DECIMAL(16,2),
			DueDate DATE,
			Number INT,
			SundryRecurringId BIGINT,
			BillPastEndDate BIT,
			ProjectedVATAmount DECIMAL(16,2)
		);
		CREATE TABLE #GeneratedNextPaymentDate
		(
			NextPaymentDate DATE,
			SundryRecurringId BIGINT
		);
		SELECT
			TOP(@TakeCount) 
			Id AS SundryRecurringId
			,*
		INTO #SundryRecurring
		FROM
		stgSundryRecurring SR
		WHERE 
			IsMigrated = 0  AND (toolIdentifier = @ToolIdentifier OR toolIdentifier IS NULL)
			AND 
			Id > @MaxSundryId
			AND
			NOT Exists (SELECT * FROM #ErrorLogDetails WHERE StagingRootEntityId = SR.Id);

		UPDATE #SundryRecurring SET RegularAmount_Amount = #TempSundryRecurring.RegularAmount_Amount,
		 PayableAmount_Amount = #TempSundryRecurring.PayableAmount_Amount,
		 ReceivableAmount_Amount = #TempSundryRecurring.ReceivableAmount_Amount
		 FROM #SundryRecurring JOIN #TempSundryRecurring ON #SundryRecurring.Id = #TempSundryRecurring.Id
		SELECT @MaxSundryId = MAX(SundryRecurringId) FROM #SundryRecurring;
		SELECT @BatchCount = ISNULL(COUNT(SundryRecurringId),0) FROM #SundryRecurring;
		DECLARE @Days INT = 0;
		DECLARE @NextDate DATE;
		DECLARE @MonthsToAdd INT;
		BEGIN
		SET @SundryRecurring_Cursor  = CURSOR FOR 
			SELECT Id FROM #SundryRecurring where GeneratePaymentSchedule=1
			OPEN @SundryRecurring_Cursor
			FETCH NEXT FROM @SundryRecurring_Cursor 
			INTO @Ids
			WHILE @@FETCH_STATUS = 0
			BEGIN
			SELECT @Frequency = Frequency,
				   @LastDueDate = FirstDueDate,
				   @DueDay = DueDay,
				   @NumberOfDays = NumberOfDays 
			FROM #SundryRecurring WHERE Id = @Ids
				SET @MonthsToAdd = CASE WHEN @Frequency = 'Monthly' THEN 1
										WHEN @Frequency = 'BiMonthly' THEN 2
										WHEN @Frequency = 'Quarterly' THEN 3
										WHEN @Frequency = 'HalfYearly' THEN 6
										WHEN @Frequency = 'Yearly' THEN 12
										ELSE 1 END
				IF (DAY(@LastDueDate) < @DueDay AND MONTH(@LastDueDate) = MONTH(DATEADD(DAY,1,@LastDueDate)))
				BEGIN
					SET @LastDueDate = DATEADD(MONTH,@MonthsToAdd,@LastDueDate)
					IF DAY(EOMONTH(@LastDueDate)) < @DueDay
					BEGIN
						SET @Days = DAY(EOMONTH(@LastDueDate))
					END
					IF @Days = 0
					BEGIN
						SET @NextDate = DATEADD(DAY,@DueDay - DAY(@LastDueDate),@LastDueDate)
					END
					ELSE
					BEGIN
						SET @NextDate = DATEADD(DAY,@Days - DAY(@LastDueDate),@LastDueDate)
					END
				END
				IF @Frequency IS NOT NULL AND @NextDate IS NULL
				BEGIN
					IF @Frequency='Days' AND @NumberOfDays >0
					BEGIN
						SET @NextDate = DATEADD(DAY,@NumberOfDays,@LastDueDate)
					END
					IF @Frequency='Weekly'
					BEGIN
						SET @NextDate = DATEADD(DAY,7,@LastDueDate)
					END
					IF @Frequency='BiWeekly'
					BEGIN
						SET @NextDate = DATEADD(DAY,14,@LastDueDate)
					END
					IF @NextDate IS NULL AND @DueDay > 0
					BEGIN
						SET @LastDueDate = DATEADD(MONTH,@MonthsToAdd,@LastDueDate)
						IF DAY(EOMONTH(@LastDueDate)) < @DueDay
						BEGIN
							SET @Days = DAY(EOMONTH(@LastDueDate))
						END
						IF @Days = 0
						BEGIN
							SET @NextDate = DATEADD(DAY,@DueDay - DAY(@LastDueDate),@LastDueDate)
						END
					ELSE
					BEGIN
						SET @NextDate = DATEADD(DAY,@Days - DAY(@LastDueDate),@LastDueDate)
					END	
				    END
				END
				INSERT INTO #GeneratedNextPaymentDate(NextPaymentDate,SundryRecurringId) VALUES(@NextDate,@Ids)
				SELECT 
				@LastDueDate = FirstDueDate,
				@DueDay = DueDay,
				@Frequency = Frequency,
				@NumberOfDays= NumberOfDays,
				@NumberOfPayments = NumberOfPayments,
				@SundryType = SundryType,
				@IsRegular = IsRegular,
				@PayableAmount = PayableAmount_Amount,
				@ReceivableAmount = ReceivableAmount_Amount,
				@InitialPayableAmount = InitialPayableAmount_Amount,
				@InitialAmount = InitialAmount_Amount,
				@RegularAmount = RegularAmount_Amount,
				@SundryRecurringId = Id
				FROM #TempSundryRecurring 
				WHERE Id = @Ids AND IsMigrated = 0 AND (toolIdentifier = @ToolIdentifier OR toolIdentifier IS NULL) AND GeneratePaymentSchedule = 1
				EXEC CreateSundryRecurringPaymentSchedule @LastDueDate, @DueDay,@Frequency,@NumberOfDays, @NumberOfPayments,@SundryType,@IsRegular,@PayableAmount,@ReceivableAmount,
				@InitialPayableAmount,@InitialAmount,@RegularAmount,@SundryRecurringId,@ToolIdentifier
				FETCH NEXT FROM @SundryRecurring_Cursor 
				INTO @Ids
			END
			CLOSE @SundryRecurring_Cursor
			DEALLOCATE @SundryRecurring_Cursor
		  END
		UPDATE #GeneratedSundryRecurringPaymentSchedule
		SET BillPastEndDate = CASE WHEN ps.DueDate> ISNULL(LeaseFinanceDetails.MaturityDate,LoanFinances.MaturityDate) THEN 1 ELSE 0 END
		FROM #GeneratedSundryRecurringPaymentSchedule ps
		JOIN #TempSundryRecurring SR ON ps.SundryRecurringId = SR.Id
		JOIN Contracts ON Contracts.Id = SR.R_ContractId
		LEFT JOIN LeaseFinances ON LeaseFinances.contractId = Contracts.id AND LeaseFinances.IsCurrent = 1
		LEFT JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id = Leasefinances.Id  
		LEFT JOIN LoanFinances ON LoanFinances.ContractId  = Contracts.Id AND LoanFinances.IsCurrent = 1
		WHERE SR.EntityType = 'CT' AND SR.BillPastEndDate = 1 AND (SR.toolIdentifier = @ToolIdentifier OR SR.toolIdentifier IS NULL)

		UPDATE #SundryRecurring SET R_BillToId = NULL
		WHERE IsAssetBased = 1 AND SundryType != 'PayableOnly'
		MERGE SundryRecurrings AS sundryrecurring
		USING (SELECT SR.*,#GeneratedNextPaymentDate.NextPaymentDate AS NextPaymentDate,ReceivableCodes.IsTaxExempt As TaxExempt FROM #SundryRecurring SR LEFT JOIN ReceivableCodes on SR.ReceivableCodeName=ReceivableCodes.Name
			    LEFT JOIN #GeneratedNextPaymentDate ON #GeneratedNextPaymentDate.SundryRecurringId=SR.SundryRecurringId 
				WHERE NOT EXISTS (Select * FROM #ErrorLogs WHERE StagingRootEntityId = SR.Id )) AS SundryToMigrate
		ON 1 = 0
		WHEN NOT MATCHED
		THEN
			INSERT
				([SundryType]
				,[FirstDueDate]
				,[NextPaymentDate]
				,[EntityType]
				,[InvoiceComment]
				,[Memo]
				,[IsAssetBased]
				,[PaymentDateOffset]
				,[IsRentalBased]
				,[BillPastEndDate]
				,[NumberOfPayments]
				,[Frequency]
				,[NumberOfDays]
				,[DueDay]
				,[TerminationDate]
				,[ProcessThroughDate]
				,[InvoiceAmendmentType]
				,[IsActive]
				,[IsTaxExempt]
				,[IsFinancialParametersChanged]
				,[IsPayableAdjusted]
				,[IsServiced]
				,[IsCollected]
				,[IsPrivateLabel]
				,[IsOwned]
				,[IsRegular]
				,[IsApplyAtAssetLevel]
				,[RegularAmount_Amount]
				,[RegularAmount_Currency]
				,[IsSystemGenerated]
				,[IsExternalTermination]
				,[Type]
				,[CreatedById]
				,[CreatedTime]
				,[UpdatedById]
				,[UpdatedTime]
				,[LegalEntityId]
				,[ContractId]
				,[CustomerId]
				,[ReceivableCodeId]
				,[PayableCodeId]
				,[BillToId]
				,[VendorId]
				,[ReceivableRemitToId]
				,[PayableRemitToId]
				,[LocationId]
				,[CurrencyId]
				,[LineofBusinessId]
				,[InstrumentTypeId]
				,[Status]
				,[PayableAmount_Amount]
				,[PayableAmount_Currency]
				,[CostCenterId]
				,[BranchId]
				,[PayableWithholdingTaxRate],[IsVATAssessed])
			VALUES
				(SundryToMigrate.SundryType
				,SundryToMigrate.FirstDueDate
				,NextPaymentDate
				,SundryToMigrate.EntityType
				,SundryToMigrate.InvoiceComment
				,SundryToMigrate.Memo
				,SundryToMigrate.IsAssetBased
				,SundryToMigrate.PaymentDateOffset
				,SundryToMigrate.IsRentalBased
				,SundryToMigrate.BillPastEndDate
				,SundryToMigrate.NumberOfPayments
				,SundryToMigrate.Frequency
				,SundryToMigrate.NumberOfDays
				,SundryToMigrate.DueDay
				,TerminationDate
				,ProcessThroughDate
				,InvoiceAmendmentType
				,1
				,CASE WHEN SundryToMigrate.SundryType = 'PayableOnly' THEN 0 ELSE SundryToMigrate.TaxExempt END
				,0
				,0
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 1
					 WHEN EXISTS  (SELECT 1 FROM #TempSundryRecurringForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
						THEN (SELECT TSP.IsServiced FROM #TempSundryRecurringForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
					  ELSE SundryToMigrate.IsServiced END
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 1
					  WHEN EXISTS  (SELECT 1 FROM #TempSundryRecurringForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
						THEN (SELECT TSP.IsCollected FROM #TempSundryRecurringForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
					  ELSE SundryToMigrate.IsCollected END
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 0
					  WHEN EXISTS  (SELECT 1 FROM #TempSundryRecurringForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
						THEN (SELECT TSP.IsPrivateLabel FROM #TempSundryRecurringForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
					  ELSE SundryToMigrate.IsPrivateLabel END
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 1
					  ELSE SundryToMigrate.IsOwned END
				,SundryToMigrate.IsRegular
				,CASE WHEN SundryToMigrate.IsAssetBased = 1 AND SundryToMigrate.IsRegular = 0 THEN 0 
					  ELSE SundryToMigrate.IsApplyAtAssetLevel END
				,CASE WHEN SundryToMigrate.IsRegular =0 THEN 0
					  WHEN SundryToMigrate.SundryType='PassThrough' THEN SundryToMigrate.ReceivableAmount_Amount
					  ELSE SundryToMigrate.RegularAmount_Amount END
				,SundryToMigrate.RegularAmount_Currency
				,0
				,0
				,CASE WHEN (SundryToMigrate.Type ='_' OR SundryToMigrate.Type IS NULL) THEN 'Sundry'
					  ELSE SundryToMigrate.Type END
				,@UserId
				,@CreatedTime
				,NULL
				,NULL
				,SundryToMigrate.R_LegalEntityId
				,SundryToMigrate.R_ContractId
				,SundryToMigrate.R_CustomerId
				,SundryToMigrate.R_ReceivableCodeId
				,SundryToMigrate.R_PayableCodeId
				,SundryToMigrate.R_BillToId
				,SundryToMigrate.R_VendorId
				,SundryToMigrate.R_ReceivableRemitToId
				,SundryToMigrate.R_PayableRemitToId
				,SundryToMigrate.R_LocationId
				,SundryToMigrate.R_CurrencyId
				,SundryToMigrate.R_LineofBusinessId
				,SundryToMigrate.R_InstrumentTypeId
				,'Approved'
				,CASE WHEN SundryToMigrate.SundryType = 'PassThrough' THEN SundryToMigrate.PayableAmount_Amount
				 ELSE 0 END
				,SundryToMigrate.PayableAmount_Currency
				,SundryToMigrate.R_CostCenterId
				,SundryToMigrate.R_BranchId
				,SundryToMigrate.PayableWithholdingTaxRate,1
				)
		OUTPUT $action, Inserted.Id, SundryToMigrate.SundryRecurringId INTO #CreatedRecurringSundries
		;
		MERGE SundryRecurringPaymentDetails AS SD
		USING (SELECT SundryDetail.*,sundry.FirstDueDate, SundryIdMapping.Id CreatedSundryId FROM #CreatedRecurringSundries SundryIdMapping
				JOIN #TempSundryRecurringPaymentDetail SundryDetail ON SundryIdMapping.SundryId = SundryDetail.SundryRecurringId
				JOIN #TempSundryRecurring sundry ON sundry.Id=SundryIdMapping.SundryId
				WHERE NOT EXISTS (Select * FROM #ErrorLogs WHERE StagingRootEntityId = SundryIdMapping.SundryId ) ) AS Sundry
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
			([Amount_Amount]
			,[Amount_Currency]
			,[IsActive]
			,[StartDate]
			,[TerminationDate]
			,[CreatedById]
			,[CreatedTime]
			,[UpdatedById]
			,[UpdatedTime]
			,[AssetId]
			,[BillToId]
			,[SundryRecurringId]
			,[PayableAmount_Amount]
			,[PayableAmount_Currency], [VATAmount_Amount]
			,[VATAmount_Currency])
		VALUES
			(Sundry.Amount_Amount
		    ,Sundry.Amount_Currency
		    ,1
		    ,Sundry.FirstDueDate
		    ,Sundry.TerminationDate
		    ,@UserId
		    ,@CreatedTime
		    ,NULL
		    ,NULL
		    ,Sundry.R_AssetId
			,Sundry.R_BillToId
			,Sundry.CreatedSundryId
			,Sundry.PayableAmount_Amount
			,Sundry.PayableAmount_Currency,Sundry.VATAmount_Amount, Sundry.VATAmount_Currency
			)						  
		;
		MERGE SundryRecurringPaymentSchedules AS PaymentSchedules
		USING (SELECT PaymentSchedule.*, SundryIdMapping.Id AS CreatedSundryId, SR.CurrencyCode AS Currency
				FROM #CreatedRecurringSundries SundryIdMapping
				JOIN #GeneratedSundryRecurringPaymentSchedule PaymentSchedule ON SundryIdMapping.SundryId = PaymentSchedule.SundryRecurringId
				JOIN #TempSundryRecurring SR ON SR.Id =  PaymentSchedule.SundryRecurringId AND SR.GeneratePaymentSchedule=1
				WHERE NOT EXISTS (SELECT * FROM #ErrorLogs WHERE StagingRootEntityId = SR.Id)	
				) AS Sundry
		 	ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
			([Number]
			,[DueDate]
			,[Amount_Amount]
			,[Amount_Currency]
			,[IsActive]
			,[BillPastEndDate]
			,[SourceId]
			,[SourceModule]
			,[CreatedById]
			,[CreatedTime]
			,[UpdatedById]
			,[UpdatedTime]
			,[ReceivableId]
			,[PayableId]
			,[SundryRecurringId]
			,[PayableAmount_Amount]
			,[PayableAmount_Currency],[ProjectedVATAmount_Amount]
			,[ProjectedVATAmount_Currency])
		VALUES
			(Sundry.Number
		    ,Sundry.DueDate
		    ,Sundry.Amount
			,Sundry.Currency
		    ,1
		    ,Sundry.BillPastEndDate
		    ,Sundry.CreatedSundryId
		    ,'SundryRecurring'
		    ,@UserId
		    ,@CreatedTime
			,NULL
			,NULL
		    ,NULL
			,NULL
			,Sundry.CreatedSundryId
			,Sundry.PayableAmount
			,Sundry.Currency, Sundry.ProjectedVATAmount, Sundry.Currency
			);	
		MERGE SundryRecurringPaymentSchedules AS PaymentSchedules
		USING (SELECT PaymentSchedule.*, SundryIdMapping.Id AS CreatedSundryId
				FROM #CreatedRecurringSundries SundryIdMapping
				JOIN stgSundryRecurringPaymentSchedule PaymentSchedule ON SundryIdMapping.SundryId = PaymentSchedule.SundryRecurringId
				JOIN #TempSundryRecurring SR ON SR.Id =  PaymentSchedule.SundryRecurringId AND SR.GeneratePaymentSchedule=0
				WHERE NOT EXISTS (SELECT * FROM #ErrorLogs WHERE StagingRootEntityId = SR.Id)) AS Sundry
		 	ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
			([Number]
			,[DueDate]
			,[Amount_Amount]
			,[Amount_Currency]
			,[IsActive]
			,[BillPastEndDate]
			,[SourceId]
			,[SourceModule]
			,[CreatedById]
			,[CreatedTime]
			,[UpdatedById]
			,[UpdatedTime]
			,[ReceivableId]
			,[PayableId]
			,[SundryRecurringId]
			,[PayableAmount_Amount]
			,[PayableAmount_Currency],[ProjectedVATAmount_Amount]
			,[ProjectedVATAmount_Currency])
		VALUES
			(Sundry.Number
		    ,Sundry.DueDate
		    ,Sundry.Amount_Amount
			,Sundry.Amount_Currency
		    ,1
		    ,Sundry.BillPastEndDate
		    ,Sundry.CreatedSundryId
		    ,'SundryRecurring'
		    ,@UserId
		    ,@CreatedTime
			,NULL
			,NULL
		    ,NULL
			,NULL
			,Sundry.CreatedSundryId
			,Sundry.PayableAmount_Amount
			,Sundry.PayableAmount_Currency,Sundry.ProjectedVATAmount_Amount, Sundry.ProjectedVATAmount_Currency
			);
	  UPDATE stgSundryRecurring SET IsMigrated = 1
	  WHERE 			
	  EXISTS (SELECT * FROM #CreatedRecurringSundries where SundryId = stgSundryRecurring.Id
			  AND NOT Exists (SELECT * FROM #ErrorLogs WHERE StagingRootEntityId = SundryId)		);
			MERGE stgProcessingLog AS ProcessingLog
				USING (SELECT SundryId
						FROM #CreatedRecurringSundries) AS ProcessedSundry
				ON (ProcessingLog.StagingRootEntityId = ProcessedSundry.SundryId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)		
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
						 ProcessedSundry.SundryId						
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
		DROP TABLE #CreatedRecurringSundries;
		DROP TABLE #SundryRecurring 
		DROP TABLE #GeneratedSundryRecurringPaymentSchedule
		DROP TABLE #GeneratedNextPaymentDate	
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateRecurringSundries'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
	IF (XACT_STATE()) = -1  
	BEGIN  
		ROLLBACK TRANSACTION;
		EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		SET @FailedRecords = @FailedRecords+@BatchCount
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
		USING (SELECT Distinct StagingRootEntityId
				FROM #ErrorLogDetails) AS ProcessedSundries
		ON (ProcessingLog.StagingRootEntityId = ProcessedSundries.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime,
						UpdatedById = @UserId
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
				ProcessedSundries.StagingRootEntityId
				,@UserId
				,@CreatedTime
				,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
		MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT DISTINCT StagingRootEntityId
				FROM #ErrorLogs) AS ErrorSundries
		ON (ProcessingLog.StagingRootEntityId = ErrorSundries.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime,
						UpdatedById = @UserId
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
				ErrorSundries.StagingRootEntityId
				,@UserId
				,@CreatedTime
				,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id, ErrorSundries.StagingRootEntityId INTO #FailedProcessingLogs;	
		DECLARE @TotalRecordsFailed INT = (SELECT COUNT(DISTINCT Id) FROM #FailedProcessingLogs)
		INSERT INTO stgProcessingLogDetail
				(Message
				,Type
				,CreatedById
				,CreatedTime	
				,ProcessingLogId)
		SELECT
				 #ErrorLogs.Message
				,#ErrorLogs.Result
				,@UserId
				,@CreatedTime
				,#FailedProcessingLogs.Id
		FROM #ErrorLogs
		JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.SundryId
		;
	SET @FailedRecords =@FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogDetails)
	SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount;
	DROP TABLE #TempSundryRecurring
	DROP TABLE #TempSundryRecurringPaymentDetail
	DROP TABLE #TempSundryRecurringForPrivateLabel	
	SET NOCOUNT OFF;
	SET XACT_ABORT OFF;
END

GO
