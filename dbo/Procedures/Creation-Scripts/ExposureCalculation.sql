SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ExposureCalculation]
(
	@AsOfDate DATE = NULL
	,@CustomerId BIGINT = NULL
	,@CreatedById BIGINT
	,@CreatedTime DATETIMEOFFSET
	,@IsCDCEnabled BIT
	,@DefaultCurrency NVARCHAR(3)
)
AS
BEGIN
SET NOCOUNT ON
--DECLARE	@return_value int

--EXEC	@return_value = [dbo].[ExposureCalculation]
--		@AsOfDate = '10/25/2018',
--		@CustomerId = NULL,
--		@CreatedById = 1,
--		@CreatedTime = '10/25/2018',
--		@IsCDCEnabled = 0,
--@DefaultCurrency = 'USD'

--SELECT	'Return Value' = @return_value						

--DROP TABLE #IndirectCustomersUnallocated
--DROP TABLE #CustomerExposure
--DROP TABLE #ExposureTypes
--DROP TABLE #DealExposure
--DROP TABLE #LOCContractLevel
--DROP TABLE #CustomerUnallocated
--DROP TABLE #CustomerUnallocatedSecDep
--DROP TABLE #CustomerUnallocatedSecDepOSAR
--DROP TABLE #LatestRNI
--DROP TABLE #IndirectCustomerPrimaryDeals
--DROP TABLE #IndirectCustomers
--DROP TABLE #CustomersRelationship
--DROP TABLE #ParentChildCustomerPrimaryDeals
--DROP TABLE #IndirectCustomersRelationship
--DROP TABLE #IndirectParentChildCustomerPrimaryDeals
--DROP TABLE #ExposureTypesForDealExposure
--DROP TABLE #DealExposureCustomers
--DROP TABLE #InDirectCustomersToDelete
--DROP TABLE #AllCustomersForContract
--DROP TABLE #RNItoReduceFromCurrentCustomer
--DROP TABLE #ContractCustomers
--DROP TABLE #AssumptionTable
--DROP TABLE #LatestRNIToProcess
--DROP TABLE #IndirectCustomersUnallocated
--DROP TABLE #CustomerExposure
--DROP TABLE #LOCUsedAmount
--DROP TABLE #TotalFinancedAmount

--DECLARE	@AsOfDate DATE = DATE()
--DECLARE	@CustomerId BIGINT = 20
--DECLARE	@CreatedById BIGINT = 1
--DECLARE	@CreatedTime DATETIMEOFFSET = GETDATE()
--DECLARE @DefaultCurrency NVARCHAR(3) = 'USD'

--IF @CustomerId IS NULL
--BEGIN
	--UPDATE DealExposures SET IsActive = 0
	--UPDATE CustomerExposures SET IsActive = 0
--END
--ELSE IF @CustomerId IS NOT NULL
--BEGIN	
--	UPDATE DealExposures SET IsActive = 0 WHERE CustomerID = @CustomerId
--	UPDATE CustomerExposures SET IsActive = 0 WHERE CustomerID = @CustomerId
--END

--IF @IsCDCEnabled = 1
--BEGIN

--DECLARE @rolename sysname ='cdc_admin';

--/*To disable cdc for a table*/
--EXECUTE AS USER = 'cdc'
--EXEC sys.sp_cdc_disable_table 
--@source_schema = 'dbo'
--,@source_name = 'DealExposures'
--,@capture_instance ='all'
--REVERT

--/*Execute the sql commands that is needed to perform your task*/
--	TRUNCATE TABLE DealExposures

--/*To enable cdc for a table*/
--EXECUTE AS USER = 'cdc'
--EXEC sys.sp_cdc_enable_table 
--@source_schema ='dbo'
--,@source_name='DealExposures'
--,@role_name = @rolename
--,@supports_net_changes=0
--REVERT

--/*To disable cdc for a table*/
--EXECUTE AS USER = 'cdc'
--EXEC sys.sp_cdc_disable_table 
--@source_schema = 'dbo'
--,@source_name = 'CustomerExposures'  
--,@capture_instance ='all'
--REVERT

--/*Execute the sql commands that is needed to perform your task*/
--	TRUNCATE TABLE  CustomerExposures

--/*To enable cdc for a table*/
--EXECUTE AS USER = 'cdc'
--EXEC sys.sp_cdc_enable_table 
--@source_schema ='dbo'
--,@source_name='CustomerExposures'
--,@role_name = @rolename
--,@supports_net_changes=0
--REVERT

--END
--ELSE
--BEGIN
--	TRUNCATE TABLE DealExposures
--	TRUNCATE TABLE CustomerExposures
--END

--DELETE DealExposures
--DELETE CustomerExposures

CREATE TABLE #ExposureTypes 
(
	CustomerId BIGINT
	,ExposureType NVARCHAR(100)
	,RelationType NVARCHAR(100)
	,IsCorporateGaranter TINYINT
	,RelationShipPercentage DECIMAL(18,6)
	,EntityId BIGINT
	,EntityType NVARCHAR(100)
	,IsLoc TINYINT 
	,ExposureCustomerId BIGINT
)

CREATE TABLE #ExposureTypesForDealExposure
(
	CustomerId BIGINT
	,ExposureType NVARCHAR(100)
	,RelationType NVARCHAR(100)
	,RelationShipPercentage DECIMAL(18,6)
	,EntityId BIGINT
	,EntityType NVARCHAR(100)
	,IsLoc TINYINT 
	,ExposureCustomerId BIGINT
)

CREATE TABLE #CustomersRelationship
(
	ExposureCustomerId BIGINT
	,CustomerId BIGINT
	,RelationType NVARCHAR(100)
	,ParentChildCustomerId BIGINT
	,IsLoc BIT
)
CREATE INDEX IX_CustomerId_IsLoc_RelationType_ExposureCustomerId ON #CustomersRelationship (CustomerId,IsLoc,RelationType,ExposureCustomerId)


CREATE TABLE #ParentChildCustomerPrimaryDeals
(
	CustomerId BIGINT
	,ContractID BIGINT
	,ContractType NVARCHAR(100)
	,ExposureCustomerId BIGINT
	,IsLoc BIT
)
CREATE TABLE #IndirectCustomersRelationship
(
	ExposureCustomerId BIGINT
	,CustomerId BIGINT
	,RelationType NVARCHAR(100)
	,ParentChildCustomerId BIGINT
	,IsLoc BIT
)

CREATE TABLE #IndirectParentChildCustomerPrimaryDeals
(
	CustomerId BIGINT
	,ContractID BIGINT
	,ContractType NVARCHAR(100)
	,ExposureCustomerId BIGINT
	,IsLoc BIT
)
CREATE TABLE #DealExposure
(
	CustomerID BIGINT NOT NULL
	,EntityID  BIGINT NOT NULL
	,EntityType NVARCHAR(100) NOT NULL
	,ExposureDate DATETIME NOT NULL
	,ExposureType NVARCHAR(100) NOT NULL
	,RelationshipPercentage DECIMAL(18,6) NULl
	,RNIID BIGINT NULL
	,CommencedDealRNI_Amount Decimal(24,2) NULL
	,OTPLeaseRNI_Amount Decimal(24,2) NULL
	,UncommencedDealRNI_Amount Decimal(24,2) NULL
	,LOCBalanceRevolving_Amount Decimal(24,2) NULL
	,LOCBalanceNonRevolving_Amount Decimal(24,2) NULL
	,ExposureCustomerId BIGINT
)

CREATE TABLE #LOCContractLevel
(
	LOCId BIGINT
	,ContractId BIGINT
	,Status NVARCHAR(100)
	,ContractType NVARCHAR(100)
	,SubType  NVARCHAR(100)
	,UsedLineRevolvingAmount Decimal(24,2)
	,UsedLineNonRevolvingAmount Decimal(24,2)
	,UsedLineRevolvingAmountForExpBalance DECIMAL(18,2)
	,UsedLineNonRevolvingAmountForExpBalance DECIMAL(18,2)
)

CREATE TABLE #CustomerUnallocated (CustomerId BIGINT,Amount Decimal(24,2))
CREATE TABLE #CustomerUnallocatedSecDep (CustomerId BIGINT,Amount Decimal(24,2))
CREATE TABLE #CustomerUnallocatedSecDepOSAR (CustomerId BIGINT,Amount Decimal(24,2))

CREATE TABLE #LatestRNI
(
	ContractId BIGINT
	,RNIId BIGINT
	,CreditProfileId BIGINT
	,IncomeDate DATETIME
	,ContractType NVARCHAR(100)
	,RNIAmount Decimal(24,2)
	,IsOTP BIT
	,CurrencyId INT
	,SubType NVARCHAR(50)
	,Status NVARCHAR(50)
	,UnchangedRNIAmount_Amount Decimal(24,2)
)

CREATE TABLE #DealExposureCustomers
(
	ExposureCustomerId BIGINT
	,CustomerId BIGINT
	,Isindirect TINYINT
)

CREATE TABLE #AssumptionTable 
(
	 ContractId BIGINT
	,CustomerId BIGINT
	,ContractType NVARCHAR(28)
	,IsRNI BIT
)

CREATE TABLE #AllCustomersForContract
(
ContractId BIGINT
,CustomerId BIGINT
,RNIAmount Decimal(24,2)
,IsRNI BIT
)

CREATE TABLE #LatestRNIToProcess
(
	ContractId BIGINT
	,RNIId BIGINT
	,CreditProfileId BIGINT
	,IncomeDate DATETIME
	,ContractType NVARCHAR(100)
	,RNIAmount Decimal(24,2)
	,CustomerId BIGINT
	,IsOTP BIT
	,CurrencyId INT
	,SubType NVARCHAR(50)
	,Status NVARCHAR(50)
	,UnchangedRNIAmount_Amount Decimal(24,2)
)

CREATE TABLE #RNItoReduceFromCurrentCustomer
(
ContractId BIGINT
,Amount Decimal(24,2)
)

CREATE TABLE #ContractCustomers
(
ContractId BIGINT
,CustomerId BIGINT
,ContractType NVARCHAR(50)
)

CREATE TABLE #IndirectCustomersUnallocated
(
ExposureCustomerId BIGINT
,IndirectCustomerId BIGINT
,UnallocatedAmount Decimal(24,2)
,SecurityDepositAmount Decimal(24,2)
,SecurityDepositOSARAmount Decimal(24,2)
)

CREATE TABLE #CustomerExposure (ExposureCustomerId BIGINT)

CREATE TABLE #LOCUsedAmount
(
	LOCId BIGINT
	,UsedLineRevolvingAmt DECIMAL(18,2)
	,UsedLineNonRevolvingAmt DECIMAL(18,2)
	,UsedLineRevolvingAmtForExposure DECIMAL(18,2)
	,UsedLineNonRevolvingAmtForExposure DECIMAL(18,2)
)

CREATE TABLE #TotalFinancedAmount
(
	ContractId BIGINT
	,Amount DECIMAL(18,2)
)

CREATE TABLE #FutureFundedAmount
(
	CreditProfileId BIGINT
	,FutureFundedAmount DECIMAL(18,2)
)

DECLARE @ExposureDate DATETIME 
--SELECT TOP 1 @ExposureDate = CurrentBusinessDate FROM BusinessUnits ORDER BY Id DESC
SET @ExposureDate = @AsOfDate;


DECLARE @ExposureCurrency NVARCHAR(3) = @DefaultCurrency;
DECLARE @ExposureCurrencyId BIGINT
SELECT @ExposureCurrencyId=Currencies.Id FROM Currencies 
JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
AND CurrencyCodes.ISO=@ExposureCurrency AND Currencies.IsActive = 1;

/* To update customerId in RNI tables */
INSERT INTO #ContractCustomers
SELECT ContractId,CustomerId,ContractType 
FROM 
	(SELECT ContractId,CustomerId,Contracts.ContractType
	FROM LeaseFinances
	JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id 
	AND IsCurrent = 1 AND (@CustomerId IS NULL OR LeaseFinances.CustomerId = @CustomerId)
	UNION ALL
	SELECT ContractId,CustomerId,Contracts.ContractType
	FROM LoanFinances 
	JOIN Contracts ON LoanFinances.ContractId = Contracts.Id 
	AND IsCurrent = 1 AND (@CustomerId IS NULL OR LoanFinances.CustomerId = @CustomerId) 
	UNION ALL
	SELECT ContractId,CustomerId,Contracts.ContractType 
	FROM LeveragedLeases
	JOIN Contracts ON LeveragedLeases.ContractId = Contracts.Id
	AND IsCurrent = 1 AND (@CustomerId IS NULL OR LeveragedLeases.CustomerId = @CustomerId))

AS Contracts

/* To get Assumed Contracts. Exclude these contracts from current routine */

INSERT INTO #AssumptionTable(ContractId,CustomerId,ContractType,IsRNI)
SELECT a.ContractId,a.OriginalCustomerId,ContractType,0 FROM Assumptions a
WHERE a.Status='Approved' 

INSERT INTO #AssumptionTable(ContractId,CustomerId,ContractType,IsRNI)
SELECT a.ContractId,a.NewCustomerId,a.ContractType,1 FROM Assumptions a
WHERE a.Status='Approved' AND a.Id IN (SELECT MAX(Id) FROM Assumptions WHERE Status='Approved' GROUP BY ContractId)

/* END - Assumed Contracts */

/* START - To maintain latest incomedate RNI records */

INSERT INTO #LatestRNI
SELECT RNI.ContractId,RNI.RNIID,RNI.CreditProfileId,RNI.IncomeDate,RNI.ContractType,RNI.RNIAmount_Amount,IsOTP,CurrencyId,SubType,Status,RNI.RNIAmount_Amount
FROM
(
SELECT ROW_NUMBER() OVER (PARTITION BY RNI.ContractId ORDER by RNI.Id DESC) RowId,
	RNI.Id RNIID,
	RNI.ContractId,
	RNI.IncomeDate,
	RNI.RNIAmount_Amount,
	RNI.CreditProfileId,
	RNI.ContractType,
	IsOTP,
	CurrencyId,
	SubType,
	Status
FROM RemainingNetInvestments RNI 
WHERE IsActive = 1
) RNI
WHERE RNI.RowId = 1

/* END - To maintain latest incomedate RNI records */

/* START - Security Deposit and UnAllocated cash for CUstomer Level */

;WITH CTE_CustomerUnallocated AS
(
SELECT CustomerId, SUM(R.Balance_Amount) CustomerUnallocated,R.CurrencyId
FROM Receipts R 
JOIN ReceiptAllocations RA ON R.Id = RA.ReceiptId
AND R.EntityType = 'Customer' AND RA.EntityType= 'Unallocated' AND RA.IsActive = 1 AND Status !='Reversed'
GROUP BY R.CustomerId,R.CurrencyId
)
,CTE_Grouped AS
(
SELECT CustomerId, CASE WHEN currencyId != @ExposureCurrencyId THEN dbo.CalculateAmtInTargetCurrency(currencyId,@ExposureCurrencyId,CustomerUnallocated) ELSE CustomerUnallocated END Amount
FROM CTE_CustomerUnallocated 
)
INSERT INTO #CustomerUnallocated
SELECT CustomerId,SUM(Amount) FROM CTE_Grouped GROUP BY CustomerId

;WITH CTE_CustomerUnallocatedSecDep AS
(
SELECT SD.CustomerId , SUM(SDA.Amount_Amount) CustomerUnallocatedSecDep,SD.CurrencyId
FROM SecurityDepositAllocations SDA 
JOIN SecurityDeposits SD ON SDA.SecurityDepositId = SD.Id 
AND SDA.EntityType='Unallocated' and SD.IsActive = 1
GROUP BY SD.CustomerId,SD.CurrencyId
)
,CTE_Grouped AS
(
SELECT CustomerId,dbo.CalculateAmtInTargetCurrency(currencyId,@ExposureCurrencyId,CustomerUnallocatedSecDep) Amount
FROM CTE_CustomerUnallocatedSecDep 
)
INSERT INTO #CustomerUnallocatedSecDep
SELECT CustomerId,SUM(Amount) FROM CTE_Grouped GROUP BY CustomerId

;WITH CTE_CustomerUnallocatedSecDepOSAR AS
(
SELECT SD.CustomerId ,SUM(R.TotalBalance_Amount) CustomerUnallocatedSecDepOSAR,SD.CurrencyId
FROM SecurityDeposits SD 
JOIN Receivables R ON SD.ReceivableId = R.Id AND R.IsActive = 1
AND R.EntityType='CU'  and SD.IsActive = 1 
GROUP BY SD.CustomerId,SD.CurrencyId
)
,CTE_Grouped AS
(
SELECT CustomerId,dbo.CalculateAmtInTargetCurrency(currencyId,@ExposureCurrencyId,CustomerUnallocatedSecDepOSAR) Amount
FROM CTE_CustomerUnallocatedSecDepOSAR 
)
INSERT INTO #CustomerUnallocatedSecDepOSAR
SELECT CustomerId,SUM(Amount) FROM CTE_Grouped GROUP BY CustomerId

/* END - Security Deposit and UnAllocated cash for CUstomer Level */

/* START - Customer Relationship */
/* START - Primary Customer deals */

IF @CustomerId IS NULL
BEGIN
	INSERT INTO #ExposureTypes 
	SELECT CustomerId CustomerId,'PrimaryCustomer','PrimaryCustomer' ,0,100.00,ContractId,ContractType,0,CustomerId
	FROM #ContractCustomers; 

	/* If customer does not have any primary contracts */
	INSERT INTO #ExposureTypes 
	SELECT NULL CustomerId,'PrimaryCustomer','PrimaryCustomer' ,0,100.00,0,'Dummy',0,Customers.Id
	FROM Customers 
	WHERE NOT EXISTS(SELECT 1 FROM #ExposureTypes WHERE CustomerId = Customers.Id);
END
ELSE
BEGIN
	INSERT INTO #ExposureTypes 
	SELECT CustomerId CustomerId,'PrimaryCustomer','PrimaryCustomer' ,0,100.00,ContractId,ContractType,0,CustomerId
	FROM #ContractCustomers 
	WHERE CustomerId = @CustomerId;

	/* If customer does not have any primary contracts */
	INSERT INTO #ExposureTypes 
	SELECT NULL CustomerId,'PrimaryCustomer','PrimaryCustomer' ,0,100.00,0,'Dummy',0,Customers.Id
	FROM Customers 
	WHERE NOT EXISTS(SELECT 1 FROM #ExposureTypes WHERE CustomerId = Customers.Id) 
	AND Customers.Id = @CustomerId;
END

--Assumption contracts
INSERT INTO #ExposureTypes 
SELECT #AssumptionTable.CustomerId CustomerId,'PrimaryCustomer','PrimaryCustomer' ,0,100.00,ContractId,#AssumptionTable.ContractType,0,CustomerId
FROM #AssumptionTable
WHERE IsRNI = 0;

/* END - Primary Customer deals */

/* START - Direct/Indirect Customers Relationship*/

INSERT INTO #ExposureTypes 
SELECT DISTINCT 
IndirectCustomerPrimaryDeals.CustomerId,
	CASE WHEN RelationshipType IN ('CorporateGuarantor','PersonalGuarantor') THEN 'IndirectRelationship' ELSE 'DirectRelationship' END
	,CASE WHEN RelationshipType IN ('CorporateGuarantor','PersonalGuarantor') THEN 'IndirectRelationship' ELSE 'DirectRelationship' END
	,CASE WHEN RelationshipType IN ('CorporateGuarantor','PersonalGuarantor') THEN 1 ELSE 0 END,ISNULL(RelationshipPercentage,100)
	,IndirectCustomerPrimaryDeals.ContractID,ContractType,0,IndirectCustomerPrimaryDeals.ExposureCustomerId
FROM (SELECT #ContractCustomers.CustomerId,ContractId,ContractType,IndirectCustomers.ExposureCustomerId 
FROM (SELECT #ExposureTypes.ExposureCustomerId,CustomerThirdPartyRelationships.CustomerId,RelationshipType
		FROM #ExposureTypes
		JOIN CustomerThirdPartyRelationships ON ThirdPartyId = #ExposureTypes.ExposureCustomerId AND IsLoc = 0 AND CustomerThirdPartyRelationships.IsActive = 1
		AND RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')) 
	AS IndirectCustomers
	JOIN #ContractCustomers ON IndirectCustomers.CustomerId = #ContractCustomers.CustomerId) 
AS IndirectCustomerPrimaryDeals
JOIN CustomerThirdPartyRelationships ON IndirectCustomerPrimaryDeals.ExposureCustomerId = CustomerThirdPartyRelationships.ThirdPartyId
JOIN ContractThirdPartyRelationships ON CustomerThirdPartyRelationships.Id = ContractThirdPartyRelationships.ThirdPartyRelationshipId
	AND IndirectCustomerPrimaryDeals.ContractID = ContractThirdPartyRelationships.ContractId 
	AND CustomerThirdPartyRelationships.IsActive = 1 AND ContractThirdPartyRelationships.IsActive = 1
WHERE RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor');

/* END - Direct/Indirect Customers Relationship*/

/* START - Primary Customers Parent Child Relationship*/

INSERT INTO #CustomersRelationship
SELECT DISTINCT #ExposureTypes.ExposureCustomerId,ParentPartyId,'Parent',ParentPartyId,0 FROM Parties
JOIN #ExposureTypes ON Parties.Id = #ExposureTypes.ExposureCustomerId AND #ExposureTypes.ExposureType = 'PrimaryCustomer' AND IsLoc = 0 
AND ParentPartyId IS NOT NULL AND #ExposureTypes.ExposureCustomerId != ParentPartyId

INSERT INTO #CustomersRelationship
SELECT DISTINCT #CustomersRelationship.ExposureCustomerId,Parties.Id,'Parent',Parties.Id,0 FROM Parties
JOIN #CustomersRelationship ON Parties.ParentPartyId = #CustomersRelationship.CustomerId AND IsLoc = 0 AND RelationType='Parent'
AND #CustomersRelationship.ExposureCustomerId != Parties.Id

INSERT INTO #CustomersRelationship
SELECT DISTINCT #ExposureTypes.ExposureCustomerId,Parties.Id,'Child',Parties.Id,0 FROM Parties
JOIN #ExposureTypes ON Parties.ParentPartyId = #ExposureTypes.ExposureCustomerId AND #ExposureTypes.ExposureType = 'PrimaryCustomer' AND IsLoc = 0
AND #ExposureTypes.ExposureCustomerId != Parties.Id

INSERT INTO #ParentChildCustomerPrimaryDeals
SELECT #ContractCustomers.CustomerId,ContractId,ContractType,#CustomersRelationship.ExposureCustomerId,0 
FROM #CustomersRelationship 
JOIN #ContractCustomers ON #CustomersRelationship.CustomerId = #ContractCustomers.CustomerId AND #CustomersRelationship.IsLoc = 0

INSERT INTO #ExposureTypes
SELECT DISTINCT #ParentChildCustomerPrimaryDeals.CustomerId,'IndirectRelationship','IndirectRelationship',0,100,#ParentChildCustomerPrimaryDeals.ContractID,#ParentChildCustomerPrimaryDeals.ContractType,0,#ExposureTypes.ExposureCustomerId 
FROM #ParentChildCustomerPrimaryDeals JOIN #ExposureTypes ON #ParentChildCustomerPrimaryDeals.ExposureCustomerId = #ExposureTypes.ExposureCustomerId
AND #ExposureTypes.RelationType = 'PrimaryCustomer' AND #ExposureTypes.IsLoc = 0

/* END - Primary Customers Parent Child Relationship*/

/* START - Third Party Relationship for Parent/child customers (primary customers) */

INSERT INTO #ExposureTypes 
SELECT DISTINCT 
	IndirectCustomerPrimaryDeals.CustomerId,'IndirectRelationship','IndirectRelationship',0
	,ISNULL(RelationshipPercentage,100)
	,IndirectCustomerPrimaryDeals.ContractID,ContractType,0,IndirectCustomerPrimaryDeals.ExposureCustomerId
FROM (SELECT #ContractCustomers.CustomerId,ContractId,ContractType,IndirectCustomers.ExposureCustomerId,ThirdPartyId
FROM (SELECT #CustomersRelationship.ExposureCustomerId,ThirdPartyId,CustomerThirdPartyRelationships.CustomerId,RelationshipType FROM #CustomersRelationship
		JOIN CustomerThirdPartyRelationships ON ThirdPartyId = #CustomersRelationship.CustomerId AND IsLoc = 0 AND CustomerThirdPartyRelationships.IsActive = 1
		AND #CustomersRelationship.ExposureCustomerId != CustomerThirdPartyRelationships.CustomerId
		WHERE RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')) 
	AS IndirectCustomers
	JOIN #ContractCustomers ON IndirectCustomers.CustomerId = #ContractCustomers.CustomerId) 
AS IndirectCustomerPrimaryDeals
JOIN CustomerThirdPartyRelationships ON IndirectCustomerPrimaryDeals.CustomerId = CustomerThirdPartyRelationships.CustomerId AND IndirectCustomerPrimaryDeals.ThirdPartyId = CustomerThirdPartyRelationships.ThirdPartyId
JOIN ContractThirdPartyRelationships ON CustomerThirdPartyRelationships.Id = ContractThirdPartyRelationships.ThirdPartyRelationshipId
	AND IndirectCustomerPrimaryDeals.ContractID = ContractThirdPartyRelationships.ContractId
	AND CustomerThirdPartyRelationships.IsActive = 1 AND ContractThirdPartyRelationships.IsActive = 1
WHERE RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')

/* END - Third Party Relationship for Parent/child customers (primary customers) */
/* END - Customer Relationship */

/* START - LOC Starts */

INSERT INTO #ExposureTypes
SELECT DISTINCT CustomerId,'PrimaryCustomer','PrimaryCustomer',0,100.00,CreditProfileId,'LOC' ,1,CustomerId FROM CreditProfiles 
JOIN CreditDecisions ON CreditDecisions.CreditProfileId = CreditProfiles.Id
WHERE IsSyndicated = 0 AND CreditDecisions.DecisionStatus = 'Approved' AND CAST(ExpiryDate AS  DATE) >= CAST(@ExposureDate AS DATE)
AND (@CustomerId IS NULL OR CreditProfiles.CustomerId = @CustomerId) 
AND CreditDecisions.IsActive = 1

INSERT INTO #ExposureTypes
SELECT DISTINCT Customers.Id,'PrimaryCustomer','PrimaryCustomer',0,100.00,NULL,'LOC' ,1,Customers.Id FROM Customers
WHERE Id NOT IN (SELECT ExposureCustomerId FROM #ExposureTypes WHERE IsLoc = 1)
AND (@CustomerId IS NULL OR Customers.Id = @CustomerId) 

/* START - Direct/Indirect Customers Relationship*/

;WITH CTE_IndirectCustomerPrimaryDeals AS
	(SELECT DISTINCT 
		CreditProfiles.CustomerId,CreditProfileId ContractID,'LOC' ContractType,IndirectCustomers.ExposureCustomerId
	FROM CreditProfiles 
	JOIN CreditDecisions ON CreditDecisions.CreditProfileId = CreditProfiles.Id
	JOIN ( SELECT #CustomersRelationship.ExposureCustomerId,CustomerThirdPartyRelationships.CustomerId,RelationshipType 
			FROM #CustomersRelationship
			JOIN CustomerThirdPartyRelationships ON ThirdPartyId = #CustomersRelationship.CustomerId AND IsLoc = 0 AND CustomerThirdPartyRelationships.IsActive = 1
			AND #CustomersRelationship.ExposureCustomerId != CustomerThirdPartyRelationships.CustomerId
			WHERE RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')
			UNION ALL
			SELECT #ExposureTypes.ExposureCustomerId,CustomerThirdPartyRelationships.CustomerId,RelationshipType
			FROM #ExposureTypes
			JOIN CustomerThirdPartyRelationships ON ThirdPartyId = #ExposureTypes.ExposureCustomerId AND IsLoc = 1 AND CustomerThirdPartyRelationships.IsActive = 1
			WHERE RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')) 
		AS IndirectCustomers ON CreditProfiles.CustomerId = IndirectCustomers.CustomerId
	WHERE IsSyndicated = 0 AND CreditDecisions.DecisionStatus = 'Approved' AND CAST(ExpiryDate AS  DATE) >= CAST(@ExposureDate AS DATE)
	AND CreditDecisions.IsActive = 1)
INSERT INTO #ExposureTypes 
SELECT DISTINCT 
	IndirectCustomerPrimaryDeals.CustomerId,
	CASE WHEN RelationshipType IN ('CorporateGuarantor','PersonalGuarantor') THEN 'IndirectRelationship' ELSE 'DirectRelationship' END
	,CASE WHEN RelationshipType IN ('CorporateGuarantor','PersonalGuarantor') THEN 'IndirectRelationship' ELSE 'DirectRelationship' END
	,CASE WHEN RelationshipType IN ('CorporateGuarantor','PersonalGuarantor') THEN 1 ELSE 0 END,ISNULL(RelationshipPercentage,100)
	,IndirectCustomerPrimaryDeals.ContractID,ContractType,1,IndirectCustomerPrimaryDeals.ExposureCustomerId
FROM CTE_IndirectCustomerPrimaryDeals IndirectCustomerPrimaryDeals
JOIN CustomerThirdPartyRelationships ON IndirectCustomerPrimaryDeals.ExposureCustomerId = CustomerThirdPartyRelationships.ThirdPartyId
	AND RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')
JOIN CreditProfileThirdPartyRelationships ON CustomerThirdPartyRelationships.Id = CreditProfileThirdPartyRelationships.ThirdPartyRelationshipId
	AND IndirectCustomerPrimaryDeals.ContractID = CreditProfileThirdPartyRelationships.CreditProfileId 
	AND CustomerThirdPartyRelationships.IsActive = 1 AND CreditProfileThirdPartyRelationships.IsActive = 1

/* END - Direct/Indirect Customers Relationship*/

/* START - Primary Customers Parent Child Relationship*/

INSERT INTO #CustomersRelationship
SELECT DISTINCT #ExposureTypes.ExposureCustomerId,ParentPartyId,'Parent',ParentPartyId,1 FROM Parties
JOIN #ExposureTypes ON Parties.Id = #ExposureTypes.ExposureCustomerId AND #ExposureTypes.ExposureType = 'PrimaryCustomer' AND IsLoc = 1 
AND ParentPartyId IS NOT NULL AND #ExposureTypes.ExposureCustomerId != ParentPartyId

INSERT INTO #CustomersRelationship
SELECT DISTINCT #CustomersRelationship.ExposureCustomerId,Parties.Id,'Parent',Parties.Id,1 FROM Parties
JOIN #CustomersRelationship ON Parties.ParentPartyId = #CustomersRelationship.CustomerId AND IsLoc = 1 AND RelationType='Parent'
AND #CustomersRelationship.ExposureCustomerId != Parties.Id

INSERT INTO #CustomersRelationship
SELECT DISTINCT #ExposureTypes.ExposureCustomerId,Parties.Id,'Child',Parties.Id,1 FROM Parties
JOIN #ExposureTypes ON Parties.ParentPartyId = #ExposureTypes.ExposureCustomerId AND #ExposureTypes.ExposureType = 'PrimaryCustomer' AND IsLoc = 1
AND #ExposureTypes.ExposureCustomerId != Parties.Id

INSERT INTO #ParentChildCustomerPrimaryDeals
SELECT DISTINCT 
	CreditProfiles.CustomerId,CreditProfileId,'LOC',#CustomersRelationship.ExposureCustomerId,1
FROM CreditProfiles 
JOIN CreditDecisions ON CreditDecisions.CreditProfileId = CreditProfiles.Id
JOIN #CustomersRelationship ON #CustomersRelationship.CustomerId = CreditProfiles.CustomerId
WHERE IsSyndicated = 0 AND CreditDecisions.DecisionStatus = 'Approved' AND CAST(ExpiryDate AS  DATE) >= CAST(@ExposureDate AS DATE) 
AND CreditDecisions.IsActive =1

INSERT INTO #ExposureTypes
SELECT DISTINCT #ParentChildCustomerPrimaryDeals.CustomerId,'IndirectRelationship','IndirectRelationship',0,100,#ParentChildCustomerPrimaryDeals.ContractID,#ParentChildCustomerPrimaryDeals.ContractType,1,#ExposureTypes.ExposureCustomerId 
FROM #ParentChildCustomerPrimaryDeals JOIN #ExposureTypes ON #ParentChildCustomerPrimaryDeals.ExposureCustomerId = #ExposureTypes.ExposureCustomerId
AND #ExposureTypes.RelationType = 'PrimaryCustomer' AND #ExposureTypes.IsLoc = 1 AND #ParentChildCustomerPrimaryDeals.IsLoc = 1

/* END - Primary Customers Parent Child Relationship*/

/* START - Third Party Relationship for Parent/child customers (for primary customers) */

;WITH CTE_IndirectCustomerPrimaryDeals AS
	(SELECT DISTINCT 
		CreditProfiles.CustomerId,CreditProfileId ContractId,'LOC' ContractType,IndirectCustomers.ExposureCustomerId
	FROM CreditProfiles 
	JOIN CreditDecisions ON CreditDecisions.CreditProfileId = CreditProfiles.Id
	JOIN (SELECT #CustomersRelationship.ExposureCustomerId,CustomerThirdPartyRelationships.CustomerId,RelationshipType FROM #CustomersRelationship
		JOIN CustomerThirdPartyRelationships ON ThirdPartyId = #CustomersRelationship.CustomerId AND IsLoc = 1 AND CustomerThirdPartyRelationships.IsActive = 1
		AND #CustomersRelationship.ExposureCustomerId != CustomerThirdPartyRelationships.CustomerId
		WHERE RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')) 
	AS IndirectCustomers ON IndirectCustomers.CustomerId = CreditProfiles.CustomerId
	WHERE IsSyndicated = 0 AND CreditDecisions.DecisionStatus = 'Approved' AND CAST(ExpiryDate AS  DATE) >= CAST(@ExposureDate AS DATE)
	AND CreditDecisions.IsActive =1)
INSERT INTO #ExposureTypes 
SELECT DISTINCT 
IndirectCustomerPrimaryDeals.CustomerId,'IndirectRelationship','IndirectRelationship',0
	,ISNULL(RelationshipPercentage,100)
	,IndirectCustomerPrimaryDeals.ContractID,ContractType,1,IndirectCustomerPrimaryDeals.ExposureCustomerId
FROM CTE_IndirectCustomerPrimaryDeals IndirectCustomerPrimaryDeals 
JOIN CustomerThirdPartyRelationships ON  IndirectCustomerPrimaryDeals.CustomerId = CustomerThirdPartyRelationships.CustomerId
JOIN CreditProfileThirdPartyRelationships ON CustomerThirdPartyRelationships.Id = CreditProfileThirdPartyRelationships.ThirdPartyRelationshipId
	AND IndirectCustomerPrimaryDeals.ContractID = CreditProfileThirdPartyRelationships.CreditProfileId 
	AND CustomerThirdPartyRelationships.IsActive = 1 AND CreditProfileThirdPartyRelationships.IsActive = 1
WHERE RelationshipType IN ('CoBorrower','CoLessee','CorporateGuarantor','PersonalGuarantor')

/* END - Third Party Relationship for Parent/child customers (for primary customers) */

/* END - LOC Ends*/

DELETE FROM #ExposureTypes WHERE EntityId IS NULL OR EntityId = 0

/* START - LOC Details to update Credit profile UsedAmount values */

INSERT INTO #TotalFinancedAmount
SELECT C.Id,
	SUM(PIOC.Amount_Amount)
FROM Contracts C
JOIN LoanFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LoanFundings LFU ON LF.Id = LFU.LoanFinanceId AND LFU.IsActive = 1
JOIN PayableInvoices PI ON LFU.FundingId = PI.Id
JOIN PayableInvoiceOtherCosts PIOC ON LFU.FundingId = PIOC.PayableInvoiceId AND PIOC.IsActive = 1
JOIN DisbursementRequestInvoices DRI ON PIOC.PayableInvoiceId = DRI.InvoiceId AND DRI.IsActive = 1
JOIN DisbursementRequestPaymentDetails DRP ON DRI.DisbursementRequestId = DRP.DisbursementRequestId AND DRP.IsActive = 1
JOIN DisbursementRequests DR ON DRP.DisbursementRequestId = DR.Id
WHERE  LFU.TYPE = 'FutureScheduledFunded' AND DR.Status = 'Completed' AND PIOC.AllocationMethod = 'LoanDisbursement'
GROUP BY C.Id

;WITH CTE_MaxGLPostedEndDate AS(
SELECT R.EntityId as ContractId
,MAX(LP.EndDate) AS EndDate
FROM Receivables R
JOIN ReceivableCodes RC on R.ReceivableCodeId= RC.Id
JOIN ReceivableTypes RT on RC.ReceivableTypeId = RT.Id
JOIN LoanFinances LF ON R.EntityId = LF.ContractId
JOIN LoanPaymentSchedules LP on LF.Id = LP.LoanFinanceId AND LP.Id = R.PaymentScheduleId
WHERE R.IsActive = 1 AND LP.IsActive = 1 AND  R.IsGLPosted = 1 AND (@CustomerId IS NULL OR LF.CustomerId = @CustomerId)
AND RT.Name IN('LoanInterest','LoanPrincipal')
GROUP BY R.EntityId)
INSERT INTO #FutureFundedAmount
SELECT CP.Id AS CreditProfileId,
		SUM(InvoiceOtherCost.Amount_Amount) AS FutureFundedAmount
	FROM Contracts C
	JOIN LoanFinances LF ON C.Id = LF.ContractId
	JOIN LoanFundings Funding ON LF.Id = Funding.LoanFinanceId AND Funding.IsActive = 1  AND LF.IsCurrent = 1 AND LF.IsRevolvingLoan = 1
	JOIN PayableInvoices Invoice ON Funding.FundingId = Invoice.Id
	JOIN PayableInvoiceOtherCosts InvoiceOtherCost ON Invoice.Id = InvoiceOtherCost.PayableInvoiceId AND InvoiceOtherCost.IsActive = 1 
	JOIN CreditApprovedStructures CAS ON C.CreditApprovedStructureId = CAS.Id
	JOIN CreditProfiles CP ON CAS.CreditProfileId = CP.Id
	JOIN CreditDecisions CD ON CP.Id = CD.CreditProfileId AND CD.IsActive=1 
	JOIN CTE_MaxGLPostedEndDate MaxDate ON LF.ContractId = MaxDate.ContractId
	WHERE InvoiceOtherCost.AllocationMethod = 'LoanDisbursement' AND (@CustomerId IS NULL OR LF.CustomerId = @CustomerId) AND LF.Status != 'Cancelled'
	and Funding.Type <> 'Origination' AND Invoice.DueDate <= CD.ExpiryDate 
	AND ((MaxDate.EndDate IS NULL AND Invoice.DueDate > LF.CommencementDate) OR Invoice.DueDate > MaxDate.EndDate)
	GROUP BY CP.Id

INSERT INTO #LOCContractLevel 
SELECT
	CreditProfileId
	,ContractId
	,Status
	,ContractType
	,SubType
	,dbo.GetMaxValue(0,UsedRevolvingAmount)
	,dbo.GetMaxValue(0,UsedNonRevolvingAmount)
	,dbo.GetMaxValue(0,UsedLineRevolvingAmountForExpBalance)
	,dbo.GetMaxValue(0,UsedLineNonRevolvingAmountForExpBalance)
FROM
(
SELECT 
	RNI.CreditProfileId
	,RNI.ContractId
	,RNI.Status
	,RNI.ContractType
	,RNI.SubType
	,CASE WHEN RNI.ContractType='ProgressLoan'
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId, ISNULL(RNI.ProgressFundings,0)) - dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.ProgressPaymentCredits,0)) 
				FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  WHEN RNI.ContractType='Loan' AND RNI.Status='UnCommenced' 
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.TotalFinancedAmountLOC,0)) 
				FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND (RNI.Status='UnCommenced' OR RNI.Status='InstallingAssets')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.TotalFinancedAmountLOC,0)) 
				FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  WHEN RNI.ContractType='Loan' AND (RNI.Status='Commenced' OR RNI.Status='FullyPaidOff') 
				THEN (SELECT 
						CASE WHEN ISNULL(RNI.RetainedPercentage,0) != 100 AND ISNULL(RNI.RetainedPercentage,0) != 0 THEN dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,((ISNULL(RNI.PrincipalBalance,0)*100)/ISNULL(RNI.RetainedPercentage,0))) 
							ELSE dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrincipalBalance,0)) END
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.NetWritedowns,0))  
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.LoanPrincipleOSAR,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.LoanInterestOSAR,0)) 
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(FFA.FutureFundedAmount,0)) 

						FROM CreditProfiles childCP LEFT JOIN #FutureFundedAmount FFA ON childCP.Id = FFA.CreditProfileId
						LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
						WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  
		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.IsOTP=0 AND RNI.SubType IN ('Operating','LeveragedLease') AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseAssetGrossCost,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.AccumulatedDepreciation,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceIncomeAccrualBalance,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseRentOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0)) 

					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0)) 					
					
					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))

		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.IsOTP=1 AND RNI.SubType IN ('Operating','LeveragedLease') AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseAssetGrossCost,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.AccumulatedDepreciation,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceIncomeAccrualBalance,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseRentOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0)) 
	
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OverTermRentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OTPResidualRecapture,0)) 
					
					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  
		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.SubType!='Operating' AND RNI.IsOTP=0 AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0))
					- CASE WHEN RNI.ContractType = 'Lease' THEN 
						dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(IncomeAccrualBalance,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(FinanceIncomeAccrualBalance,0)) 
					  ELSE dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(UnearnedRentalIncome,0)) END
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0))
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0))

					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))

		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.SubType!='Operating' AND RNI.IsOTP=1 AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0)) 
					- CASE WHEN RNI.ContractType = 'Lease' THEN 
						dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(IncomeAccrualBalance,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(FinanceIncomeAccrualBalance,0)) 
					  ELSE dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(UnearnedRentalIncome,0)) END
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OTPResidualRecapture,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNi.OverTermRentOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0))
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0))

					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))

		END UsedRevolvingAmount
	,CASE WHEN RNI.ContractType='ProgressLoan'
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,CreditProfiles.CurrencyId,ISNULL(RNI.ProgressFundings,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,CreditProfiles.CurrencyId,ISNULL(RNI.ProgressPaymentCredits,0)) FROM CreditProfiles WHERE RNI.CreditProfileId = CreditProfiles.Id AND IsRevolving=0)
				ELSE (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,CreditProfiles.CurrencyId,ISNULL(RNI.TotalFinancedAmountLOC,0)) FROM CreditProfiles WHERE RNI.CreditProfileId = CreditProfiles.Id AND IsRevolving=0)
		END UsedNonRevolvingAmount
-- Used for LOC Balalce Calculation
,CASE WHEN RNI.ContractType='ProgressLoan'
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId, ISNULL(RNI.ProgressFundings,0)) - dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.ProgressPaymentCredits,0)) 
				FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  WHEN RNI.ContractType='Loan' AND RNI.Status='UnCommenced' 
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.TotalFinancedAmount,0)) 
				FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND (RNI.Status='UnCommenced' OR RNI.Status='InstallingAssets')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.TotalFinancedAmount,0)) 
				FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  WHEN RNI.ContractType='Loan' AND (RNI.Status='Commenced' OR RNI.Status='FullyPaidOff') 
				THEN (SELECT 
						CASE WHEN ISNULL(RNI.RetainedPercentage,0) != 100 AND ISNULL(RNI.RetainedPercentage,0) != 0 THEN dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,(((ISNULL(RNI.PrincipalBalance,0) + ISNULL(RNI.PrincipalBalanceAdjustment,0))*100)/ISNULL(RNI.RetainedPercentage,0)))
							ELSE dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrincipalBalance,0) + ISNULL(RNI.PrincipalBalanceAdjustment,0)) END
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.NetWritedowns,0))  
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.LoanPrincipleOSAR,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.LoanInterestOSAR,0)) 
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
						- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0))
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(FFA.FutureFundedAmount,0)) 

						FROM CreditProfiles childCP LEFT JOIN #FutureFundedAmount FFA ON childCP.Id = FFA.CreditProfileId
						LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
						WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  
		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.IsOTP=0 AND RNI.SubType IN ('Operating','LeveragedLease') AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseAssetGrossCost,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.AccumulatedDepreciation,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceIncomeAccrualBalance,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseRentOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0)) 

					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0)) 					
					
					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  
		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.IsOTP=1 AND RNI.SubType IN ('Operating','LeveragedLease') AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseAssetGrossCost,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.AccumulatedDepreciation,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceIncomeAccrualBalance,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OperatingLeaseRentOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0)) 
	
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OverTermRentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OTPResidualRecapture,0)) 
					
					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))

		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.SubType!='Operating' AND RNI.IsOTP=0 AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0))
					- CASE WHEN RNI.ContractType = 'Lease' THEN 
						dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(IncomeAccrualBalance,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(FinanceIncomeAccrualBalance,0)) 
					  ELSE dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(UnearnedRentalIncome,0)) END
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.PrepaidReceivables,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0))
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedPrepaidReceivables,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0))

					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))

		  WHEN RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.SubType!='Operating' AND RNI.IsOTP=1 AND (RNI.Status = 'Commenced' OR RNI.Status='FullyPaidOff')
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseContractReceivable,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.CapitalLeaseRentOSAR,0)) 
					- CASE WHEN RNI.ContractType = 'Lease' THEN 
						dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(IncomeAccrualBalance,0)) 
						+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(FinanceIncomeAccrualBalance,0)) 
					  ELSE dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(UnearnedRentalIncome,0)) END
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.OTPResidualRecapture,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNi.OverTermRentOSAR,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FloatRateAdjustmentOSAR,0))
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.UnappliedCash,0)) 
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.SyndicatedFixedTermReceivablesOSAR,0)) 
					
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinanceSyndicatedFixedTermReceivablesOSAR,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingContractReceivable,0))
					+ dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,childCP.CurrencyId,ISNULL(RNI.FinancingRentOSAR,0))
					
					FROM CreditProfiles childCP LEFT JOIN CreditProfiles parentCP ON childCP.LineofCreditId = parentCP.Id 
					WHERE RNI.CreditProfileId = childCP.Id AND (childCP.IsRevolving=1 OR (childCP.LineofCreditId IS NOT NULL AND parentCP.IsRevolving = 1)))
		  END UsedLineRevolvingAmountForExpBalance
,CASE WHEN RNI.ContractType='ProgressLoan'
				THEN (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,CreditProfiles.CurrencyId,ISNULL(RNI.ProgressFundings,0)) 
					- dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,CreditProfiles.CurrencyId,ISNULL(RNI.ProgressPaymentCredits,0)) FROM CreditProfiles WHERE RNI.CreditProfileId = CreditProfiles.Id AND IsRevolving=0)
		WHEN RNI.ContractType='Loan' THEN 
			(SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,CreditProfiles.CurrencyId,ISNULL(RNI.TotalFinancedAmount,0)) 
				FROM CreditProfiles WHERE RNI.CreditProfileId = CreditProfiles.Id AND IsRevolving=0) 
			+   ISNULL((SELECT ISNULL(TFA.Amount,0) FROM #TotalFinancedAmount TFA WHERE RNI.ContractId = TFA.ContractId),0)
		ELSE (SELECT dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,CreditProfiles.CurrencyId,ISNULL(RNI.TotalFinancedAmount,0)) FROM CreditProfiles WHERE RNI.CreditProfileId = CreditProfiles.Id AND IsRevolving=0)
		  END UsedLineNonRevolvingAmountForExpBalance
FROM RemainingNetInvestments RNI 
JOIN #LatestRNI LatestRNI ON RNI.Id	= LatestRNI.RNIId
WHERE RNI.CreditProfileId IS NOT NULL AND RNI.IsActive = 1
) A
UPDATE #LOCContractLevel SET UsedLineRevolvingAmount = 0,UsedLineNonRevolvingAmount = 0
,UsedLineRevolvingAmountForExpBalance = 0,UsedLineNonRevolvingAmountForExpBalance = 0 FROM #LOCContractLevel
JOIN Contracts ON #LOCContractLevel.ContractId = Contracts.Id
WHERE (Contracts.ContractType in ('Lease','LeveragedLease') and Contracts.Status = 'Inactive') 
OR (Contracts.ContractType in ('Loan','ProgressLoan') and Contracts.Status = 'Cancelled')																								

-- Update statement to update used amount in credit profile tables
SELECT 
	CASE 
		WHEN childCP.LineOfCreditId IS NOT NULL --AND parentCP.IsRevolving = 1 
			THEN parentCP.Id 
		ELSE LOCId 
	END LOCId,
	LOCId ChildLOCId,  
	SUM(UsedLineRevolvingAmount) UsedLineRevolvingAmount,
	SUM(UsedLineNonRevolvingAmount) UsedLineNonRevolvingAmount,
	SUM(UsedLineRevolvingAmountForExpBalance) UsedLineRevolvingAmountForExpBalance, 
	SUM(UsedLineNonRevolvingAmountForExpBalance) UsedLineNonRevolvingAmountForExpBalance
INTO #LOCUsedAmountTemp1
FROM #LOCContractLevel
JOIN CreditProfiles childCP ON #LOCContractLevel.LOCId = childCP.Id
LEFT JOIN CreditProfiles parentCP ON childCP.LineOfCreditId = parentCP.Id
GROUP BY childCP.LineOfCreditId,parentCP.IsRevolving,parentCP.Id,LOCId,childCP.UsedAmount_Amount,UsedLineRevolvingAmount							 

INSERT INTO #LOCUsedAmount
SELECT LOCId, SUM(UsedLineRevolvingAmount), SUM(UsedLineNonRevolvingAmount),SUM(UsedLineRevolvingAmountForExpBalance), SUM(UsedLineNonRevolvingAmountForExpBalance)
FROM #LOCUsedAmountTemp1 GROUP BY LOCId

SELECT ChildLOCId, SUM(UsedLineRevolvingAmount) UsedLineRevolvingAmount, SUM(UsedLineNonRevolvingAmount) UsedLineNonRevolvingAmount,
SUM(UsedLineRevolvingAmountForExpBalance) UsedLineRevolvingAmountForExpBalance, SUM(UsedLineNonRevolvingAmountForExpBalance) UsedLineNonRevolvingAmountForExpBalance
INTO #LOCUsedAmountChild
FROM #LOCUsedAmountTemp1
 GROUP BY ChildLOCId

IF EXISTS (Select 1 FROM CreditProfiles CP JOIN #LOCUsedAmount ON CP.Id = #LOCUsedAmount.LOCId
			WHERE CP.IsPreApproval = 1)
BEGIN
(SELECT ParentLOCId = ParentCP.Id, 
ParentUsedAmount = 
CASE 
	--SUM(LOC.UsedLineRevolvingAmt) + (sum of available balance of all the child LOCs)
	WHEN ParentCP.IsRevolving = 1 
		THEN SUM(LOC.UsedLineRevolvingAmt) + 
		((SELECT SUM(ApprovedAmount_Amount) FROM CreditProfiles WHERE LineOfCreditId = ParentCP.Id) - 
		(SELECT SUM(UsedLineNonRevolvingAmount) FROM #LOCUsedAmountChild L JOIN CreditProfiles C ON L.ChildLOCId = C.Id WHERE C.LineOfCreditId = ParentCP.Id))
	ELSE ParentCP.UsedAmount_Amount
 END,
ChildLOCId = ChildCP.Id, 
ChildUsedAmount = SUM(LOCChild.UsedLineNonRevolvingAmount)
INTO #LocUsedAmountForParentChild
FROM CreditProfiles ParentCP
JOIN CreditProfiles ChildCP ON ParentCP.Id = ChildCP.LineOfCreditId
JOIN #LOCUsedAmount LOC ON ParentCP.Id	= LOC.LOCId
JOIN #LOCUsedAmountChild LOCChild ON ChildCP.Id = LOCChild.ChildLOCId
JOIN CreditDecisions CD ON ParentCP.Id = CD.CreditProfileId
AND CD.DecisionStatus = 'Approved' 
AND (ParentCP.IsPreApproval = 1 AND ChildCP.LineOfCreditId IS NOT NULL) AND CD.IsActive = 1
GROUP BY ParentCP.Id,ChildCP.Id,ParentCP.IsRevolving,ParentCP.UsedAmount_Amount)

UPDATE CreditProfiles SET UsedAmount_Amount = #LocUsedAmountForParentChild.ParentUsedAmount,UpdatedById = @CreatedById, UpdatedTime=@CreatedTime 
FROM #LocUsedAmountForParentChild
JOIN CreditProfiles ON #LocUsedAmountForParentChild.ParentLocId = CreditProfiles.Id

UPDATE CreditProfiles SET UsedAmount_Amount = #LocUsedAmountForParentChild.ChildUsedAmount,UpdatedById = @CreatedById, UpdatedTime=@CreatedTime 
FROM #LocUsedAmountForParentChild
JOIN CreditProfiles ON #LocUsedAmountForParentChild.ChildLOCId = CreditProfiles.Id
END

UPDATE CP SET UsedAmount_Amount = CASE WHEN CP.IsRevolving=1 THEN LOC.UsedLineRevolvingAmt ELSE LOC.UsedLineNonRevolvingAmt END 
,UpdatedById = @CreatedById, UpdatedTime=@CreatedTime
FROM CreditProfiles CP 
JOIN #LOCUsedAmount LOC ON CP.Id = LOC.LOCId
JOIN CreditDecisions CD ON CP.Id = CD.CreditProfileId
AND CD.DecisionStatus = 'Approved' AND CP.IsPreApproval = 0 AND CD.IsActive = 1 AND CP.IsPreApproved = 0											   

/* END - LOC Details to update Credit profile UsedAmount values */

/* START - Customers have both Direct and Indirect Relationship then we should not consider Indirect relationship*/
;WITH CTE_DirectRelationship AS
(
SELECT ExposureCustomerId,CustomerId, ExposureType,EntityType,EntityId FROM #ExposureTypes 
WHERE ExposureType = 'DirectRelationship'
GROUP BY ExposureCustomerId,CustomerId,ExposureType,EntityType,EntityId
)
DELETE #ExposureTypes FROM #ExposureTypes 
JOIN CTE_DirectRelationship InDirectCustomersToDelete ON #ExposureTypes.CustomerId = InDirectCustomersToDelete.CustomerId
AND #ExposureTypes.ExposureCustomerId = InDirectCustomersToDelete.ExposureCustomerId
AND #ExposureTypes.EntityId = InDirectCustomersToDelete.EntityId
WHERE #ExposureTypes.ExposureType = 'IndirectRelationship'

/* END - Customers have both Direct and Indirect Relationship then we should not consider Indirect relationship*/

/* START - Max Relationship Percentage for indirect relationship */

INSERT INTO #ExposureTypesForDealExposure
SELECT CustomerId,ExposureType,RelationType,MAX(RelationShipPercentage),EntityId,EntityType,IsLoc,ExposureCustomerId
FROM #ExposureTypes
GROUP BY CustomerId,ExposureType,RelationType,EntityId,EntityType,IsLoc,ExposureCustomerId

/* END - Max Relationship Percentage for indirect relationship */

/* START - For Assumed Contracts */

INSERT INTO #AllCustomersForContract
SELECT AC.ContractId,AC.CustomerId,SUM(ISNULL(TotalBalance_Amount,0)) RNIAmount,IsRNI
FROM  #AssumptionTable AC
LEFT JOIN Receivables R ON AC.ContractId = R.EntityId AND AC.CustomerId = R.CustomerId
GROUP BY AC.ContractId,AC.CustomerId,IsRNI

INSERT INTO #RNItoReduceFromCurrentCustomer
SELECT ContractId, SUM(RNIAmount) FROM #AllCustomersForContract
WHERE IsRNI = 0
GROUP BY ContractId,IsRNI

UPDATE LRNI SET LRNI.RNIAmount = LRNI.RNIAmount - RNIR.Amount 
FROM #LatestRNI LRNI
JOIN #RNItoReduceFromCurrentCustomer RNIR ON LRNI.ContractId = RNIR.ContractId 

INSERT INTO #LatestRNIToProcess
SELECT #LatestRNI.ContractId
	,CASE WHEN #AllCustomersForContract.IsRNI = 0 THEN NULL ELSE #LatestRNI.RNIId END RNIId
	,NULL CreditProfileId,IncomeDate,#LatestRNI.ContractType
	,CASE WHEN #AllCustomersForContract.IsRNI = 0 THEN #AllCustomersForContract.RNIAmount ELSE #LatestRNI.RNIAmount END RNIAmount
	,CASE WHEN #AllCustomersForContract.IsRNI = 0 THEN NULL ELSE #ContractCustomers.CustomerId END CustomerId 
	,Isotp,currencyId,subtype,status
	,#LatestRNI.UnchangedRNIAmount_Amount
FROM #LatestRNI
JOIN #ContractCustomers ON #LatestRNI.ContractId = #ContractCustomers.ContractId
LEFT JOIN #AllCustomersForContract ON #LatestRNI.ContractId = #AllCustomersForContract.ContractId

/* END - For Assumed Contracts */

/* START - DealExposure , To Populate Deal Exposure , Exposure Currency always USD so will declare one constant and use for exposure calculation */

INSERT INTO #DealExposure 
SELECT 
	EX.CustomerId
	,EX.EntityId
	,EX.EntityType
	,@ExposureDate
	,EX.ExposureType
	,EX.RelationShipPercentage
	,RNI.RNIId
	,0 CommencedDealRNI_Amount  
	,0 OTPLeaseRNI_Amount  
	,0 UncommencedDealRNI_Amount 
	,0 LOCBalanceRevolving_Amount
	,0 LOCBalanceNonRevolving_Amount
	,ExposureCustomerId 
FROM
#LatestRNIToProcess RNI
JOIN #ExposureTypesForDealExposure EX
ON EX.EntityId = RNI.ContractId AND EX.EntityType = RNI.ContractType AND EX.CustomerId = RNI.CustomerId
WHERE EX.IsLoc = 0;

UPDATE #DealExposure
SET CommencedDealRNI_Amount = dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,@ExposureCurrencyId, RNI.UnchangedRNIAmount_Amount) 
FROM #DealExposure
JOIN #LatestRNIToProcess RNI ON #DealExposure.RNIId = RNI.RNIId AND (RNI.Status='Commenced' OR RNI.Status='FullyPaidOff') AND RNI.IsOTP=0;

UPDATE #DealExposure
SET OTPLeaseRNI_Amount = dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,@ExposureCurrencyId, RNI.UnchangedRNIAmount_Amount) 
FROM #DealExposure
JOIN #LatestRNIToProcess RNI ON #DealExposure.RNIId = RNI.RNIId AND (RNI.Status='Commenced' OR RNI.Status='FullyPaidOff') AND RNI.IsOTP=1 
AND RNI.ContractType IN ('Lease','LeveragedLease') AND RNI.SubType IN ('Operating','DirectFinance','SalesType');

UPDATE #DealExposure
SET UncommencedDealRNI_Amount = dbo.CalculateAmtInTargetCurrency(RNI.CurrencyId,@ExposureCurrencyId,RNI.UnchangedRNIAmount_Amount)
FROM #DealExposure
JOIN #LatestRNIToProcess RNI ON #DealExposure.RNIId = RNI.RNIId AND RNI.IsOTP=0 
AND (RNI.Status='UnCommenced' OR RNI.Status='InstallingAssets' OR RNI.Status='FullyPaid');

INSERT INTO #DealExposure 
SELECT 
	CustomerId
	,EntityId
	,EntityType
	,@ExposureDate
	,ExposureType
	,RelationShipPercentage
	,NULL
	,0
	,0
	,0
	,dbo.GetMaxValue(0,RevolvingAmt)
	,dbo.GetMaxValue(0,NonRevolvingAmt)
	,ExposureCustomerId 
FROM
(
SELECT
	Ex.CustomerId
	,Ex.EntityId
	,Ex.EntityType
	,Ex.ExposureType
	,Ex.RelationShipPercentage
	,CASE WHEN ((SELECT COUNT(1) FROM #LOCUsedAmount WHERE LocId = Ex.EntityId AND Ex.EntityType = 'LOC') > 0) THEN
	(SELECT dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,SubCR.ApprovedAmount_Amount) 
			- dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,LOC.UsedLineRevolvingAmtForExposure)
			- ISNULL((SELECT SUM(ApprovedAmount_Amount) - LOC.UsedLineNonRevolvingAmtForExposure FROM creditprofiles WHERE LineOfCreditId = LOC.LOCId),0.00)
			FROM CreditProfiles SubCR JOIN #LOCUsedAmount LOC  ON SubCR.Id = LOC.LOCId
			WHERE SubCR.Id = Ex.EntityId AND SubCR.IsRevolving=1)
	ELSE
	(SELECT dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,SubCR.ApprovedAmount_Amount) 
			- dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,SubCR.UsedAmount_Amount) FROM CreditProfiles SubCR 
			WHERE SubCR.Id = Ex.EntityId AND SubCR.IsRevolving=1) END
	 RevolvingAmt
	,CASE WHEN ((SELECT COUNT(1) FROM #LOCUsedAmount WHERE LocId = Ex.EntityId AND Ex.EntityType = 'LOC') > 0) THEN
	(SELECT dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,SubCR.ApprovedAmount_Amount) 
			- dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,SubCR.UsedAmount_Amount) FROM CreditProfiles SubCR 
			WHERE SubCR.Id = Ex.EntityId AND SubCR.IsRevolving=0)
	ELSE
	(SELECT dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,SubCR.ApprovedAmount_Amount) 
			- dbo.CalculateAmtInTargetCurrency(SubCR.CurrencyId,@ExposureCurrencyId,SubCR.UsedAmount_Amount) FROM CreditProfiles SubCR 
			WHERE SubCR.Id = Ex.EntityId AND SubCR.IsRevolving=0) END
	 NonRevolvingAmt
,Ex.ExposureCustomerId
FROM #ExposureTypesForDealExposure Ex
WHERE Ex.IsLoc = 1
) B

/* START - DealExposure To Insert Deal Exposure tables */

INSERT INTO DealExposures
(
CustomerID 
,EntityID 
,EntityType
,ExposureDate
,ExposureType
,RelationshipPercentage
,RNIID
,CommencedDealRNI_Amount
,CommencedDealRNI_Currency
,CommencedDealExposure_Amount
,CommencedDealExposure_Currency
,OTPLeaseRNI_Amount
,OTPLeaseRNI_Currency
,OTPLeaseExposure_Amount
,OTPLeaseExposure_Currency
,UncommencedDealRNI_Amount
,UncommencedDealRNI_Currency
,UncommencedDealExposure_Amount
,UncommencedDealExposure_Currency
,LOCBalanceRevolving_Amount
,LOCBalanceRevolving_Currency
,LOCBalanceNonRevolving_Amount
,LOCBalanceNonRevolving_Currency
,LOCBalanceExposure_Amount
,LOCBalanceExposure_Currency
,TotalExposure_Amount
,TotalExposure_Currency
,CreatedById
,CreatedTime
,IsActive
,ExposureCustomerId
)
SELECT 
CustomerID 
,EntityID 
,EntityType
,ExposureDate
,ExposureType
,RelationshipPercentage
,RNIID
,ISNULL(CommencedDealRNI_Amount,0)
,@ExposureCurrency
,ISNULL(CommencedDealRNI_Amount,0) * (RelationshipPercentage/100)
,@ExposureCurrency
,ISNULL(OTPLeaseRNI_Amount,0)
,@ExposureCurrency
,ISNULL(OTPLeaseRNI_Amount,0) * (RelationshipPercentage/100)
,@ExposureCurrency
,ISNULL(UncommencedDealRNI_Amount,0)
,@ExposureCurrency
,ISNULL(UncommencedDealRNI_Amount,0)  * (RelationshipPercentage/100)
,@ExposureCurrency
,ISNULL(LOCBalanceRevolving_Amount,0) LOCBalanceRevolving_Amount
,@ExposureCurrency
,ISNULL(LOCBalanceNonRevolving_Amount,0) LOCBalanceNonRevolving_Amount
,@ExposureCurrency
,(ISNULL(LOCBalanceRevolving_Amount,0) + ISNULL(LOCBalanceNonRevolving_Amount,0)) * (RelationshipPercentage/100)
,@ExposureCurrency
,(ISNULL(CommencedDealRNI_Amount,0) * (RelationshipPercentage/100)) + (ISNULL(OTPLeaseRNI_Amount,0) * (RelationshipPercentage/100)) 
	+ (ISNULL(UncommencedDealRNI_Amount,0)  * (RelationshipPercentage/100)) 
	+ ((ISNULL(LOCBalanceRevolving_Amount,0) + ISNULL(LOCBalanceNonRevolving_Amount,0)) * (RelationshipPercentage/100))
,@ExposureCurrency
,@CreatedById
,@CreatedTime
,1
,ExposureCustomerId
FROM #DealExposure 

/* END - DealExposure To Insert Deal Exposure tables */


;WITH CTE_IndirectCustomer AS
(
SELECT ExposureType ,CustomerId,ExposureCustomerId FROM DealExposures
WHERE ExposureType = 'IndirectRelationship'
GROUP BY ExposureType ,CustomerId,ExposureCustomerId
)
INSERT INTO #DealExposureCustomers
SELECT 
ExposureCustomerId,CustomerId,1
FROM CTE_IndirectCustomer

/* START - Customer Level Calculations */

INSERT INTO #CustomerExposure
SELECT ExposureCustomerId FROM DealExposures GROUP BY ExposureCustomerId 

--Parent
INSERT INTO #IndirectCustomersUnallocated
SELECT DISTINCT Parties.Id ExposureCustomerId,ParentPartyId,0,0,0 FROM Parties
JOIN #CustomerExposure ON Parties.Id = ExposureCustomerId
WHERE ParentPartyId IS NOT NULL AND #CustomerExposure.ExposureCustomerId != ParentPartyId

--Child
INSERT INTO #IndirectCustomersUnallocated
SELECT DISTINCT ParentPartyId ExposureCustomerId,Parties.Id,0,0,0 FROM Parties
JOIN #CustomerExposure ON Parties.ParentPartyId = ExposureCustomerId
AND #CustomerExposure.ExposureCustomerId != Parties.Id

--Siblings
;WITH CTE_Sibling AS
(
SELECT DISTINCT Parties.Id ChildCustomerId,ParentPartyId FROM Parties
JOIN #CustomerExposure ON Parties.Id = ExposureCustomerId
WHERE ParentPartyId IS NOT NULL AND #CustomerExposure.ExposureCustomerId != ParentPartyId
)
INSERT INTO #IndirectCustomersUnallocated
SELECT Parties.Id ExposureCustomerId,Parties.ParentPartyId,0,0,0 FROM Parties 
JOIN CTE_Sibling ON Parties.ParentPartyId = CTE_Sibling.ParentPartyId
AND Parties.Id != CTE_Sibling.ChildCustomerId

UPDATE #IndirectCustomersUnallocated SET #IndirectCustomersUnallocated.UnallocatedAmount = #CustomerUnallocated.Amount FROM #IndirectCustomersUnallocated
JOIN #CustomerUnallocated ON #IndirectCustomersUnallocated.IndirectCustomerId = #CustomerUnallocated.CustomerId

UPDATE #IndirectCustomersUnallocated SET #IndirectCustomersUnallocated.SecurityDepositAmount = #CustomerUnallocatedSecDep.Amount FROM #IndirectCustomersUnallocated
JOIN #CustomerUnallocatedSecDep ON #IndirectCustomersUnallocated.IndirectCustomerId = #CustomerUnallocatedSecDep.CustomerId

UPDATE #IndirectCustomersUnallocated SET #IndirectCustomersUnallocated.SecurityDepositOSARAmount = #CustomerUnallocatedSecDepOSAR.Amount FROM #IndirectCustomersUnallocated
JOIN #CustomerUnallocatedSecDepOSAR ON #IndirectCustomersUnallocated.IndirectCustomerId = #CustomerUnallocatedSecDepOSAR.CustomerId

/* END - Customer Level Calculations */

/* START - CustomerExposure To Insert Customer Exposure tables */

INSERT INTO CustomerExposures
(
ExposureCustomerId
,ExposureDate
,CreatedById 
,CreatedTime 
,IsActive
,PrimaryCustomerCommencedLoanExposure_Amount
,PrimaryCustomerCommencedLeaseExposure_Amount
,PrimaryCustomerOTPLeaseExposure_Amount
,PrimaryCustomerUncommencedDealExposure_Amount
,PrimaryCustomerLOCBalanceExposure_Amount
,PrimaryCustomerUnallocatedSecurityDepositOSAR_Amount
,PrimaryCustomerUnallocatedSecurityDeposit_Amount
,PrimaryCustomerUnallocatedCash_Amount
,DirectRelationshipCommencedLoanExposure_Amount
,DirectRelationshipCommencedLeaseExposure_Amount
,DirectRelationshipOTPLeaseExposure_Amount
,DirectRelationshipUncommencedDealExposure_Amount
,DirectRelationshipLOCBalanceExposure_Amount
,IndirectRelationshipCommencedLoanExposure_Amount
,IndirectRelationshipCommencedLeaseExposure_Amount
,IndirectRelationshipOTPLeaseExposure_Amount
,IndirectRelationshipUncommencedDealExposure_Amount
,IndirectRelationshipLOCBalanceExposure_Amount
,IndirectRelationshipUnallocatedSecurityDepositOSAR_Amount
,IndirectRelationshipUnallocatedSecurityDeposit_Amount
,IndirectRelationshipUnallocatedCash_Amount
,TotalPrimaryCustomerExposure_Amount
,TotalDirectRelationshipExposure_Amount
,TotalIndirectRelationshipExposure_Amount
,TotalCreditExposure_Amount
,PrimaryCustomerCommencedLoanExposure_Currency
,PrimaryCustomerCommencedLeaseExposure_Currency
,PrimaryCustomerOTPLeaseExposure_Currency
,PrimaryCustomerUncommencedDealExposure_Currency
,PrimaryCustomerLOCBalanceExposure_Currency
,PrimaryCustomerUnallocatedSecurityDepositOSAR_Currency
,PrimaryCustomerUnallocatedSecurityDeposit_Currency
,PrimaryCustomerUnallocatedCash_Currency
,DirectRelationshipCommencedLoanExposure_Currency
,DirectRelationshipCommencedLeaseExposure_Currency
,DirectRelationshipOTPLeaseExposure_Currency
,DirectRelationshipUncommencedDealExposure_Currency
,DirectRelationshipLOCBalanceExposure_Currency
,IndirectRelationshipCommencedLoanExposure_Currency
,IndirectRelationshipCommencedLeaseExposure_Currency
,IndirectRelationshipOTPLeaseExposure_Currency
,IndirectRelationshipUncommencedDealExposure_Currency
,IndirectRelationshipLOCBalanceExposure_Currency
,IndirectRelationshipUnallocatedSecurityDepositOSAR_Currency
,IndirectRelationshipUnallocatedSecurityDeposit_Currency
,IndirectRelationshipUnallocatedCash_Currency
,TotalPrimaryCustomerExposure_Currency
,TotalDirectRelationshipExposure_Currency
,TotalIndirectRelationshipExposure_Currency
,TotalCreditExposure_Currency
)
SELECT ExposureCustomerId,@ExposureDate,@CreatedById,@CreatedTime,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency
,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency
,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency,@ExposureCurrency
FROM DealExposures GROUP BY ExposureCustomerId 

UPDATE CustomerExposures SET PrimaryCustomerCommencedLoanExposure_Amount = CommencedLoan FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(CommencedDealExposure_Amount,0)) AS CommencedLoan FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='PrimaryCustomer' AND EntityType='Loan' AND CommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET PrimaryCustomerCommencedLeaseExposure_Amount = CommencedLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(CommencedDealExposure_Amount,0)) AS CommencedLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='PrimaryCustomer' AND EntityType IN ('Lease','LeveragedLease') AND CommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET PrimaryCustomerOTPLeaseExposure_Amount = OTPLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(OTPLeaseExposure_Amount,0)) AS OTPLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='PrimaryCustomer' AND EntityType IN ('Lease','LeveragedLease') AND OTPLeaseRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET PrimaryCustomerUncommencedDealExposure_Amount = UncomencedLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(UncommencedDealExposure_Amount,0)) AS UncomencedLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='PrimaryCustomer' AND UncommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET PrimaryCustomerLOCBalanceExposure_Amount = LOCbalance FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(LOCBalanceExposure_Amount,0)) AS LOCbalance FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='PrimaryCustomer' AND EntityType ='LOC'
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET PrimaryCustomerUnallocatedSecurityDepositOSAR_Amount = ISNULL(Amount,0) FROM CustomerExposures
JOIN #CustomerUnallocatedSecDepOSAR ON CustomerExposures.ExposureCustomerId = #CustomerUnallocatedSecDepOSAR.CustomerId

UPDATE CustomerExposures SET PrimaryCustomerUnallocatedSecurityDeposit_Amount = ISNULL(Amount,0) FROM CustomerExposures
JOIN #CustomerUnallocatedSecDep ON CustomerExposures.ExposureCustomerId = #CustomerUnallocatedSecDep.CustomerId

UPDATE CustomerExposures SET PrimaryCustomerUnallocatedCash_Amount = ISNULL(Amount,0) FROM CustomerExposures
JOIN #CustomerUnallocated ON CustomerExposures.ExposureCustomerId = #CustomerUnallocated.CustomerId

UPDATE CustomerExposures SET DirectRelationshipCommencedLoanExposure_Amount = CommencedLoan FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(CommencedDealExposure_Amount,0)) AS CommencedLoan FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='DirectRelationship' AND EntityType='Loan' AND CommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET DirectRelationshipCommencedLeaseExposure_Amount = CommencedLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(CommencedDealExposure_Amount,0)) AS CommencedLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='DirectRelationship' AND EntityType IN ('Lease','LeveragedLease') AND CommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET DirectRelationshipOTPLeaseExposure_Amount = OTPLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(OTPLeaseExposure_Amount,0)) AS OTPLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='DirectRelationship' AND EntityType IN ('Lease','LeveragedLease') AND OTPLeaseRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET DirectRelationshipUncommencedDealExposure_Amount = UncomencedLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(UncommencedDealExposure_Amount,0)) AS UncomencedLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='DirectRelationship' AND UncommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET DirectRelationshipLOCBalanceExposure_Amount = LOCbalance FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(LOCBalanceExposure_Amount,0)) AS LOCbalance FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='DirectRelationship' AND EntityType ='LOC'
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET IndirectRelationshipCommencedLoanExposure_Amount = CommencedLoan FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(CommencedDealExposure_Amount,0)) AS CommencedLoan FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='IndirectRelationship' AND EntityType='Loan' AND CommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET IndirectRelationshipCommencedLeaseExposure_Amount = CommencedLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(CommencedDealExposure_Amount,0)) AS CommencedLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='IndirectRelationship' AND EntityType IN ('Lease','LeveragedLease') AND CommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET IndirectRelationshipOTPLeaseExposure_Amount = OTPLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(OTPLeaseExposure_Amount,0)) AS OTPLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='IndirectRelationship' AND EntityType IN ('Lease','LeveragedLease') AND OTPLeaseRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET IndirectRelationshipUncommencedDealExposure_Amount = UncomencedLease FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(UncommencedDealExposure_Amount,0)) AS UncomencedLease FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='IndirectRelationship' AND UncommencedDealRNI_Amount > 0
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET IndirectRelationshipLOCBalanceExposure_Amount = LOCbalance FROM 
(SELECT DealExposures.ExposureCustomerId CustomerId,SUM(ISNULL(LOCBalanceExposure_Amount,0)) AS LOCbalance FROM CustomerExposures
JOIN DealExposures ON CustomerExposures.ExposureCustomerId = DealExposures.ExposureCustomerId
WHERE ExposureType='IndirectRelationship' AND EntityType ='LOC'
GROUP BY DealExposures.ExposureCustomerId) Grouped  WHERE CustomerExposures.ExposureCustomerId = Grouped.CustomerId

UPDATE CustomerExposures SET 
IndirectRelationshipUnallocatedSecurityDepositOSAR_Amount = ISNULL(UCE.SecurityDepositOSARAmount,0)
,IndirectRelationshipUnallocatedSecurityDeposit_Amount = ISNULL(UCE.SecurityDepositAmount,0)
,IndirectRelationshipUnallocatedCash_Amount = ISNULL(UCE.UnallocatedAmount,0)
--SELECT CE.ExposureCustomerId, IndirectRelationshipUnallocatedCash_Amount ,UCE.Amount
FROM CustomerExposures CE JOIN #IndirectCustomersUnallocated UCE ON CE.ExposureCustomerId = UCE.ExposureCustomerId

UPDATE CustomerExposures SET 
TotalPrimaryCustomerExposure_Amount=ISNULL(PrimaryCustomerCommencedLoanExposure_Amount,0) + ISNULL(PrimaryCustomerCommencedLeaseExposure_Amount,0) 
	+ ISNULL(PrimaryCustomerOTPLeaseExposure_Amount,0) + ISNULL(PrimaryCustomerUncommencedDealExposure_Amount,0) 
	+ ISNULL(PrimaryCustomerLOCBalanceExposure_Amount,0) + ISNULL(PrimaryCustomerUnallocatedSecurityDepositOSAR_Amount,0) 
	- ISNULL(PrimaryCustomerUnallocatedSecurityDeposit_Amount,0) - ISNULL(PrimaryCustomerUnallocatedCash_Amount,0)
,TotalDirectRelationshipExposure_Amount = ISNULL(DirectRelationshipCommencedLoanExposure_Amount,0) + ISNULL(DirectRelationshipCommencedLeaseExposure_Amount,0) 
	+ ISNULL(DirectRelationshipOTPLeaseExposure_Amount,0)+ ISNULL(DirectRelationshipUncommencedDealExposure_Amount,0) + ISNULL(DirectRelationshipLOCBalanceExposure_Amount,0)
,TotalIndirectRelationshipExposure_Amount = ISNULL(IndirectRelationshipCommencedLoanExposure_Amount,0) + ISNULL(IndirectRelationshipCommencedLeaseExposure_Amount,0) 
	+ ISNULL(IndirectRelationshipOTPLeaseExposure_Amount,0) + ISNULL(IndirectRelationshipUncommencedDealExposure_Amount,0) 
	+ ISNULL(IndirectRelationshipLOCBalanceExposure_Amount,0) + ISNULL(IndirectRelationshipUnallocatedSecurityDepositOSAR_Amount,0) 
	- ISNULL(IndirectRelationshipUnallocatedSecurityDeposit_Amount,0) - ISNULL(IndirectRelationshipUnallocatedCash_Amount,0)
,TotalCreditExposure_Amount = (ISNULL(PrimaryCustomerCommencedLoanExposure_Amount,0) + ISNULL(PrimaryCustomerCommencedLeaseExposure_Amount,0) 
	+ ISNULL(PrimaryCustomerOTPLeaseExposure_Amount,0) + ISNULL(PrimaryCustomerUncommencedDealExposure_Amount,0)+ ISNULL(PrimaryCustomerLOCBalanceExposure_Amount,0) 
	+ ISNULL(PrimaryCustomerUnallocatedSecurityDepositOSAR_Amount,0) - ISNULL(PrimaryCustomerUnallocatedSecurityDeposit_Amount,0) - ISNULL(PrimaryCustomerUnallocatedCash_Amount,0))
	+ (ISNULL(DirectRelationshipCommencedLoanExposure_Amount,0) + ISNULL(DirectRelationshipCommencedLeaseExposure_Amount,0) + ISNULL(DirectRelationshipOTPLeaseExposure_Amount,0) 
	+ ISNULL(DirectRelationshipUncommencedDealExposure_Amount,0) + ISNULL(DirectRelationshipLOCBalanceExposure_Amount,0)) + (ISNULL(IndirectRelationshipCommencedLoanExposure_Amount,0) 
	+ ISNULL(IndirectRelationshipCommencedLeaseExposure_Amount,0) + ISNULL(IndirectRelationshipOTPLeaseExposure_Amount,0) + ISNULL(IndirectRelationshipUncommencedDealExposure_Amount,0) 
	+ ISNULL(IndirectRelationshipLOCBalanceExposure_Amount,0) + ISNULL(IndirectRelationshipUnallocatedSecurityDepositOSAR_Amount,0) - ISNULL(IndirectRelationshipUnallocatedSecurityDeposit_Amount,0) - ISNULL(IndirectRelationshipUnallocatedCash_Amount,0))

UPDATE CustomerExposures SET TotalPrimaryCustomerExposure_Amount = 0.00 WHERE TotalPrimaryCustomerExposure_Amount < 0
UPDATE CustomerExposures SET TotalCreditExposure_Amount = 0.00 WHERE TotalCreditExposure_Amount < 0
UPDATE CustomerExposures SET TotalDirectRelationshipExposure_Amount = 0.00 WHERE TotalDirectRelationshipExposure_Amount < 0
UPDATE CustomerExposures SET TotalIndirectRelationshipExposure_Amount = 0.00 WHERE TotalIndirectRelationshipExposure_Amount < 0
	
/* END - CustomerExposure To Insert Customer Exposure tables */

/* Update Same Day Credit Approvals */

IF @CustomerId IS NULL
	UPDATE Customers SET SameDayCreditApprovals_Amount = 0,UpdatedById = @CreatedById, UpdatedTime=@CreatedTime
ELSE IF @CustomerId IS NOT NULL
	UPDATE Customers SET SameDayCreditApprovals_Amount = 0,UpdatedById = @CreatedById, UpdatedTime=@CreatedTime WHERE Id = @CustomerId

/* Updating	CreditSummaryExposures table values from CUstomer exposure calculation*/

UPDATE CSE SET 
	CSE.Direct_Amount = CE.TotalDirectRelationshipExposure_Amount
	,CSE.Indirect_Amount = CE.TotalIndirectRelationshipExposure_Amount 
	,CSE.PrimaryCustomer_Amount = CE.TotalPrimaryCustomerExposure_Amount 
	,CSE.AsOfDate = CE.ExposureDate
	,CSE.UpdatedById = @CreatedById, CSE.UpdatedTime=@CreatedTime
FROM CreditSummaryExposures CSE
JOIN CustomerExposures CE ON CSE.CustomerId = CE.ExposureCustomerId
WHERE CSE.ExposureType = 'EF'

UPDATE CSE SET 
	CSE.Direct_Amount = 0
	,CSE.Indirect_Amount = 0
	,CSE.PrimaryCustomer_Amount = 0
	,CSE.AsOfDate = @ExposureDate
	,CSE.UpdatedById = @CreatedById, CSE.UpdatedTime=@CreatedTime
FROM CreditSummaryExposures CSE 
WHERE CSE.ExposureType = 'EF'
AND CSE.CustomerId NOT IN (SELECT ExposureCustomerId FROM CustomerExposures)

	--Update Deal Exposure For OriginatingVendor--
UPDATE DealExposures SET
	DealExposures.OriginatingVendorId=OriginationSourceId
	FROM(
SELECT ContractId,OriginationSourceId,'Lease' as ContractType
	FROM LeaseFinances
	JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
	JOIN ContractOriginations on LeaseFinances.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes on ContractOriginations.OriginationSourceTypeId =OriginationSourceTypes.Id
	JOIN Vendors on ContractOriginations.OriginationSourceId =Vendors.Id
	AND IsCurrent = 1 AND (@CustomerId IS NULL OR LeaseFinances.CustomerId = @CustomerId) 
	WHERE OriginationSourceTypes.Name='Vendor' AND Vendors.Status='Active'
	UNION ALL
	SELECT ContractId,OriginationSourceId , Contracts.ContractType as ContractType
	FROM LoanFinances 
	JOIN Contracts ON LoanFinances.ContractId = Contracts.Id 
	JOIN ContractOriginations on LoanFinances.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes on ContractOriginations.OriginationSourceTypeId =OriginationSourceTypes.Id
	JOIN Vendors on ContractOriginations.OriginationSourceId = Vendors.Id
	AND IsCurrent = 1 AND (@CustomerId IS NULL OR LoanFinances.CustomerId = @CustomerId) 
	where OriginationSourceTypes.Name='Vendor'	AND Vendors.Status='Active'
	UNION ALL
	SELECT CreditProfiles.Id as ContractId,OriginationSourceId,'LOC' as ContractType
	FROM CreditProfiles
	JOIN OriginationSourceTypes on CreditProfiles.OriginationSourceTypeId =OriginationSourceTypes.Id
	JOIN Vendors on CreditProfiles.OriginationSourceId =Vendors.Id
	AND (@CustomerId IS NULL OR CreditProfiles.CustomerId = @CustomerId) 
	WHERE OriginationSourceTypes.Name='Vendor'	AND Vendors.Status='Active'
	) as VendorExposure
	join DealExposures on VendorExposure.ContractId = DealExposures.EntityId
	where DealExposures.ExposureType='PrimaryCustomer' AND VendorExposure.ContractType = DealExposures.EntityType 


IF OBJECT_ID('tempdb..#ExposureTypes') IS NOT NULL
	DROP TABLE #ExposureTypes
IF OBJECT_ID('tempdb..#ExposureTypesForDealExposure') IS NOT NULL
	DROP TABLE #ExposureTypesForDealExposure
IF OBJECT_ID('tempdb..#CustomersRelationship') IS NOT NULL
	DROP TABLE #CustomersRelationship
IF OBJECT_ID('tempdb..#ParentChildCustomerPrimaryDeals') IS NOT NULL
	DROP TABLE #ParentChildCustomerPrimaryDeals
IF OBJECT_ID('tempdb..#IndirectCustomersRelationship') IS NOT NULL
	DROP TABLE #IndirectCustomersRelationship
IF OBJECT_ID('tempdb..#IndirectParentChildCustomerPrimaryDeals') IS NOT NULL
	DROP TABLE #IndirectParentChildCustomerPrimaryDeals
IF OBJECT_ID('tempdb..#DealExposure') IS NOT NULL
	DROP TABLE #DealExposure
IF OBJECT_ID('tempdb..#LOCContractLevel') IS NOT NULL
	DROP TABLE #LOCContractLevel
IF OBJECT_ID('tempdb..#CustomerUnallocated') IS NOT NULL
	DROP TABLE #CustomerUnallocated
IF OBJECT_ID('tempdb..#CustomerUnallocatedSecDep') IS NOT NULL
	DROP TABLE #CustomerUnallocatedSecDep
IF OBJECT_ID('tempdb..#CustomerUnallocatedSecDepOSAR') IS NOT NULL
	DROP TABLE #CustomerUnallocatedSecDepOSAR
IF OBJECT_ID('tempdb..#LatestRNI') IS NOT NULL
	DROP TABLE #LatestRNI
IF OBJECT_ID('tempdb..#DealExposureCustomers') IS NOT NULL
	DROP TABLE #DealExposureCustomers
IF OBJECT_ID('tempdb..#InDirectCustomersToDelete') IS NOT NULL
	DROP TABLE #InDirectCustomersToDelete
IF OBJECT_ID('tempdb..#AssumptionTable') IS NOT NULL
	DROP TABLE #AssumptionTable
IF OBJECT_ID('tempdb..#AllCustomersForContract') IS NOT NULL
	DROP TABLE #AllCustomersForContract
IF OBJECT_ID('tempdb..#LatestRNIToProcess') IS NOT NULL
	DROP TABLE #LatestRNIToProcess
IF OBJECT_ID('tempdb..#RNItoReduceFromCurrentCustomer') IS NOT NULL
	DROP TABLE #RNItoReduceFromCurrentCustomer
IF OBJECT_ID('tempdb..#ContractCustomers') IS NOT NULL
	DROP TABLE #ContractCustomers
IF OBJECT_ID('tempdb..#IndirectCustomersUnallocated') IS NOT NULL
	DROP TABLE #IndirectCustomersUnallocated
IF OBJECT_ID('tempdb..#CustomerExposure') IS NOT NULL
	DROP TABLE #CustomerExposure
IF OBJECT_ID('tempdb..#LOCUsedAmount') IS NOT NULL
	DROP TABLE #LOCUsedAmount
IF OBJECT_ID('tempdb..#TotalFinancedAmount') IS NOT NULL
	DROP TABLE #TotalFinancedAmount
IF OBJECT_ID('tempdb..#CustomerExposure') IS NOT NULL
	DROP TABLE #CustomerExposure
IF OBJECT_ID('tempdb..#FutureFundedAmount') IS NOT NULL
	DROP TABLE #FutureFundedAmount
IF OBJECT_ID('tempdb..#LOCUsedAmountTemp1') IS NOT NULL
	DROP TABLE #LOCUsedAmountTemp1
IF OBJECT_ID('tempdb..#LocUsedAmountForParentChild') IS NOT NULL
	DROP TABLE #LocUsedAmountForParentChild
IF OBJECT_ID('tempdb..#LOCUsedAmountChild') IS NOT NULL
	DROP TABLE #LOCUsedAmountChild

END

GO
