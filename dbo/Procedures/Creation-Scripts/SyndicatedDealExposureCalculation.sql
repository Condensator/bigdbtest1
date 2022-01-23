SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SyndicatedDealExposureCalculation]
(
	@AsOfDate DATE = NULL
	,@CreatedById BIGINT
	,@CreatedTime DATETIMEOFFSET
	,@DefaultCurrency NVARCHAR(3)	
)
AS
BEGIN
SET NOCOUNT ON

--DECLARE @ContractMin BIGINT =1
--DECLARE @ContractMax  BIGINT = 652
--DECLARE	@CreatedById BIGINT = 1
--DECLARE	@CreatedTime DATETIMEOFFSET = GETDATE()
--DECLARE @DefaultCurrency NVARCHAR(3) = 'USD'
--DECLARE @AsOfDate DATE = '2016-01-01'

CREATE TABLE #SyndicatedContractVendors
(
ContractId BIGINT
,VendorId BIGINT
,ContractType NVARCHAR(50)
,SyndicatedLOCBalanceExposureRevolving_Amount Decimal(24,2)  NULL
,SyndicatedLOCBalanceExposureNonRevolving_Amount Decimal(24,2) NULL 
)

CREATE INDEX IX_VendorId ON #SyndicatedContractVendors (VendorId)

CREATE TABLE #SydicatedDealExposure
(
	 EntityID  BIGINT NOT NULL
	,EntityType NVARCHAR(100) NOT NULL
	,ExposureDate DATETIME NOT NULL
	,RNIID BIGINT NULL
	,SyndicatedLOCBalanceExposureRevolving_Amount Decimal(24,2) NULL
	,SyndicatedLOCBalanceExposureNonRevolving_Amount Decimal(24,2) NULL
	,SyndicatedContractExposure_Amount Decimal(24,2) NULL
	,TotalSyndicatedExposures_Amount Decimal(24,2) NULL
	,OriginationVendorId BIGINT
)


/* START To fetch Vendors associated with Syndicated contracts/LOC's*/

-- Lease
INSERT INTO #SyndicatedContractVendors
SELECT ContractId,Vendors.Id as VendorId,Contracts.ContractType,0.00,0.00
	FROM LeaseFinances
	JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
	JOIN ContractOriginations ON LeaseFinances.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
	JOIN Vendors ON ContractOriginations.OriginationSourceId = Vendors.Id AND Vendors.Status ='Active'
	AND IsCurrent = 1 AND OriginationSourceTypes.Name = 'Vendor' AND Contracts.SyndicationType <> 'None'

-- Loans
INSERT INTO #SyndicatedContractVendors
SELECT ContractId,Vendors.Id as VendorId,Contracts.ContractType,0.00,0.00
	FROM LoanFinances 
	JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
	JOIN ContractOriginations ON LoanFinances.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
	JOIN Vendors ON ContractOriginations.OriginationSourceId = Vendors.Id AND Vendors.Status ='Active'
	AND IsCurrent = 1 AND OriginationSourceTypes.Name = 'Vendor' AND Contracts.SyndicationType <> 'None'

-- LeveragedLeases
INSERT INTO #SyndicatedContractVendors
SELECT ContractId,Vendors.Id as VendorId,Contracts.ContractType,0.00,0.00 
	FROM LeveragedLeases
	JOIN Contracts ON LeveragedLeases.ContractId = Contracts.Id
	JOIN ContractOriginations ON LeveragedLeases.ContractOriginationId = ContractOriginations.Id
	JOIN OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
	JOIN Vendors ON ContractOriginations.OriginationSourceId = Vendors.Id AND Vendors.Status ='Active'
	AND IsCurrent = 1 AND OriginationSourceTypes.Name = 'Vendor' AND Contracts.SyndicationType <> 'None'

-- LOC
INSERT INTO #SyndicatedContractVendors
SELECT CreditProfileId,Vendors.Id as VendorId,'LOC'
,SUM(CASE WHEN (CreditProfiles.IsRevolving = 1 AND  (CreditProfiles.ApprovedAmount_Amount - CreditProfiles.UsedAmount_Amount)>0.00) THEN  (CreditProfiles.ApprovedAmount_Amount - CreditProfiles.UsedAmount_Amount) ELSE 0.00 END)
,SUM(CASE WHEN (CreditProfiles.IsRevolving = 0 AND  (CreditProfiles.ApprovedAmount_Amount - CreditProfiles.UsedAmount_Amount)>0.00) THEN  (CreditProfiles.ApprovedAmount_Amount - CreditProfiles.UsedAmount_Amount) ELSE 0.00 END)
FROM CreditProfiles 
JOIN CreditDecisions ON CreditDecisions.CreditProfileId = CreditProfiles.Id
JOIN OriginationSourceTypes ON CreditProfiles.OriginationSourceTypeId = OriginationSourceTypes.Id AND OriginationSourceTypes.Name='Vendor'
JOIN Vendors ON CreditProfiles.OriginationSourceId = Vendors.Id AND Vendors.Status ='Active'
WHERE  CreditProfiles.IsSyndicated=1 AND CreditDecisions.DecisionStatus = 'Approved' AND ExpiryDate >= @AsOfDate
AND CreditDecisions.IsActive = 1
GROUP BY CreditDecisions.CreditProfileId,Vendors.Id

/* End To fetch Vendors associated with Syndicated contracts/LOC's*/

/* Contract Level Syndicated Deal Exposure calculation */
; WITH CTE_LatestRNI AS
(
SELECT ROW_NUMBER() OVER (PARTITION BY RNI.ContractId ORDER by RNI.Id DESC) RowId,
	RNI.Id RNIID,
	RNI.ContractId,
	RNI.IncomeDate,
	RNI.ServicedRNIAmount,
	RNI.CreditProfileId,
	RNI.ContractType,
	IsOTP,
	CurrencyId,
	SubType,
	Status
FROM RemainingNetInvestments RNI 
WHERE IsActive = 1
) 
INSERT INTO #SydicatedDealExposure
(
	 EntityID  
	,EntityType 
	,ExposureDate 
	,RNIID 
	,SyndicatedLOCBalanceExposureRevolving_Amount 
	,SyndicatedLOCBalanceExposureNonRevolving_Amount 
	,SyndicatedContractExposure_Amount 
	,TotalSyndicatedExposures_Amount
	,OriginationVendorId 
)
SELECT DISTINCT
#SyndicatedContractVendors.ContractId as ContractId
,#SyndicatedContractVendors.ContractType
,@AsOfDate
,CTE_LatestRNI.RNIID
,0
,0
,CTE_LatestRNI.ServicedRNIAmount
,0
,#SyndicatedContractVendors.VendorId
 FROM CTE_LatestRNI
JOIN #SyndicatedContractVendors ON CTE_LatestRNI.ContractId = #SyndicatedContractVendors.ContractId
AND CTE_LatestRNI.ContractType = #SyndicatedContractVendors.ContractType AND CTE_LatestRNI.RowId =1

/*LOC Level Sydicated Deal Exposure Calculation */
INSERT INTO #SydicatedDealExposure
(
	 EntityID  
	,EntityType 
	,ExposureDate 
	,RNIID 
	,SyndicatedLOCBalanceExposureRevolving_Amount 
	,SyndicatedLOCBalanceExposureNonRevolving_Amount 
	,SyndicatedContractExposure_Amount 
	,TotalSyndicatedExposures_Amount
	,OriginationVendorId 
)
SELECT DISTINCT
#SyndicatedContractVendors.ContractId as ContractId
,#SyndicatedContractVendors.ContractType
,@AsOfDate
,NULL
,#SyndicatedContractVendors.SyndicatedLOCBalanceExposureRevolving_Amount 
,#SyndicatedContractVendors.SyndicatedLOCBalanceExposureNonRevolving_Amount
,0
,0
,#SyndicatedContractVendors.VendorId
 FROM #SyndicatedContractVendors 
 Where #SyndicatedContractVendors.ContractType = 'LOC'


  UPDATE #SydicatedDealExposure SET TotalSyndicatedExposures_Amount = SyndicatedLOCBalanceExposureRevolving_Amount + SyndicatedLOCBalanceExposureNonRevolving_Amount + SyndicatedContractExposure_Amount;
 
 /* Final insert into Syndicated Deal Exposure Table*/

  INSERT INTO SyndicatedDealExposures
		(  [EntityType]
           ,[EntityId]
		   ,[RNIId]
           ,[SyndicatedLOCBalanceExposureRevolving_Amount]
           ,[SyndicatedLOCBalanceExposureRevolving_Currency]
           ,[SyndicatedLOCBalanceExposureNonRevolving_Amount]
           ,[SyndicatedLOCBalanceExposureNonRevolving_Currency]
           ,[SyndicatedContractExposure_Amount]
           ,[SyndicatedContractExposure_Currency]
           ,[TotalSyndicatedExposures_Amount]
           ,[TotalSyndicatedExposures_Currency]
           ,[IsActive]
           ,[ExposureDate]
           ,[OriginationVendorId]
           ,[CreatedById]
           ,[CreatedTime])
  SELECT DISTINCT
 #SydicatedDealExposure.EntityType
 ,#SydicatedDealExposure.EntityID
 ,#SydicatedDealExposure.RNIID
 ,dbo.GetMaxValue(0,#SydicatedDealExposure.SyndicatedLOCBalanceExposureRevolving_Amount)
 ,@DefaultCurrency
 ,dbo.GetMaxValue(0,#SydicatedDealExposure.SyndicatedLOCBalanceExposureNonRevolving_Amount)
 ,@DefaultCurrency
 ,dbo.GetMaxValue(0,#SydicatedDealExposure.SyndicatedContractExposure_Amount)
 ,@DefaultCurrency
 ,dbo.GetMaxValue(0,#SydicatedDealExposure.TotalSyndicatedExposures_Amount)
 ,@DefaultCurrency
 ,1
 ,@AsOfDate
 ,#SydicatedDealExposure.OriginationVendorId
 ,@CreatedById
 ,@CreatedTime
  FROM
 #SydicatedDealExposure


IF OBJECT_ID('tempdb..#SyndicatedContractVendors') IS NOT NULL
	DROP TABLE #SyndicatedContractVendors
IF OBJECT_ID('tempdb..#SydicatedDealExposure') IS NOT NULL
	DROP TABLE #SydicatedDealExposure

END

GO
