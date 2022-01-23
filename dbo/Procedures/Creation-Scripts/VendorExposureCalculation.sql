SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[VendorExposureCalculation]
(
	@AsOfDate DATE = NULL
	,@CreatedById BIGINT
	,@CreatedTime DATETIMEOFFSET
	,@DefaultCurrency NVARCHAR(3)
)
AS
BEGIN
SET NOCOUNT ON


--DECLARE	@AsOfDate DATE = '2018-01-01'
----DECLARE	@VendorId BIGINT = null
--DECLARE @ContractMin BIGINT =1
--DECLARE @ContractMax  BIGINT = 1800
--DECLARE	@CreatedById BIGINT = 1
--DECLARE	@CreatedTime DATETIMEOFFSET = GETDATE()
--DECLARE   @DefaultCurrency NVARCHAR(3) = 'USD'


CREATE TABLE #ExposureTypes 
(
	VendorId BIGINT
	,ExposureType NVARCHAR(100)
	,RelationType NVARCHAR(100)
	,EntityId BIGINT
	,EntityType NVARCHAR(100)
	,IsLoc TINYINT 
	,ExposureVendorId BIGINT
)


CREATE TABLE #VendorsRelationship
(
	ExposureVendorId BIGINT
	,VendorId BIGINT
	,RelationType NVARCHAR(100)
	,ParentChildVendorId BIGINT
	,IsLoc BIT
)
CREATE INDEX IX_VendorId_IsLoc_RelationType_ExposureVendorId ON #VendorsRelationship (VendorId,IsLoc,RelationType,ExposureVendorId)


CREATE TABLE #ParentChildVendorPrimaryDeals
(
	VendorId BIGINT
	,ContractID BIGINT
	,ContractType NVARCHAR(100)
	,ExposureVendorId BIGINT
	,IsLoc BIT
)

CREATE TABLE #ContractVendors
(
ContractId BIGINT
,VendorId BIGINT
,ContractType NVARCHAR(50)
)

CREATE INDEX IX_VendorId ON #ContractVendors (VendorId)

CREATE TABLE #VendorExposure
(
	ExposureVendorId BIGINT NOT NULL
	,ExposureDate DATETIME NOT NULL
	,IsActive BIT 
	,OwnedDirectExposure Decimal(24,2) NULL
	,OwnedIndirectExposure Decimal(24,2) NULL
	,SyndicatedDirectExposure Decimal(24,2) NULL
	,SyndicatedIndirectExposure Decimal(24,2) NULL
	,TotalVendorExposure Decimal(24,2) NULL
	,ExposureType NVARCHAR(100)
	,VendorId BIGINT
)

--DECLARE @DefaultCurrencyId BIGINT

--SELECT @DefaultCurrencyId=Currencies.Id FROM Currencies 
--JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
--AND CurrencyCodes.ISO=@DefaultCurrency AND Currencies.IsActive = 1;

/* To fetch VendorId of each contract*/

-- Lease
INSERT INTO #ContractVendors
SELECT ContractId,Vendors.Id as VendorId,Contracts.ContractType
	FROM LeaseFinances
	JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id 
	JOIN ContractOriginations ON LeaseFinances.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
	JOIN Vendors ON ContractOriginations.OriginationSourceId = Vendors.Id AND Vendors.Status ='Active'
	AND IsCurrent = 1 
	AND OriginationSourceTypes.Name = 'Vendor' 

-- Loans
INSERT INTO #ContractVendors
SELECT ContractId,Vendors.Id as VendorId,Contracts.ContractType
	FROM LoanFinances 
	JOIN Contracts ON LoanFinances.ContractId = Contracts.Id 
	JOIN ContractOriginations ON LoanFinances.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
	JOIN Vendors ON ContractOriginations.OriginationSourceId = Vendors.Id AND Vendors.Status ='Active'
	AND IsCurrent = 1
	AND OriginationSourceTypes.Name = 'Vendor'

-- LeveragedLeases
INSERT INTO #ContractVendors
SELECT ContractId,Vendors.Id as VendorId,Contracts.ContractType 
	FROM LeveragedLeases
	JOIN Contracts ON LeveragedLeases.ContractId = Contracts.Id 
	JOIN ContractOriginations ON LeveragedLeases.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
	JOIN Vendors ON ContractOriginations.OriginationSourceId = Vendors.Id AND Vendors.Status ='Active'
	AND IsCurrent = 1 
	AND OriginationSourceTypes.Name = 'Vendor'

/* START - Vendor Relationship */
/* START - Primary Vendor deals */

	INSERT INTO #ExposureTypes (VendorId,ExposureType,RelationType,EntityId,EntityType,IsLoc,ExposureVendorId)
	SELECT VendorId VendorId,'DirectRelationship','DirectRelationship' ,ContractId,ContractType,0,VendorId
	FROM #ContractVendors; 

	/* If vendor does not have any primary contracts */
	INSERT INTO #ExposureTypes (VendorId,ExposureType,RelationType,EntityId,EntityType,IsLoc,ExposureVendorId)
	SELECT NULL VendorId,'DirectRelationship','DirectRelationship' ,0,'Dummy',0,Vendors.Id
	FROM Vendors 
	LEFT JOIN #ExposureTypes ON VendorId = Vendors.Id 
	LEFT JOIN #ContractVendors ON  Vendors.Id = #ContractVendors.VendorId
	WHERE  #ExposureTypes.VendorId IS NULL


/* END - Primary Vendor deals */

/* START - Primary Vendors Parent Child Relationship*/

-- parent
INSERT INTO #VendorsRelationship
SELECT DISTINCT #ExposureTypes.ExposureVendorId,ParentPartyId,'Parent',ParentPartyId,0 FROM Parties
JOIN #ExposureTypes ON Parties.Id = #ExposureTypes.ExposureVendorId AND #ExposureTypes.ExposureType = 'DirectRelationship' AND IsLoc = 0 
AND ParentPartyId IS NOT NULL AND #ExposureTypes.ExposureVendorId != ParentPartyId 

-- siblings
INSERT INTO #VendorsRelationship
SELECT DISTINCT #VendorsRelationship.ExposureVendorId,Parties.Id,'Parent',Parties.Id,0 FROM Parties
JOIN #VendorsRelationship ON Parties.ParentPartyId = #VendorsRelationship.VendorId AND IsLoc = 0 AND RelationType='Parent'
AND #VendorsRelationship.ExposureVendorId != Parties.Id 

-- child
INSERT INTO #VendorsRelationship
SELECT DISTINCT #ExposureTypes.ExposureVendorId,Parties.Id,'Child',Parties.Id,0 FROM Parties
JOIN #ExposureTypes ON Parties.ParentPartyId = #ExposureTypes.ExposureVendorId AND #ExposureTypes.ExposureType = 'DirectRelationship' AND IsLoc = 0
AND #ExposureTypes.ExposureVendorId != Parties.Id

INSERT INTO #ParentChildVendorPrimaryDeals
SELECT #ContractVendors.VendorId,ContractId,ContractType,#VendorsRelationship.ExposureVendorId,0 
FROM #VendorsRelationship 
JOIN #ContractVendors ON #VendorsRelationship.VendorId = #ContractVendors.VendorId AND #VendorsRelationship.IsLoc = 0

INSERT INTO #ExposureTypes (VendorId,ExposureType,RelationType,EntityId,EntityType,IsLoc,ExposureVendorId)
SELECT DISTINCT #ParentChildVendorPrimaryDeals.VendorId,'IndirectRelationship','IndirectRelationship',#ParentChildVendorPrimaryDeals.ContractID,#ParentChildVendorPrimaryDeals.ContractType,0,#ExposureTypes.ExposureVendorId 
FROM #ParentChildVendorPrimaryDeals JOIN #ExposureTypes ON #ParentChildVendorPrimaryDeals.ExposureVendorId = #ExposureTypes.ExposureVendorId
AND #ExposureTypes.RelationType = 'DirectRelationship' AND #ExposureTypes.IsLoc = 0

/* END - Primary Vendors Parent Child Relationship*/


/* END - Vendor Relationship */

/* START - LOC Starts */

INSERT INTO #ExposureTypes (VendorId,ExposureType,RelationType,EntityId,EntityType,IsLoc,ExposureVendorId)
SELECT DISTINCT CreditProfiles.OriginationSourceId as VendorId,'DirectRelationship','DirectRelationship',CreditProfileId,'LOC' ,1,CreditProfiles.OriginationSourceId FROM CreditProfiles 
JOIN CreditDecisions ON CreditDecisions.CreditProfileId = CreditProfiles.Id
JOIN OriginationSourceTypes ON CreditProfiles.OriginationSourceTypeId = OriginationSourceTypes.Id AND OriginationSourceTypes.Name='Vendor'
--LEFT JOIN #ExposureTypes on CreditProfiles.OriginationSourceId = #ExposureTypes.ExposureVendorId
WHERE CreditDecisions.DecisionStatus = 'Approved' AND ExpiryDate >= @AsOfDate
AND CreditDecisions.IsActive = 1

INSERT INTO #ExposureTypes (VendorId,ExposureType,RelationType,EntityId,EntityType,IsLoc,ExposureVendorId)
SELECT DISTINCT Vendors.Id,'DirectRelationship','DirectRelationship',NULL,'LOC' ,1,Vendors.Id FROM Vendors
LEFT JOIN #ExposureTypes ON VendorId = Vendors.Id 
--LEFT JOIN #ContractVendors ON  Vendors.Id = #ContractVendors.VendorId
WHERE  #ExposureTypes.VendorId IS NULL 

/* START - Primary Customers Parent Child Relationship*/

-- Parent
INSERT INTO #VendorsRelationship
SELECT DISTINCT #ExposureTypes.ExposureVendorId,ParentPartyId,'Parent',ParentPartyId,1 FROM Parties
JOIN #ExposureTypes ON Parties.Id = #ExposureTypes.ExposureVendorId AND #ExposureTypes.ExposureType = 'DirectRelationship' AND IsLoc = 1 
AND ParentPartyId IS NOT NULL AND #ExposureTypes.ExposureVendorId != ParentPartyId

-- siblings
INSERT INTO #VendorsRelationship
SELECT DISTINCT #VendorsRelationship.ExposureVendorId,Parties.Id,'Parent',Parties.Id,1 FROM Parties
JOIN #VendorsRelationship ON Parties.ParentPartyId = #VendorsRelationship.VendorId AND IsLoc = 1 AND RelationType='Parent'
AND #VendorsRelationship.ExposureVendorId != Parties.Id

--child
INSERT INTO #VendorsRelationship
SELECT DISTINCT #ExposureTypes.ExposureVendorId,Parties.Id,'Child',Parties.Id,1 FROM Parties
JOIN #ExposureTypes ON Parties.ParentPartyId = #ExposureTypes.ExposureVendorId AND #ExposureTypes.ExposureType = 'DirectRelationship' AND IsLoc = 1
AND #ExposureTypes.ExposureVendorId != Parties.Id

INSERT INTO #ParentChildVendorPrimaryDeals
SELECT DISTINCT 
	CreditProfiles.CustomerId,CreditProfileId,'LOC',#VendorsRelationship.ExposureVendorId,1
FROM CreditProfiles 
JOIN CreditDecisions ON CreditDecisions.CreditProfileId = CreditProfiles.Id
JOIN #VendorsRelationship ON #VendorsRelationship.VendorId = CreditProfiles.CustomerId
WHERE CreditDecisions.DecisionStatus = 'Approved' AND ExpiryDate >= @AsOfDate 
AND CreditDecisions.IsActive =1

INSERT INTO #ExposureTypes (VendorId,ExposureType,RelationType,EntityId,EntityType,IsLoc,ExposureVendorId)
SELECT DISTINCT #ParentChildVendorPrimaryDeals.VendorId,'IndirectRelationship','IndirectRelationship',#ParentChildVendorPrimaryDeals.ContractID,#ParentChildVendorPrimaryDeals.ContractType,1,#ExposureTypes.ExposureVendorId 
FROM #ParentChildVendorPrimaryDeals JOIN #ExposureTypes ON #ParentChildVendorPrimaryDeals.ExposureVendorId = #ExposureTypes.ExposureVendorId
AND #ExposureTypes.RelationType = 'DirectRelationship' AND #ExposureTypes.IsLoc = 1 AND #ParentChildVendorPrimaryDeals.IsLoc = 1

/* END - Primary Customers Parent Child Relationship*/
/* END - LOC Ends*/

DELETE FROM #ExposureTypes WHERE EntityId IS NULL OR EntityId = 0

/* START - Vendors have both Direct and Indirect Relationship then we should not consider Indirect relationship*/
;WITH CTE_DirectRelationship AS
(
SELECT ExposureVendorId,VendorId, ExposureType,EntityType,EntityId FROM #ExposureTypes 
WHERE ExposureType = 'DirectRelationship'
GROUP BY ExposureVendorId,VendorId,ExposureType,EntityType,EntityId
)
DELETE #ExposureTypes FROM #ExposureTypes 
JOIN CTE_DirectRelationship InDirectCustomersToDelete ON #ExposureTypes.VendorId = InDirectCustomersToDelete.VendorId
AND #ExposureTypes.ExposureVendorId = InDirectCustomersToDelete.ExposureVendorId
AND #ExposureTypes.EntityId = InDirectCustomersToDelete.EntityId
WHERE #ExposureTypes.ExposureType = 'IndirectRelationship'

/* END - Vendors have both Direct and Indirect Relationship then we should not consider Indirect relationship*/

/* START - VendorExposure To Insert Deal Exposure tables */

INSERT INTO #VendorExposure
(ExposureVendorId,ExposureDate,IsActive,OwnedDirectExposure,OwnedIndirectExposure,SyndicatedDirectExposure,SyndicatedIndirectExposure,TotalVendorExposure,ExposureType,VendorId)
SELECT DISTINCT
 #ExposureTypes.ExposureVendorId as ExposureVendorId
, @AsOfDate 
, 1 
,0
,0
,0
,0
,0
,#ExposureTypes.ExposureType
,#ExposureTypes.VendorId
FROM #ExposureTypes
GROUP BY VendorId,ExposureType,EntityId,EntityType,IsLoc,ExposureVendorId


UPDATE #VendorExposure SET OwnedDirectExposure = OwnedDirectExposureAmount FROM 
(SELECT DealExposures.OriginatingVendorId VendorId,SUM(ISNULL(DealExposures.TotalExposure_Amount,0)) AS OwnedDirectExposureAmount FROM #VendorExposure
JOIN DealExposures ON #VendorExposure.ExposureVendorId = DealExposures.OriginatingVendorId
WHERE DealExposures.ExposureType='PrimaryCustomer' and #VendorExposure.ExposureType ='DirectRelationship' AND DealExposures.TotalExposure_Amount <> 0
GROUP BY DealExposures.OriginatingVendorId,#VendorExposure.ExposureType) Grouped  WHERE #VendorExposure.ExposureVendorId = Grouped.VendorId

UPDATE #VendorExposure SET OwnedIndirectExposure = OwnedIndirectExposureAmount FROM 
(SELECT #VendorExposure.ExposureVendorId VendorId,SUM(ISNULL(DealExposures.TotalExposure_Amount,0)) AS OwnedIndirectExposureAmount FROM #VendorExposure
JOIN DealExposures ON #VendorExposure.VendorId = DealExposures.OriginatingVendorId 
WHERE   DealExposures.ExposureType='PrimaryCustomer' and #VendorExposure.ExposureType ='IndirectRelationship' AND DealExposures.TotalExposure_Amount <> 0
GROUP BY #VendorExposure.ExposureVendorId,#VendorExposure.ExposureType) Grouped  WHERE #VendorExposure.ExposureVendorId = Grouped.VendorId

----START - Vendor Syndicated Direct And Indirect Exposure----

UPDATE #VendorExposure SET SyndicatedDirectExposure = SyndicatedDirectExposureAmount FROM 
(SELECT SyndicatedDealExposures.OriginationVendorId VendorId,SUM(ISNULL(SyndicatedDealExposures.TotalSyndicatedExposures_Amount,0)) AS SyndicatedDirectExposureAmount 
FROM #VendorExposure
JOIN SyndicatedDealExposures ON #VendorExposure.ExposureVendorId = SyndicatedDealExposures.OriginationVendorId
WHERE #VendorExposure.ExposureType ='DirectRelationship' AND SyndicatedDealExposures.TotalSyndicatedExposures_Amount <> 0
GROUP BY SyndicatedDealExposures.OriginationVendorId,#VendorExposure.ExposureType) Grouped  WHERE #VendorExposure.ExposureVendorId = Grouped.VendorId

UPDATE #VendorExposure SET SyndicatedIndirectExposure = SyndicatedIndirectExposureAmount FROM 
(SELECT #VendorExposure.ExposureVendorId VendorId,SUM(ISNULL(SyndicatedDealExposures.TotalSyndicatedExposures_Amount,0)) AS SyndicatedIndirectExposureAmount
FROM #VendorExposure
JOIN SyndicatedDealExposures ON #VendorExposure.VendorId = SyndicatedDealExposures.OriginationVendorId 
WHERE   #VendorExposure.ExposureType ='IndirectRelationship' AND SyndicatedDealExposures.TotalSyndicatedExposures_Amount <> 0
GROUP BY #VendorExposure.ExposureVendorId,#VendorExposure.ExposureType) Grouped  WHERE #VendorExposure.ExposureVendorId = Grouped.VendorId
----END - Vendor Syndicated Direct And Indirect Exposure----

INSERT INTO VendorExposures
(ExposureVendorId,ExposureDate,IsActive,OwnedDirectExposure_Amount,OwnedDirectExposure_Currency,OwnedIndirectExposure_Amount,OwnedIndirectExposure_Currency,SyndicatedDirectExposure_Amount,SyndicatedDirectExposure_Currency,SyndicatedIndirectExposure_Amount,SyndicatedIndirectExposure_Currency,TotalVendorExposure_Amount,TotalVendorExposure_Currency,CreatedById,CreatedTime) 
SELECT DISTINCT
 #VendorExposure.ExposureVendorId 
, @AsOfDate 
, 1 
,dbo.GetMaxValue(0,OwnedDirectExposure)
,@DefaultCurrency 
,dbo.GetMaxValue(0,OwnedIndirectExposure)
,@DefaultCurrency
,dbo.GetMaxValue(0,SyndicatedDirectExposure)
,@DefaultCurrency
,dbo.GetMaxValue(0,SyndicatedIndirectExposure)
,@DefaultCurrency
,dbo.GetMaxValue(0,OwnedDirectExposure + OwnedIndirectExposure + SyndicatedDirectExposure + SyndicatedIndirectExposure)
,@DefaultCurrency
,@CreatedById
,@CreatedTime
FROM #VendorExposure

/* END - VendorExposure To Insert Deal Exposure tables */

IF OBJECT_ID('tempdb..#ExposureTypes') IS NOT NULL
	DROP TABLE #ExposureTypes
IF OBJECT_ID('tempdb..#VendorsRelationship') IS NOT NULL
	DROP TABLE #VendorsRelationship
IF OBJECT_ID('tempdb..#ParentChildVendorPrimaryDeals') IS NOT NULL
	DROP TABLE #ParentChildVendorPrimaryDeals
IF OBJECT_ID('tempdb..#ContractVendors') IS NOT NULL
	DROP TABLE #ContractVendors
IF OBJECT_ID('tempdb..#VendorExposure') IS NOT NULL
	DROP TABLE #VendorExposure

END

GO
