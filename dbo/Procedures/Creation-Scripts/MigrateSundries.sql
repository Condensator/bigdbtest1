SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateSundries]
(
	@UserId BIGINT ,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUTPUT,
	@FailedRecords BIGINT OUTPUT,
	@ToolIdentifier INT
)
AS
BEGIN
	--DECLARE @UserId BIGINT =1;
	--DECLARE @ModuleIterationStatusId BIGINT=40450;
	--DECLARE @CreatedTime DATETIMEOFFSET = NULL;
	--DECLARE @ProcessedRecords BIGINT =0;
	--DECLARE @FailedRecords BIGINT =0; 
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	IF(@CreatedTime IS NULL)
	SET @CreatedTime = SYSDATETIMEOFFSET();
	DECLARE @Counter INT = 0;
	DECLARE @TakeCount INT = 50000;
	DECLARE @SkipCount INT = 0;
	DECLARE @MaxSundryId INT = 0;
	DECLARE @BatchCount INT = 0;
	DECLARE @IsCollected BIT = NULL;
	DECLARE	@IsServiced BIT = NULL ;
	DECLARE @IsPrivateLabel BIT = NULL;
	SET @FailedRecords = 0;
	SET @ProcessedRecords = 0;
	DECLARE @IsSalesTaxRequiredForLoan BIT = ISNULL((SELECT TOP 1 
																(CASE 
																	WHEN UPPER(Value) = 'TRUE' 
																		 THEN 1 
																	ELSE 0 END) 
															   FROM GlobalParameters 
															   WHERE Category = 'SalesTax' 
																 AND Name = 'IsSalesTaxRequiredForLoan'),
															 0);
	DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgSundry
										WHERE IsMigrated = 0  AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)
										  AND Type = 'Sundry');
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module, @ToolIdentifier
	SELECT * INTO #TempSundry
	FROM StgSundry
	WHERE isMigrated =0 AND (ToolIdentifier IS NULL OR ToolIdentifier = @ToolIdentifier)

    Select StgSundryDetail.* INTO #TempSundryDetail
    FROM StgSundryDetail
	JOIN #TempSundry ON #TempSundry.Id = StgSundryDetail.SundryId 

		CREATE TABLE #ErrorLogs
		(
			Id BIGINT not null IDENTITY PRIMARY KEY,
			StagingRootEntityId BIGINT,
			Result NVARCHAR(10),
			Message NVARCHAR(MAX)
		);
		CREATE TABLE #TempSundryForPrivateLabel
		(
			Id BIGINT,
			IsCollected BIT,
			IsServiced BIT,
			IsPrivateLabel BIT
		);
		Select 
			S.Id As SundryId
			,Contracts.Id As ContractId
			,PaymentOrder = ROW_NUMBER()Over(Partition By Contracts.Id Order By S.Id)
		Into #SundryWithPaymentOrder
		From
		stgSundry S
		Inner Join Contracts On Contracts.SequenceNumber = S.ContractSequenceNumber
		Where S.IsMigrated=0 AND (S.ToolIdentifier IS NULL OR S.ToolIdentifier = @ToolIdentifier)
		Select ContractBillingId, ISNULL(MAX(ACHPaymentNumber),1) As ACHPaymentNumber 
		Into #ContractsWithLatestACHPaymentNumber
		From 
		ACHSchedules
		Inner Join #SundryWithPaymentOrder On #SundryWithPaymentOrder.ContractId = ACHSchedules.ContractBillingId 
		where IsActive=1 Group By ContractBillingId			
		Select
			SundryId
			,ACHPaymentNumber = #SundryWithPaymentOrder.PaymentOrder + IsNull(#ContractsWithLatestACHPaymentNumber.ACHPaymentNumber,0)
		Into #ContractsWithACHPaymentNumber
		From #SundryWithPaymentOrder
		Left Join #ContractsWithLatestACHPaymentNumber On #ContractsWithLatestACHPaymentNumber.ContractBillingId = #SundryWithPaymentOrder.ContractId
		SELECT 
			DISTINCT LineofBusinessId
			,LegalEntityId 
		INTO #LegalEntityLOB
		FROM GLOrgStructureConfigs where IsActive=1	
		;
		UPDATE #TempSundry SET R_CustomerId = Parties.Id
        From #TempSundry SD WITH (NOLOCK)
        INNER JOIN Parties WITH (NOLOCK) ON UPPER(Parties.PartyNumber) = UPPER(SD.CustomerPartyNumber) AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		UPDATE #TempSundry SET R_CustomerId = CASE WHEN Contracts.ContractType='Loan' THEN Loan.CustomerId
		WHEN Contracts.ContractType='Lease' THEN Lease.CustomerId 
		WHEN Contracts.ContractType='LeveragedLease' THEN LeveragedLease.CustomerId
		ELSE Loan.CustomerId END
		From #TempSundry SR WITH (NOLOCK)
		LEFT JOIN Contracts WITH (NOLOCK) ON UPPER(SR.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SR.EntityType = 'CT'
		LEFT JOIN LoanFinances Loan WITH (NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 
		LEFT JOIN LeaseFinances Lease WITH (NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1
		LEFT JOIN LeveragedLeases LeveragedLease WITH (NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1
		WHERE SR.IsMigrated=0 AND (SR.ToolIdentifier IS NULL OR SR.ToolIdentifier = @ToolIdentifier) AND SR.R_CustomerId IS NULL ; 
		UPDATE #TempSundry SET R_ContractId = Contracts.Id
        From #TempSundry SD WITH (NOLOCK)
        INNER JOIN Contracts WITH (NOLOCK) ON UPPER(Contracts.SequenceNumber) = UPPER(SD.ContractSequencenumber) AND SD.EntityType = 'CT' AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		
		UPDATE #TempSundry SET R_CountryId = Countries.Id  
        From #TempSundry SD WITH (NOLOCK)
        INNER JOIN Countries WITH (NOLOCK) ON UPPER(Countries.ShortName) = UPPER(SD.Country) AND Countries.IsActive = 1
		WHERE SD.EntityType = 'CU' AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)

		UPDATE #TempSundry SET R_CountryId = Countries.Id  
        From #TempSundry SD WITH (NOLOCK)
        INNER JOIN Countries WITH (NOLOCK) ON Countries.ShortName = SD.Country AND Countries.IsActive = 1
		INNER JOIN Contracts WITH (NOLOCK) ON SD.ContractSequencenumber = Contracts.SequenceNumber
		AND Countries.Id = Contracts.CountryId 
		AND SD.EntityType = 'CT' AND Contracts.CountryId IS NOT NULL
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)

		UPDATE #TempSundry SET R_InstrumentTypeId = CASE WHEN EntityType='CU' THEN InstrumentTypes.Id ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.InstrumentTypeId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.InstrumentTypeId ELSE Loan.InstrumentTypeId END END		
        From #TempSundry SD WITH (NOLOCK)
		LEFT JOIN InstrumentTypes WITH (NOLOCK) ON UPPER(InstrumentTypes.Code) = UPPER(SD.InstrumentTypeCode) AND InstrumentTypes.IsActive = 1
		LEFT JOIN Contracts WITH (NOLOCK) ON UPPER(SD.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SD.EntityType = 'CT'
		LEFT JOIN LoanFinances Loan WITH (NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 
		LEFT JOIN LeaseFinances Lease WITH (NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1 
		LEFT JOIN LeveragedLeases LeveragedLease WITH (NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_InstrumentTypeId IS NULL ;		
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Invalid InstrumentTypeCode : '+ISNULL(SD.InstrumentTypeCode,' ')+' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.R_InstrumentTypeId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier); 
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','ContractSequencenumber is not valid for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.R_ContractId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType ='CT'; 
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Sundry can only be created for Contract with status as Commenced  { Id : '+CONVERT(NVARCHAR,SD.Id)+'}' 
		FROM #TempSundry SD WITH (NOLOCK) 
		JOIN Contracts ON Contracts.Id = SD.R_ContractId
		LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
		LEFT JOIN LoanFinances ON LoanFinances.ContractId = Contracts.Id
		LEFT JOIN LeveragedLeases ON LeveragedLeases.ContractId = Contracts.Id
		WHERE  SD.EntityType = 'CT' AND ((LeaseFinances.Id IS NOT NULL AND LeaseFinances.BookingStatus != 'Commenced' AND LeaseFinances.IsCurrent=1)
		OR (LoanFinances.Id IS NOT NULL AND LoanFinances.Status != 'Commenced' AND LoanFinances.IsCurrent=1)
		OR (LeveragedLeases.Id IS NOT NULL AND LeveragedLeases.Status != 'Commenced' AND LeveragedLeases.IsCurrent=1))
		AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) ;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Cannot create sundry for a syndicated contract with IsServiced = False and IsCollected = False {Id : '+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		JOIN Contracts ON Contracts.Id = R_ContractId
		WHERE Contracts.SyndicationType != 'None' AND SD.IsServiced=0 AND SD.IsCollected =0 AND SD.EntityType = 'CT'
		AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier); 
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','CustomerPartyNumber cannot be null for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.R_CustomerId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType ='CU';
		UPDATE #TempSundry SET R_SundryDetailId = detail.Id
        From #TempSundry SD WITH (NOLOCK)
		LEFT JOIN #TempSundryDetail detail WITH (NOLOCK) ON detail.SundryId = SD.Id
        WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_SundryDetailId IS NULL;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Atleast one asset must be present for the asset based sundry { Id : '+CONVERT(NVARCHAR,SD.Id)+'}' 
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE SD.R_SundryDetailId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=1;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Asset must not be present for the sundry as it is not set as IsAssetBased  for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.R_SundryDetailId IS NOT NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=0;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Cost Center cannot be null for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.CostCenterName IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType='CU';
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Invalid Cost Center for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN CostCenterConfigs CostCenterConfig WITH (NOLOCK) ON UPPER(CostCenterConfig.CostCenter) = UPPER(SD.CostCenterName)
		WHERE SD.CostCenterName IS NOT NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType='CU' AND CostCenterConfig.Id IS NULL;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Only lease based sundry can be Asset Based for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		JOIN Contracts WITH (NOLOCK) on Contracts.Id = SD.R_ContractId
		WHERE (SD.EntityType ='CT' AND SD.R_ContractId IS NOT NULL AND Contracts.ContractType!='Lease') AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=1;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Payable sundry can not be Asset Based for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=1 AND SD.SundryType='Payable';
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Invalid country for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		AND  SD.Country IS NOT NULL AND R_CountryId IS NULL;
		;
		UPDATE #TempSundryDetail SET R_AssetId = Assets.Id
        From #TempSundry SD WITH (NOLOCK)
		INNER JOIN #TempSundryDetail detail WITH (NOLOCK) ON detail.SundryId = SD.Id
		INNER JOIN LeaseFinances WITH (NOLOCK) ON LeaseFinances.ContractId = SD.R_ContractId
	    INNER JOIN LeaseAssets WITH (NOLOCK) ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
	    INNER JOIN Assets WITH (NOLOCK) ON LeaseAssets.AssetId = Assets.Id AND detail.AssetAlias = Assets.Alias
	    WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=1 
		AND SD.EntityType = 'CT' AND (Assets.Status = 'InvestorLeased' OR Assets.Status = 'Leased') AND Assets.FinancialType = 'Real';
		UPDATE #TempSundryDetail SET R_AssetId = Assets.Id
        From #TempSundry SD WITH (NOLOCK)
		INNER JOIN #TempSundryDetail detail WITH (NOLOCK) ON detail.SundryId = SD.Id
	    INNER JOIN Assets WITH (NOLOCK) ON Assets.CustomerId = SD.R_CustomerId AND detail.AssetAlias = Assets.Alias
	    WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=1 
		AND SD.EntityType = 'CU' AND Assets.Status = 'Inventory' AND Assets.FinancialType = 'Real'
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error',('Invalid Asset Alias: {'+ ISNULL(detail.AssetAlias,'NULL') + '}for Sundry Id {' + CONVERT(VARCHAR,SD.Id) + '}') 
		FROM #TempSundry SD WITH (NOLOCK)
		INNER JOIN #TempSundryDetail Detail WITH (NOLOCK) ON detail.SundryId = SD.Id		
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND Detail.R_AssetId IS NULL AND SD.IsAssetBased=1 AND SD.EntityType = 'CU';
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error',('Invalid Asset Alias: {'+ ISNULL(detail.AssetAlias,'NULL') + '}for Sundry Id {' + CONVERT(VARCHAR,SD.Id) + '}') 
		FROM #TempSundry SD WITH (NOLOCK)
		INNER JOIN #TempSundryDetail Detail WITH (NOLOCK) ON detail.SundryId = SD.Id		
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND Detail.R_AssetId IS NULL AND SD.IsAssetBased=1 AND SD.EntityType = 'CT' AND SD.R_ContractId IS NOT NULL;
		;
		UPDATE #TempSundry SET R_LegalEntityId = CASE WHEN SD.EntityType = 'CU' THEN #LegalEntityLOB.LegalEntityId ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.LegalEntityId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.LegalEntityId ELSE Loan.LegalEntityId END END,
		R_LineofBusinessId=CASE WHEN SD.EntityType = 'CU' THEN LineofBusinesses.Id ELSE Contracts.LineOfBusinessId END
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN LineofBusinesses WITH (NOLOCK) ON UPPER(LineofBusinesses.Name) = UPPER(SD.LineofBusinessName) AND LineofBusinesses.IsActive = 1
		LEFT JOIN LegalEntities WITH (NOLOCK) ON UPPER(LegalEntities.LegalEntityNumber) = UPPER(SD.LegalEntityNumber)
		LEFT JOIN #LegalEntityLOB WITH (NOLOCK) ON #LegalEntityLOB.LegalEntityId = LegalEntities.Id AND LineofBusinesses.Id = #LegalEntityLOB.LineofBusinessId
		LEFT JOIN Contracts WITH (NOLOCK) ON UPPER(SD.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SD.EntityType = 'CT'
		LEFT JOIN LoanFinances Loan WITH (NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1
		LEFT JOIN LeaseFinances Lease WITH (NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1
		LEFT JOIN LeveragedLeases LeveragedLease WITH (NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_LegalEntityId IS NULL;
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error', 'Invalid LineOfBusiness Name : ' + ISNULL(SD.LineofBusinessName, ' ')  + ' with EntityType {' + SD.EntityType + '} for sundry { Id : ' + CONVERT(NVARCHAR, SD.Id) + '}'
		FROM #TempSundry SD 
		WHERE SD.IsMigrated=0  AND (SD.toolIdentifier = @ToolIdentifier OR SD.toolIdentifier IS NULL) AND SD.R_LineofBusinessId IS NULL AND SD.EntityType = 'CU';
		
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error', 'Invalid LineOfBusiness for ContractSequencenumber : ' + ISNULL(SD.ContractSequencenumber, ' ')  + ' with EntityType {' + SD.EntityType + '} for sundry { Id : ' + CONVERT(NVARCHAR, SD.Id) + '}'
		FROM #TempSundry SD 
		WHERE SD.IsMigrated=0  AND (SD.toolIdentifier = @ToolIdentifier OR SD.toolIdentifier IS NULL) AND SD.R_LineofBusinessId IS NULL AND SD.EntityType = 'CT';
		
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Invalid LegalEntityNumber : '+ISNULL(SD.LegalEntityNumber,' ')+' for Contract {Id : '+ ISNULL(CONVERT(NVARCHAR,SD.R_ContractId),' ') +'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LegalEntityId IS NULL AND SD.EntityType = 'CU';
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Invalid LegalEntityNumber : '+ISNULL(SD.LegalEntityNumber,' ')+' for Contract {Id : '+ ISNULL(CONVERT(NVARCHAR,SD.R_ContractId),' ') +'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LegalEntityId IS NULL 
		AND SD.EntityType = 'CT' AND SD.R_ContractId IS NOT NULL;
		
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Entity Type must be either Contract or Customer for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType !='CT' AND SD.EntityType !='CU';

		UPDATE #TempSundry SET R_ReceivableCodeId = ReceivableCodes.Id, R_ReceivableGroupingOption=ReceivableCodes.DefaultInvoiceReceivableGroupingOption
        From #TempSundry SD
		LEFT JOIN ReceivableCodes ON SD.ReceivableCodeName = ReceivableCodes.Name AND ReceivableCodes.IsActive = 1
	    LEFT JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		WHERE ReceivableTypes.Name IN ('Sundry','SundrySeparate','InsurancePremium','InsurancePremiumAdmin')
        AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier);

		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Valid Receivable Code is required for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.SundryType !='PayableOnly' AND (SD.ReceivableCodeName IS NULL OR SD.R_ReceivableCodeId IS NULL)
		INSERT INTO #ErrorLogs
		SELECT SD.Id
			  ,'Error'
			  ,('Customer Status must be either Active or Pending for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK) 
		INNER JOIN Parties WITH (NOLOCK) ON SD.CustomerPartyNumber= Parties.PartyNumber
		INNER JOIN Customers WITH (NOLOCK) ON Parties.Id = Customers.Id 
		WHERE Status != 'Active'
		  AND Status!= 'Pending' AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
			  ,'Error'
			  ,('Contract Status must be either Active or Pending for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN Contracts WITH (NOLOCK) ON SD.R_ContractId = Contracts.Id
		WHERE SD.R_ContractId IS NOT NULL AND ((Contracts.ContractType = 'Lease' AND Contracts.ReferenceType = 'Assumed')
				OR Contracts.Status = 'Inactive'
				OR Contracts.Status= 'Cancelled')
		  AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier);
		UPDATE #TempSundry SET R_CurrencyId = Currency.Id 
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN CurrencyCodes CurrencyCode WITH (NOLOCK) ON UPPER(SD.CurrencyCode) = UPPER(CurrencyCode.ISO) AND CurrencyCode.IsActive = 1
		LEFT JOIN Currencies Currency WITH (NOLOCK) ON CurrencyCode.Id = Currency.CurrencyCodeId AND Currency.IsActive = 1
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_CurrencyId IS NULL ;
		UPDATE #TempSundry SET R_BillToId = CASE WHEN SD.EntityType = 'CT' THEN ISNULL(LeaseAssets.BillToId,Contracts.BillToId) ELSE BillToes.Id END
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN BillToes ON BillToes.CustomerId = SD.R_CustomerId AND BillToes.IsPrimary = 1 AND BillToes.IsActive = 1
		LEFT JOIN Contracts ON Contracts.Id = SD.R_ContractId
		LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
		LEFT JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.BillToName IS NULL AND SD.IsAssetBased = 0 AND SD.SundryType != 'PayableOnly'
		UPDATE #TempSundryDetail SET R_BillToId = CASE WHEN SD.EntityType = 'CT' THEN ISNULL(LeaseAssets.BillToId,Contracts.BillToId) ELSE BillToes.Id END
		FROM #TempSundryDetail WITH (NOLOCK)
		JOIN #TempSundry SD ON SD.Id = #TempSundryDetail.SundryId
		LEFT JOIN BillToes ON BillToes.CustomerId = SD.R_CustomerId AND BillToes.IsPrimary = 1 AND BillToes.IsActive = 1
		LEFT JOIN Contracts ON Contracts.Id = SD.R_ContractId
		LEFT JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
		LEFT JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND #TempSundryDetail.BillToName IS NULL AND SD.IsAssetbased = 1 AND SD.SundryType != 'PayableOnly'
		UPDATE 
		#TempSundry SET R_BillToId = BillToes.Id 
		FROM #TempSundry SD WITH (NOLOCK) 
		INNER JOIN Parties WITH (NOLOCK) ON UPPER(Parties.PartyNumber) = UPPER(SD.CustomerPartyNumber)
		INNER JOIN BillToes WITH (NOLOCK) ON BillToes.CustomerId = Parties.Id AND SD.BillToName = BillToes.Name AND BillToes.IsActive = 1 
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_BillToId IS NULL AND SD.EntityType='CU' AND SD.SundryType !='PayableOnly';
		UPDATE #TempSundry SET R_BillToId = BillToes.Id 
	    FROM #TempSundry SD WITH (NOLOCK)
	    LEFT JOIN Contracts WITH (NOLOCK) ON Contracts.SequenceNumber = SD.ContractSequenceNumber
	    LEFT JOIN LeaseFinances LF  WITH (NOLOCK) on Contracts.Id=LF.ContractId
	    LEFT JOIN BillToes WITH (NOLOCK) ON SD.BillToName = BillToes.Name AND BillToes.IsActive = 1 AND LF.CustomerId=BillToes.CustomerId
	    WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_BillToId IS NULL AND SD.EntityType='CT' AND SD.SundryType != 'PayableOnly';
		UPDATE #TempSundry SET R_BillToId = BillToes.Id 
	    FROM #TempSundry SD WITH (NOLOCK)
	    LEFT JOIN Contracts WITH (NOLOCK) ON Contracts.SequenceNumber = SD.ContractSequenceNumber
	    LEFT JOIN LoanFinances LF  WITH (NOLOCK) on Contracts.Id=LF.ContractId
	    LEFT JOIN BillToes WITH (NOLOCK) ON SD.BillToName = BillToes.Name AND BillToes.IsActive = 1 AND LF.CustomerId=BillToes.CustomerId
	    WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)AND SD.R_BillToId IS NULL AND SD.EntityType='CT' AND SD.SundryType != 'PayableOnly';
		UPDATE #TempSundryDetail SET R_BillToId = BillToes.Id
		FROM #TempSundry SD WITH (NOLOCK)
	    INNER JOIN #TempSundryDetail WITH (NOLOCK) ON SD.Id = #TempSundryDetail.SundryId
		INNER JOIN BillToes WITH (NOLOCK) ON #TempSundryDetail.BillToName = BillToes.Name AND BillToes.IsActive = 1
		INNER JOIN Customers WITH (NOLOCK) ON Customers.Id = BillToes.CustomerId
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) 
		AND #TempSundryDetail.R_BillToId IS NULL AND SD.IsAssetBased=1 AND Customers.Id = R_CustomerId;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
			  ,'Error'
			  ,'Invalid BillToName : '+ISNULL(SD.BillToName,'')+' for Sundry {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}' AS Message
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.R_BillToId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=0
		  AND SD.SundryType !='PayableOnly' AND SD.EntityType = 'CU';
		  INSERT INTO #ErrorLogs
		SELECT SD.Id
			  ,'Error'
			  ,'Invalid BillToName : '+ISNULL(SD.BillToName,'')+' for Sundry {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}' AS Message
		FROM #TempSundry SD  WITH (NOLOCK)
		WHERE SD.R_BillToId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=0
		  AND SD.SundryType !='PayableOnly' AND SD.EntityType = 'CT' AND SD.R_ContractId IS NOT NULL;
        INSERT INTO #ErrorLogs
               SELECT SD.Id
                     ,'Error'
                     ,'Invalid BillToName : '+ISNULL(#TempSundryDetail.BillToName,'')+' for SundryDetail {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}' AS Message
               FROM #TempSundry SD WITH (NOLOCK)
               INNER JOIN #TempSundryDetail WITH (NOLOCK) ON SD.Id = #TempSundryDetail.SundryId
               WHERE #TempSundryDetail.R_BillToId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=1
                 AND SD.SundryType !='PayableOnly' AND SD.EntityType = 'CU';
		INSERT INTO #ErrorLogs
               SELECT SD.Id
                     ,'Error'
                     ,'Invalid BillToName : '+ISNULL(#TempSundryDetail.BillToName,'')+' for SundryDetail {Id : '+CONVERT(NVARCHAR,SD.Id)+'} with EntityType {'+SD.EntityType+'}' AS Message
              FROM #TempSundry SD 
              INNER JOIN #TempSundryDetail WITH (NOLOCK) ON SD.Id = #TempSundryDetail.SundryId
              WHERE #TempSundryDetail.R_BillToId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.IsAssetBased=1
              AND SD.SundryType !='PayableOnly' AND SD.EntityType = 'CT' AND SD.R_ContractId IS NOT NULL;

		UPDATE #TempSundry SET R_ReceivableRemitToId = RemitToes.Id,R_ReceivableRemitToLegalEntityId= LegalEntityRemitTo.LegalEntityId
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN RemitToes WITH (NOLOCK) ON UPPER(RemitToes.UniqueIdentifier) = UPPER(SD.ReceivableRemitToUniqueIdentifier) AND RemitToes.IsActive=1
		LEFT JOIN LegalEntityRemitToes LegalEntityRemitTo ON RemitToes.Id = LegalEntityRemitTo.RemitToId AND SD.R_LegalEntityId= LegalEntityRemitTo.LegalEntityId
		WHERE SD.IsMigrated=0 AND SD.SundryType != 'PayableOnly' AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND (SD.R_ReceivableRemitToId IS NULL  OR  SD.R_ReceivableRemitToLegalEntityId IS NULL)
		

		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Valid Receivable Remit to is required for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}' AS Message
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE SD.R_ReceivableRemitToId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.SundryType !='PayableOnly';
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Receivable Remit to must belong to the selected Legal Entity for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE SD.R_ReceivableRemitToId IS NOT NULL
			AND SD.R_ReceivableRemitToLegalEntityId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CU'
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Receivable Remit to must belong to the selected Legal Entity for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE SD.R_ReceivableRemitToId IS NOT NULL
			AND SD.R_ReceivableRemitToLegalEntityId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) 
			AND SD.R_ContractId IS NOT NULL AND SD.EntityType = 'CT';
		UPDATE #TempSundry SET R_LocationId = Location.Id
		FROM #TempSundry SD WITH (NOLOCK) 
		LEFT JOIN Locations Location WITH (NOLOCK) ON UPPER(SD.LocationCode) = UPPER(Location.Code)
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_LocationId IS NULL ;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Location is required for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD
		LEFT JOIN Contracts WITH (NOLOCK) ON Contracts.Id = SD.R_ContractId 
			WHERE SundryType != 'PayableOnly'
			AND LocationCode IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
			AND SD.EntityType !='CT'
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Location must be an active and approved location present in the system' + ISNULL(' : ' + LocationCode, '') +' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD
		LEFT JOIN Locations WITH (NOLOCK) ON SD.R_LocationId = Locations.Id
		WHERE SundryType != 'PayableOnly'
		  AND LocationCode IS NOT NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		  AND (SD.R_LocationId IS NULL
			   OR Locations.IsActive = 0 
			   OR (Locations.ApprovalStatus != 'Approved' AND Locations.ApprovalStatus != 'ReAssess'))
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Location must either be associated to sundry''s customer or must not be associated to any customer' + ISNULL(' : ' + LocationCode, '') +' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD
		LEFT JOIN Locations WITH (NOLOCK) ON SD.R_LocationId = Locations.Id
		WHERE SundryType != 'PayableOnly'
			AND Locations.CustomerId IS NOT NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
			AND Locations.CustomerId != SD.R_CustomerId
		;
		INSERT INTO #ErrorLogs
		SELECT  SD.Id
				,'Error'
				,('Vendor Party Number is required for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE (SD.SundryType = 'PayableOnly' OR SD.SundryType = 'PassThrough')
			AND SD.VendorPartyNumber IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		;
		UPDATE #TempSundry SET R_VendorId = Vendors.Id
		FROM #TempSundry SD WITH (NOLOCK) 
		LEFT JOIN Parties WITH (NOLOCK) ON UPPER(SD.VendorPartyNumber) = UPPER(Parties.PartyNumber)
		LEFT JOIN Vendors WITH (NOLOCK) ON Parties.Id = Vendors.Id
		WHERE SD.IsMigrated=0 AND SD.SundryType != 'ReceivableOnly'AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_VendorId IS NULL
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Vendor must be active' + ISNULL(' : ' + VendorPartyNumber, '') + ' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN Vendors WITH (NOLOCK) ON Vendors.Id=SD.R_VendorId 
		WHERE (SD.SundryType = 'PayableOnly' OR SD.SundryType = 'PassThrough')
			AND (SD.R_VendorId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
				OR Vendors.Status != 'Active')
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Vendor {' + ISNULL(VendorPartyNumber,' ') + '} must be actively associated with Sundry''s Legal Entity {' + ISNULL(LegalEntityNumber, '') + '}' + 'for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
			FROM #TempSundry SD WITH (NOLOCK)
			LEFT JOIN VendorLegalEntities WITH (NOLOCK) ON SD.R_vendorId = VendorLegalEntities.VendorId AND SD.R_LegalEntityId = VendorLegalEntities.LegalEntityId AND VendorLegalEntities.IsActive = 1
		WHERE (SD.SundryType = 'PayableOnly' OR SD.SundryType = 'PassThrough')
			AND SD.R_VendorId IS NOT NULL AND VendorLegalEntities.VendorId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) 
			AND (VendorLegalEntities.IsActive IS NULL OR VendorLegalEntities.IsActive  = 0)
		;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Payable Code is required for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE (SD.SundryType = 'PayableOnly' OR SD.SundryType = 'PassThrough')
			AND SD.PayableCodeName IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier);
		UPDATE #TempSundry SET R_PayableCodeId = PayableCode.Id
		FROM #TempSundry SD WITH (NOLOCK) 
		INNER JOIN PayableCodes PayableCode WITH (NOLOCK) ON UPPER(SD.PayableCodeName) = UPPER(PayableCode.Name) AND PayableCode.IsActive = 1
		INNER JOIN PayableTypes PayableType WITH (NOLOCK) ON PayableCode.PayableTypeId = PayableType.Id AND PayableType.IsActive = 1 AND PayableType.Name ='MiscAP'
		WHERE SD.IsMigrated=0 AND SD.SundryType != 'ReceivableOnly'AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.R_PayableCodeId IS NULL;
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Payable Code must be of Type "Misc AP"' + ' : ' +IsNull(PayableCodeName,'Null') +' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE (SD.SundryType = 'PayableOnly' OR SD.SundryType = 'PassThrough')
			AND SD.PayableCodeName IS NOT NULL
			AND SD.R_PayableCodeId IS NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier);
		INSERT INTO #ErrorLogs
		SELECT SD.Id
				,'Error'
				,('Payable Remit To is required for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE (SD.SundryType = 'PayableOnly' OR SD.SundryType = 'PassThrough') AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
			AND SD.PayableRemitToUniqueIdentifier IS NULL
		;
		UPDATE #TempSundry SET R_PayableRemitToId = PayableRemitTo.Id, R_ReceiptType=PayableRemitTo.ReceiptType
		FROM #TempSundry SD WITH (NOLOCK)
		LEFT JOIN RemitToes PayableRemitTo ON UPPER(SD.PayableRemitToUniqueIdentifier) = UPPER(PayableRemitTo.UniqueIdentifier) AND PayableRemitTo.IsActive = 1
		WHERE SD.IsMigrated=0 AND SD.SundryType != 'ReceivableOnly' AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_PayableRemitToId IS NULL;
		INSERT INTO #ErrorLogs
		SELECT SD.id
				,'Error'
				,('Payable Remit To {' + ISNULL(PayableRemitToUniqueIdentifier, '') + '} must be associated to Vendor {' + ISNULL(VendorPartyNumber, '') + '}' + ' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,sd.Id),' ')+'} with EntityType {'+sd.EntityType+'}') AS Message
		FROM #TempSundry SD WITH (NOLOCK) 
		WHERE (SD.SundryType = 'PayableOnly' OR SD.SundryType = 'PassThrough')
			AND R_PayableRemitToId IS NULL
			AND PayableRemitToUniqueIdentifier IS NOT NULL
			AND SD.IsMigrated = 0  AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		UPDATE #TempSundry SET R_BranchId = Branch.Id
		FROM #TempSundry SD WITH (NOLOCK) 
		LEFT JOIN Branches Branch WITH (NOLOCK) ON UPPER(SD.BranchName) = UPPER(Branch.BranchName) AND Branch.Status = 'Active'
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_BranchId IS NULL AND SD.BranchName IS NOT NULL
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Invalid Branch Name : '+ISNULL(SD.BranchName,'NULL')+' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE R_BranchId IS NULL
			AND BranchName IS NOT NULL
			AND SD.IsMigrated = 0  AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		UPDATE #TempSundry SET R_BranchId = LF.BranchId
		FROM #TempSundry SD WITH (NOLOCK) 
		INNER JOIN LoanFinances LF WITH (NOLOCK) ON SD.R_ContractId = LF.ContractId
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_BranchId IS NULL AND SD.EntityType = 'CT'
		UPDATE #TempSundry SET R_BranchId = LF.BranchId
		FROM #TempSundry SD WITH (NOLOCK)
		INNER JOIN LeaseFinances LF WITH (NOLOCK) ON SD.R_ContractId = LF.ContractId
		WHERE SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND R_BranchId IS NULL AND SD.EntityType = 'CT'
		UPDATE #TempSundry SET R_CostCenterConfigId = CASE WHEN EntityType='CU' THEN CostCenterConfig.Id ELSE CASE WHEN Contracts.ContractType = 'Lease' THEN Lease.CostCenterId WHEN Contracts.ContractType = 'LeveragedLease' THEN LeveragedLease.CostCenterId ELSE Loan.CostCenterId END END
		From #TempSundry SD WITH(NOLOCK)
		LEFT JOIN CostCenterConfigs CostCenterConfig WITH(NOLOCK) ON UPPER(CostCenterConfig.CostCenter) = UPPER(SD.CostCenterName) AND CostCenterConfig.IsActive = 1
		LEFT JOIN Contracts WITH(NOLOCK) ON UPPER(SD.ContractSequencenumber) = UPPER(Contracts.SequenceNumber) AND SD.EntityType = 'CT'
		LEFT JOIN LoanFinances Loan WITH(NOLOCK) ON Loan.ContractId = Contracts.Id AND Loan.IsCurrent = 1 
		LEFT JOIN LeaseFinances Lease WITH(NOLOCK) ON Lease.ContractId = Contracts.Id AND Lease.IsCurrent = 1 
		LEFT JOIN LeveragedLeases LeveragedLease WITH(NOLOCK) ON LeveragedLease.ContractId = Contracts.Id AND LeveragedLease.IsCurrent = 1
		WHERE SD.IsMigrated=0  AND (SD.toolIdentifier = @ToolIdentifier OR SD.toolIdentifier IS NULL) AND SD.R_CostCenterConfigId IS NULL ;	
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Invalid CostCenter Name : '+ISNULL(SD.CostCenterName,'NULL')+' for Sundry {Id : '+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with EntityType {'+SD.EntityType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
		WHERE R_CostCenterConfigId IS NULL AND SD.IsMigrated = 0   AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) AND SD.EntityType = 'CU'
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Detail level amounts dont match up to the Header level amount for Sundry { Id :'+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with SundryType {'+SD.SundryType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
        INNER JOIN (
        SELECT SDT.SundryId,SUM(SDT.Amount_Amount) AS ReceivableAmount  from  #TempSundryDetail SDT  WITH (NOLOCK)
        GROUP BY SDT.SundryId ) as t on  t.SundryId = SD.Id
        WHERE SD.Amount_Amount != t.ReceivableAmount AND SD.SundryType='ReceivableOnly' AND SD.IsMigrated = 0   AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		INSERT INTO #ErrorLogs
		SELECT SD.Id, 'Error','Detail level amounts dont match up to the Header level amount for Sundry { Id :'+ISNULL(CONVERT(NVARCHAR,SD.Id),' ')+'} with SundryType {'+SD.SundryType+'}'
		FROM #TempSundry SD WITH (NOLOCK)
        INNER JOIN (
        SELECT SDT.SundryId,SUM(SDT.Amount_Amount) AS ReceivableAmount,SUM(SDT.PayableAmount_Amount) AS PayableAmount   from  #TempSundryDetail SDT WITH (NOLOCK) 
        GROUP BY SDT.SundryId ) as t  on t.SundryId = SD.Id
        WHERE (SD.Amount_Amount != t.ReceivableAmount OR SD.PayableAmount_Amount != t.PayableAmount) AND SD.SundryType='PassThrough' AND SD.IsMigrated = 0   AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		INSERT INTO #TempSundryForPrivateLabel 
		SELECT SD.Id,IsCollected=Detail.IsCollected,IsServiced=Detail.IsServiced,IsPrivateLabel=Detail.IsPrivateLabel
		FROM #TempSundry SD WITH (NOLOCK)
		INNER JOIN LoanFinances LF WITH (NOLOCK) ON SD.R_ContractId = LF.ContractId
		INNER JOIN ContractOriginations CO WITH (NOLOCK) ON CO.Id = LF.ContractOriginationId
		INNER JOIN ContractOriginationServicingDetails COSD WITH (NOLOCK) ON COSD.ContractOriginationId = CO.Id
		INNER JOIN ServicingDetails Detail WITH (NOLOCK) ON Detail.Id = COSD.ServicingDetailId 
		WHERE
		Detail.IsActive = 1 AND R_ContractId IS NOT NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		INSERT INTO #TempSundryForPrivateLabel 
		SELECT SD.Id,IsCollected=Detail.IsCollected,IsServiced=Detail.IsServiced,IsPrivateLabel=Detail.IsPrivateLabel
		FROM #TempSundry SD WITH (NOLOCK)
		INNER JOIN LeaseFinances LF WITH (NOLOCK) ON SD.R_ContractId = LF.ContractId
		INNER JOIN ContractOriginations CO WITH (NOLOCK) ON CO.Id = LF.ContractOriginationId
		INNER JOIN ContractOriginationServicingDetails COSD WITH (NOLOCK) ON COSD.ContractOriginationId = CO.Id
		INNER JOIN ServicingDetails Detail WITH (NOLOCK) ON Detail.Id = COSD.ServicingDetailId 
		WHERE
		Detail.IsActive = 1 AND R_ContractId IS NOT NULL AND SD.IsMigrated=0 AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier)
		SELECT * INTO #ErrorLogDetails
		FROM #ErrorLogs ORDER BY StagingRootEntityId ;
		
		SELECT StagingRootEntityId INTO #ErrorRecords FROM #ErrorLogDetails

		Create Index IX_StagingRootEntityId On #ErrorRecords(StagingRootEntityId)

		Create Index IX_StagingRootEntityId On #ErrorLogDetails(StagingRootEntityId)

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

	UPDATE StgSundry SET  
		 R_ContractId=#TempSundry.R_ContractId,                       
		 R_InstrumentTypeId=#TempSundry.R_InstrumentTypeId,                 
		 R_SundryDetailId=#TempSundry.R_SundryDetailId,                   
		 R_LegalEntityId=#TempSundry.R_LegalEntityId,                    
		 R_ReceivableCodeId=#TempSundry.R_ReceivableCodeId,                                       
		 R_CustomerId=#TempSundry.R_CustomerId,                       
		 R_ReceivableRemitToId=#TempSundry.R_ReceivableRemitToId,              
		 R_ReceivableRemitToLegalEntityId=#TempSundry.R_ReceivableRemitToLegalEntityId,   
		 R_LocationId=#TempSundry.R_LocationId,                       
		 R_VendorId=#TempSundry.R_VendorId,                         
		 R_PayableCodeId=#TempSundry.R_PayableCodeId,                    
		 R_PayableRemitToId=#TempSundry.R_PayableRemitToId,                 
		 R_CurrencyId=#TempSundry.R_CurrencyId,                       
		 R_LineofBusinessId=#TempSundry.R_LineofBusinessId,                 
		 R_ReceiptType=#TempSundry.R_ReceiptType,                      
		 R_ReceivableGroupingOption=#TempSundry.R_ReceivableGroupingOption,         
		 R_BranchId=#TempSundry.R_BranchId,                         
		 R_CostCenterConfigId=#TempSundry.R_CostCenterConfigId,               
		 R_BillToId=#TempSundry.R_BillToId  
		 FROM stgSundry JOIN #TempSundry ON stgSundry.Id = #TempSundry.Id                      

    
	UPDATE StgSundryDetail SET  
		 R_AssetId = #TempSundryDetail.R_AssetId,  
		 R_BillToId = #TempSundryDetail.R_BillToId  
		 FROM StgSundryDetail JOIN #TempSundryDetail ON #TempSundryDetail.Id = StgSundryDetail.Id 

		 Select 
		 S.Id As SundryId
		,#SundryWithPaymentOrder.ContractId
		,S.ReceivableDueDate
		,ContractACHAssignments.BankAccountId As ACHAccountId
		,S.Amount_Amount As ACHAmount
		,S.Amount_Currency As ACHAmountCurrency
		,ReceivableTypes.Id As ReceivableTypeId
		,#ContractsWithACHPaymentNumber.ACHPaymentNumber As ACHPaymentNumber
		,'Pending' As Status
		,Convert(Nvarchar,dbo.GetSettlementDate(#SundryWithPaymentOrder.ContractId, S.ReceivableDueDate),121) As SettlementDate
		,0 As IsPreNotificationCreated
		,ContractACHAssignments.PaymentType As PaymentType
		Into #SundryWithACHSchedule
		From 
		stgSundry S
		Inner Join #SundryWithPaymentOrder On #SundryWithPaymentOrder.SundryId = S.Id
		Inner Join ContractACHAssignments On ContractACHAssignments.ContractBillingId = #SundryWithPaymentOrder.ContractId AND S.ReceivableDueDate >= ContractACHAssignments.BeginDate
			And ContractACHAssignments.IsActive=1
		Inner Join ReceivableCodes On ReceivableCodes.Name = S.ReceivableCodeName AND ReceivableCodes.IsActive = 1
		Inner Join ReceivableTypes On ReceivableTypes.Id = ReceivableCodes.ReceivableTypeId AND ReceivableTypes.IsActive = 1
			And ReceivableTypes.Id = ContractACHAssignments.ReceivableTypeId
		Left Join #ContractsWithACHPaymentNumber
			On #ContractsWithACHPaymentNumber.SundryId = S.Id
		Where
		((ContractACHAssignments.EndDate IS NOT NULL AND S.ReceivableDueDate <= ContractACHAssignments.EndDate)
		OR
		(ContractACHAssignments.EndDate IS NULL AND S.receivableDueDate<=ISNULL(DATEADD(DAY,-1,(Select TOP 1 contractACH.BeginDate From ContractACHAssignments contractACH 
		Where contractACH.ReceivableTypeId = ReceivableTypes.Id
		and contractACH.ContractBillingId = s.r_contractid and contractACH.Isactive=1
		AND contractACH.BeginDate>ContractACHAssignments.BeginDate AND contractACH.Id != ContractACHAssignments.Id ORDER BY contractACH.BeginDate)),S.receivableDueDate)
		))
		AND S.IsMigrated=0 AND (S.ToolIdentifier IS NULL OR S.ToolIdentifier = @ToolIdentifier)

	WHILE @SkipCount < @TotalRecordsCount
	BEGIN
    BEGIN TRY  
    BEGIN TRANSACTION
		CREATE TABLE #CreatedSundries
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[SundryId] BIGINT NOT NULL,
		);
		CREATE TABLE #PayableSundryMapping
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[SundryId] BIGINT NOT NULL,
			[ReceiptType] NVARCHAR(20) NOT NULL
		);
		CREATE TABLE #ReceivableSundryMapping
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[SundryId] BIGINT NOT NULL
		);
		CREATE TABLE #TreasuryPayableIdMapping
		(
			[Action] NVARCHAR(10) NOT NULL,
			[Id] BIGINT NOT NULL,
			[PayableId] BIGINT NOT NULL,
			[Currency] NVARCHAR(10) NOT NULL
		);

 
		SELECT TOP(@TakeCount) Id AS SundryId,0 AS ReceivableCodeTaxExempt,* INTO #Sundry 
		FROM stgSundry SD 
		WHERE IsMigrated = 0 
		AND (SD.ToolIdentifier IS NULL OR SD.ToolIdentifier = @ToolIdentifier) 
		AND Id > @MaxSundryId
		AND Id NOT IN (SELECT StagingRootEntityId FROM #ErrorRecords);	
		
		UPDATE #Sundry SET ReceivableCodeTaxExempt = ReceivableCodes.IsTaxExempt 
		FROM #Sundry 
		INNER JOIN ReceivableCodes ON #Sundry.R_ReceivableCodeId = ReceivableCodes.Id
		WHERE #Sundry.R_ReceivableCodeId IS NOT NULL
		SELECT @MaxSundryId = MAX(SundryId) FROM #Sundry;
		SELECT @BatchCount = ISNULL(COUNT(SundryId),0) FROM #Sundry;
		UPDATE #Sundry SET R_BillToId = NULL
		WHERE IsAssetBased = 1 AND SundryType != 'PayableOnly'
		MERGE Sundries AS Sundry
		USING (SELECT * FROM #Sundry) AS SundryToMigrate
		ON 1 = 0
		WHEN NOT MATCHED
		THEN
			INSERT
				([SundryType]
				,[EntityType]
				,[ReceivableDueDate]
				,[InvoiceComment]
				,[PayableDueDate]
				,[Memo]
				,[IsAssetBased]
				,[Amount_Amount]
				,[Amount_Currency]
				,[IsActive]
				,[IsTaxExempt]
				,[IsServiced]
				,[IsCollected]
				,[IsPrivateLabel]
				,[CreatedById]
				,[CreatedTime]
				,[UpdatedById]
				,[UpdatedTime]
				,[ReceivableCodeId]
				,[PayableCodeId]
				,PayableWithholdingTaxRate
				,[BillToId]
				,[LegalEntityId]
				,[ContractId]
				,[CustomerId]
				,[VendorId]
				,[ReceivableRemitToId]
				,[PayableRemitToId]
				,[LocationId]
				,[ReceivableId]
				,[CurrencyId]
				,[PayableId]
				,[LineofBusinessId]
				,[InstrumentTypeId]
				,[IsOwned]
				,[IsAssignAtAssetLevel]
				,[IsSystemGenerated]
				,[InvoiceAmendmentType]
				,[Type]
				,[TaxPortionOfPayable_Amount]
				,[TaxPortionOfPayable_Currency]
				,[PayableAmount_Amount]
				,[PayableAmount_Currency]
				,[Status]
				,[CostCenterId]
				,[BranchId]
				,[IsVATAssessed]
				,[ProjectedVATAmount_Amount]
				,[ProjectedVATAmount_Currency]
				,[CountryId])
			VALUES
				(SundryToMigrate.SundryType
				,SundryToMigrate.EntityType
				,CASE WHEN SundryToMigrate.SundryType ='PayableOnly' THEN NULL ELSE SundryToMigrate.ReceivableDueDate END
				,CASE WHEN SundryToMigrate.SundryType ='PayableOnly' THEN NULL ELSE SundryToMigrate.InvoiceComment END
				,CASE WHEN SundryToMigrate.SundryType ='ReceivableOnly' THEN NULL ELSE SundryToMigrate.PayableDueDate END
				,CASE WHEN SundryToMigrate.SundryType ='ReceivableOnly' THEN NULL ELSE SundryToMigrate.Memo END
				,SundryToMigrate.IsAssetBased
				,CASE WHEN SundryToMigrate.SundryType ='PayableOnly' THEN SundryToMigrate.PayableAmount_Amount ELSE SundryToMigrate.Amount_Amount END
				,SundryToMigrate.Amount_Currency 
				,1
				,CASE WHEN SundryToMigrate.SundryType = 'PayableOnly' THEN 0 ELSE SundryToMigrate.ReceivableCodeTaxExempt END
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 1
					   WHEN EXISTS  (SELECT 1 FROM #TempSundryForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
						THEN (SELECT TSP.IsServiced FROM  #TempSundryForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
					  ELSE SundryToMigrate.IsServiced END
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 1
					  WHEN EXISTS  (SELECT 1 FROM #TempSundryForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
						THEN   (SELECT TSP.IsCollected FROM  #TempSundryForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
					  ELSE SundryToMigrate.IsCollected END
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 0
					 WHEN	EXISTS  (SELECT 1 FROM #TempSundryForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
						THEN	(SELECT TSP.IsPrivateLabel FROM  #TempSundryForPrivateLabel TSP WHERE TSP.Id=SundryToMigrate.Id)
					  ELSE SundryToMigrate.IsPrivateLabel END
				,@UserId
				,@CreatedTime
				,NULL
				,NULL
				,SundryToMigrate.R_ReceivableCodeId
				,SundryToMigrate.R_PayableCodeId 
				,CASE WHEN SundryToMigrate.SundryType ='ReceivableOnly' THEN 0 ELSE SundryToMigrate.PayableWithholdingTaxRate END
				,SundryToMigrate.R_BillToId
				,SundryToMigrate.R_LegalEntityId
				,SundryToMigrate.R_ContractId
				,SundryToMigrate.R_CustomerId
				,SundryToMigrate.R_VendorId
				,SundryToMigrate.R_ReceivableRemitToId
				,SundryToMigrate.R_PayableRemitToId
				,SundryToMigrate.R_LocationId
				,NULL
				,SundryToMigrate.R_CurrencyId
				,NULL
				,SundryToMigrate.R_LineofBusinessId
				,SundryToMigrate.R_InstrumentTypeId
				,CASE WHEN SundryToMigrate.EntityType = 'CU' THEN 1
					  ELSE SundryToMigrate.IsOwned END
				,SundryToMigrate.IsAssignAtAssetLevel
				,0
				,'Credit'
				,SundryToMigrate.Type
				,0.00
				,SundryToMigrate.Amount_Currency
				,CASE WHEN SundryToMigrate.SundryType ='ReceivableOnly' THEN 0 ELSE  SundryToMigrate.PayableAmount_Amount END
				,SundryToMigrate.payableAmount_Currency
				,'Approved'
				,SundryToMigrate.R_CostCenterConfigId
				,SundryToMigrate.R_BranchId
				,1
				,SundryToMigrate.ProjectedVATAmount_Amount
				,SundryToMigrate.ProjectedVATAmount_Currency
				,SundryToMigrate.R_CountryId)
		OUTPUT $action, Inserted.Id, SundryToMigrate.SundryId INTO #CreatedSundries
		;
		MERGE SundryDetails AS SD
		USING (SELECT SundryDetail.*, SundryIdMapping.Id CreatedSundryId
				FROM #CreatedSundries SundryIdMapping 
				JOIN stgSundryDetail SundryDetail ON SundryIdMapping.SundryId = SundryDetail.SundryId
				JOIN stgSundry sundry ON sundry.Id=SundryIdMapping.SundryId ) AS Sundry
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
			([Amount_Amount]
			,[Amount_Currency]
			,[CreatedById]
			,[CreatedTime]
			,[UpdatedById]
			,[UpdatedTime]
			,[AssetId]
			,[BillToId]
			,[SundryId]
			,[IsActive]
			,[PayableAmount_Amount]
			,[PayableAmount_Currency]
			,[VATAmount_Amount]
			,[VATAmount_Currency])
			VALUES
			(Sundry.Amount_Amount
		    ,Sundry.Amount_Currency
		    ,@UserId
		    ,@CreatedTime
		    ,NULL
		    ,NULL
		    ,Sundry.R_AssetId
		    ,Sundry.R_BillToId
		    ,Sundry.CreatedSundryId
		    ,1
			,Sundry.PayableAmount_Amount
			,Sundry.PayableAmount_Currency
			,Sundry.ProjectedVATAmount_Amount
			,Sundry.ProjectedVATAmount_Currency)						  
		;
		MERGE Payables AS Payable
		USING (SELECT SundryToMigrate.*, SundryIdMapping.Id CreatedSundryId
				FROM #Sundry SundryToMigrate 
				JOIN #CreatedSundries SundryIdMapping ON SundryToMigrate.SundryId = SundryIdMapping.SundryId
				Join ReceivableCodes ReceivableCodes On SundryToMigrate.R_ReceivableCodeId = ReceivableCodes.Id
				WHERE SundryToMigrate.SundryType ='PayableOnly' OR (SundryToMigrate.SundryType = 'PassThrough' AND ReceivableCodes.AccountingTreatment !='CashBased')) AS Sundry
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
			([EntityType]
			,[EntityId]
			,[Amount_Amount]
			,[Amount_Currency]
			,[Balance_Amount]
			,[Balance_Currency]
			,[DueDate]
			,[Status]
			,[SourceTable]
			,[SourceId]
			,[InternalComment]
			,[IsGLPosted]
			,[CreatedById]
			,[CreatedTime]
			,[UpdatedById]
			,[UpdatedTime]
			,[CurrencyId]
			,[PayableCodeId]
			,[LegalEntityId]
			,[PayeeId]
			,[RemitToId]
			,[TaxPortion_Amount]
			,[TaxPortion_Currency]
			,WithholdingTaxRate)
		VALUES
			((CASE
				WHEN Sundry.EntityType = 'CT'
				THEN 'CT'
				ELSE 'CU'
				END)
			,(CASE
				WHEN Sundry.EntityType = 'CT'
				THEN Sundry.R_ContractId
				ELSE Sundry.R_CustomerId
				END)
			,Sundry.PayableAmount_Amount
			,Sundry.PayableAmount_Currency
			,Sundry.PayableAmount_Amount
			,Sundry.PayableAmount_Currency
			,Sundry.PayableDueDate
			,'Approved'
			,'SundryPayable'
			,Sundry.CreatedSundryId
			,Sundry.Memo
			,0
			,@UserId
			,@CreatedTime
			,NULL
			,NULL
			,Sundry.R_CurrencyId
			,Sundry.R_PayableCodeId
			,Sundry.R_LegalEntityId
			,Sundry.R_VendorId
			,Sundry.R_PayableRemitToId
			,0.00
			,'USD'
			,Sundry.PayableWithholdingTaxRate)
		OUTPUT $action, Inserted.Id, Sundry.CreatedSundryId, Sundry.R_ReceiptType INTO #PayableSundryMapping
		;
		UPDATE S
		SET S.PayableId = Payable.Id
		FROM Sundries S 
		JOIN #PayableSundryMapping Payable ON S.Id = Payable.SundryId
		;
		MERGE TreasuryPayables AS TreasuryPayable
		USING (SELECT SundryToMigrate.*, SundryIdMapping.Id CreatedSundryId, Payable.Id PayableId, Payable.ReceiptType
			   FROM #Sundry SundryToMigrate 
			   JOIN #CreatedSundries SundryIdMapping ON SundryToMigrate.SundryId = SundryIdMapping.SundryId
			   JOIN #PayableSundryMapping Payable ON SundryIdMapping.Id = Payable.SundryId
			   WHERE SundryToMigrate.SundryType != 'ReceivableOnly') AS Sundry
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
			([RequestedPaymentDate]
            ,[Amount_Amount]
            ,[Amount_Currency]
            ,[Balance_Amount]
            ,[Balance_Currency]
            ,[Status]
            ,[ApprovalComment]
            ,[Urgency]
            ,[Memo]
            ,[Comment]
            ,[ReceiptType]
            ,[CreatedById]
            ,[CreatedTime]
            ,[UpdatedById]
            ,[UpdatedTime]
            ,[LegalEntityId]
            ,[CurrencyId]
            ,[PayeeId]
            ,[RemitToId]
            ,[PayFromAccountId])
		VALUES
		   (Sundry.PayableDueDate
		   ,Sundry.Amount_Amount
		   ,Sundry.Amount_Currency
		   ,Sundry.Amount_Amount
		   ,Sundry.Amount_Currency
		   ,'Pending'
		   ,NULL
		   ,NULL
		   ,Sundry.Memo
		   ,NULL
		   ,Sundry.ReceiptType
		   ,@UserId
		   ,@CreatedTime
		   ,NULL
		   ,NULL
		   ,Sundry.R_LegalEntityId
		   ,Sundry.R_CurrencyId
		   ,Sundry.R_VendorId
		   ,Sundry.R_PayableRemitToId
		   ,NULL)
		OUTPUT $action, Inserted.Id, Sundry.PayableId, Sundry.Amount_Currency INTO #TreasuryPayableIdMapping
		;
		INSERT INTO TreasuryPayableDetails
           ([IsActive]
           ,[CreatedById]
           ,[CreatedTime]
           ,[UpdatedById]
           ,[UpdatedTime]
           ,[PayableId]
           ,[DisbursementRequestPayableId]
           ,[TreasuryPayableId]
           ,[ReceivableOffsetAmount_Amount]
           ,[ReceivableOffsetAmount_Currency])
		SELECT
			1
		   ,@UserId
		   ,@CreatedTime
		   ,NULL
		   ,NULL
		   ,TreasuryPayable.PayableId
		   ,NULL
		   ,TreasuryPayable.Id
		   ,0.0
		   ,TreasuryPayable.Currency
		FROM #TreasuryPayableIdMapping TreasuryPayable
		;
		MERGE Receivables AS Receivable
		USING (SELECT SundryToMigrate.*, SundryIdMapping.Id CreatedSundryId
				FROM #Sundry SundryToMigrate 
				JOIN #CreatedSundries SundryIdMapping ON SundryToMigrate.SundryId = SundryIdMapping.SundryId
				WHERE SundryToMigrate.SundryType != 'PayableOnly') AS Sundry
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
			([EntityType]
			,[EntityId]
			,[DueDate]
			,[IsDSL]
			,[IsActive]
			,[InvoiceComment]
			,[InvoiceReceivableGroupingOption]
			,[IsGLPosted]
			,[IncomeType]
			,[PaymentScheduleId]
			,[IsCollected]
			,[IsServiced]
			,[CreatedById]
			,[CreatedTime]
			,[UpdatedById]
			,[UpdatedTime]
			,[ReceivableCodeId]
			,[CustomerId]
			,[FunderId]
			,[RemitToId]
			,[TaxRemitToId]
			,[LocationId]
			,[LegalEntityId]
			,[IsDummy]
			,[IsPrivateLabel]
			,[SourceId]
			,[SourceTable]
			,[TotalAmount_Amount]
			,[TotalAmount_Currency]
			,[TotalBalance_Amount]
			,[TotalBalance_Currency]
			,[TotalEffectiveBalance_Amount]
			,[TotalEffectiveBalance_Currency]
			,[TotalBookBalance_Amount]
			,[TotalBookBalance_Currency]
			 ,[ExchangeRate]                        
			,[AlternateBillingCurrencyId]
			,[UniqueIdentifier]) 				
		VALUES
			((CASE
				WHEN Sundry.EntityType = 'CT'
				THEN 'CT'
				ELSE 'CU'
				END)
			,(CASE
				WHEN Sundry.EntityType = 'CT'
				THEN Sundry.R_ContractId
				ELSE Sundry.R_CustomerId
				END)
			,Sundry.ReceivableDueDate
			,0
			,1
			,Sundry.InvoiceComment
			,Sundry.R_ReceivableGroupingOption
			,0
			,'_'
			,NULL
			,Sundry.IsCollected
			,Sundry.IsServiced
			,@UserId
			,@CreatedTime
			,NULL
			,NULL
			,Sundry.R_ReceivableCodeId
			,Sundry.R_CustomerId
			,NULL
			,Sundry.R_ReceivableRemitToId
			,Sundry.R_ReceivableRemitToId
			,Sundry.R_LocationId
			,Sundry.R_LegalEntityId
			,0
			,Sundry.IsPrivateLabel
			,Sundry.CreatedSundryId
			,'Sundry'
			,Sundry.Amount_Amount
			,Sundry.Amount_Currency
			,Sundry.Amount_Amount
			,Sundry.Amount_Currency
			,Sundry.Amount_Amount
			,Sundry.Amount_Currency
			,0.0
			,Sundry.Amount_Currency
			,1.00
            ,Sundry.R_CurrencyId
            ,Sundry.UniqueIdentifier)
		OUTPUT $action, Inserted.Id, Sundry.CreatedSundryId INTO #ReceivableSundryMapping
		;
		UPDATE S
		SET S.ReceivableId = Receivable.Id
		FROM Sundries S
		JOIN #ReceivableSundryMapping Receivable ON S.Id = Receivable.SundryId
		;
		INSERT INTO ReceivableDetails
				([Amount_Amount]
				,[Amount_Currency]
				,[Balance_Amount]
				,[Balance_Currency]
				,[EffectiveBalance_Amount]
				,[EffectiveBalance_Currency]
				,[IsActive]
				,[BilledStatus]
				,[IsTaxAssessed]
				,[CreatedById]
				,[CreatedTime]
				,[UpdatedById]
				,[UpdatedTime]
				,[AssetId]
				,[BillToId]
				,[AdjustmentBasisReceivableDetailId]
				,[ReceivableId]
				,[StopInvoicing]
				,[EffectiveBookBalance_Amount]
				,[EffectiveBookBalance_Currency]
				,[AssetComponentType]
				,[LeaseComponentAmount_Amount]
				,[LeaseComponentAmount_Currency]
				,[NonLeaseComponentAmount_Amount]
				,[NonLeaseComponentAmount_Currency]
				,[LeaseComponentBalance_Amount]
				,[LeaseComponentBalance_Currency]
				,[NonLeaseComponentBalance_Amount]
				,[NonLeaseComponentBalance_Currency]
				,[PreCapitalizationRent_Amount]
				,[PreCapitalizationRent_Currency]
				)
			SELECT
				 SundryDetail.Amount_Amount
				,SundryDetail.Amount_Currency
				,SundryDetail.Amount_Amount
				,SundryDetail.Amount_Currency
				,SundryDetail.Amount_Amount
				,SundryDetail.Amount_Currency
				,1
				,'NotInvoiced'
				,0
				,@UserId
				,@CreatedTime
				,NULL
				,NULL
				,SundryDetail.R_AssetId
				,SundryDetail.R_BillToId
				,NULL
				,Receivable.Id
				,0
				,0.0
				,SundryDetail.Amount_Currency
				,CASE WHEN LeaseAssets.Id Is NOT NULL 
				      THEN 
					      CASE WHEN IsLeaseAsset = 1 THEN 'Lease' ELSE 'Finance' END
					  ELSE 
					      '_'
				      END
				,SundryDetail.Amount_Amount
				,SundryDetail.Amount_Currency
				,0.00
				,SundryDetail.Amount_Currency
				,SundryDetail.Amount_Amount
				,SundryDetail.Amount_Currency
				,0.00
				,SundryDetail.Amount_Currency
				,0.00
				,SundryDetail.Amount_Currency
			FROM #Sundry SundryToMigrate 
			JOIN #CreatedSundries SundryIdMapping ON SundryToMigrate.SundryId = SundryIdMapping.SundryId
			JOIN #ReceivableSundryMapping Receivable ON SundryIdMapping.Id = Receivable.SundryId
			JOIN stgSundryDetail SundryDetail ON SundryToMigrate.SundryId = SundryDetail.SundryId
			JOIN ReceivableCodes ON ReceivableCodes.Id = SundryToMigrate.R_ReceivableCodeId
			LEFT JOIN LeaseAssets ON LeaseAssets.AssetId = SundryDetail.R_AssetId AND LeaseAssets.IsActive = 1
			WHERE SundryToMigrate.IsAssetBased = 1
		;
		INSERT INTO ReceivableDetails
				([Amount_Amount]
				,[Amount_Currency]
				,[Balance_Amount]
				,[Balance_Currency]
				,[EffectiveBalance_Amount]
				,[EffectiveBalance_Currency]
				,[IsActive]
				,[BilledStatus]
				,[IsTaxAssessed]
				,[CreatedById]
				,[CreatedTime]
				,[UpdatedById]
				,[UpdatedTime]
				,[AssetId]
				,[BillToId]
				,[AdjustmentBasisReceivableDetailId]
				,[ReceivableId]
				,[StopInvoicing]
				,[EffectiveBookBalance_Amount]
				,[EffectiveBookBalance_Currency]
				,[AssetComponentType]
				,[LeaseComponentAmount_Amount]
				,[LeaseComponentAmount_Currency]
				,[NonLeaseComponentAmount_Amount]
				,[NonLeaseComponentAmount_Currency]
				,[LeaseComponentBalance_Amount]
				,[LeaseComponentBalance_Currency]
				,[NonLeaseComponentBalance_Amount]
				,[NonLeaseComponentBalance_Currency]
				,[PreCapitalizationRent_Amount]
				,[PreCapitalizationRent_Currency]
				)
			SELECT
				 SundryToMigrate.Amount_Amount
				,SundryToMigrate.Amount_Currency
				,SundryToMigrate.Amount_Amount
				,SundryToMigrate.Amount_Currency
				,SundryToMigrate.Amount_Amount
				,SundryToMigrate.Amount_Currency
				,1
				,'NotInvoiced'
				,CASE WHEN (Contracts.ContractType = 'IsLoan' AND (ReceivableCodes.IsTaxExempt = 1 OR @IsSalesTaxRequiredForLoan = 0)) 
						THEN 1 							
					  ELSE 0
				 END
				,@UserId
				,@CreatedTime
				,NULL
				,NULL
				,NULL
				,SundryToMigrate.R_BillToId
				,NULL
				,Receivable.Id
				,0
				,0.0
				,SundryToMigrate.Amount_Currency
				,'_'
				,SundryToMigrate.Amount_Amount
				,SundryToMigrate.Amount_Currency
				,0.00
				,SundryToMigrate.Amount_Currency
				,SundryToMigrate.Amount_Amount
				,SundryToMigrate.Amount_Currency
				,0.00
				,SundryToMigrate.Amount_Currency
				,0.00
				,SundryToMigrate.Amount_Currency
			FROM #Sundry SundryToMigrate 
			JOIN #CreatedSundries SundryIdMapping ON SundryToMigrate.SundryId = SundryIdMapping.SundryId
			JOIN #ReceivableSundryMapping Receivable ON SundryIdMapping.Id = Receivable.SundryId
			JOIN ReceivableCodes ON ReceivableCodes.Id = SundryToMigrate.R_ReceivableCodeId
			LEFT JOIN Contracts ON SundryToMigrate.R_ContractId= Contracts.Id
			WHERE SundryToMigrate.IsAssetBased = 0
		;	
		MERGE ACHSchedules AS ACHSchedule
		USING (Select #SundryWithACHSchedule.*, #ReceivableSundryMapping.Id As ReceivableId 
			   From #SundryWithACHSchedule 
			   Inner Join #CreatedSundries On #CreatedSundries.SundryId = #SundryWithACHSchedule.SundryId
			   Inner join #ReceivableSundryMapping On #ReceivableSundryMapping.SundryId = #CreatedSundries.Id ) AS SundryWithACHScheduleDetails
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT
		(
			ACHPaymentNumber
			,PaymentType
			,ACHAmount_Amount
			,ACHAmount_Currency
			,SettlementDate
			,Status
			,StopPayment
			,IsActive
			,CreatedById
			,CreatedTime
			,UpdatedById
			,UpdatedTime
			,ReceivableId
			,ACHAccountId
			,ContractBillingId
			,BankAccountPaymentThresholdId
			,IsPreACHNotificationCreated
		)
		Values
		(
			ACHPaymentNumber
			,PaymentType
			,ACHAmount
			,ACHAmountCurrency
			,SettlementDate
			,Status
			,0
			,1
			,@UserId
			,@CreatedTime
			,Null
			,Null
			,ReceivableId
			,ACHAccountId
			,ContractId
			,Null
			,IsPreNotificationCreated
		);

			MERGE stgProcessingLog AS ProcessingLog
				USING (SELECT SundryId
						FROM #CreatedSundries) AS ProcessedSundry
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
		UPDATE stgSundry SET IsMigrated = 1
				FROM stgSundry With(nolock)
			JOIN #CreatedSundries ON SundryId = stgSundry.Id 					
		SET @SkipCount = @SkipCount + @TakeCount;
		DROP TABLE #CreatedSundries;
		DROP TABLE #PayableSundryMapping;
		DROP TABLE #ReceivableSundryMapping;
	    DROP TABLE #TreasuryPayableIdMapping;
		DROP TABLE #Sundry 
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'MigrateSundries'
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
	Drop Table #ErrorLogs;
	Drop Table #ErrorRecords;
	Drop Table #FailedProcessingLogs;
	Drop Table #CreatedProcessingLogs;
	Drop Table #ErrorLogDetails; 
    Drop Table #LegalEntityLOB;
	Drop Table #SundryWithPaymentOrder;
	Drop Table #ContractsWithACHPaymentNumber;
	Drop Table #ContractsWithLatestACHPaymentNumber;
	Drop Table #SundryWithACHSchedule;
	Drop Table #TempSundryForPrivateLabel;	
	Drop Table #TempSundry
	Drop Table #TempSundryDetail
	SET NOCOUNT OFF;
	SET XACT_ABORT OFF;
END

GO
