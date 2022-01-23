SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[FilterCollectionWorkLists]
(
	@PortfolioId				BIGINT,
	@BusinessUnitId				BIGINT,	
	@CurrentBusinessDate		DATE,
	@ShowAllAccounts			BIT,
	@ShowUnAssignedAccounts		BIT,
	@ShowMyWorkedAccounts		BIT,
	@ShowMyAccounts				BIT,
	@ShowFollowUpAccounts		BIT,
	@UserId						BIGINT,
	@CollectionWorklistStatusOpen	NVARCHAR(22),
	@CollectionWorklistStatusHibernation NVARCHAR(22),
	@CustomerName				NVARCHAR(500) = NULL,
	@CustomerAlias				NVARCHAR(80) = NULL,
	@PartyNumber				NVARCHAR(80) = NULL,
	@SSN4Digits					NVARCHAR(8) = NULL,
	@DoingBusinessAs			NVARCHAR(200) = NULL,
	@BankAccounts4Digits		NVARCHAR(8) = NULL,
	@ExternalPartyNumber		NVARCHAR(80) = NULL,
	@GuarantorName				NVARCHAR(500) = NULL,
	@ContactName				NVARCHAR(500) = NULL,
	@PhoneNumber				NVARCHAR(30) = NULL,
	@EMailId					NVARCHAR(140) = NULL,
	@CollectionStatus			NVARCHAR(200) = NULL,
	@CollectionQueue			NVARCHAR(80) = NULL,
	@CollectorName				NVARCHAR(40) = NULL,
	@SequenceNumber				NVARCHAR(80) = NULL,
	@ContractAlias				NVARCHAR(80) = NULL,
	@ExternalContractReferenceNumber NVARCHAR(80) = NULL,
	@InvoiceNumber				NVARCHAR(80) = NULL,
	@ReceivableCategoryPayoff	NVARCHAR(200) = NULL,
	@ReceivableCategoryAssetSale NVARCHAR(200) = NULL,
	@ReceivableCategoryPaydown	NVARCHAR(200) = NULL,
	@RelationshipTypeCorporateGuarantor NVARCHAR(200) = NULL,
	@RelationshipTypePersonalGuarantor NVARCHAR(200) = NULL
)
AS
BEGIN
	CREATE TABLE #EligibleCustomer
	(
		Id BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_EligbleCustomer ON #EligibleCustomer (Id);

	CREATE TABLE #EligibleWorklists
	(
		Id BIGINT
		,CustomerId BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_ElibileWorklist ON #EligibleWorklists (Id);
	CREATE NONCLUSTERED INDEX IX_Temp_ElibileWorklistCustomer ON #EligibleWorklists (CustomerId);

	CREATE TABLE #ThirdPartyEligibleCustomers
	(
		Id BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_ThirdPartyEligibleCustomer ON #ThirdPartyEligibleCustomers (Id);

	CREATE TABLE #ContactEligibleCustomers
	(
		Id BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_ContactEligibleCustomer ON #ContactEligibleCustomers (Id);

	CREATE TABLE #CustomersWithDoingBusinessAS
	(
		Id BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_DoingBusinessAS ON #CustomersWithDoingBusinessAS (Id);

	CREATE TABLE #CustomerBankAccounts
	(
		Id BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_BankAccount ON #CustomerBankAccounts (Id);

	IF(@ShowFollowUpAccounts = 1)
	BEGIN

		INSERT INTO #EligibleWorklists
		(
			Id
			,CustomerId
		)
		SELECT  DISTINCT 
			CollectionWorkLists.Id
			,CollectionWorkLists.CustomerId
		FROM Activities
			INNER JOIN ActivityForCollectionWorkLists
				ON Activities.Id = ActivityForCollectionWorkLists.Id 
			INNER JOIN CollectionWorkLists
				ON ActivityForCollectionWorkLists.CollectionWorkListId = CollectionWorkLists.Id
		WHERE 
			  Activities.OwnerId = @UserId 
			  AND Activities.IsActive = 1
			  AND Activities.CloseFollowUp = 0
			  AND Activities.IsFollowUpRequired = 1;

	END
	ELSE
	BEGIN

		INSERT INTO #EligibleWorklists
		(
			Id
			,CustomerId
		)
		SELECT 
			Id
			,CustomerId
		FROM
			CollectionWorkLists
		WHERE
			CollectionWorkLists.PortfolioId = @PortfolioId
			AND CollectionWorkLists.BusinessUnitId = @BusinessUnitId
			AND
			(
				(@ShowMyAccounts = 1 AND PrimaryCollectorId = @UserId AND Status = @CollectionWorklistStatusOpen)
				OR (@ShowAllAccounts = 1 AND Status IN (@CollectionWorklistStatusOpen, @CollectionWorklistStatusHibernation))
				OR (@ShowUnAssignedAccounts = 1 AND PrimaryCollectorId IS NULL AND Status = @CollectionWorklistStatusOpen)
				OR (@ShowMyWorkedAccounts = 1 AND PrimaryCollectorId = @UserId AND Status = @CollectionWorklistStatusHibernation)
			);
			
	END


	INSERT INTO #EligibleCustomer
	(
		Id
	)
	SELECT  DISTINCT 
		CustomerId
	FROM #EligibleWorklists;


	IF @GuarantorName IS NOT NULL
	BEGIN
		INSERT INTO #ThirdPartyEligibleCustomers
		(
			Id
		)
		SELECT 
			DISTINCT #EligibleCustomer.Id
		FROM
			 #EligibleCustomer
		INNER JOIN CustomerThirdPartyRelationships
			ON #EligibleCustomer.Id = CustomerThirdPartyRelationships.CustomerId
		INNER JOIN Parties ThirdParty
			ON ThirdParty.Id = CustomerThirdPartyRelationships.ThirdPartyId
		WHERE
			CustomerThirdPartyRelationships.RelationshipType IN (@RelationshipTypeCorporateGuarantor, @RelationshipTypePersonalGuarantor) AND
			(@GuarantorName IS NULL OR ThirdParty.PartyName LIKE '%'+@GuarantorName+'%')
	END


	IF (@ContactName IS NOT NULL OR @EMailId IS NOT NULL OR @PhoneNumber IS NOT NULL)
	BEGIN
		INSERT INTO #ContactEligibleCustomers
		(
			Id
		)
		SELECT
			DISTINCT #EligibleCustomer.Id
		FROM
			#EligibleCustomer
		INNER JOIN PartyContacts
			ON PartyContacts.PartyId = #EligibleCustomer.Id
		WHERE
			PartyContacts.IsActive = 1 AND
			(@EMailId IS NULL OR PartyContacts.EMailId LIKE '%'+@EMailId+'%') AND
			(@ContactName IS NULL OR PartyContacts.FullName LIKE '%'+@ContactName+'%') AND
			(@PhoneNumber IS NULL OR PartyContacts.PhoneNumber1 LIKE '%'+@PhoneNumber+'%' OR PartyContacts.PhoneNumber2 LIKE '%'+@PhoneNumber+'%')
	END

	
	IF (@DoingBusinessAs IS NOT NULL)
	BEGIN
		INSERT INTO #CustomersWithDoingBusinessAS
		(
			Id
		)
		SELECT
			#EligibleCustomer.Id
		FROM
			#EligibleCustomer
		INNER JOIN CustomerDoingBusinessAs
			ON #EligibleCustomer.Id = CustomerDoingBusinessAs.CustomerId
		WHERE
			CustomerDoingBusinessAs.IsActive = 1 AND
			(@DoingBusinessAs IS NULL OR CustomerDoingBusinessAs.DoingBusinessAsName LIKE '%'+@DoingBusinessAs+'%')
	END


	IF (@BankAccounts4Digits IS NOT NULL)
	BEGIN
		INSERT INTO #CustomerBankAccounts
		(
			Id
		)
		SELECT
			#EligibleCustomer.Id
		FROM
			#EligibleCustomer
		INNER JOIN PartyBankAccounts
			ON #EligibleCustomer.Id = PartyBankAccounts.PartyId 
		INNER JOIN BankAccounts
			ON BankAccounts.Id = PartyBankAccounts.BankAccountId
		WHERE
			BankAccounts.IsActive = 1 AND
			(@BankAccounts4Digits IS NULL OR BankAccounts.LastFourDigitAccountNumber = @BankAccounts4Digits)
	END

	CREATE TABLE #WorkListFilteredByCustomer
	(
		Id BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_FilteredCustomer ON #WorkListFilteredByCustomer (Id);

	INSERT INTO #WorkListFilteredByCustomer
	(
		Id
	)
	SELECT DISTINCT
		CollectionWorkLists.Id 
	FROM
		#EligibleCustomer
	INNER JOIN Parties	
		ON #EligibleCustomer.Id = Parties.Id
	INNER JOIN Customers
		ON Parties.Id = Customers.Id
	INNER JOIN #EligibleWorklists
		ON #EligibleCustomer.Id = #EligibleWorklists.CustomerId
	INNER JOIN CollectionWorkLists
		ON CollectionWorkLists.Id = #EligibleWorklists.Id
	LEFT JOIN CollectionStatus
		ON Customers.CollectionStatusId = CollectionStatus.Id
	LEFT JOIN CollectionQueues
		ON CollectionWorkLists.CollectionQueueId = CollectionQueues.Id
	LEFT JOIN Users
		ON CollectionWorkLists.PrimaryCollectorId = Users.Id
	LEFT JOIN #ThirdPartyEligibleCustomers
		ON #EligibleCustomer.Id = #ThirdPartyEligibleCustomers.Id
	LEFT JOIN #CustomerBankAccounts
		ON #CustomerBankAccounts.Id = #EligibleCustomer.Id
	LEFT JOIN #CustomersWithDoingBusinessAS
		ON #CustomersWithDoingBusinessAS.Id = #EligibleCustomer.Id
	LEFT JOIN #ContactEligibleCustomers
		ON #ContactEligibleCustomers.Id = #EligibleCustomer.Id
	WHERE
		(@CustomerName IS NULL OR Parties.PartyName LIKE '%'+@CustomerName+'%') AND
		(@PartyNumber IS NULL OR Parties.PartyNumber LIKE '%'+@PartyNumber+'%') AND
		(@ExternalPartyNumber IS NULL OR Parties.ExternalPartyNumber LIKE '%'+@ExternalPartyNumber+'%') AND
		(@CustomerAlias IS NULL OR Parties.Alias LIKE '%'+@CustomerAlias+'%') AND
		(@SSN4Digits IS NULL OR Parties.LastFourDigitUniqueIdentificationNumber = @SSN4Digits) AND
		(@CollectionStatus IS NULL OR CollectionStatus.Name LIKE '%'+@CollectionStatus+'%') AND
		(@CollectionQueue IS NULL OR CollectionQueues.Name LIKE '%'+@CollectionQueue+'%') AND
		(@CollectorName IS NULL OR Users.LoginName LIKE '%'+@CollectorName+'%') AND
		(@GuarantorName IS NULL OR #ThirdPartyEligibleCustomers.Id IS NOT NULL) AND
		(@BankAccounts4Digits IS NULL OR #CustomerBankAccounts.Id IS NOT NULL) AND
		(@DoingBusinessAs IS NULL OR #CustomersWithDoingBusinessAS.Id IS NOT NULL) AND
		((@ContactName IS NULL AND @EMailId IS NULL AND @PhoneNumber IS NULL) OR #ContactEligibleCustomers.Id IS NOT NULL);
		

	CREATE TABLE #WorkListFilteredByContract
	(
		Id BIGINT
	)
	CREATE CLUSTERED INDEX IX_Temp_WorkListFilteredByContract ON #WorkListFilteredByContract (Id);

	IF (@SequenceNumber IS NOT NULL OR @ExternalContractReferenceNumber IS NOT NULL OR @ContractAlias IS nOT NULL)
	BEGIN

		INSERT INTO #WorkListFilteredByContract
		(
			Id
		)
		SELECT DISTINCT
			#WorkListFilteredByCustomer.Id
		FROM
			#WorkListFilteredByCustomer
		INNER JOIN CollectionWorkListContractDetails
			ON #WorkListFilteredByCustomer.Id =  CollectionWorkListContractDetails.CollectionWorkListId
		INNER JOIN Contracts
			ON CollectionWorkListContractDetails.ContractId = Contracts.Id
		WHERE	
			CollectionWorkListContractDetails.IsWorkCompleted = 0 AND
			(@SequenceNumber IS NULL OR Contracts.SequenceNumber LIKE '%'+@SequenceNumber+'%') AND
			(@ExternalContractReferenceNumber IS NULL OR Contracts.ExternalReferenceNumber LIKE '%'+@ExternalContractReferenceNumber+'%') AND
			(@ContractAlias IS NULL OR Contracts.Alias LIKE '%'+@ContractAlias+'%')
	END
	ELSE
	BEGIN
		INSERT INTO #WorkListFilteredByContract
		(
			Id
		)
		SELECT 
			#WorkListFilteredByCustomer.Id
		FROM
			#WorkListFilteredByCustomer
	END

	IF (@InvoiceNumber IS NOT NULL)
	BEGIN
		SELECT DISTINCT
			#WorkListFilteredByContract.Id AS CollectionWorkListId
		FROM 
			#WorkListFilteredByContract
		INNER JOIN CollectionWorkListContractDetails
			ON CollectionWorkListContractDetails.CollectionWorkListId = #WorkListFilteredByContract.Id
		INNER JOIN ReceivableInvoiceDetails
			ON ReceivableInvoiceDetails.EntityId = CollectionWorkListContractDetails.ContractId AND
			   ReceivableInvoiceDetails.EntityType = 'CT' 
		INNER JOIN ReceivableInvoices
			ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
		INNER JOIN ReceivableDetails
			ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id 
		INNER JOIN Receivables
			ON ReceivableDetails.ReceivableId = Receivables.Id
		INNER JOIN ReceivableCodes
			ON Receivables.ReceivableCodeId = ReceivableCodes.Id
		INNER JOIN ReceivableCategories
			ON ReceivableCodes.ReceivableCategoryId = ReceivableCategories.Id
		INNER JOIN LegalEntities
			ON ReceivableInvoices.LegalEntityId = LegalEntities.Id
		WHERE
			ReceivableInvoiceDetails.IsActive = 1 AND
			(ReceivableInvoices.IsDummy = 0 OR (ReceivableInvoices.IsDummy = 1 AND Receivablecategories.Name NOT IN (@ReceivableCategoryPayoff, @ReceivableCategoryAssetSale, @ReceivableCategoryPaydown))) AND DATEADD(day, LegalEntities.ThresholdDays, ReceivableInvoices.DueDate) <= @CurrentBusinessDate AND (ReceivableInvoiceDetails.Balance_Amount > 0 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0) AND
			(@InvoiceNumber IS NULL OR ReceivableInvoices.Number LIKE '%'+@InvoiceNumber+'%')
	END
	ELSE 
	BEGIN
		SELECT DISTINCT
			#WorkListFilteredByContract.Id AS CollectionWorkListId
		FROM
			#WorkListFilteredByContract
	END
END

GO
