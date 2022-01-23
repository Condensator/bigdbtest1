SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateLienFilings]
(	
	@UserId BIGINT,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUT,
	@FailedRecords BIGINT OUT,
	@ToolIdentifier INT
)
AS
BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON
--DECLARE @UserId BIGINT;
--DECLARE @FailedRecords BIGINT;
--DECLARE @ProcessedRecords BIGINT;
--DECLARE @CreatedTime DATETIMEOFFSET;
--DECLARE @ModuleIterationStatusId BIGINT;
--SET @UserId = 1;
--SET @CreatedTime = SYSDATETIMEOFFSET();	
--SElect @ModuleIterationStatusId=id from stgModuleIterationStatus
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
SET @FailedRecords = 0
SET @ProcessedRecords = 0
DECLARE @TakeCount INT = 50000
DECLARE @BatchCount INT = 0
DECLARE @TransactionType NVARCHAR(30);
DECLARE @IsILien BIT = (SELECT CASE WHEN Value = 'true' THEN 1 ELSE 0 END  FROM GlobalParameters WHERE Category = 'LienFiling' AND Name = 'IsILien')
DECLARE @ExternalBusinessTypeConfig TABLE(BusinessTypeName nvarchar(100))
INSERT INTO @ExternalBusinessTypeConfig SELECT Name FROM ExternalBusinessTypeConfigs WHERE IsILien = @IsILien
CREATE TABLE #TransactionType (TransactionTypeId INT IDENTITY(1,1),TransactionType NVARCHAR(30));
INSERT INTO #TransactionType
SELECT DISTINCT TransactionType FROM stgLienFiling IntermediateLienFiling ORDER BY TransactionType DESC
DECLARE @TotalTransactionTypeCount INT = (SELECT COUNT(*) FROM #TransactionType)
DECLARE @TransactionTypeCount INT = 1
DECLARE @Module VARCHAR(50) = NULL
SET @Module = (SELECT StgModule.Name FROM StgModule INNER JOIN StgModuleIterationStatus ON StgModule.Id = StgModuleIterationStatus.ModuleId WHERE StgModuleIterationStatus.Id = @ModuleIterationStatusId)
EXEC ResetStagingTempFields @Module , @ToolIdentifier
        CREATE TABLE #ErrorLogs
		(
			Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
			StagingRootEntityId BIGINT,
			Result NVARCHAR(10),
			Message NVARCHAR(MAX)
		)
		CREATE TABLE #FailedProcessingLogs
		(
			MergeAction NVARCHAR(20),
			InsertedId BIGINT,
			ErrorId BIGINT
		)

DECLARE @TotalRecordsCount BIGINT = 0;

WHILE @TransactionTypeCount <= @TotalTransactionTypeCount
BEGIN
	DECLARE @SkipCount INT = 0
	DECLARE @MaxLienFilingId INT = 0
	SELECT @TransactionType = TransactionType FROM #TransactionType WHERE TransactionTypeId = @TransactionTypeCount
	SET @TotalRecordsCount = (SELECT COUNT(Id) FROM stgLienFiling IntermediateLienFiling WHERE IsMigrated=0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL) AND TransactionType = @TransactionType)
	WHILE @SkipCount < @TotalRecordsCount
	 BEGIN
	 BEGIN TRY  
     BEGIN TRANSACTION
		CREATE TABLE #CreatedLienFilingIds
		(
			MergeAction NVARCHAR(20),
			InsertedId BIGINT,
			LienFilingId BIGINT,
		)
		CREATE TABLE #CreatedProcessingLogs
		(
			MergeAction NVARCHAR(20),
			InsertedId BIGINT
		)
		SELECT 
			TOP(@TakeCount) * INTO #LienFilingSubset 
		FROM 
			stgLienFiling IntermediateLienFiling
		WHERE
			IntermediateLienFiling.Id > @MaxLienFilingId AND IntermediateLienFiling.IsMigrated=0 AND (IntermediateLienFiling.ToolIdentifier = @ToolIdentifier OR IntermediateLienFiling.ToolIdentifier IS NULL)
			AND IntermediateLienFiling.TransactionType = @TransactionType
		ORDER BY 
			IntermediateLienFiling.Id
update stgLienFilingContract Set R_ContractId=Contracts.Id
from stgLienFilingContract SLFC
join stgLienFiling SLF ON SLFC.Id=SLF.Id
join Contracts  on SLFC.ContractSequenceNumber=Contracts.SequenceNumber
where SLF.IsMigrated=0 AND (SLF.ToolIdentifier = @ToolIdentifier OR SLF.ToolIdentifier IS NULL) AND SLFC.R_ContractId is NULL
update stgLienFilingContract Set R_LeaseFinanceId=LeaseFinances.Id
from stgLienFilingContract SLFC
join stgLienFiling SLF ON SLFC.Id=SLF.Id
join Contracts  on SLFC.ContractSequenceNumber=Contracts.SequenceNumber
join LeaseFinances  ON LeaseFinances.ContractId=Contracts.Id
where SLF.IsMigrated=0 AND (SLF.ToolIdentifier = @ToolIdentifier OR SLF.ToolIdentifier IS NULL) AND SLFC.R_LeaseFinanceId is NULL
update stgLienFilingContract Set R_LoanFinanceId=LoanFinances.Id
from stgLienFilingContract SLFC
join stgLienFiling SLF ON SLFC.Id=SLF.Id
join Contracts  on SLFC.ContractSequenceNumber=Contracts.SequenceNumber
join LoanFinances  ON LoanFinances.ContractId=Contracts.Id
where SLF.IsMigrated=0 AND (SLF.ToolIdentifier = @ToolIdentifier OR SLF.ToolIdentifier IS NULL) AND SLFC.R_LeaseFinanceId is NULL
		SELECT 
		IntermediateLienFiling.Id [LienFilingId]
		,IntermediateLienFiling.FilingAlias
		,IntermediateLienFiling.Type
		,IntermediateLienFiling.EntityType
		,IntermediateLienFiling.TransactionType
		,IntermediateLienFiling.RecordType
		,IntermediateLienFiling.AmendmentType
		,IntermediateLienFiling.AmendmentAction
		,IntermediateLienFiling.AmendmentRecordDate
		,IntermediateLienFiling.SecuredPartyType
		,IntermediateLienFiling.IsAssignee
		,IntermediateLienFiling.CollateralText
		,IntermediateLienFiling.CollateralClassification
		,IntermediateLienFiling.InternalComment
		,IntermediateLienFiling.PrincipalAmount_Amount
		,IntermediateLienFiling.PrincipalAmount_Currency
		,IntermediateLienFiling.IsNoFixedDate
		,IntermediateLienFiling.DateOfMaturity
		,IntermediateLienFiling.SigningPlace
		,IntermediateLienFiling.SigningDate
		,IntermediateLienFiling.IsAutoContinuation
		,IntermediateLienFiling.AuthorizingPartyType
		,IntermediateLienFiling.AltFilingType
		,IntermediateLienFiling.AltNameDesignation
		,IntermediateLienFiling.LienDebtorAltCapacity
		,IntermediateLienFiling.IsManualUpdate
		,CASE WHEN IntermediateLienFiling.TransactionType = 'Amendment' AND IntermediateLienFiling.AmendmentType != '_'
				THEN 'Amendment'
			  ELSE 'Create' END LienTransactions
		,IntermediateLienFiling.LienRefNumber
		,IntermediateLienFiling.IsFloridaDocumentaryStampTax
		,IntermediateLienFiling.MaximumIndebtednessAmount_Amount
		,IntermediateLienFiling.MaximumIndebtednessAmount_Currency
		,IntermediateLienFiling.LienFilingStatus
		,CASE WHEN IntermediateLienFiling.EntityType = 'Customer' THEN Customer.Id 
			  ELSE NULL END [CustomerId]
		,Customer.Status [CustomerStatus]
		,CASE WHEN IntermediateLienFiling.EntityType = 'Contract' THEN Contract.Id 
			  ELSE NULL END [ContractId]
		,FirstDebtorCustomer.Id [FirstDebtorId]
		,State.Id [StateId]
		,State.IsActive [StateIsActive]
		,Country.Id [CountryId]
		,CASE WHEN IntermediateLienFiling.SecuredPartyType = 'Funder' THEN SecuredFunder.Id
			  ELSE NULL END [SecuredFunderId]
		,SecuredFunder.Status [SecuredFunderStatus]
		,CASE WHEN IntermediateLienFiling.SecuredPartyType = 'LegalEntity' THEN SecuredLegalEntity.Id
			  ELSE NULL END [SecuredLegalEntityId]
		,SecuredLegalEntity.Status [SecuredLegalEntityStatus]
		,CASE WHEN IntermediateLienFiling.TransactionType = 'Amendment' THEN LFiling.Id
			  ELSE NULL END [OriginalFilingRecordId]
		,CASE WHEN IntermediateLienFiling.AuthorizingPartyType = 'Debtor' THEN AuthorizingCustomer.Id
			  ELSE NULL END [AuthorizingCustomerId]
		,AuthorizingCustomer.Status [AuthorizingCustomerStatus]
		,CASE WHEN IntermediateLienFiling.AuthorizingPartyType = 'Funder' THEN AuthorizingFunder.Id
			  ELSE NULL END [AuthorizingFunderId]
		,AuthorizingFunder.Status [AuthorizingFunderStatus]
		,CASE WHEN IntermediateLienFiling.AuthorizingPartyType = 'LegalEntity' THEN AuthorizingLegalEntity.Id
			  ELSE NULL END [AuthorizingLegalEntityId]
		,AuthorizingLegalEntity.Status [AuthorizingLegalEntityStatus]
		,NULL [ContinuationRecordId]
		,LienCollateralTextTemplate.Id [LienCollateralTemplateId]
		,LienCollateralTextTemplate.IsActive [LienCollateralTextTemplateIsActive]
		,NULL [AttachmentURL]
		,County.Id [CountyId]
		,County.Name [CountyName]
		,IntermediateLienFiling.FLTaxStamp
		,IntermediateLienFiling.InDebType
		,IntermediateLienFiling.AttachmentType
		,IntermediateLienFiling.IncludeSerialNumberInAssetInformation
		,IntermediateLienFiling.IsFinancialStatementRequiredForRealEstate
		,IntermediateLienFiling.SecuredFunderPartyNumber
		,IntermediateLienFiling.Description
		,IntermediateLienFiling.RecordOwnerNameAndAddress
		,IntermediateLienFiling.[FinancingStatementDate] 
		,IntermediateLienFiling.[FinancingStatementFileNumber]
		,CASE WHEN (IntermediateLienFiling.SecuredPartyType='Funder') THEN Businessunit.[Id]  ELSE SecuredLegalEntity.BusinessUnitId END AS BusinessUnitId 
		,IntermediateLienFiling.[HistoricalExpirationDate] 
		,IntermediateLienFiling.[InitialFileDate] 
		,IntermediateLienFiling.[InitialFileNumber]
		,IntermediateLienFiling.SecuredLegalEntityNumber 
		,CASE WHEN IntermediateLienFiling.[OriginalDebtorName] IS NULL THEN FirstDebtorParty.PartyName
		      ELSE IntermediateLienFiling.[OriginalDebtorName] END AS OriginalDebtorName
		,CASE WHEN IntermediateLienFiling.[OriginalSecuredPartyName] IS NULL THEN
				   CASE WHEN IntermediateLienFiling.SecuredPartyType = 'LegalEntity' THEN SecuredLegalEntity.Name
				        ELSE SecuredFunderParty.PartyName END
			  ELSE IntermediateLienFiling.[OriginalSecuredPartyName] END AS OriginalSecuredPartyName
		INTO #LienFilingsMappedWithTarget
		FROM #LienFilingSubset IntermediateLienFiling
		LEFT JOIN Parties Party
			ON IntermediateLienFiling.CustomerPartyNumber = Party.PartyNumber
		LEFT JOIN Customers Customer
			ON Customer.Id = Party.Id AND Customer.Status = 'Active' AND Customer.IsLienFilingRequired = 1
		LEFT JOIN States State
			ON State.ShortName = IntermediateLienFiling.StateShortName 
		LEFT JOIN Countries Country
			ON Country.Id = State.CountryId AND Country.IsActive = 1 AND Country.ShortName =CASE WHEN  IntermediateLienFiling.Type = 'UCC' THEN 'USA' ELSE 'CAN' END
		LEFT JOIN Counties County
			ON County.Name = IntermediateLienFiling.CountyName AND County.IsActive = 1 AND (County.StateId IS NOT NULL AND County.StateId = State.Id)
		LEFT JOIN Contracts Contract
			ON IntermediateLienFiling.ContractSequenceNumber = Contract.SequenceNumber
		LEFT JOIN Parties FirstDebtorParty
			ON IntermediateLienFiling.FirstDebtorPartyNumber = FirstDebtorParty.PartyNumber
		LEFT JOIN Customers FirstDebtorCustomer
			ON FirstDebtorCustomer.Id = FirstDebtorParty.Id
		LEFT JOIN Parties SecuredFunderParty
			ON IntermediateLienFiling.SecuredFunderPartyNumber = SecuredFunderParty.PartyNumber
		LEFT JOIN Funders SecuredFunder 
			ON SecuredFunderParty.Id = SecuredFunder.Id AND SecuredFunder.Status='Active'
		LEFT JOIN LegalEntities SecuredLegalEntity
			ON IntermediateLienFiling.SecuredLegalEntityNumber = SecuredLegalEntity.LegalEntityNumber AND SecuredLegalEntity.Status='Active'
		LEFT JOIN Parties AuthorizingParty
			ON IntermediateLienFiling.AuthorizingCustomerPartyNumber = AuthorizingParty.PartyNumber
		LEFT JOIN Customers AuthorizingCustomer
			ON AuthorizingCustomer.Id = AuthorizingParty.Id
		LEFT JOIN Parties AuthorizingFunderParty
			ON IntermediateLienFiling.AuthorizingFunderPartyNumber = AuthorizingFunderParty.PartyNumber
		LEFT JOIN Funders AuthorizingFunder
			ON AuthorizingFunderParty.Id = AuthorizingFunder.Id
		LEFT JOIN LegalEntities AuthorizingLegalEntity
			ON IntermediateLienFiling.AuthorizingLegalEntityNumber = AuthorizingLegalEntity.LegalEntityNumber
		LEFT JOIN LienCollateralTextTemplates LienCollateralTextTemplate
			ON LienCollateralTextTemplate.Name = IntermediateLienFiling.LienCollateralTemplateName AND LienCollateralTextTemplate.IsActive = 1
		LEFT JOIN LienFilings LFiling
			ON LFiling.FilingAlias = IntermediateLienFiling.OriginalFilingRecordAlias
        LEFT JOIN BusinessUnits Businessunit 
		     ON  Businessunit.PortfolioId = SecuredFunderParty.PortfolioId and Businessunit.IsActive=1 and Businessunit.IsDefault=1
		WHERE
			IntermediateLienFiling.Id > @MaxLienFilingId AND IntermediateLienFiling.TransactionType = @TransactionType 
		ORDER BY 
			IntermediateLienFiling.Id
		SELECT @MaxLienFilingId = MAX(LienFilingId) FROM #LienFilingsMappedWithTarget;
		SELECT @BatchCount = ISNULL(COUNT(LienFilingId),0) FROM #LienFilingsMappedWithTarget;
		SELECT 
		IntermediateLienResponse.Id [LienFilingId]
		,IntermediateLienResponse.ExternalSystemNumber
		,IntermediateLienResponse.ExternalRecordStatus
		,IntermediateLienResponse.AuthorityFilingStatus
		,IntermediateLienResponse.AuthoritySubmitDate
		,IntermediateLienResponse.AuthorityFileNumber
		,IntermediateLienResponse.AuthorityFileDate
		,IntermediateLienResponse.AuthorityOriginalFileDate
		,IntermediateLienResponse.AuthorityFileExpiryDate
		,IntermediateLienResponse.AuthorityFilingOffice
		,IntermediateLienResponse.AuthorityFilingType
		,State.Id [AuthorityFilingStateId]
		,IntermediateLienFiling.FilingAlias [LienFilingAlias]
		INTO #LienResponseSubset
		FROM 
			stgLienResponse IntermediateLienResponse
		INNER JOIN 	#LienFilingsMappedWithTarget IntermediateLienFiling
			ON IntermediateLienResponse.Id = IntermediateLienFiling.LienFilingId
		LEFT JOIN States State
			ON State.ShortName = IntermediateLienResponse.AuthorityFilingStateShortName
		SELECT 
		IntermediateLienCollateral.LienFilingId
		,1 [IsActive]
		,IntermediateLienCollateral.IsAssigned
		,0 [IsRemoved]
		,Asset.Id [AssetId]
		,IntermediateLienCollateral.AssetAlias [AssetAlias]
		,IntermediateLienFiling.FilingAlias [LienFilingAlias]
		INTO #LienCollateralSubset
		FROM 
			stgLienCollateral IntermediateLienCollateral
		INNER JOIN 	#LienFilingsMappedWithTarget IntermediateLienFiling
			ON IntermediateLienCollateral.LienFilingId = IntermediateLienFiling.LienFilingId
		LEFT JOIN Assets Asset
			ON Asset.Alias = IntermediateLienCollateral.AssetAlias
		SELECT 
		IntermediateLienAdditionalDebtor.LienFilingId
		,1 [IsActive]
		,0 [IsRemoved]
		,Customer.Id [CustomerId]
		,Party.PartyNumber [CustomerPartyNumber]
		,IntermediateLienFiling.FilingAlias [LienFilingAlias]
		,IntermediateLienAdditionalDebtor.RelationshipType [RelationshipType]
		INTO #LienAdditionalDebtorSubset
		FROM 
			stgLienAdditionalDebtor IntermediateLienAdditionalDebtor
		INNER JOIN 	#LienFilingsMappedWithTarget IntermediateLienFiling
			ON IntermediateLienAdditionalDebtor.LienFilingId = IntermediateLienFiling.LienFilingId
		LEFT JOIN Parties Party
			ON IntermediateLienAdditionalDebtor.CustomerPartyNumber = Party.PartyNumber
		LEFT JOIN Customers Customer
			ON Customer.Id = Party.Id
        SELECT
		#LienFilingSubset.Id [LienFilingId]
		,IntermediateLienFilingContract.LienFilingAlias
		,IntermediateLienFilingContract.ContractSequenceNumber
		,IntermediateLienFilingContract.ContractType
		,IntermediateLienFilingContract.R_ContractId
		,IntermediateLienFilingContract.R_LeaseFinanceId
		,IntermediateLienFilingContract.R_LoanFinanceId
		INTO #LienFilingContractSubset
		FROM
		   stgLienFilingContract IntermediateLienFilingContract
		   join #LienFilingSubset on IntermediateLienFilingContract.Id=#LienFilingSubset.Id
		SELECT 
		IntermediateLienAdditionalSecuredParty.LienFilingId
		,0 [IsAssignor]
		,1 [IsActive]
		,0 [IsRemoved]
		,IntermediateLienAdditionalSecuredParty.SecuredPartyType
		,IntermediateLienAdditionalSecuredParty.SecuredFunderPartyNumber
		,IntermediateLienAdditionalSecuredParty.SecuredLegalEntityNumber
		,SecuredLegalEntity.Id [SecuredLegalEntityId]
		,SecuredFunder.Id [SecuredFunderId]
		,IntermediateLienFiling.FilingAlias [LienFilingAlias]
		--,IntermediateLienFiling.SecuredFunderId [FilingSecuredFunderId]
		--,IntermediateLienFiling.SecuredLegalEntityId [FilingSecuredLegalEntityId]
		INTO #LienAdditionalSecuredPartySubset
		FROM 
			stgLienAdditionalSecuredParty IntermediateLienAdditionalSecuredParty
		INNER JOIN 	#LienFilingsMappedWithTarget IntermediateLienFiling
			ON IntermediateLienAdditionalSecuredParty.LienFilingId = IntermediateLienFiling.LienFilingId
		LEFT JOIN Parties SecuredFunder
			ON IntermediateLienAdditionalSecuredParty.SecuredFunderPartyNumber = SecuredFunder.PartyNumber
		--LEFT JOIN Funders 
	    --		ON SecuredFunder.Id = Funders.Id
		LEFT JOIN LegalEntities SecuredLegalEntity
			ON IntermediateLienAdditionalSecuredParty.SecuredLegalEntityNumber = SecuredLegalEntity.LegalEntityNumber
		SELECT 
		#LienFilingsMappedWithTarget.LienFilingId
		,#LienFilingsMappedWithTarget.FilingAlias
		INTO #LienFilingWithAlias
		FROM LienFilings
		INNER JOIN #LienFilingsMappedWithTarget
			ON LienFilings.FilingAlias = #LienFilingsMappedWithTarget.FilingAlias
		WHERE LienFilings.LienFilingStatus = 'Approved'		
		SELECT
			#LienFilingsMappedWithTarget.LienFilingId,#LienFilingsMappedWithTarget.FilingAlias INTO #InvalidContracts
		FROM 
			#LienFilingsMappedWithTarget 
			INNER JOIN Contracts ON #LienFilingsMappedWithTarget.ContractId = Contracts.Id
			LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1 
			LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
		WHERE 
			#LienFilingsMappedWithTarget.EntityType='Contract' AND ((Contracts.ContractType = 'Lease' AND LeaseFinances.BookingStatus NOT IN('Pending','InstallingAssets','Commenced')) OR
			(Contracts.ContractType = 'Loan' AND LoanFinances.Status NOT IN('Commenced','Uncommenced')))
	   INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				  ,('The Filing Alias In LienFiling Contract is Invalid for the Filing : ' + #LienFilingSubset.FilingAlias) AS Message
				FROM 
					#LienFilingContractSubset
					INNER JOIN #LienFilingSubset on #LienFilingSubset.Id = #LienFilingContractSubset.LienFilingId
		WHERE 
			   #LienFilingSubset.FilingAlias!=#LienFilingContractSubset.LienFilingAlias
	    INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				  ,('Selected Contract does not exist for Filing In LienFiling Contract : ' + #LienFilingContractSubset.LienFilingAlias) AS Message
				FROM 
					#LienFilingContractSubset
					INNER JOIN Contracts ON #LienFilingContractSubset.ContractSequenceNumber = Contracts.SequenceNumber
					INNER JOIN #LienFilingSubset on #LienFilingSubset.Id = #LienFilingContractSubset.LienFilingId
		WHERE 
			   Contracts.Id is Null	  
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidContracts ) > 0)
		BEGIN
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				  ,('Selected Contract does not exist for Filing : ' + #InvalidContracts.FilingAlias) AS Message
				FROM 
					#InvalidContracts
		END
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Secured Legal Entity Number does not exist: '+ #LienFilingsMappedWithTarget.SecuredLegalEntityNumber + ' in Lien Filing ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
				FROM 
					#LienFilingsMappedWithTarget
			    WHERE #LienFilingsMappedWithTarget.SecuredLegalEntityId IS NULL AND  #LienFilingsMappedWithTarget.SecuredLegalEntityNumber IS NOT NULL AND  #LienFilingsMappedWithTarget.SecuredPartyType='LegalEntity'
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Secured Funder Party Number does not exist: '+ #LienFilingsMappedWithTarget.SecuredFunderPartyNumber + ' in Lien Filing ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
				FROM 
					#LienFilingsMappedWithTarget
			   WHERE #LienFilingsMappedWithTarget.SecuredFunderId IS NULL AND  #LienFilingsMappedWithTarget.SecuredFunderPartyNumber IS NOT NULL AND  #LienFilingsMappedWithTarget.SecuredPartyType='Funder'
		SELECT
			#LienFilingsMappedWithTarget.LienFilingId,#LienFilingsMappedWithTarget.FilingAlias,#LienFilingsMappedWithTarget.SecuredFunderPartyNumber INTO #InvalidSecuredFunderParties
		FROM 
			#LienFilingsMappedWithTarget 
			INNER JOIN Parties ON #LienFilingsMappedWithTarget.SecuredFunderId = Parties.Id
		WHERE 
			#LienFilingsMappedWithTarget.SecuredPartyType='Funder' AND #LienFilingsMappedWithTarget.SecuredFunderId NOT IN 
			( 
			SELECT PRT.PartyId FROM RemitToes RT
            INNER JOIN PartyRemitToes PRT ON RT.Id = PRT.RemitToId
            WHERE RT.IsActive = 1 AND RT.IsSecuredParty = 1
            GROUP BY PRT.PartyId 
			)
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				  ,('Atleast one RemitTo should be both Active and SecuredParty for the Selected Secured Funder Party Number : ' +IsNull(#InvalidSecuredFunderParties.SecuredFunderPartyNumber,'Null')) AS Message
				FROM 
					#InvalidSecuredFunderParties
		SELECT
			#LienFilingsMappedWithTarget.LienFilingId,#LienFilingsMappedWithTarget.FilingAlias,#LienFilingsMappedWithTarget.SecuredLegalEntityNumber INTO #InvalidSecuredLegalEntity
		FROM 
			#LienFilingsMappedWithTarget 
			INNER JOIN LegalEntities ON #LienFilingsMappedWithTarget.SecuredLegalEntityId = LegalEntities.Id
		WHERE 
			#LienFilingsMappedWithTarget.SecuredPartyType='LegalEntity' AND #LienFilingsMappedWithTarget.SecuredLegalEntityId NOT IN 
			( 
			SELECT LRT.LegalEntityId FROM RemitToes RT
            INNER JOIN LegalEntityRemitToes LRT ON RT.Id = LRT.RemitToId
            WHERE RT.IsActive = 1 AND RT.IsSecuredParty = 1
            GROUP BY LRT.LegalEntityId 
			)
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				  ,('Atleast one RemitTo should be both Active and SecuredParty for the Selected Secured Legal Entity Number : ' +IsNull(#InvalidSecuredLegalEntity.SecuredLegalEntityNumber,'Null')) AS Message
				FROM 
					#InvalidSecuredLegalEntity
		SELECT
			#LienAdditionalSecuredPartySubset.LienFilingId , #LienAdditionalSecuredPartySubset.SecuredFunderPartyNumber , #LienAdditionalSecuredPartySubset.LienFilingAlias 
			INTO #InvalidAdditionalFunders
		FROM 
			#LienAdditionalSecuredPartySubset 
			INNER JOIN #LienFilingsMappedWithTarget ON #LienAdditionalSecuredPartySubset.LienFilingId = #LienFilingsMappedWithTarget.LienFilingId
			INNER JOIN Funders ON #LienAdditionalSecuredPartySubset.SecuredFunderId = Funders.Id
			WHERE 
			#LienAdditionalSecuredPartySubset.SecuredPartyType='Funder' AND 
			((#LienFilingsMappedWithTarget.SecuredPartyType='Funder' AND Funders.Id =  #LienFilingsMappedWithTarget.SecuredFunderId ) OR Funders.Status != 'Active')
			Group By #LienAdditionalSecuredPartySubset.LienFilingId , #LienAdditionalSecuredPartySubset.SecuredFunderPartyNumber , #LienAdditionalSecuredPartySubset.LienFilingAlias 
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidAdditionalFunders ) > 0)
		BEGIN
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Secured Funder does not exist for Additional Secured Party : '+IsNull(#InvalidAdditionalFunders.SecuredFunderPartyNumber,'Null') + ' in Lien Filing ' + #InvalidAdditionalFunders.LienFilingAlias) AS Message
				FROM 
					#InvalidAdditionalFunders
		END
		SELECT
			#LienAdditionalSecuredPartySubset.LienFilingId , #LienAdditionalSecuredPartySubset.SecuredLegalEntityNumber , #LienAdditionalSecuredPartySubset.LienFilingAlias 
			INTO #InvalidAdditionalLegalEntities
		FROM 
			#LienAdditionalSecuredPartySubset 
			INNER JOIN #LienFilingsMappedWithTarget ON #LienAdditionalSecuredPartySubset.LienFilingId = #LienFilingsMappedWithTarget.LienFilingId
			INNER JOIN LegalEntities ON #LienAdditionalSecuredPartySubset.SecuredLegalEntityId = LegalEntities.Id
			WHERE 
			#LienAdditionalSecuredPartySubset.SecuredPartyType='LegalEntity' AND 
			((#LienFilingsMappedWithTarget.SecuredPartyType='LegalEntity' AND LegalEntities.Id =  #LienFilingsMappedWithTarget.SecuredLegalEntityId ) OR LegalEntities.Status != 'Active')
			Group By #LienAdditionalSecuredPartySubset.LienFilingId , #LienAdditionalSecuredPartySubset.SecuredLegalEntityNumber , #LienAdditionalSecuredPartySubset.LienFilingAlias  
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidAdditionalLegalEntities ) > 0)
		BEGIN
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Secured Legal Entity does not exist for Additional Secured Party : '+ ISNull(#InvalidAdditionalLegalEntities.SecuredLegalEntityNumber,'Null') + ' in Lien Filing ' + #InvalidAdditionalLegalEntities.LienFilingAlias) AS Message
				FROM 
					#InvalidAdditionalLegalEntities
		END
		SELECT
			#LienAdditionalDebtorSubset.LienFilingId , #LienAdditionalDebtorSubset.CustomerPartyNumber , #LienAdditionalDebtorSubset.LienFilingAlias
			 INTO #InvalidAdditionalCustomerDebtors
		FROM 
			#LienAdditionalDebtorSubset 
			INNER JOIN #LienFilingsMappedWithTarget ON #LienAdditionalDebtorSubset.LienFilingId = #LienFilingsMappedWithTarget.LienFilingId
			INNER JOIN Customers ON #LienAdditionalDebtorSubset.CustomerId = Customers.Id
			LEFT JOIN CustomerThirdPartyRelationships ON Customers.Id = CustomerThirdPartyRelationships.ThirdPartyId AND CustomerThirdPartyRelationships.RelationshipType = 'CoLessee'
			WHERE 
			#LienFilingsMappedWithTarget.EntityType = 'Customer' 
			AND (CustomerThirdPartyRelationships.CustomerId != Customers.Id 
			OR CustomerThirdPartyRelationships.ThirdPartyId = #LienFilingsMappedWithTarget.FirstDebtorId OR 
			Customers.Status != 'Active')
			GROUP BY #LienAdditionalDebtorSubset.LienFilingId , #LienAdditionalDebtorSubset.CustomerPartyNumber , #LienAdditionalDebtorSubset.LienFilingAlias
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidAdditionalCustomerDebtors)  > 0)
		BEGIN
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Additional debtor does not exist for Additional Secured Party : '+IsNull(#InvalidAdditionalCustomerDebtors.CustomerPartyNumber,'Null') + ' in Lien Filing ' + #InvalidAdditionalCustomerDebtors.LienFilingAlias) AS Message
				FROM 
					#InvalidAdditionalCustomerDebtors
		END
		SELECT
			#LienAdditionalDebtorSubset.LienFilingId , #LienAdditionalDebtorSubset.CustomerPartyNumber , #LienAdditionalDebtorSubset.LienFilingAlias
			 INTO #InvalidAdditionalContractDebtors
		FROM 
			#LienAdditionalDebtorSubset 
			INNER JOIN #LienFilingsMappedWithTarget ON #LienAdditionalDebtorSubset.LienFilingId = #LienFilingsMappedWithTarget.LienFilingId
			INNER JOIN Customers ON #LienAdditionalDebtorSubset.CustomerId = Customers.Id
			INNER JOIN CustomerThirdPartyRelationships ON Customers.Id = CustomerThirdPartyRelationships.ThirdPartyId
			INNER JOIN ContractThirdPartyRelationships ON CustomerThirdPartyRelationships.Id = ContractThirdPartyRelationships.ThirdPartyRelationshipId 
			LEFT JOIN LeaseFinances ON Customers.Id = LeaseFinances.CustomerId
			LEFT JOIN LoanFinances ON Customers.Id = LoanFinances.CustomerId
			WHERE 
			#LienFilingsMappedWithTarget.EntityType = 'Contract'  
				AND ( ContractThirdPartyRelationships.ContractId != #LienFilingsMappedWithTarget.ContractId OR
				ContractThirdPartyRelationships.IsActive = 0
				 OR CustomerThirdPartyRelationships.RelationshipType = 'CoLessee'
			OR CustomerThirdPartyRelationships.CustomerId != Customers.Id 
			OR CustomerThirdPartyRelationships.ThirdPartyId = #LienFilingsMappedWithTarget.FirstDebtorId OR 
			Customers.Status != 'Active')
			GROUP BY #LienAdditionalDebtorSubset.LienFilingId , #LienAdditionalDebtorSubset.CustomerPartyNumber , #LienAdditionalDebtorSubset.LienFilingAlias
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidAdditionalContractDebtors)  > 0)
		BEGIN
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Additional debtor does not exist for Additional Secured Party : '+IsNull(#InvalidAdditionalContractDebtors.CustomerPartyNumber,'Null') + ' in Lien Filing ' + #InvalidAdditionalContractDebtors.LienFilingAlias) AS Message
				FROM 
					#InvalidAdditionalContractDebtors
		END
		SELECT
			#LienCollateralSubset.LienFilingId , #LienCollateralSubset.AssetAlias , #LienCollateralSubset.LienFilingAlias
			 INTO #InvalidCustomerCollaterals
		FROM 
			#LienCollateralSubset 
			INNER JOIN #LienFilingsMappedWithTarget ON #LienCollateralSubset.LienFilingId = #LienFilingsMappedWithTarget.LienFilingId
			INNER JOIN Assets ON #LienCollateralSubset.AssetId = Assets.Id
			WHERE 
			#LienFilingsMappedWithTarget.EntityType = 'Customer'  	
				AND (Assets.CustomerId != #LienFilingsMappedWithTarget.CustomerId or Assets.Status IN ('Scrap','Error','Sold','Donated','WriteOff') )
			GROUP BY #LienCollateralSubset.LienFilingId , #LienCollateralSubset.AssetAlias , #LienCollateralSubset.LienFilingAlias
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidCustomerCollaterals)  > 0)
		BEGIN
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Asset Alias does not exist for Additional collateral : '+ #InvalidCustomerCollaterals.AssetAlias + ' in Lien Filing ' + #InvalidCustomerCollaterals.LienFilingAlias) AS Message
				FROM 
					#InvalidCustomerCollaterals
		END
		SELECT
			#LienCollateralSubset.LienFilingId , #LienCollateralSubset.AssetAlias , #LienCollateralSubset.LienFilingAlias
			 INTO #InvalidContractCollaterals
		FROM 
			#LienCollateralSubset 
			INNER JOIN #LienFilingsMappedWithTarget ON #LienCollateralSubset.LienFilingId = #LienFilingsMappedWithTarget.LienFilingId
			INNER JOIN Assets ON #LienCollateralSubset.AssetId = Assets.Id
			INNER JOIN Contracts ON #LienFilingsMappedWithTarget.ContractId = Contracts.Id
			LEFT JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
			LEFT JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
			WHERE 
			#LienFilingsMappedWithTarget.EntityType = 'Contract'  	AND ( Assets.Status IN ('Scrap','Error','Sold','Donated','WriteOff') OR
			(Contracts.ContractType = 'Lease' AND (Assets.CustomerId != LeaseFinances.CustomerId ) OR ((Contracts.ContractType = 'Loan' OR Contracts.ContractType = 'ProgressLoan' ) AND (Assets.CustomerId != LoanFinances.CustomerId ))))
			GROUP BY #LienCollateralSubset.LienFilingId , #LienCollateralSubset.AssetAlias , #LienCollateralSubset.LienFilingAlias
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidContractCollaterals)  > 0)
		BEGIN
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				 ,('Selected Asset Alias does not exist for Additional collateral : '+ #InvalidContractCollaterals.AssetAlias + ' in Lien Filing ' + #InvalidContractCollaterals.LienFilingAlias) AS Message
				FROM 
					#InvalidContractCollaterals
		END
		 INSERT INTO #ErrorLogs
				SELECT
				   LienFilingId
				  ,'Error'
				  ,('Invalid Secured Funder Party Number for Additional Secured Party : '+IsNull(#LienAdditionalSecuredPartySubset.SecuredFunderPartyNumber,'Null') + ' in Lien Filing : ' + #LienAdditionalSecuredPartySubset.LienFilingAlias) AS Message
				FROM 
					#LienAdditionalSecuredPartySubset
				WHERE
					 SecuredPartyType = 'Funder' AND SecuredFunderId IS NULL
		 INSERT INTO #ErrorLogs
				SELECT
				   LienFilingId
				  ,'Error'
				  ,('Invalid Secured Legal Entity Number for Additional Secured Party : '+IsNull(#LienAdditionalSecuredPartySubset.SecuredLegalEntityNumber,'Null') + ' in Lien Filing : ' + #LienAdditionalSecuredPartySubset.LienFilingAlias) AS Message
				FROM 
					#LienAdditionalSecuredPartySubset
				WHERE
					 SecuredPartyType = 'LegalEntity' AND SecuredLegalEntityId IS NULL
		SELECT
			#LienFilingsMappedWithTarget.LienFilingId , #LienFilingsMappedWithTarget.FilingAlias
			 INTO #InvalidFirstDebtors
		FROM 
			#LienFilingsMappedWithTarget
			INNER JOIN Customers ON #LienFilingsMappedWithTarget.FirstDebtorId = Customers.Id
		WHERE 
			#LienFilingsMappedWithTarget.EntityType='Customer' AND ( #LienFilingsMappedWithTarget.FirstDebtorId IS NULL OR Customers.Status != 'Active')
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidFirstDebtors)  > 0)
		BEGIN	
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				  ,('Selected First Debtor does not exist for Filing : ' + #InvalidFirstDebtors.FilingAlias) AS Message
				FROM 
					#InvalidFirstDebtors
		END
		SELECT
			#LienFilingsMappedWithTarget.LienFilingId , #LienFilingsMappedWithTarget.FilingAlias
			 INTO #InvalidFirstDebtorForContracts
		FROM 
			#LienFilingsMappedWithTarget 
			INNER JOIN Customers ON #LienFilingsMappedWithTarget.FirstDebtorId = Customers.Id
			LEFT JOIN CustomerThirdPartyRelationships ON Customers.Id = CustomerThirdPartyRelationships.ThirdPartyId AND CustomerThirdPartyRelationships.RelationshipType = 'CoLessee'
			LEFT JOIN ContractThirdPartyRelationships ON CustomerThirdPartyRelationships.Id = ContractThirdPartyRelationships.ThirdPartyRelationshipId 
		WHERE 
			#LienFilingsMappedWithTarget.EntityType='Contract' AND #LienFilingsMappedWithTarget.ContractId IS NOT NULL 
			AND ContractThirdPartyRelationships.ContractId = #LienFilingsMappedWithTarget.ContractId  AND ( ContractThirdPartyRelationships.IsActive = 0 OR Customers.Status != 'Active' )
		IF ((SELECT COUNT(LienFilingId) FROM #InvalidFirstDebtorForContracts)  > 0)
		BEGIN	
		INSERT INTO #ErrorLogs
				SELECT
					LienFilingId
				  ,'Error'
				  ,('Selected First Debtor does not exist for Filing : ' + #InvalidFirstDebtorForContracts.FilingAlias) AS Message
				FROM 
					#InvalidFirstDebtorForContracts
		END
		INSERT INTO #ErrorLogs
		SELECT
			LienFilingId
			,'Error'
			,('Invalid Alt Filing Type for Lien Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			@IsILien = 1 AND AltFilingType IS NOT NULL AND AltFilingType <> '_' AND AltFilingType NOT IN ('AgLien','NonUCCFiling','TransmittingUtility','ManufacturedHome','PublicFinance','FoodSecurityAct','FixtureFiling','NOAltType')
		INSERT INTO #ErrorLogs
		SELECT
			LienFilingId
			,'Error'
			,('Invalid Alt Name Designation for Lien Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			@IsILien = 1 AND AltNameDesignation IS NOT NULL AND AltNameDesignation <> '_' AND AltNameDesignation NOT IN ('Lessee_Lessor','Consignee_Consignor','Bailee_Bailor','Seller_Buyer','NOAltName')
		INSERT INTO #ErrorLogs
		SELECT
			LienFilingId
			,'Error'
			,('Invalid Attachment Type for Lien Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			@IsILien = 1 AND AttachmentType IS NOT NULL AND AttachmentType <> '_' AND AttachmentType NOT IN ('NoType','F','C','E','P')
		INSERT INTO #ErrorLogs
		SELECT
			LienFilingId
			,'Error'
			,('Only Approved Lien Filing can be migrated for Lien Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
				LienRefNumber IS NULL OR LienFilingStatus <> 'Approved'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Date Of Maturity cannot be null for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 DateOfMaturity IS NULL AND  IsNoFixedDate = 0 AND Type = 'PPSA'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Record Owner Name And Address does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 RecordOwnerNameAndAddress IS NULL AND IsFinancialStatementRequiredForRealEstate = 1
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Description does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 Description IS NULL AND IsFinancialStatementRequiredForRealEstate = 1
	    INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Filing Alias cannot contain special characters for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			FilingAlias like '%[^a-z 0-9]%'
       INSERT INTO #ErrorLogs
	   SELECT
		   #LienFilingsMappedWithTarget.LienFilingId
		  ,'Error'
		  ,('Lien Response should be available for: ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
	   FROM 
			#LienFilingsMappedWithTarget LEFT join  #LienResponseSubset  on #LienFilingsMappedWithTarget.LienFilingId=#LienResponseSubset.LienFilingId
	   WHERE
	      ( #LienResponseSubset.LienFilingId IS NULL AND #LienFilingsMappedWithTarget.LienFilingId is NOT NULL ) 
		SELECT #LienAdditionalDebtorSubset.CustomerId  INTO #InvalidDebtors FROM #LienAdditionalDebtorSubset
		JOIN Customers [Customer] ON #LienAdditionalDebtorSubset.CustomerId = Customer.Id
		LEFT JOIN BusinessTypes [BusinessType] on Customer.BusinessTypeId = BusinessType.Id
		LEFT JOIN ExternalBusinessTypeConfigs [ExternalBusinessType] on BusinessType.ExternalBusinessTypeId = ExternalBusinessType.Id
		WHERE ExternalBusinessType.Name IS NOT NULL 
			AND ExternalBusinessType.Name NOT IN (SELECT BusinessTypeName FROM @ExternalBusinessTypeConfig)
		SELECT #LienAdditionalSecuredPartySubset.SecuredLegalEntityId INTO #InvalidSecuredLegalEntites FROM #LienAdditionalSecuredPartySubset
		JOIN LegalEntities [LegalEntity] ON #LienAdditionalSecuredPartySubset.SecuredLegalEntityId = LegalEntity.Id
		LEFT JOIN BusinessTypes [BusinessType] on LegalEntity.BusinessTypeId = BusinessType.Id
		LEFT JOIN ExternalBusinessTypeConfigs [ExternalBusinessType] on BusinessType.ExternalBusinessTypeId = ExternalBusinessType.Id
		WHERE ExternalBusinessType.Name IS NOT NULL 
			AND ExternalBusinessType.Name NOT IN (SELECT BusinessTypeName FROM @ExternalBusinessTypeConfig)
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Business Type is not valid for  Debtors '+IsNull(#LienAdditionalDebtorSubset.CustomerPartyNumber,'Null')+ ' in Lien Filing ' + #LienAdditionalDebtorSubset.LienFilingAlias) AS Message
		FROM 
			#LienAdditionalDebtorSubset
		 WHERE 
		    CustomerId IN (SELECT CustomerId FROM #InvalidDebtors) 
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Amendment Type does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (AmendmentType IS NULL OR AmendmentType = '_') AND LienTransactions = 'Amendment'
		INSERT INTO #ErrorLogs
		SELECT
			LienFilingId
			,'Error'
			,('Invalid Amendment Type : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE LienTransactions = 'Amendment' AND
			(@IsILien = 1 AND  AmendmentType NOT IN ('AmendmentCollateral','AmendmentParties','Assignment','Continuation','TerminationSecuredParty','NOType') OR
			@IsILien = 0 AND  AmendmentType NOT IN ('DebtorAmendment','AmendmentCollateral','AmendmentParties','Assignment','Continuation','Termination','NOType'))
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Amendment Action does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (AmendmentAction IS NULL OR AmendmentAction = '_') AND LienTransactions = 'Amendment'
		INSERT INTO #ErrorLogs
		SELECT
			LienFilingId
			,'Error'
			,('Invalid Amendment Action : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			@IsILien  = 1 AND Type = 'UCC' AND Lientransactions = 'Amendment' AND
			((AmendmentType = 'AmendmentCollateral' AND AmendmentAction NOT IN ('CollateralAdd','CollateralChange','CollateralDelete')) OR
			(AmendmentType = 'AmendmentParties' AND AmendmentAction NOT IN ('DebtorAdd','DebtorChange','DebtorDelete')) OR
			(AmendmentType = 'Assignment' AND AmendmentAction NOT IN ('CollateralRestate','CollateralAssign')) OR
			(AmendmentType = 'Continuation' AND AmendmentAction NOT IN ('NOAction')) OR
			(AmendmentType IN('TerminationSecuredParty','NOType') AND AmendmentAction NOT IN ('SecuredPartyAdd','SecuredPartyChange','SecuredPartyDelete')))
	    INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Authorizing Party Type does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (AuthorizingPartyType IS NULL OR AuthorizingPartyType = '_') AND LienTransactions = 'Amendment'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Authorizing Funder Party Number does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 AuthorizingFunderId IS NULL AND LienTransactions ='Amendment' AND AuthorizingPartyType='Funder'
	    INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Authorizing Customer Party Number does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 AuthorizingCustomerId IS NULL AND LienTransactions ='Amendment' AND AuthorizingPartyType='Debtor'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Authorizing Legal Entity Number does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 AuthorizingLegalEntityId IS NULL AND LienTransactions ='Amendment' AND AuthorizingPartyType='LegalEntity'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		   ,('Business Type is not valid for Secured Legal Entity '+IsNull(#LienAdditionalSecuredPartySubset.SecuredLegalEntityNumber,'Null')+ ' in Lien Filing ' + #LienAdditionalSecuredPartySubset.LienFilingAlias) AS Message
		FROM 
			#LienAdditionalSecuredPartySubset
		 WHERE 
		    SecuredLegalEntityId IN (SELECT SecuredLegalEntityId FROM #InvalidSecuredLegalEntites)
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Customer does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 CustomerId IS NULL AND EntityType = 'Customer'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Contract does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 ContractId IS NULL AND EntityType = 'Contract'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Alias must be unique. Alias ('+#LienFilingWithAlias.FilingAlias+') already exists in Target') AS Message
		FROM 
			#LienFilingWithAlias	
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Customer status must be Active or Pending for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 CustomerId IS NOT NULL AND CustomerStatus != 'Active' AND CustomerStatus != 'Pending'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Secured Funder status must be Active or Pending for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 SecuredFunderId IS NOT NULL AND SecuredFunderStatus != 'Active' AND SecuredFunderStatus != 'Pending'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Secured Legal Entity status must be Active or Pending for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 SecuredLegalEntityId IS NOT NULL AND SecuredLegalEntityStatus != 'Active' AND SecuredLegalEntityStatus != 'Pending'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Authorized Debtor status must be Active or Pending for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 AuthorizingCustomerId IS NOT NULL AND AuthorizingCustomerStatus != 'Active' AND AuthorizingCustomerStatus != 'Pending'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Authorized Funder status must be Active or Pending for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 AuthorizingFunderId IS NOT NULL AND AuthorizingFunderStatus != 'Active' AND AuthorizingFunderStatus != 'Pending'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Authorized Legal Entity status must be Active or Pending for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 AuthorizingLegalEntityId IS NOT NULL AND AuthorizingLegalEntityStatus != 'Active' AND AuthorizingLegalEntityStatus != 'Pending'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Original Filing Alias does not exist for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			OriginalFilingRecordId IS NULL AND TransactionType = 'Amendment'
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected State is invalid for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 StateIsActive = 0 or CountryId IS NULL or StateId is Null 
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Initial File Date cannot be null for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias + 'of type : ' + #LienFilingsMappedWithTarget.TransactionType) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (TransactionType = 'InitialHISUCC1' OR TransactionType = 'AmendmentHISUCC3') AND InitialFileDate IS NULL AND @IsIlien = 0
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Initial File Number cannot be null for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias + 'of type : ' + #LienFilingsMappedWithTarget.TransactionType) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (TransactionType = 'InitialHISUCC1' OR TransactionType = 'AmendmentHISUCC3') AND InitialFileNumber IS NULL AND @IsIlien = 0
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Historical Expiration Date cannot be null for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias + 'of type : ' + #LienFilingsMappedWithTarget.TransactionType) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (TransactionType = 'InitialHISUCC1' OR TransactionType = 'AmendmentHISUCC3') AND HistoricalExpirationDate IS NULL AND @IsIlien = 0
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Financing Statement Date cannot be null for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias + 'of type : ' + #LienFilingsMappedWithTarget.TransactionType) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (TransactionType = 'AmendmentHISUCC3') AND FinancingStatementDate IS NULL AND @IsIlien = 0
		INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Financing Statement File Number cannot be null for Filing : ' + #LienFilingsMappedWithTarget.FilingAlias + 'of type : ' + #LienFilingsMappedWithTarget.TransactionType) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			 (TransactionType = 'AmendmentHISUCC3') AND FinancingStatementFileNumber IS NULL AND @IsIlien = 0
       INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected County is Invalid For Filing: ' + #LienFilingsMappedWithTarget.FilingAlias) AS Message
		FROM 
			#LienFilingsMappedWithTarget
		WHERE
			StateId IS Not NULL AND CountyId IS NULL 
	   INSERT INTO #ErrorLogs
		SELECT
		   LienFilingId
		  ,'Error'
		  ,('Selected Asset is Invalid For Filing: ' + #LienCollateralSubset.LienFilingAlias) AS Message
		FROM 
			#LienCollateralSubset 
		WHERE
			 AssetId IS NULL  
		MERGE LienFilings AS LienFiling
		USING (SELECT
				#LienFilingsMappedWithTarget.* ,#ErrorLogs.StagingRootEntityId
			   FROM
				#LienFilingsMappedWithTarget
			   LEFT JOIN #ErrorLogs
					  ON #LienFilingsMappedWithTarget.LienFilingId = #ErrorLogs.StagingRootEntityId) AS LienFilingsToMigrate
		ON (LienFiling.FilingAlias = LienFilingsToMigrate.FilingAlias) 
		WHEN MATCHED AND LienFilingsToMigrate.StagingRootEntityId IS NULL THEN
			UPDATE SET LienFiling.FilingAlias = LienFilingsToMigrate.FilingAlias
		WHEN NOT MATCHED AND LienFilingsToMigrate.StagingRootEntityId IS NULL
		THEN
		INSERT
		(
		FilingAlias
		,Type
		,EntityType
		,TransactionType
		,RecordType
		,AmendmentType
		,AmendmentAction
		,AmendmentRecordDate
		,SecuredPartyType
		,IsAssignee
		,CollateralText
		,CollateralClassification
		,InternalComment
		,PrincipalAmount_Amount
		,PrincipalAmount_Currency
		,IsNoFixedDate
		,DateOfMaturity
		,SigningPlace
		,SigningDate
		,IsAutoContinuation
		,AuthorizingPartyType
		,AltFilingType
		,AltNameDesignation
		,LienDebtorAltCapacity
		,IsManualUpdate
		,IsRenewalRecordGenerated
		,LienTransactions
		,LienRefNumber
		,SubmissionStatus
		,IsFloridaDocumentaryStampTax
		,MaximumIndebtednessAmount_Amount
		,MaximumIndebtednessAmount_Currency
		,LienFilingStatus
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,CustomerId
		,ContractId
		,FirstDebtorId
		,StateId
		,SecuredFunderId
		,SecuredLegalEntityId
		,OriginalFilingRecordId
		,AuthorizingCustomerId
		,AuthorizingFunderId
		,AuthorizingLegalEntityId
		,ContinuationRecordId
		,LienCollateralTemplateId
		,AttachmentURL
		,CountyId
		,FLTaxStamp
		,InDebType
		,AttachmentType
		,IncludeSerialNumberInAssetInformation
		,IsFinancialStatementRequiredForRealEstate
		,Description
		,RecordOwnerNameAndAddress
		,InitialFileDate
		,InitialFileNumber
		,HistoricalExpirationDate
		,FinancingStatementDate
		,FinancingStatementFileNumber
		,OriginalDebtorName
		,OriginalSecuredPartyName
		,IsUpdateFilingRequired
		,BusinessUnitId
		)
		VALUES
		(
		LienFilingsToMigrate.FilingAlias
		,LienFilingsToMigrate.Type
		,LienFilingsToMigrate.EntityType
		,LienFilingsToMigrate.TransactionType
		,LienFilingsToMigrate.RecordType
		,LienFilingsToMigrate.AmendmentType
		,LienFilingsToMigrate.AmendmentAction
		,LienFilingsToMigrate.AmendmentRecordDate
		,LienFilingsToMigrate.SecuredPartyType
		,LienFilingsToMigrate.IsAssignee
		,LienFilingsToMigrate.CollateralText
		,LienFilingsToMigrate.CollateralClassification
		,LienFilingsToMigrate.InternalComment
		,LienFilingsToMigrate.PrincipalAmount_Amount
		,LienFilingsToMigrate.PrincipalAmount_Currency
		,LienFilingsToMigrate.IsNoFixedDate
		,LienFilingsToMigrate.DateOfMaturity
		,LienFilingsToMigrate.SigningPlace
		,LienFilingsToMigrate.SigningDate
		,LienFilingsToMigrate.IsAutoContinuation
		,LienFilingsToMigrate.AuthorizingPartyType
		,LienFilingsToMigrate.AltFilingType
		,LienFilingsToMigrate.AltNameDesignation
		,LienFilingsToMigrate.LienDebtorAltCapacity
		,LienFilingsToMigrate.IsManualUpdate
		,0
		,LienFilingsToMigrate.LienTransactions
		,LienFilingsToMigrate.LienRefNumber
		,'Ok'
		,LienFilingsToMigrate.IsFloridaDocumentaryStampTax
		,LienFilingsToMigrate.MaximumIndebtednessAmount_Amount
		,LienFilingsToMigrate.MaximumIndebtednessAmount_Currency
		,LienFilingsToMigrate.LienFilingStatus
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,LienFilingsToMigrate.CustomerId
		,LienFilingsToMigrate.ContractId
		,LienFilingsToMigrate.FirstDebtorId
		,LienFilingsToMigrate.StateId
		,LienFilingsToMigrate.SecuredFunderId
		,LienFilingsToMigrate.SecuredLegalEntityId
		,LienFilingsToMigrate.OriginalFilingRecordId
		,LienFilingsToMigrate.AuthorizingCustomerId
		,LienFilingsToMigrate.AuthorizingFunderId
		,LienFilingsToMigrate.AuthorizingLegalEntityId
		,LienFilingsToMigrate.ContinuationRecordId
		,LienFilingsToMigrate.LienCollateralTemplateId
		,LienFilingsToMigrate.AttachmentURL
		,LienFilingsToMigrate.CountyId
	    ,LienFilingsToMigrate.FLTaxStamp
		,LienFilingsToMigrate.InDebType
		,LienFilingsToMigrate.AttachmentType
		,LienFilingsToMigrate.IncludeSerialNumberInAssetInformation
		,LienFilingsToMigrate.IsFinancialStatementRequiredForRealEstate
		,LienFilingsToMigrate.Description
		,LienFilingsToMigrate.RecordOwnerNameAndAddress
		,LienFilingsToMigrate.[InitialFileDate] 
		,LienFilingsToMigrate.[InitialFileNumber] 
		,LienFilingsToMigrate.[HistoricalExpirationDate]
		,LienFilingsToMigrate.[FinancingStatementDate] 
		,LienFilingsToMigrate.[FinancingStatementFileNumber]
		,LienFilingsToMigrate.OriginalDebtorName		
		,LienFilingsToMigrate.OriginalSecuredPartyName
		,0
		,LienFilingsToMigrate.[BusinessUnitId]
		)
		OUTPUT $action, Inserted.Id, LienFilingsToMigrate.LienFilingId INTO #CreatedLienFilingIds;
		UPDATE stgLienFiling SET IsMigrated = 1 WHERE Id IN (SELECT LienFilingId FROM #CreatedLienFilingIds)
		INSERT INTO LienSubmissionHistories
		(
		HistoryDate
		,SubmissionStatus
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,LienFilingId
		,SubmissionError
		)
		SELECT
		@CreatedTime
		,'Ok'
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,#CreatedLienFilingIds.InsertedId
		,NULL
		FROM #CreatedLienFilingIds
		INNER JOIN #LienFilingsMappedWithTarget
			ON #LienFilingsMappedWithTarget.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INSERT INTO LienResponses
		(
		Id
		,ExternalSystemNumber
		,ExternalRecordStatus
		,AuthorityFilingStatus
		,AuthoritySubmitDate
		,AuthorityFileNumber
		,AuthorityFileDate
		,AuthorityOriginalFileDate
		,AuthorityFileExpiryDate
		,AuthorityFilingOffice
		,AuthorityFilingType
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,AuthorityFilingStateId
		,ReasonReport_Source
		,ReasonReport_Type
		,ReasonReport_Content
		)
		SELECT
		#CreatedLienFilingIds.InsertedId
		,#LienResponseSubset.ExternalSystemNumber
		,CASE WHEN #LienResponseSubset.ExternalRecordStatus = 'Complete' THEN 'Completed'
			  ELSE #LienResponseSubset.ExternalRecordStatus END ExternalRecordStatus			
		,CASE WHEN #LienResponseSubset.AuthorityFilingStatus = 'Complete' THEN 'Completed'
			  ELSE #LienResponseSubset.AuthorityFilingStatus END AuthorityFilingStatus	
		,#LienResponseSubset.AuthoritySubmitDate
		,#LienResponseSubset.AuthorityFileNumber
		,#LienResponseSubset.AuthorityFileDate
		,#LienResponseSubset.AuthorityOriginalFileDate
		,#LienResponseSubset.AuthorityFileExpiryDate
		,#LienResponseSubset.AuthorityFilingOffice
		,#LienResponseSubset.AuthorityFilingType
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,#LienResponseSubset.AuthorityFilingStateId
		,NULL
		,NULL
		,NULL
		FROM #LienResponseSubset
		INNER JOIN #CreatedLienFilingIds
			ON #LienResponseSubset.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INNER JOIN #LienFilingsMappedWithTarget
			ON #LienFilingsMappedWithTarget.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INSERT INTO LienRecordStatusHistories
		(
		HistoryDate
		,RecordStatus
		,FilingType
		,FilingStatus
		,FileNumber
		,FileDate
		,OriginalFileDate
		,ExpiryDate
		,FilingOffice
		,RejectedReason
		,ResponseError
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,FilingStateId
		,LienFilingId
		)
		SELECT
		@CreatedTime
		,CASE WHEN #LienResponseSubset.ExternalRecordStatus = 'Complete' THEN 'Completed'
			  ELSE #LienResponseSubset.ExternalRecordStatus END RecordStatus	
		,#LienResponseSubset.AuthorityFilingType	  		
		,CASE WHEN #LienResponseSubset.AuthorityFilingStatus = 'Complete' THEN 'Completed'
			  ELSE #LienResponseSubset.AuthorityFilingStatus END FilingStatus	
		,#LienResponseSubset.AuthorityFileNumber
		,#LienResponseSubset.AuthorityFileDate
		,#LienResponseSubset.AuthorityOriginalFileDate
		,#LienResponseSubset.AuthorityFileExpiryDate
		,#LienResponseSubset.AuthorityFilingOffice
		,NULL
		,NULL	
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,#LienFilingsMappedWithTarget.StateId
		,#CreatedLienFilingIds.InsertedId
		FROM #LienResponseSubset
		INNER JOIN #CreatedLienFilingIds
			ON #LienResponseSubset.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INNER JOIN #LienFilingsMappedWithTarget
			ON #LienFilingsMappedWithTarget.LienFilingId = #CreatedLienFilingIds.LienFilingId AND IsManualUpdate = 1
		INSERT INTO LienCollaterals
		(
		IsActive
		,IsAssigned
		,IsRemoved
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,AssetId
		,LienFilingId
		,IsSerializedAsset
		)
		SELECT 
		#LienCollateralSubset.IsActive
		,#LienCollateralSubset.IsAssigned
		,#LienCollateralSubset.IsRemoved
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,#LienCollateralSubset.AssetId
		,#CreatedLienFilingIds.InsertedId
		,0
		FROM #LienCollateralSubset
		INNER JOIN #CreatedLienFilingIds
			ON #LienCollateralSubset.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INNER JOIN #LienFilingsMappedWithTarget
			ON #LienFilingsMappedWithTarget.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INSERT INTO LienAdditionalDebtors
		(
		IsActive
		,IsRemoved
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,CustomerId
		,LienFilingId
		,RelationshipType
		)
		SELECT
		#LienAdditionalDebtorSubset.IsActive
		,#LienAdditionalDebtorSubset.IsRemoved
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,#LienAdditionalDebtorSubset.CustomerId
		,#CreatedLienFilingIds.InsertedId
		,#LienAdditionalDebtorSubset.RelationshipType
		FROM #LienAdditionalDebtorSubset
		INNER JOIN #CreatedLienFilingIds
			ON #LienAdditionalDebtorSubset.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INNER JOIN #LienFilingsMappedWithTarget
			ON #LienFilingsMappedWithTarget.LienFilingId = #CreatedLienFilingIds.LienFilingId
      INSERT INTO LeaseLienFilings
	  (
	    IsActive
	    ,CreatedById
        ,CreatedTime
	    ,UpdatedById
	    ,UpdatedTime
	    ,LienFilingId
	    ,LeaseFinanceId
	  )
	  SELECT
	  1
	  ,@UserId
	  ,@CreatedTime
	  ,null
	  ,null
	  ,#CreatedLienFilingIds.InsertedId
	  ,LeaseFinances.Id
	  FROM #LienFilingContractSubset
	  INNER JOIN #CreatedLienFilingIds
	      ON #LienFilingContractSubset.LienFilingId=#CreatedLienFilingIds.LienFilingId
	  INNER JOIN Contracts on contracts.SequenceNumber=#LienFilingContractSubset.ContractSequenceNumber
	  INNER JOIN LeaseFinances on LeaseFinances.ContractId=Contracts.Id
	  where R_LeaseFinanceId IS NOT NULL
	  INSERT INTO LoanLienFilings
	  (
	    IsActive
	    ,CreatedById
        ,CreatedTime
	    ,UpdatedById
	    ,UpdatedTime
	    ,LienFilingId
	    ,LoanFinanceId
	  )
	  SELECT
	  1
	  ,@UserId
	  ,@CreatedTime
	  ,null
	  ,null
	  ,#CreatedLienFilingIds.InsertedId
	  ,LoanFinances.Id
	  FROM #LienFilingContractSubset
	  INNER JOIN #CreatedLienFilingIds
	      ON #LienFilingContractSubset.LienFilingId=#CreatedLienFilingIds.LienFilingId
	  INNER JOIN Contracts on contracts.SequenceNumber=#LienFilingContractSubset.ContractSequenceNumber
	  INNER JOIN LoanFinances on LoanFinances.ContractId=Contracts.Id
	  where R_LoanFinanceId IS NOT NULL
		INSERT INTO LienAdditionalSecuredParties
		(
		IsAssignor
		,IsRemoved
		,IsActive
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,SecuredFunderId
		,SecuredLegalEntityId
		,SecuredPartyType
		,LienFilingId
		)
		SELECT
		#LienAdditionalSecuredPartySubset.IsAssignor
		,#LienAdditionalSecuredPartySubset.IsRemoved
		,#LienAdditionalSecuredPartySubset.IsActive
		,@UserId
		,@CreatedTime
		,NULL
		,NULL
		,#LienAdditionalSecuredPartySubset.SecuredFunderId
		,#LienAdditionalSecuredPartySubset.SecuredLegalEntityId
		,#LienAdditionalSecuredPartySubset.SecuredPartyType
		,#CreatedLienFilingIds.InsertedId
		FROM #LienAdditionalSecuredPartySubset
		INNER JOIN #CreatedLienFilingIds
			ON #LienAdditionalSecuredPartySubset.LienFilingId = #CreatedLienFilingIds.LienFilingId
		INNER JOIN #LienFilingsMappedWithTarget
			ON #LienFilingsMappedWithTarget.LienFilingId = #CreatedLienFilingIds.LienFilingId
		MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				LienFilingId
			   FROM
				#CreatedLienFilingIds
			  ) AS ProcessedLienFilings
		ON (ProcessingLog.StagingRootEntityId = ProcessedLienFilings.LienFilingId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime
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
				ProcessedLienFilings.LienFilingId
			   ,@UserId
			   ,@CreatedTime
			   ,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
		INSERT INTO 
			stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			)
		SELECT
		    'Successful'
		   ,'Information'
		   ,@UserId
		   ,@CreatedTime
		   ,InsertedId
		FROM
			#CreatedProcessingLogs
	DROP TABLE #InvalidContracts
	DROP TABLE #InvalidSecuredFunderParties
	DROP TABLE #InvalidSecuredLegalEntity
	DROP TABLE #InvalidFirstDebtors
	DROP TABLE #InvalidFirstDebtorForContracts
	DROP TABLE #CreatedLienFilingIds
	DROP TABLE #LienFilingSubset
	DROP TABLE #LienFilingsMappedWithTarget
	DROP TABLE #LienResponseSubset
	DROP TABLE #LienCollateralSubset
	DROP TABLE #LienAdditionalDebtorSubset
	DROP TABLE #LienAdditionalSecuredPartySubset
	DROP TABLE #CreatedProcessingLogs	
	DROP TABLE #LienFilingWithAlias
	DROP TABLE #InvalidDebtors
	DROP TABLE #InvalidSecuredLegalEntites
	DROP TABLE #InvalidAdditionalFunders
	DROP TABLE #InvalidAdditionalLegalEntities
	DROP TABLE #InvalidAdditionalCustomerDebtors
	DROP TABLE #InvalidAdditionalContractDebtors
	DROP TABLE #InvalidCustomerCollaterals
	DROP TABLE #InvalidContractCollaterals
	DROP TABLE #LienFilingContractSubset
	SET @SkipCount = @SkipCount + @TakeCount
	MERGE stgProcessingLog AS ProcessingLog
		USING (SELECT
				 DISTINCT StagingRootEntityId
			   FROM
				#ErrorLogs 
			  ) AS ErrorLienFilings
		ON (ProcessingLog.StagingRootEntityId = ErrorLienFilings.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
		WHEN MATCHED THEN
			UPDATE SET UpdatedTime = @CreatedTime
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
				ErrorLienFilings.StagingRootEntityId
			   ,@UserId
			   ,@CreatedTime
			   ,@ModuleIterationStatusId
			)
		OUTPUT $action, Inserted.Id,ErrorLienFilings.StagingRootEntityId INTO #FailedProcessingLogs;	
		DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT InsertedId) FROM #FailedProcessingLogs)
		INSERT INTO 
			stgProcessingLogDetail
			(
				Message
			   ,Type
			   ,CreatedById
			   ,CreatedTime	
			   ,ProcessingLogId
			)
		SELECT
		    #ErrorLogs.Message
		   ,#ErrorLogs.Result
		   ,@UserId
		   ,@CreatedTime
		   ,#FailedProcessingLogs.InsertedId
		FROM
			#ErrorLogs
		INNER JOIN #FailedProcessingLogs
				ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.ErrorId
		SET @FailedRecords = @FailedRecords+(SELECT COUNT(DISTINCT StagingRootEntityId) FROM #ErrorLogs)
		DELETE #FailedProcessingLogs
		DELETE #ErrorLogs
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @SkipCount = @SkipCount  + @TakeCount;
	DECLARE @ErrorMessage Nvarchar(max);
	DECLARE @ErrorLine Nvarchar(max);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLogs ErrorMessageList;
	DECLARE @ModuleName Nvarchar(max) = 'LienFilingMigration'
	Insert into @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
	SELECT * FROM @ErrorLogs
	SELECT * FROM @ErrorLogs
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
SET @TransactionTypeCount = @TransactionTypeCount + 1
END

SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount
	DROP TABLE #TransactionType
	DROP TABLE #ErrorLogs
	DROP TABLE #FailedProcessingLogs
SET NOCOUNT OFF
SET XACT_ABORT OFF;
END

GO
