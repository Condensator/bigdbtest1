SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_ContractsGL_Reconciliation]
(@ResultOption      NVARCHAR(20), 
 @IsFromLegalEntity BIT NULL, 
 @LegalEntityIds    ReconciliationId READONLY
)
AS
    BEGIN
	IF OBJECT_ID('tempdb..#ContractTable') IS NOT NULL
BEGIN
	DROP TABLE #ContractTable;
END
        IF OBJECT_ID('tempdb..#EligibleContracts') IS NOT NULL
BEGIN
	DROP TABLE #EligibleContracts;
END
IF OBJECT_ID('tempdb..#OverTerm') IS NOT NULL
BEGIN
	DROP TABLE #OverTerm;
END
IF OBJECT_ID('tempdb..#ChargeOff') IS NOT NULL
BEGIN
	DROP TABLE #ChargeOff;
END
IF OBJECT_ID('tempdb..#RenewalDone') IS NOT NULL
BEGIN
	DROP TABLE #RenewalDone;
END
IF OBJECT_ID('tempdb..#AmendmentList') IS NOT NULL
BEGIN
	DROP TABLE #AmendmentList;
END
IF OBJECT_ID('tempdb..#RenewalDone') IS NOT NULL
BEGIN
	DROP TABLE #RenewalDone;
END
IF OBJECT_ID('tempdb..#ClearedFixedTermAVHIncomeDate') IS NOT NULL
BEGIN
	DROP TABLE #ClearedFixedTermAVHIncomeDate;
END
IF OBJECT_ID('tempdb..#PayOffDetails') IS NOT NULL
BEGIN
	DROP TABLE #PayOffDetails;
END
IF OBJECT_ID('tempdb..#OTPReclass') IS NOT NULL
BEGIN
	DROP TABLE #OTPReclass;
END
IF OBJECT_ID('tempdb..#LeaseFinanceForOTPReclass') IS NOT NULL
BEGIN
	DROP TABLE #LeaseFinanceForOTPReclass;
END
IF OBJECT_ID('tempdb..#FullPaidOffContracts') IS NOT NULL
BEGIN
	DROP TABLE #FullPaidOffContracts;
END
IF OBJECT_ID('tempdb..#SyndicationAVHInfo') IS NOT NULL
BEGIN
	DROP TABLE #SyndicationAVHInfo;
END
IF OBJECT_ID('tempdb..#RenewalDetails') IS NOT NULL
BEGIN
	DROP TABLE #RenewalDetails;
END
IF OBJECT_ID('tempdb..#ReclassDetails') IS NOT NULL
BEGIN
	DROP TABLE #ReclassDetails
END
IF OBJECT_ID('tempdb..#LeaseAssetValues') IS NOT NULL
BEGIN
	DROP TABLE #LeaseAssetValues
END
IF OBJECT_ID('tempdb..#LeaseAssetSkus') IS NOT NULL
BEGIN
	DROP TABLE #LeaseAssetSkus
END
IF OBJECT_ID('tempdb..#GLDetails') IS NOT NULL
BEGIN
	DROP TABLE #GLDetails
END
IF OBJECT_ID('tempdb..#NotCleared') IS NOT NULL
BEGIN
	DROP TABLE #NotCleared
END
IF OBJECT_ID('tempdb..#ChargedOffAssets') IS NOT NULL
BEGIN
	DROP TABLE #ChargedOffAssets
END
IF OBJECT_ID('tempdb..#ClearedAVHIncomeDate') IS NOT NULL
BEGIN
	DROP TABLE #ClearedAVHIncomeDate
END
IF OBJECT_ID('tempdb..#ClearedAVHIncomeDateForImpairment') IS NOT NULL
BEGIN
	DROP TABLE #ClearedAVHIncomeDateForImpairment
END
IF OBJECT_ID('tempdb..#ClearedAVHIncomeDateForNBVImpairment') IS NOT NULL
BEGIN
	DROP TABLE #ClearedAVHIncomeDateForNBVImpairment
END
IF OBJECT_ID('tempdb..#NBVAssetValueHistoriesInfo') IS NOT NULL
BEGIN
	DROP TABLE #NBVAssetValueHistoriesInfo
END
IF OBJECT_ID('tempdb..#LeasedAssetReturnedtoInventory') IS NOT NULL
BEGIN
	DROP TABLE #LeasedAssetReturnedtoInventory
END
IF OBJECT_ID('tempdb..#LeasedAssetReturnedtoInventorySKUs') IS NOT NULL
BEGIN
	DROP TABLE #LeasedAssetReturnedtoInventorySKUs
END
IF OBJECT_ID('tempdb..#ClearedFixedTermAVHIncomeDateCO') IS NOT NULL
BEGIN
	DROP TABLE #ClearedFixedTermAVHIncomeDateCO
END
IF OBJECT_ID('tempdb..#Payoffs') IS NOT NULL
BEGIN
	DROP TABLE #Payoffs
END
IF OBJECT_ID('tempdb..#MaxCleared') IS NOT NULL
BEGIN
	DROP TABLE #MaxCleared
END
IF OBJECT_ID('tempdb..#MinCleared') IS NOT NULL
BEGIN
	DROP TABLE #MinCleared
END
IF OBJECT_ID('tempdb..#ContractSummary') IS NOT NULL
BEGIN
	DROP TABLE #ContractSummary
END
IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
BEGIN
	DROP TABLE #ResultList
END
IF OBJECT_ID('tempdb..#Cleared_AssetImpairment') IS NOT NULL
BEGIN
	DROP TABLE #Cleared_AssetImpairment
END
IF OBJECT_ID('tempdb..#Cleared_NBVImpairment') IS NOT NULL
BEGIN
	DROP TABLE #Cleared_NBVImpairment
END
IF OBJECT_ID('tempdb..#NBVImpairment') IS NOT NULL
BEGIN
	DROP TABLE #NBVImpairment
END
IF OBJECT_ID('tempdb..#AssetDepreciation') IS NOT NULL
BEGIN
	DROP TABLE #AssetDepreciation
END
IF OBJECT_ID('tempdb..#ClearedOTPAmount') IS NOT NULL
BEGIN
	DROP TABLE #ClearedOTPAmount
END
IF OBJECT_ID('tempdb..#LastRecordAVHForPayoff') IS NOT NULL
BEGIN
	DROP TABLE #LastRecordAVHForPayoff
END
IF OBJECT_ID('tempdb..#ClearedAssetDepreciationAmount') IS NOT NULL
BEGIN
	DROP TABLE #ClearedAssetDepreciationAmount
END
IF OBJECT_ID('tempdb..#AssetDepreciationAmount') IS NOT NULL
BEGIN
	DROP TABLE #AssetDepreciationAmount
END
IF OBJECT_ID('tempdb..#SyndicationAssetDepreciationAmount') IS NOT NULL
BEGIN
	DROP TABLE #SyndicationAssetDepreciationAmount
END
IF OBJECT_ID('tempdb..#ClearedAssetDepreciation') IS NOT NULL
BEGIN
	DROP TABLE #ClearedAssetDepreciation
END
IF OBJECT_ID('tempdb..#PreviousContact') IS NOT NULL
BEGIN
	DROP TABLE #PreviousContact
END
IF OBJECT_ID('tempdb..#LeaseFinanceIdBeforeRenewal') IS NOT NULL
BEGIN
	DROP TABLE #LeaseFinanceIdBeforeRenewal
END
IF OBJECT_ID('tempdb..#RenewalLeaseAssetValues') IS NOT NULL
BEGIN
	DROP TABLE #RenewalLeaseAssetValues
END
IF OBJECT_ID('tempdb..#RenewalLeaseAssetSkus') IS NOT NULL
BEGIN
	DROP TABLE #RenewalLeaseAssetSkus
END
IF OBJECT_ID('tempdb..#PayoffAssetDetails') IS NOT NULL
BEGIN
	DROP TABLE #PayoffAssetDetails
END
IF OBJECT_ID('tempdb..#ClearedAssetImpairment') IS NOT NULL
BEGIN
	DROP TABLE #ClearedAssetImpairment
END
IF OBJECT_ID('tempdb..#ClearedNBVImpairment') IS NOT NULL
BEGIN
	DROP TABLE #ClearedNBVImpairment
END
IF OBJECT_ID('tempdb..#AssetImpairment') IS NOT NULL
BEGIN
	DROP TABLE #AssetImpairment
END
IF OBJECT_ID('tempdb..#MaxBookValueAdjustment') IS NOT NULL
BEGIN
	DROP TABLE #MaxBookValueAdjustment
END
IF OBJECT_ID('tempdb..#TrueClearedAmount') IS NOT NULL
BEGIN
	DROP TABLE #TrueClearedAmount
END 
IF OBJECT_ID('tempdb..#MaxCleared_TrueCleared') IS NOT NULL
BEGIN
	DROP TABLE #MaxCleared_TrueCleared
END 
IF OBJECT_ID('tempdb..#MinCleared_TrueCleared') IS NOT NULL
BEGIN
	DROP TABLE #MinCleared_TrueCleared
END 
IF OBJECT_ID('tempdb..#OTPDepreciationExists') IS NOT NULL
BEGIN
	DROP TABLE #OTPDepreciationExists
END 
IF OBJECT_ID('tempdb..#TrueClearedAssetImpairmentAmount') IS NOT NULL
BEGIN
	DROP TABLE #TrueClearedAssetImpairmentAmount
END 
IF OBJECT_ID('tempdb..#ContractETCAmount') IS NOT NULL
BEGIN
    DROP TABLE #ContractETCAmount;
END
IF OBJECT_ID('tempdb..#ContractSKUETCAmount') IS NOT NULL
BEGIN
    DROP TABLE #ContractSKUETCAmount;
END
IF OBJECT_ID('tempdb..#RebookContractETCAmount') IS NOT NULL
BEGIN	
	DROP TABLE #RebookContractETCAmount;
END
IF OBJECT_ID('tempdb..#RebookContractSKUETCAmount') IS NOT NULL
BEGIN
	DROP TABLE #RebookContractSKUETCAmount;
END
IF OBJECT_ID('tempdb..#CapitalizedAmounts') IS NOT NULL
BEGIN
	DROP TABLE #CapitalizedAmounts;
END
IF OBJECT_ID('tempdb..#RenewalCapitalizedAmounts') IS NOT NULL
BEGIN
	DROP TABLE #RenewalCapitalizedAmounts;
END
IF OBJECT_ID('tempdb..#LeaseAmendmentInfo') IS NOT NULL
BEGIN
	DROP TABLE #LeaseAmendmentInfo;
END
IF OBJECT_ID('tempdb..#ClearedAssetImpairment') IS NOT NULL
BEGIN
	DROP TABLE #ClearedAssetImpairment;
END
IF OBJECT_ID('tempdb..#ClearedNBVImpairment') IS NOT NULL
BEGIN
	DROP TABLE #ClearedNBVImpairment;
END
IF OBJECT_ID('tempdb..#Impairment_Asset') IS NOT NULL
BEGIN
	DROP TABLE #Impairment_Asset;
END
IF OBJECT_ID('tempdb..#AVHChargeoff') IS NOT NULL
BEGIN
	DROP TABLE #AVHChargeoff;
END
IF OBJECT_ID('tempdb..#SyndicatedPayoffAmount') IS NOT NULL
BEGIN
	DROP TABLE #SyndicatedPayoffAmount;
END
IF OBJECT_ID('tempdb..#SyndicationLeaseAssetReturnedToInventory') IS NOT NULL
BEGIN
	DROP TABLE #SyndicationLeaseAssetReturnedToInventory;
END
IF OBJECT_ID('tempdb..#PayoffAmort_Table') IS NOT NULL
BEGIN
	DROP TABLE #PayoffAmort_Table;
END
IF OBJECT_ID('tempdb..#PaidOffNotCOAmountInfo') IS NOT NULL
BEGIN
	DROP TABLE #PaidOffNotCOAmountInfo;
END
IF OBJECT_ID('tempdb..#FinanceChargeOffAmount_Info') IS NOT NULL
BEGIN
	DROP TABLE #FinanceChargeOffAmount_Info;
END
IF OBJECT_ID('tempdb..#ETCAmort_Table') IS NOT NULL
BEGIN
	DROP TABLE #ETCAmort_Table;
END
IF OBJECT_ID('tempdb..#AmortizeContract') IS NOT NULL
BEGIN
	DROP TABLE #AmortizeContract;
END
IF OBJECT_ID('tempdb..#OperatingPaidOffContract') IS NOT NULL
BEGIN
	DROP TABLE #OperatingPaidOffContract;
END
IF OBJECT_ID('tempdb..#OperatingPaidOffContractSKU') IS NOT NULL
BEGIN
	DROP TABLE #OperatingPaidOffContractSKU;
END
IF OBJECT_ID('tempdb..#CapitalPaidOffContract') IS NOT NULL
BEGIN
	DROP TABLE #CapitalPaidOffContract;
END
IF OBJECT_ID('tempdb..#OperatingInventory') IS NOT NULL
BEGIN
	DROP TABLE #OperatingInventory;
END
IF OBJECT_ID('tempdb..#PayoffandSynContract') IS NOT NULL
BEGIN
	DROP TABLE #PayoffandSynContract;
END
IF OBJECT_ID('tempdb..#AmortChargeOffInfo') IS NOT NULL
BEGIN
	DROP TABLE #AmortChargeOffInfo;
END
IF OBJECT_ID('tempdb..#AccumulatedNotClearedPayoff') IS NOT NULL
BEGIN
	DROP TABLE #AccumulatedNotClearedPayoff;
END
IF OBJECT_ID('tempdb..#ImpairmentOnPayoff') IS NOT NULL
BEGIN
	DROP TABLE #ImpairmentOnPayoff;
END
IF OBJECT_ID('tempdb..#HaveCapitalLeaseLEInfo') IS NOT NULL
BEGIN
	DROP TABLE #HaveCapitalLeaseLEInfo;
END
IF OBJECT_ID('tempdb..#RenewalPaidOffInventory') IS NOT NULL
BEGIN
	DROP TABLE #RenewalPaidOffInventory;
END
IF OBJECT_ID('tempdb..#PayoffNoCOTrueClearedAmount') IS NOT NULL
BEGIN
	DROP TABLE #PayoffNoCOTrueClearedAmount;
END
IF OBJECT_ID('tempdb..#PayoffNoCOTrueClearedAssetImpairmentAmount') IS NOT NULL
BEGIN
	DROP TABLE #PayoffNoCOTrueClearedAssetImpairmentAmount;
END

        DECLARE @True BIT= 1;
        DECLARE @False BIT= 0;
		
        DECLARE @LegalEntitiesCount BIGINT= ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0);
        DECLARE @FilterCondition nvarchar(max) = '';

DECLARE @IsSku BIT = 0;
DECLARE @Sql nvarchar(max) ='';
DECLARE @u_ConversionSource nvarchar(50); 
DECLARE @AddCharge BIT = 0
DECLARE @CapitalizedAdditionalCharge nvarchar(50) = '';
DECLARE @SKUCapitalizedAdditionalCharge nvarchar(50) = '';
DECLARE @ClearAccumulatedAccountsatPayoff nvarchar(50);
SELECT @ClearAccumulatedAccountsatPayoff = Value FROM GlobalParameters WHERE Category ='Payoff' AND Name = 'ClearAccumulatedAccountsatPayoff'

IF @ClearAccumulatedAccountsatPayoff IS NULL
SET @ClearAccumulatedAccountsatPayoff = 'True'

SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource'
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @FilterCondition = ' AND a.IsSKU = 0'
SET @IsSku = 1
END;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
BEGIN
SET @AddCharge = 1;
SET @CapitalizedAdditionalCharge = ' la.CapitalizedAdditionalCharge_Amount'
SET @SKUCapitalizedAdditionalCharge = ' las.CapitalizedAdditionalCharge_Amount'
END;

CREATE TABLE #LeaseAssetValues
(ContractId                       BIGINT, 
 Booking_Inventory_LC             DECIMAL(16, 2), 
 Booking_Inventory_NLC            DECIMAL(16, 2), 
 GPSpecificInventory_NLC          DECIMAL(16, 2), 
 LeasedAssetReturnToInventory_LC  DECIMAL(16, 2), 
 LeasedAssetReturnToInventory_NLC DECIMAL(16, 2),
 OperatingLeaseComponentPaidoff   DECIMAL(16, 2),
 PaidOffAssets_Inventory_LC       DECIMAL(16, 2),
 PaidOffAssets_Inventory_NLC      DECIMAL(16, 2)
);

CREATE TABLE #RenewalLeaseAssetValues
(ContractId                     BIGINT, 
 Renewal_Inventory_LC           DECIMAL(16, 2), 
 Renewal_Inventory_NLC          DECIMAL(16, 2), 
 OperatingLeaseComponentPaidoff DECIMAL(16, 2),
 PaidOffAssets_Inventory_LC     DECIMAL(16, 2),
 PaidOffAssets_Inventory_NLC    DECIMAL(16, 2)
);

CREATE TABLE #LeaseAssetSkus
(ContractId                       BIGINT, 
 Booking_Inventory_LC             DECIMAL(16, 2), 
 Booking_Inventory_NLC            DECIMAL(16, 2), 
 GPSpecificInventory_NLC          DECIMAL(16, 2), 
 LeasedAssetReturnToInventory_LC  DECIMAL(16, 2), 
 LeasedAssetReturnToInventory_NLC DECIMAL(16, 2),
 OperatingLeaseComponentPaidoff	  DECIMAL(16, 2),
 PaidOffAssets_Inventory_LC       DECIMAL(16, 2),
 PaidOffAssets_Inventory_NLC      DECIMAL(16, 2)
);

CREATE TABLE #RenewalLeaseAssetSkus
(ContractId                     BIGINT, 
 Renewal_Inventory_LC           DECIMAL(16, 2), 
 Renewal_Inventory_NLC          DECIMAL(16, 2), 
 OperatingLeaseComponentPaidoff DECIMAL(16, 2),
 PaidOffAssets_Inventory_LC     DECIMAL(16, 2),
 PaidOffAssets_Inventory_NLC    DECIMAL(16, 2)
);

CREATE TABLE #NBVAssetValueHistoriesInfo
(ContractId                           BIGINT, 
 [AccumulatedNBVImpairment_LC_Table]  DECIMAL(16, 2), 
 [AccumulatedNBVImpairment_NLC_Table] DECIMAL(16, 2)
);

CREATE TABLE #LeasedAssetReturnedtoInventory
(ContractId                               BIGINT, 
 LeasedAssetReturnedtoInventory_LC_Table  DECIMAL(16, 2), 
 LeasedAssetReturnedtoInventory_NLC_Table DECIMAL(16, 2), 
 CostofGoodsSold_LC_Table                 DECIMAL(16, 2), 
 CostofGoodsSold_NLC_Table                DECIMAL(16, 2)
);

CREATE TABLE #LeasedAssetReturnedtoInventorySKUs
(ContractId                               BIGINT, 
 LeasedAssetReturnedtoInventory_LC_Table  DECIMAL(16, 2), 
 LeasedAssetReturnedtoInventory_NLC_Table DECIMAL(16, 2), 
 CostofGoodsSold_LC_Table                 DECIMAL(16, 2), 
 CostofGoodsSold_NLC_Table                DECIMAL(16, 2)
);

CREATE TABLE #NBVImpairment
(ContractId              BIGINT, 
 NBVImpairment_LC_Table  DECIMAL(16, 2), 
 NBVImpairment_NLC_Table DECIMAL(16, 2),
);

CREATE TABLE #Impairment_Asset
(ContractId                BIGINT, 
 AssetImpairment_LC_Table  DECIMAL(16, 2), 
 AssetImpairment_NLC_Table DECIMAL(16, 2),
);

CREATE TABLE #AssetImpairment
(ContractId                BIGINT, 
 AssetImpairment_LC_Table  DECIMAL(16, 2), 
 AssetImpairment_NLC_Table DECIMAL(16, 2), 
 NBVImpairment_LC_Table    DECIMAL(16, 2), 
 NBVImpairment_NLC_Table   DECIMAL(16, 2),
);

CREATE TABLE #ContractETCAmount
(ContractId                  BIGINT, 
 ETCAmount_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 ETCAmount_NonLeaseComponent DECIMAL(16, 2) NOT NULL,
 ActiveAssets_ETCAmount_LC   DECIMAL(16, 2) NOT NULL,
 ActiveAssets_ETCAmount_NLC  DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #ContractSKUETCAmount
(ContractId                  BIGINT, 
 ETCAmount_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 ETCAmount_NonLeaseComponent DECIMAL(16, 2) NOT NULL,
 ActiveAssets_ETCAmount_LC   DECIMAL(16, 2) NOT NULL,
 ActiveAssets_ETCAmount_NLC  DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #RebookContractETCAmount
(ContractId                  BIGINT NOT NULL,
ETCAmount_LeaseComponent	 DECIMAL (16, 2) NOT NULL,
ETCAmount_NonLeaseComponent	 DECIMAL (16, 2) NOT NULL,
 ActiveAssets_ETCAmount_LC   DECIMAL(16, 2) NOT NULL,
 ActiveAssets_ETCAmount_NLC  DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #RebookContractSKUETCAmount
(ContractId                  BIGINT NOT NULL,
ETCAmount_LeaseComponent	 DECIMAL (16, 2) NOT NULL,
ETCAmount_NonLeaseComponent	 DECIMAL (16, 2) NOT NULL,
 ActiveAssets_ETCAmount_LC   DECIMAL(16, 2) NOT NULL,
 ActiveAssets_ETCAmount_NLC  DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #CapitalizedAmounts
(ContractId                                   BIGINT NOT NULL, 
 CapitalizedAdditionalCharge_LeaseComponent   DECIMAL(16, 2) NOT NULL, 
 CapitalizedAdditionalCharge_FinanceComponent DECIMAL(16, 2) NOT NULL, 
 CapitalizedSalesTax_LeaseComponent           DECIMAL(16, 2) NOT NULL, 
 CapitalizedSalesTax_FinanceComponent         DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimInterest_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimInterest_FinanceComponent  DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimRent_LeaseComponent        DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimRent_FinanceComponent      DECIMAL(16, 2) NOT NULL, 
 CapitalizedProgressPayment_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 CapitalizedProgressPayment_FinanceComponent  DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #RenewalCapitalizedAmounts
(ContractId                                   BIGINT NOT NULL, 
 CapitalizedAdditionalCharge_LeaseComponent   DECIMAL(16, 2) NOT NULL, 
 CapitalizedAdditionalCharge_FinanceComponent DECIMAL(16, 2) NOT NULL, 
 CapitalizedSalesTax_LeaseComponent           DECIMAL(16, 2) NOT NULL, 
 CapitalizedSalesTax_FinanceComponent         DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimInterest_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimInterest_FinanceComponent  DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimRent_LeaseComponent        DECIMAL(16, 2) NOT NULL, 
 CapitalizedInterimRent_FinanceComponent      DECIMAL(16, 2) NOT NULL, 
 CapitalizedProgressPayment_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 CapitalizedProgressPayment_FinanceComponent  DECIMAL(16, 2) NOT NULL, 
 TotalAmount_Lease                            DECIMAL(16, 2) NOT NULL, 
 TotalAmount_Finance                          DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #OperatingPaidOffContract
(ContractId BIGINT NOT NULL
);

CREATE TABLE #OperatingPaidOffContractSKU
(ContractId BIGINT NOT NULL
);

CREATE TABLE #CapitalPaidOffContract
(ContractId BIGINT NOT NULL
);

CREATE TABLE #PaidOffNotCOAmountInfo
(ContractId        BIGINT NOT NULL,
PaidOffNotCOAmount DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #FinanceChargeOffAmount_Info
(ContractId            BIGINT NOT NULL,
FinanceChargeOffAmount DECIMAL (16,2) NOT NULL
);

SELECT c.Sequencenumber AS SequenceNumber
     , c.Alias AS ContractAlias
     , c.Id AS ContractId
     , lfd.LeaseContractType
     , lf.legalEntityId AS LegalEntityId
     , c.LineofBusinessId
     , lf.Id AS LeaseFinanceId
     , lf.CustomerId AS CustomerId
     , CASE
           WHEN c.u_ConversionSource = ISNULL(@u_ConversionSource, 'PMS')
           THEN 'Migrated'
           ELSE 'Not Migrated'
       END AS IsMigrated
     , c.AccountingStandard
     , c.Status AS ContractStatus
     , lfd.CommencementDate
     , lfd.MaturityDate
     , lfd.LeaseContractType AS ContractType
     , c.SyndicationType
     , CASE
           WHEN c.IsNonAccrual = 0
           THEN 'Accrual'
           ELSE 'Non Accrual'
       END AS AccrualStatus
     , c.ChargeOffStatus
     , rft.Id AS ReceivableForTransfersId
	 , rft.ReceivableForTransferType
	 , rft.EffectiveDate AS [SyndicationDate]
	 , CAST((1 - rft.RetainedPercentage / 100) AS DECIMAL(16,2)) AS SoldPortion
	 , CAST('_' AS VARCHAR(50)) AS [AccountingTreatment] 
	 , ISNULL(rft.IsFromContract, 0) AS IsFromContract
	 , CAST(ISNULL(rft.RetainedPercentage / 100, 1) AS DECIMAL(16,2)) AS RetainedPortion
	  , CAST(ISNULL((100 - rft.RetainedPercentage) / 100, 1) AS DECIMAL(16,2)) AS ParticipatedPortion
	 , rft.LeaseFinanceId AS SyndicationLeaseFinanceId
	 , IIF(rft.IsFromContract = 0, ISNULL(rft.SoldNBV_Amount, 0.00), 0.00) AS SoldNBV_Amount
	 , IIF(rft.IsFromContract = 0, ISNULL(rft.FinancingSoldNBV_Amount, 0.00), 0.00) AS FinancingSoldNBV_Amount
INTO #EligibleContracts
FROM Contracts c
     INNER JOIN LeaseFinances lf ON lf.ContractId = c.Id
     INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
     LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = c.Id
						                       AND rft.ApprovalStatus = 'Approved'
WHERE lf.IsCurrent = 1
      AND C.Status IN ('Commenced', 'FullyPaid', 'FullyPaidOff', 'Terminated')
        AND @True = (CASE WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = lf.LegalEntityId) THEN @True
								WHEN @LegalEntitiesCount = 0 THEN @True
								ELSE @False
                           END)

CREATE NONCLUSTERED INDEX IX_Id ON #EligibleContracts(ContractId);

SELECT 
	DISTINCT ec.ContractId
INTO #OverTerm
FROM #EligibleContracts ec
	INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
	INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
WHERE lis.IncomeType = 'OverTerm'
	AND lis.IsSchedule = 1
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #OverTerm(ContractId);

SELECT c.ContractId
		 , co.ChargeOffDate
		 , co.Id AS ChargeoffId
INTO #ChargeOff
FROM #EligibleContracts c
INNER JOIN ChargeOffs co ON co.ContractId = c.ContractId
WHERE co.IsActive = 1
	  AND co.Status = 'Approved'
	  AND co.IsRecovery = 0
	  AND co.ReceiptId IS NULL

CREATE NONCLUSTERED INDEX IX_Id ON #ChargeOff(ContractId);

SELECT DISTINCT 
		ec.ContractId
INTO #RenewalDone
FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseAmendments la ON la.CurrentLeaseFinanceId = lf.Id
										AND la.LeaseAmendmentStatus = 'Approved'
WHERE la.AmendmentType = 'Renewal';

CREATE NONCLUSTERED INDEX IX_Id ON #RenewalDone(ContractId);

SET @SQL = 
'SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
               THEN bia.TaxCredit_Amount
               ELSE 0.00
           END) [ETCAmount_LeaseComponent]
	, SUM(CASE
		      WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1
			  THEN bia.TaxCredit_Amount
			  ELSE 0.00
		  END) [ETCAmount_NonLeaseComponent]
     , SUM(CASE
               WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND la.IsActive = 1
               THEN bia.TaxCredit_Amount
               ELSE 0.00
           END) [ActiveAssets_ETCAmount_LC]
     , SUM(CASE
               WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND la.IsActive = 1
               THEN bia.TaxCredit_Amount
               ELSE 0.00
           END) [ActiveAssets_ETCAmount_NLC]
FROM #EligibleContracts ec
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
	 INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
	 INNER JOIN Assets a ON a.Id = la.AssetId
     INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
WHERE bi.IsActive = 1
      AND bia.IsActive = 1
      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= ec.CommencementDate))
      AND bi.IsETC = 1
      FilterCondition
GROUP BY ec.ContractId;'

IF @FilterCondition IS NOT NULL
    BEGIN
        SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
END;
    ELSE
    BEGIN
        SET @sql = REPLACE(@sql, 'FilterCondition', '');
END;

INSERT INTO #ContractETCAmount(ContractId, ETCAmount_LeaseComponent, ETCAmount_NonLeaseComponent, ActiveAssets_ETCAmount_LC, ActiveAssets_ETCAmount_NLC)
EXEC (@Sql);

CREATE NONCLUSTERED INDEX IX_Id ON #ContractETCAmount(ContractId);

IF @IsSku = 1
BEGIN
	SET @SQL = 
	'SELECT ec.ContractId
		 , SUM(CASE
				   WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ETCAmount_LeaseComponent]
		 , SUM(CASE
				   WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ETCAmount_NonLeaseComponent]
		 , SUM(CASE
				   WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND la.IsActive = 1
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ActiveAssets_ETCAmount_LC]
		 , SUM(CASE
				   WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND la.IsActive = 1
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ActiveAssets_ETCAmount_NLC]
	FROM #EligibleContracts ec
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
		 INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
		 INNER JOIN Assets a ON a.Id = la.AssetId
		 INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
		 INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
	WHERE bi.IsActive = 1
		  AND bia.IsActive = 1
		  AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= ec.CommencementDate))
		  AND bi.IsETC = 1
		  AND a.IsSKU = 1
	GROUP BY ec.ContractId;'
	INSERT INTO #ContractSKUETCAmount(ContractId, ETCAmount_LeaseComponent, ETCAmount_NonLeaseComponent, ActiveAssets_ETCAmount_LC, ActiveAssets_ETCAmount_NLC)
	EXEC (@SQL)

	CREATE NONCLUSTERED INDEX IX_Id ON #ContractSKUETCAmount(ContractId);
END

MERGE #ContractETCAmount [contract]
USING(SELECT * FROM #ContractSKUETCAmount) SKU
ON([contract].ContractId = SKU.ContractId)
    WHEN MATCHED
    THEN UPDATE SET 
                    ETCAmount_LeaseComponent += SKU.ETCAmount_LeaseComponent
				  , ETCAmount_NonLeaseComponent += SKU.ETCAmount_NonLeaseComponent
				  , ActiveAssets_ETCAmount_LC += SKU.ActiveAssets_ETCAmount_LC
				  , ActiveAssets_ETCAmount_NLC += SKU.ActiveAssets_ETCAmount_NLC
    WHEN NOT MATCHED
    THEN
      INSERT(ContractId, ETCAmount_LeaseComponent, ETCAmount_NonLeaseComponent, ActiveAssets_ETCAmount_LC, ActiveAssets_ETCAmount_NLC)
      VALUES(SKU.ContractId, SKU.ETCAmount_LeaseComponent, SKU.ETCAmount_NonLeaseComponent, SKU.ActiveAssets_ETCAmount_LC, SKU.ActiveAssets_ETCAmount_NLC);

SET @SQL = 
'SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
               THEN bia.TaxCredit_Amount
               ELSE 0.00
           END) [ETCAmount_LeaseComponent]
	, SUM(CASE
		      WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1
			  THEN bia.TaxCredit_Amount
			  ELSE 0.00
		  END) AS [ETCAmount_NonLeaseComponent]
     , SUM(CASE
               WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND la.IsActive = 1
               THEN bia.TaxCredit_Amount
               ELSE 0.00
           END) [ActiveAssets_ETCAmount_LC]
     , SUM(CASE
               WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND la.IsActive = 1
               THEN bia.TaxCredit_Amount
               ELSE 0.00
           END) [ActiveAssets_ETCAmount_NLC]
FROM #EligibleContracts ec
	 INNER JOIN LeaseFinances lf on lf.contractid = ec.ContractId
	 INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.id
	 INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
	 INNER JOIN Assets a ON a.Id = la.AssetId
     INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
WHERE bi.IsActive = 1
      AND bia.IsActive = 1
      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
      AND bi.IsETC = 1 AND lam.CurrentLeaseFinanceId != ec.leasefinanceid
      FilterCondition
GROUP BY ec.ContractId;'

IF @FilterCondition IS NOT NULL
    BEGIN
        SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
END;
    ELSE
    BEGIN
        SET @sql = REPLACE(@sql, 'FilterCondition', '');
END;

INSERT INTO #RebookContractETCAmount(ContractId, ETCAmount_LeaseComponent, ETCAmount_NonLeaseComponent, ActiveAssets_ETCAmount_LC, ActiveAssets_ETCAmount_NLC)
EXEC (@Sql);

CREATE NONCLUSTERED INDEX IX_Id ON #RebookContractETCAmount(ContractId);

IF @IsSku = 1
BEGIN
	SET @SQL = 
	'SELECT ec.ContractId
		 , SUM(CASE
				   WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ETCAmount_LeaseComponent]
		 , SUM(CASE
				   WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ETCAmount_NonLeaseComponent]
		 , SUM(CASE
				   WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND la.IsActive = 1
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ActiveAssets_ETCAmount_LC]
		 , SUM(CASE
				   WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND la.IsActive = 1
				   THEN las.ETCAdjustmentAmount_Amount
				   ELSE 0.00
			   END) [ActiveAssets_ETCAmount_NLC]
	FROM #EligibleContracts ec
		 INNER JOIN LeaseFinances lf on lf.contractid = ec.ContractId
		 INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.id
		 INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
		 INNER JOIN Assets a ON a.Id = la.AssetId
		 INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
		 INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
	WHERE bi.IsActive = 1
		  AND bia.IsActive = 1
		  AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
		  AND bi.IsETC = 1 AND lam.CurrentLeaseFinanceId != ec.leasefinanceid
		  AND a.IsSKU = 1
	GROUP BY ec.ContractId;'
	INSERT INTO #RebookContractSKUETCAmount(ContractId, ETCAmount_LeaseComponent, ETCAmount_NonLeaseComponent, ActiveAssets_ETCAmount_LC, ActiveAssets_ETCAmount_NLC)
	EXEC (@SQL)

	CREATE NONCLUSTERED INDEX IX_Id ON #RebookContractSKUETCAmount(ContractId);
END

MERGE #RebookContractETCAmount [contract]
USING(SELECT * FROM #RebookContractSKUETCAmount) SKU
ON([contract].ContractId = SKU.ContractId)
    WHEN MATCHED
    THEN UPDATE SET 
                    ETCAmount_LeaseComponent += SKU.ETCAmount_LeaseComponent
				  , ETCAmount_NonLeaseComponent += SKU.ETCAmount_NonLeaseComponent
				  , ActiveAssets_ETCAmount_LC += SKU.ActiveAssets_ETCAmount_LC
				  , ActiveAssets_ETCAmount_NLC += SKU.ActiveAssets_ETCAmount_NLC
    WHEN NOT MATCHED
    THEN
      INSERT(ContractId, ETCAmount_LeaseComponent, ETCAmount_NonLeaseComponent, ActiveAssets_ETCAmount_LC, ActiveAssets_ETCAmount_NLC)
      VALUES(SKU.ContractId, SKU.ETCAmount_LeaseComponent, SKU.ETCAmount_NonLeaseComponent, SKU.ActiveAssets_ETCAmount_LC, SKU.ActiveAssets_ETCAmount_NLC);

SELECT  ec.ContractId
	  , REPLACE(STUFF(
		(
			SELECT ', ' + CONVERT(NVARCHAR(max), la.AmendmentType)
			FROM LeaseFinances lf
			INNER JOIN LeaseAmendments la ON la.CurrentLeaseFinanceId = lf.Id
			WHERE lf.ContractId = ec.ContractId
				  AND la.LeaseAmendmentStatus = 'Approved'
			ORDER BY la.Id FOR XML PATH('')), 1, 2, ''), ' ', ''
		) AS AmendmentType
INTO #AmendmentList
FROM #EligibleContracts ec

CREATE NONCLUSTERED INDEX IX_Id ON #AmendmentList(ContractId);

SELECT ec.ContractId
     , MAX(avh.IncomeDate) [FixedTermClearedTillIncomeDate]
INTO #ClearedFixedTermAVHIncomeDate
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     LEFT JOIN LeaseAmendments la ON lf.Id = la.CurrentLeaseFinanceId
                                     AND la.AmendmentType = 'NBVImpairment'
     LEFT JOIN #ChargeOff cod ON ec.ContractId = cod.ContractId
     INNER JOIN AssetValueHistories avh ON(avh.SourceModuleId = lf.Id
                                           OR avh.SourceModuleId = la.Id
                                           OR avh.SourceModuleId = cod.ChargeOffId)
WHERE avh.IsCleared = 1 AND (avh.SourceModule = 'FixedTermDepreciation'
     OR (avh.SourceModule = 'NBVImpairments' AND la.Id IS NOT NULL)
     OR (avh.SourceModule = 'ChargeOff' AND cod.ChargeOffId IS NOT NULL))
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedFixedTermAVHIncomeDate(ContractId);

SELECT
	DISTINCT ec.ContractId
INTO #PayOffDetails
FROM #EligibleContracts ec
	INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
	INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
	INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
		AND p.Status = 'Activated';

CREATE NONCLUSTERED INDEX IX_Id ON #PayOffDetails(ContractId);

SELECT DISTINCT
	   ec.ContractId
     , p.PayoffEffectiveDate
     , p.LeaseFinanceId
     , la.AssetId
	 , p.Id AS PayoffId
	 , poa.Status AS PayoffAssetStatus
	 , poa.LeaseAssetId AS LeaseAssetId
	 , p.IsPaidOffInInstallPhase
INTO #PayoffAssetDetails
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN Payoffs p ON p.LeaseFinanceId = lf.Id
     INNER JOIN PayoffAssets poa ON poa.PayoffId = p.Id
     INNER JOIN LeaseAssets la ON la.Id = poa.LeaseAssetId
WHERE p.Status = 'Activated'
      AND poa.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_Id ON #PayoffAssetDetails(ContractId);

SELECT ec.ContractId
     , MAX(lam.CurrentLeaseFinanceId) AS RenewalFinanceId
     , MAX(lam.AmendmentDate) AS RenewalDate
INTO #RenewalDetails
FROM #EligibleContracts ec
     INNER JOIN #RenewalDone rd ON ec.ContractId = rd.ContractId
     INNER JOIN LeaseFinances lf ON lf.ContractId = rd.ContractId
     INNER JOIN LeaseAmendments lam ON lf.Id = lam.CurrentLeaseFinanceId
WHERE lam.AmendmentType = 'Renewal'
      AND lam.LeaseAmendmentStatus = 'Approved'
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #RenewalDetails(ContractId);

SELECT ec.ContractId
     , ec.LeaseFinanceId
     , ec.CommencementDate
	 , ec.MaturityDate
INTO #LeaseFinanceIdBeforeRenewal
FROM #EligibleContracts ec;

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseFinanceIdBeforeRenewal(ContractId);

UPDATE la SET 
              LeaseFinanceId = t.LeaseFinanceId
			, CommencementDate = lfd.CommencementDate
			, MaturityDate = lfd.MaturityDate
FROM #LeaseFinanceIdBeforeRenewal la
     INNER JOIN
	(
		SELECT ec.ContractId
			 , MAX(lf.Id) AS LeaseFinanceId
		FROM #EligibleContracts ec
			 INNER JOIN #RenewalDetails rd ON ec.ContractId = rd.ContractId
			 INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		WHERE lf.Id < rd.RenewalFinanceId
			  AND lf.ApprovalStatus IN('Approved', 'InsuranceFollowup')
		GROUP BY ec.ContractId
	) AS t ON t.ContractId = la.ContractId
INNER JOIN LeaseFinances lf ON lf.Id = t.LeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id;

SELECT
	DISTINCT ec.ContractId
		   , p.Id AS PayoffId 
		   , p.PayoffEffectiveDate
		   , avsc.Id AS AssetsValueStatusChangeId
INTO #Payoffs
FROM #EligibleContracts ec
	INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
	INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
	INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
	INNER JOIN AssetsValueStatusChanges avsc ON avsc.SourceModuleId = p.Id
WHERE p.Status = 'Activated'
	  AND avsc.SourceModule = 'Payoff'
	  AND avsc.Reason = 'Impairment'
	  AND avsc.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_Id ON #Payoffs(ContractId);

SELECT
	DISTINCT
	ec.ContractId
INTO #OTPReclass
FROM #EligibleContracts ec
	INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
	INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
	LEFT JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
WHERE lis.IncomeType = 'OverTerm'
	AND lis.IsLessorOwned = 1
	AND lis.IsSchedule = 1
	AND lis.IsReclassOTP = 1
	AND ((rd.ContractId IS NOT NULL AND lis.LeaseFinanceId >= rd.RenewalFinanceId) OR rd.ContractId IS NULL)

CREATE NONCLUSTERED INDEX IX_Id ON #OTPReclass(ContractId);

SELECT ec.ContractId
     , MAX(lis.LeaseFinanceId) AS LeaseFinanceId
INTO #LeaseFinanceForOTPReclass
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
     INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
WHERE lis.IncomeType = 'OverTerm'
      AND lis.IsLessorOwned = 1
      AND lis.IsSchedule = 1
      AND lis.IsReclassOTP = 1
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseFinanceForOTPReclass(ContractId);

SELECT ec.ContractId
     , p.PayoffEffectiveDate
INTO #FullPaidOffContracts
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
     INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
     INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
WHERE p.Status = 'Activated'
      AND p.FullPayoff = 1;

CREATE NONCLUSTERED INDEX IX_Id ON #FullPaidOffContracts(ContractId);

SELECT DISTINCT 
       ec.ContractId
     , a.Id AS AssetId
INTO #SyndicationAVHInfo
FROM #EligibleContracts ec
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
     INNER JOIN Assets a ON la.AssetId = a.Id
     INNER JOIN AssetValueHistories avh ON a.Id = avh.AssetId
WHERE avh.SourceModule = 'Syndications'
GROUP BY ec.ContractId
       , a.Id;

CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationAVHInfo(ContractId);

SELECT ec.ContractId
     , 1 AS IsReclassOTP
INTO #ReclassDetails
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.id
WHERE lis.IsReclassOTP = 1
GROUP BY ec.ContractId
       , lis.IsReclassOTP;
	
CREATE NONCLUSTERED INDEX IX_Id ON #ReclassDetails(ContractId);

UPDATE ec SET 
              AccountingTreatment = rc.AccountingTreatment
FROM #EligibleContracts ec
INNER JOIN LeaseFinanceDetails lfd ON ec.LeaseFinanceId = lfd.Id
INNER JOIN ReceivableCodes rc ON rc.Id = lfd.OTPReceivableCodeId;

SELECT
	cod.ContractId
	,MAX(avh.IncomeDate) [FixedTermClearedTillIncomeDateCO]
INTO #ClearedFixedTermAVHIncomeDateCO
FROM #Chargeoff cod
	INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = cod.ChargeOffId
WHERE avh.SourceModule = 'ChargeOff'
	AND avh.IsCleared = 1
GROUP BY cod.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedFixedTermAVHIncomeDateCO(ContractId);

IF @IsSku = 0 AND @AddCharge = 0
BEGIN
INSERT INTO #LeaseAssetValues
SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount
			   ELSE 0.00
           END) AS Booking_Inventory_LC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount
			   ELSE 0.00
           END) AS Booking_Inventory_NLC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0
               THEN la.BookedResidual_amount
			   ELSE 0.00
           END) AS GPSpecificInventory_NLC
	 , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND @ClearAccumulatedAccountsatPayoff = 'False' AND ec.ContractType = 'Operating'
					AND rd.ContractId IS NOT NULL
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount
			   ELSE 0.00
           END) AS LeasedAssetReturnToInventory_LC
	 , SUM(CASE
               WHEN (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND @ClearAccumulatedAccountsatPayoff = 'False' AND ec.ContractType = 'Operating'
					AND rd.ContractId IS NOT NULL
               THEN la.BookedResidual_Amount
			   ELSE 0.00
           END) AS LeasedAssetReturnToInventory_NLC
	,  SUM(CASE
			  WHEN ec.ContractType = 'Operating'
				   AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
				   AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
			  THEN la.NBV_Amount + la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount
			  ELSE 0.00
		   END) AS OperatingLeaseComponentPaidoff
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
           END)
     + SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1 AND la.CapitalizedForId IS NOT NULL
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_LC
     , SUM(CASE
               WHEN (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0) 
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
           END)
     + SUM(CASE
               WHEN (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0) AND la.CapitalizedForId IS NOT NULL
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_NLC
FROM #EligibleContracts ec
     INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON ec.ContractId = renewal.ContractId
     INNER JOIN LeaseFinances lf ON renewal.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
     INNER JOIN Assets a ON a.id = la.AssetId
	 LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
WHERE ec.IsFromContract = 0
	   AND lf.ApprovalStatus IN('Approved', 'InsuranceFollowup')
	   AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate))
GROUP BY ec.ContractId;

INSERT INTO #RenewalLeaseAssetValues
SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount
			   ELSE 0.00
           END) AS Renewal_Inventory_LC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount
			   ELSE 0.00
           END) AS Renewal_Inventory_NLC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND ec.ContractType ='Operating'
               THEN la.NBV_Amount + la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount
			   ELSE 0.00
           END) AS OperatingLeaseComponentPaidoff
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
           END)
     + SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1 AND la.CapitalizedForId IS NOT NULL
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_LC
     , SUM(CASE
               WHEN (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
           END)
     + SUM(CASE
               WHEN (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0) AND la.CapitalizedForId IS NOT NULL
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != 'FullSale' OR (ec.ReceivableForTransferType = 'FullSale' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_NLC
FROM #EligibleContracts ec
     INNER JOIN #RenewalDone renewal ON ec.ContractId = renewal.ContractId
     INNER JOIN LeaseFinances lf ON ec.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
     INNER JOIN Assets a ON a.id = la.AssetId
WHERE ec.IsFromContract = 0
	   AND lf.ApprovalStatus IN('Approved', 'InsuranceFollowup')
	   AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate))
	   AND NOT (@ClearAccumulatedAccountsatPayoff = 'False' AND ec.ContractType = 'Operating')
GROUP BY ec.ContractId;

END

IF @IsSku = 1
BEGIN
SET @Sql = 
'DECLARE @ClearAccumulatedAccountsatPayoff NVARCHAR(50)
 SELECT @ClearAccumulatedAccountsatPayoff = Value FROM GlobalParameters WHERE Name = ''ClearAccumulatedAccountsatPayoff''

 IF @ClearAccumulatedAccountsatPayoff IS NULL
 SET @ClearAccumulatedAccountsatPayoff = ''True''

SELECT t.ContractId
      , SUM(t.Booking_Inventory_LC)
	  , SUM(t.Booking_Inventory_NLC)
	  , SUM(t.GPSpecificInventory_NLC)
	  , SUM(t.LeasedAssetReturnToInventory_LC)
	  , SUM(t.LeasedAssetReturnToInventory_NLC)
	  , SUM(t.OperatingLeaseComponentPaidoff)
	  , SUM(t.PaidOffAssets_Inventory_LC)
	  , SUM(t.PaidOffAssets_Inventory_NLC)
FROM 
(SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount - LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS Booking_Inventory_LC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount - LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS Booking_Inventory_NLC
	 , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
               THEN la.BookedResidual_amount
			   ELSE 0.00
           END) AS GPSpecificInventory_NLC 
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND @ClearAccumulatedAccountsatPayoff = ''False'' AND ec.ContractType = ''Operating''
					AND rd.ContractId IS NOT NULL
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount - LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS LeasedAssetReturnToInventory_LC
	 , SUM(CASE
               WHEN (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND @ClearAccumulatedAccountsatPayoff = ''False'' AND ec.ContractType = ''Operating''
					AND rd.ContractId IS NOT NULL
               THEN la.BookedResidual_Amount
			   ELSE 0.00
           END) AS LeasedAssetReturnToInventory_NLC
	,  SUM(CASE
			  WHEN ec.ContractType = ''Operating''
				   AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
				   AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
			  THEN la.NBV_Amount + la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + LeaseAssetCapitalizedAdditionalCharge
			  ELSE 0.00
		   END) AS OperatingLeaseComponentPaidoff
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
		   END) 
     + SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				    AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS PaidOffAssets_Inventory_LC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
		   END)
     + SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS PaidOffAssets_Inventory_NLC
FROM #EligibleContracts ec
     INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON ec.ContractId = renewal.ContractId
     INNER JOIN LeaseFinances lf ON renewal.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
     INNER JOIN Assets a ON a.id = la.AssetId
	 LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
WHERE ec.IsFromContract = 0 
      AND a.IsSKU = 0
	  AND lf.ApprovalStatus IN(''Approved'', ''InsuranceFollowup'')
	  AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate))
GROUP BY ec.ContractId
UNION ALL
SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				     AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
               THEN las.NBV_Amount - las.OriginalCapitalizedAmount_Amount - SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS Booking_Inventory_LC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
               THEN las.NBV_Amount - las.OriginalCapitalizedAmount_Amount - SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS Booking_Inventory_NLC
	 , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
               THEN las.BookedResidual_amount
			   ELSE 0.00
           END) AS GPSpecificInventory_NLC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				     AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
					 AND @ClearAccumulatedAccountsatPayoff = ''False'' AND ec.ContractType = ''Operating''
					 AND rd.ContractId IS NOT NULL
               THEN las.NBV_Amount - las.OriginalCapitalizedAmount_Amount - SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS LeasedAssetReturnToInventory_LC
	 , SUM(CASE
               WHEN (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
					AND @ClearAccumulatedAccountsatPayoff = ''False'' AND ec.ContractType = ''Operating''
					AND rd.ContractId IS NOT NULL
               THEN las.BookedResidual_Amount
			   ELSE 0.00
           END) AS LeasedAssetReturnToInventory_NLC
	,  SUM(CASE
			  WHEN ec.ContractType = ''Operating''
				   AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
				   AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
			  THEN las.NBV_Amount + las.CapitalizedInterimInterest_Amount + las.CapitalizedInterimRent_Amount + las.CapitalizedSalesTax_Amount + las.CapitalizedProgressPayment_Amount + SKUAssetCapitalizedAdditionalCharge
			  ELSE 0.00
		   END) AS OperatingLeaseComponentPaidoff
	,  SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				     AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
				     AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.NBV_Amount
			   ELSE 0.00
           END)
	+  SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				     AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
				     AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.CapitalizedInterimInterest_Amount + las.CapitalizedInterimRent_Amount + las.CapitalizedSalesTax_Amount + las.CapitalizedProgressPayment_Amount + SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_LC
	,  SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				     AND (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
				     AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.NBV_Amount
			   ELSE 0.00
           END)
	+  SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				     AND (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
				     AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.CapitalizedInterimInterest_Amount + las.CapitalizedInterimRent_Amount + las.CapitalizedSalesTax_Amount + las.CapitalizedProgressPayment_Amount + SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_NLC
FROM #EligibleContracts ec
     INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON ec.ContractId = renewal.ContractId
     INNER JOIN LeaseFinances lf ON renewal.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
     INNER JOIN Assets a ON la.AssetId = a.Id
	 LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
WHERE ec.IsFromContract = 0
      AND a.IsSKU = 1
      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= renewal.CommencementDate))
      AND lf.ApprovalStatus IN(''Approved'', ''InsuranceFollowup'')
GROUP BY ec.ContractId) as t
GROUP BY t.ContractId'


IF @CapitalizedAdditionalCharge IS NOT NULL
BEGIN
	SET @sql = REPLACE(@sql, 'LeaseAssetCapitalizedAdditionalCharge', @CapitalizedAdditionalCharge);
	SET @sql = REPLACE(@sql, 'SKUAssetCapitalizedAdditionalCharge', @SKUCapitalizedAdditionalCharge);
END;
ELSE
BEGIN
	SET @sql = REPLACE(@sql, 'LeaseAssetCapitalizedAdditionalCharge', '0');
	SET @sql = REPLACE(@sql, 'SKUAssetCapitalizedAdditionalCharge', '0');
END;

INSERT INTO #LeaseAssetSkus
EXEC (@SQL)

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseAssetSkus(ContractId);

SET @Sql = 
'DECLARE @ClearAccumulatedAccountsatPayoff NVARCHAR(50)
 SELECT @ClearAccumulatedAccountsatPayoff = Value FROM GlobalParameters WHERE Name = ''ClearAccumulatedAccountsatPayoff''

 IF @ClearAccumulatedAccountsatPayoff IS NULL
 SET @ClearAccumulatedAccountsatPayoff = ''True''

SELECT t.ContractId
      , SUM(t.Renewal_Inventory_LC)
	  , SUM(t.Renewal_Inventory_NLC)
	  , SUM(t.OperatingLeaseComponentPaidoff)
	  , SUM(t.PaidOffAssets_Inventory_LC)
	  , SUM(t.PaidOffAssets_Inventory_NLC)
FROM 
(SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount - LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS Renewal_Inventory_LC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
               THEN la.NBV_Amount - la.OriginalCapitalizedAmount_Amount - LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS Renewal_Inventory_NLC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
			        AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND ec.ContractType = ''Operating''
               THEN la.NBV_Amount + la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS OperatingLeaseComponentPaidoff
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
		   END)
     + SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				    AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS PaidOffAssets_Inventory_LC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.NBV_Amount
			   ELSE 0.00
		   END)
     + SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + LeaseAssetCapitalizedAdditionalCharge
			   ELSE 0.00
		   END) AS PaidOffAssets_Inventory_NLC
FROM #EligibleContracts ec
     INNER JOIN #RenewalDone renewal ON ec.ContractId = renewal.ContractId
     INNER JOIN LeaseFinances lf ON ec.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
     INNER JOIN Assets a ON a.id = la.AssetId
WHERE ec.IsFromContract = 0 
      AND a.IsSKU = 0
	  AND lf.ApprovalStatus IN(''Approved'', ''InsuranceFollowup'')
	  AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate))
	  AND NOT (@ClearAccumulatedAccountsatPayoff = ''False'' AND ec.ContractType = ''Operating'')
GROUP BY ec.ContractId
UNION ALL
SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				     AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
               THEN las.NBV_Amount - las.OriginalCapitalizedAmount_Amount - SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS Renewal_Inventory_LC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				    AND (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
               THEN las.NBV_Amount - las.OriginalCapitalizedAmount_Amount - SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS Renewal_Inventory_NLC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
			        AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
					AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					AND ec.ContractType = ''Operating''
               THEN las.NBV_Amount + las.CapitalizedInterimInterest_Amount + las.CapitalizedInterimRent_Amount + las.CapitalizedSalesTax_Amount + las.CapitalizedProgressPayment_Amount + SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS OperatingLeaseComponentPaidoff
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				     AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
					 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.NBV_Amount
			   ELSE 0.00
           END)
     + SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				     AND la.IsFailedSaleLeaseback = 0 AND las.IsLeaseComponent = 1
					 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.CapitalizedInterimInterest_Amount + las.CapitalizedInterimRent_Amount + las.CapitalizedSalesTax_Amount + las.CapitalizedProgressPayment_Amount + SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_LC
     , SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0
				     AND (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
					 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.NBV_Amount
			   ELSE 0.00
           END)
     + SUM(CASE
               WHEN la.IsAdditionalChargeSoftAsset = 0 AND la.CapitalizedForId IS NOT NULL
				     AND (la.IsFailedSaleLeaseback = 1 OR las.IsLeaseComponent = 0)
					 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate
					 AND (ec.ReceivableForTransfersId IS NULL OR (ec.ReceivableForTransfersId IS NOT NULL AND (ec.ReceivableForTransferType != ''FullSale'' OR (ec.ReceivableForTransferType = ''FullSale'' AND la.TerminationDate <= ec.SyndicationDate))))
               THEN las.CapitalizedInterimInterest_Amount + las.CapitalizedInterimRent_Amount + las.CapitalizedSalesTax_Amount + las.CapitalizedProgressPayment_Amount + SKUAssetCapitalizedAdditionalCharge
			   ELSE 0.00
           END) AS PaidOffAssets_Inventory_NLC
FROM #EligibleContracts ec
     INNER JOIN #RenewalDone renewal ON ec.ContractId = renewal.ContractId
     INNER JOIN LeaseFinances lf ON ec.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
     INNER JOIN Assets a ON la.AssetId = a.Id
WHERE ec.IsFromContract = 0
      AND a.IsSKU = 1
      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate))
      AND lf.ApprovalStatus IN(''Approved'', ''InsuranceFollowup'')
	  AND NOT (@ClearAccumulatedAccountsatPayoff = ''False'' AND ec.ContractType = ''Operating'')
GROUP BY ec.ContractId) as t
GROUP BY t.ContractId'

IF @CapitalizedAdditionalCharge IS NOT NULL
BEGIN
	SET @sql = REPLACE(@sql, 'LeaseAssetCapitalizedAdditionalCharge', @CapitalizedAdditionalCharge);
	SET @sql = REPLACE(@sql, 'SKUAssetCapitalizedAdditionalCharge', @SKUCapitalizedAdditionalCharge);
END;
ELSE
BEGIN
	SET @sql = REPLACE(@sql, 'LeaseAssetCapitalizedAdditionalCharge', '0');
	SET @sql = REPLACE(@sql, 'SKUAssetCapitalizedAdditionalCharge', '0');
END;

INSERT INTO #RenewalLeaseAssetSkus
EXEC (@SQL)

CREATE NONCLUSTERED INDEX IX_Id ON #RenewalLeaseAssetSkus(ContractId);

END

MERGE #LeaseAssetValues AS [Source]
USING (SELECT * FROM #LeaseAssetSkus) AS [Target]
ON [Source].ContractId = [Target].ContractId
WHEN MATCHED 
	 THEN UPDATE 
	 SET [Source].Booking_Inventory_LC += [Target].Booking_Inventory_LC
       , [Source].Booking_Inventory_NLC += [Target].Booking_Inventory_NLC
	   , [Source].GPSpecificInventory_NLC += [Target].GPSpecificInventory_NLC
	   , [Source].LeasedAssetReturnToInventory_LC += [Target].LeasedAssetReturnToInventory_LC
	   , [Source].LeasedAssetReturnToInventory_NLC += [Target].LeasedAssetReturnToInventory_NLC
	   , [Source].OperatingLeaseComponentPaidoff += [Target].OperatingLeaseComponentPaidoff
	   , [Source].PaidOffAssets_Inventory_LC += [Target].PaidOffAssets_Inventory_LC
	   , [Source].PaidOffAssets_Inventory_NLC += [Target].PaidOffAssets_Inventory_NLC
WHEN NOT MATCHED
	 THEN INSERT (ContractId, Booking_Inventory_LC, Booking_Inventory_NLC, GPSpecificInventory_NLC, LeasedAssetReturnToInventory_LC, LeasedAssetReturnToInventory_NLC, OperatingLeaseComponentPaidoff, PaidOffAssets_Inventory_LC, PaidOffAssets_Inventory_NLC)
	 VALUES ([Target].ContractId, [Target].Booking_Inventory_LC, [Target].Booking_Inventory_NLC, [Target].GPSpecificInventory_NLC, [Target].LeasedAssetReturnToInventory_LC, [Target].LeasedAssetReturnToInventory_NLC, [Target].OperatingLeaseComponentPaidoff, [Target].PaidOffAssets_Inventory_LC, [Target].PaidOffAssets_Inventory_NLC);

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseAssetValues(ContractId);

-- TO Handle Renewal Logic
UPDATE la SET Booking_Inventory_LC += Booking_Inventory_LC
			, OperatingLeaseComponentPaidoff += OperatingLeaseComponentPaidoff
			, PaidOffAssets_Inventory_LC += PaidOffAssets_Inventory_LC
FROM #LeaseAssetValues la
INNER JOIN #RenewalDone renewal ON la.ContractId = renewal.ContractId
INNER JOIN #EligibleContracts ec ON ec.ContractId = renewal.ContractId
WHERE @ClearAccumulatedAccountsatPayoff = 'False'
	  AND ec.ContractType = 'Operating'

UPDATE la SET Booking_Inventory_NLC += GPSpecificInventory_NLC
FROM #LeaseAssetValues la
INNER JOIN #RenewalDone renewal ON la.ContractId = renewal.ContractId
INNER JOIN #EligibleContracts ec ON ec.ContractId = renewal.ContractId
WHERE @ClearAccumulatedAccountsatPayoff = 'False'
	  AND ec.ContractType = 'Operating'

MERGE #RenewalLeaseAssetValues AS [Source]
USING (SELECT * FROM #RenewalLeaseAssetSkus) AS [Target]
ON [Source].ContractId = [Target].ContractId
WHEN MATCHED 
	 THEN UPDATE 
	 SET [Source].Renewal_Inventory_LC += [Target].Renewal_Inventory_LC
       , [Source].Renewal_Inventory_NLC += [Target].Renewal_Inventory_NLC
	   , [Source].OperatingLeaseComponentPaidoff += [Target].OperatingLeaseComponentPaidoff
	   , [Source].PaidOffAssets_Inventory_LC += [Target].PaidOffAssets_Inventory_LC
	   , [Source].PaidOffAssets_Inventory_NLC += [Target].PaidOffAssets_Inventory_NLC
WHEN NOT MATCHED
	 THEN INSERT (ContractId, Renewal_Inventory_LC, Renewal_Inventory_NLC, OperatingLeaseComponentPaidoff, PaidOffAssets_Inventory_LC,PaidOffAssets_Inventory_NLC)
	 VALUES ([Target].ContractId, [Target].Renewal_Inventory_LC, [Target].Renewal_Inventory_NLC, [Target].OperatingLeaseComponentPaidoff
	 ,[Target].PaidOffAssets_Inventory_LC, [Target].PaidOffAssets_Inventory_NLC);	 
	 
CREATE NONCLUSTERED INDEX IX_Id ON #RenewalLeaseAssetValues(ContractId);

SELECT ec.ContractId
     , SUM(CASE
               WHEN gld.IsDebit = 0
					AND gle.Name IN('Inventory', 'AccumulatedAssetDepreciation', 'AccumulatedAssetImpairment')
					AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
					AND gld.SourceId <= renewal.LeaseFinanceId
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gle.Name IN('Inventory', 'AccumulatedAssetDepreciation', 'AccumulatedAssetImpairment')
							   AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')	
							   AND gld.SourceId <= renewal.LeaseFinanceId
                          THEN Amount_Amount
                          ELSE 0.00
                      END) BookingInventory_GL
     , SUM(CASE
               WHEN gld.IsDebit = 0
					AND gle.Name IN('Inventory', 'AccumulatedAssetDepreciation', 'AccumulatedAssetImpairment')
					AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
					AND gld.SourceId >= rd.RenewalFinanceId
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gle.Name IN('Inventory', 'AccumulatedAssetDepreciation', 'AccumulatedAssetImpairment')
							   AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')	
							   AND gld.SourceId >= rd.RenewalFinanceId
                          THEN Amount_Amount
                          ELSE 0.00
                      END) RenewalInventory_GL
     , SUM(CASE
               WHEN gld.IsDebit = 0
					AND gle.Name IN('Inventory')
					AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
					AND gld.SourceId <= renewal.LeaseFinanceId
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gle.Name IN('Inventory')
							   AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')	
							   AND gld.SourceId <= renewal.LeaseFinanceId
                          THEN Amount_Amount
                          ELSE 0.00
                      END) ActualBookingInventory_GL
     , SUM(CASE
               WHEN gld.IsDebit = 0
					AND gle.Name IN('Inventory')
					AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
					AND gld.SourceId >= rd.RenewalFinanceId
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gle.Name IN('Inventory')
							   AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')	
							   AND gld.SourceId >= rd.RenewalFinanceId
                          THEN Amount_Amount
                          ELSE 0.00
                      END) ActualRenewalInventory_GL
    ,  SUM(CASE
               WHEN gld.IsDebit = 0
					AND gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff')
					AND gle.Name = 'AccumulatedAssetImpairment'
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff')
							   AND gle.Name = 'AccumulatedAssetImpairment'
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS AccumulatedAssetImpairment_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 0
					  AND gltt.Name IN('NBVImpairment')
					  AND gle.Name IN('AccumulatedNBVImpairment')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN('NBVImpairment')
							   AND gle.Name IN('AccumulatedNBVImpairment')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS NBVImpairment_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 0
					  AND gltt.Name IN('OperatingLeasePayoff')
					  AND gle.Name IN('ImpairmentatPayoff')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN('OperatingLeasePayoff')
							   AND gle.Name IN('ImpairmentatPayoff')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS AssetImpairment_Payoff_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND ((gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff') AND gle.Name IN('LeasedAssetReturnedToInventory', 'FinancingLeasedAssetReturnedtoInventory'))
						    OR (gltt.Name = 'InstallLeasePayoff' AND gle.Name = 'Inventory'))
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND ((gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff') AND gle.Name IN('LeasedAssetReturnedToInventory', 'FinancingLeasedAssetReturnedtoInventory'))
									  OR (gltt.Name = 'InstallLeasePayoff' AND gle.Name = 'Inventory'))
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS LeasedAssetReturnedtoInventory_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('OperatingLeasePayoff' , 'CapitalLeasePayoff', 'InstallLeasePayoff')
					  AND gle.Name IN('CostOfGoodsSold')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('OperatingLeasePayoff' , 'CapitalLeasePayoff', 'InstallLeasePayoff')
							   AND gle.Name IN('CostOfGoodsSold')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS CostOfGoodsSold_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('OperatingLeasePayoff' , 'CapitalLeasePayoff', 'InstallLeasePayoff')
					  AND gle.Name IN('FinancingCostOfGoodsSold')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('OperatingLeasePayoff' , 'CapitalLeasePayoff', 'InstallLeasePayoff')
							   AND gle.Name IN('FinancingCostOfGoodsSold')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS FinancingCostOfGoodsSold_GL	
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
				      AND gle.Name = 'AccumulatedAssetImpairment'
					  AND mgle.Name = 'AccumulatedAssetImpairment'
					  AND mgltt.Name = 'AssetBookValueAdjustment'
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
							   AND gle.Name = 'AccumulatedAssetImpairment'
							   AND mgle.Name = 'AccumulatedAssetImpairment'
							   AND mgltt.Name = 'AssetBookValueAdjustment'
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedAccumulatedAssetImpairment_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
					  AND gle.Name = 'AccumulatedAssetImpairment'
					  AND mgle.Name = 'AccumulatedImpairment'
					  AND mgltt.Name IN ('OperatingLeasePayoff' , 'CapitalLeasePayoff')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking')
							   AND gle.Name = 'AccumulatedAssetImpairment'
							   AND mgle.Name = 'AccumulatedImpairment'
					           AND mgltt.Name IN ('OperatingLeasePayoff' , 'CapitalLeasePayoff')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedAccumulatedNBVImpairment_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 0
					  AND gltt.Name IN('OperatingLeaseIncome')
					  AND gle.Name IN('AccumulatedFixedTermDepreciation')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN('OperatingLeaseIncome')
							   AND gle.Name IN('AccumulatedFixedTermDepreciation')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS FixedTermDepreciation_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 0
					  AND gltt.Name IN('OTPIncome')
					  AND gle.Name IN('AccumulatedOTPDepreciation')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN('OTPIncome')
							   AND gle.Name IN('AccumulatedOTPDepreciation') 
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS OTPDepreciation_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('OTPIncome', 'OperatingLeasePayoff', 'OperatingLeaseChargeoff')
					  AND gle.Name IN ('AccumulatedFixedTermDepreciation', 'AccumulatedDepreciation')
					  AND mgltt.Name = 'OperatingLeaseIncome' 
					  AND mgle.Name = 'AccumulatedFixedTermDepreciation'
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('OTPIncome', 'OperatingLeasePayoff', 'OperatingLeaseChargeoff')
							   AND gle.Name IN ('AccumulatedFixedTermDepreciation', 'AccumulatedDepreciation')
							   AND mgltt.Name = 'OperatingLeaseIncome' 
							   AND mgle.Name = 'AccumulatedFixedTermDepreciation'
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedFixedTermDepreciation_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('OperatingLeasePayoff', 'OperatingLeaseChargeoff', 'CapitalLeasePayoff', 'CapitalLeaseChargeoff')
					  AND gle.Name IN ('AccumulatedOTPDepreciation', 'AccumulatedDepreciation')
					  AND mgltt.Name = 'OTPIncome' 
					  AND mgle.Name = 'AccumulatedOTPDepreciation'
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('OperatingLeasePayoff', 'OperatingLeaseChargeoff', 'CapitalLeasePayoff', 'CapitalLeaseChargeoff')
							   AND gle.Name IN ('AccumulatedOTPDepreciation', 'AccumulatedDepreciation')
							   AND mgltt.Name = 'OTPIncome' 
							   AND mgle.Name = 'AccumulatedOTPDepreciation'
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedOTPDepreciation_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 0
					  AND gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff')
					  AND gle.Name = 'AccumulatedAssetDepreciation'
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff')
							   AND gle.Name  = 'AccumulatedAssetDepreciation'
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS AssetDepreciation_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('OperatingLeaseBooking', 'CapitalLeaseBooking')
					  AND gle.Name = 'AccumulatedAssetDepreciation'
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('OperatingLeaseBooking', 'CapitalLeaseBooking')
							   AND gle.Name  = 'AccumulatedAssetDepreciation'
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedAssetDepreciation_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('CapitalLeaseChargeoff', 'CapitalLeasePayoff', 'OperatingLeaseChargeoff', 'OperatingLeasePayoff')
					  AND gle.Name  IN ('ImpairmentAtPayoff')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('CapitalLeaseChargeoff', 'CapitalLeasePayoff', 'OperatingLeaseChargeoff', 'OperatingLeasePayoff')
							   AND gle.Name  IN ('ImpairmentAtPayoff')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedAssetImp_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('CapitalLeaseChargeoff', 'CapitalLeasePayoff', 'OperatingLeaseChargeoff', 'OperatingLeasePayoff')
					  AND gle.Name  IN ('AccumulatedOTPNBVImpairment', 'AccumulatedNBVImpairment', 'ImpairmentAtPayoff')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('CapitalLeaseChargeoff', 'CapitalLeasePayoff', 'OperatingLeaseChargeoff', 'OperatingLeasePayoff')
							   AND gle.Name  IN ('AccumulatedOTPNBVImpairment', 'AccumulatedNBVImpairment', 'ImpairmentAtPayoff')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedImp_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('CapitalLeaseChargeoff', 'CapitalLeasePayoff', 'OperatingLeaseChargeoff', 'OperatingLeasePayoff')
					  AND gle.Name  IN ('AccumulatedOTPNBVImpairment', 'AccumulatedNBVImpairment')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('CapitalLeaseChargeoff', 'CapitalLeasePayoff', 'OperatingLeaseChargeoff', 'OperatingLeasePayoff')
							   AND gle.Name  IN ('AccumulatedOTPNBVImpairment', 'AccumulatedNBVImpairment')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS ClearedNBVImp_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('CapitalLeasePayoff', 'OperatingLeasePayoff')
					  AND gle.Name IN('ImpairmentAtPayoff')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('CapitalLeasePayoff', 'OperatingLeasePayoff')
							   AND gle.Name IN('ImpairmentAtPayoff')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS AssetImpairment_Setup_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 0
					  AND gltt.Name IN('CapitalLeasePayoff', 'OperatingLeasePayoff')
					  AND gle.Name IN('AccumulatedAssetImpairment')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN('CapitalLeasePayoff', 'OperatingLeasePayoff')
							   AND gle.Name IN('AccumulatedAssetImpairment')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS AssetImpairment_GL
	, SUM(CASE
                 WHEN gld.IsDebit = 1
					  AND gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff', 'CapitalLeaseChargeoff', 'OperatingLeaseChargeoff')
					  AND gle.Name IN ('AccumulatedFixedTermDepreciation', 'AccumulatedOTPDepreciation', 'AccumulatedDepreciation')
                 THEN Amount_Amount
                 ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('OperatingLeasePayoff', 'CapitalLeasePayoff', 'CapitalLeaseChargeoff', 'OperatingLeaseChargeoff')
							   AND gle.Name IN ('AccumulatedFixedTermDepreciation', 'AccumulatedOTPDepreciation', 'AccumulatedDepreciation')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AccumulatedDepreciation_GL
     , SUM(CASE
               WHEN gld.IsDebit = 1
					AND gltt.Name IN('BlendedIncomeSetup')
				    AND gle.Name IN ('Inventory')
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND gltt.Name IN('BlendedIncomeSetup')
							   AND gle.Name IN ('Inventory')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS BlendedIncomeSetUp_ETC_GL
     , SUM(CASE
               WHEN gld.IsDebit = 0
					AND gltt.Name IN ('CapitalLeaseBooking','OperatingLeaseBooking')
					AND gle.Name IN('CapitalizedInterimRent', 'CapitalizedInterimInterest', 'SalesTaxPayable', 'CapitalizedAdditionalFee')
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND gltt.Name IN ('CapitalLeaseBooking','OperatingLeaseBooking')
							   AND gle.Name IN('CapitalizedInterimRent', 'CapitalizedInterimInterest', 'SalesTaxPayable', 'CapitalizedAdditionalFee')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS TotalCapitalizedAmount_GL
     , SUM(CASE
               WHEN gld.IsDebit = 0
				    AND ec.ContractType = 'Operating'
					AND gltt.Name IN ('OperatingLeaseChargeoff')
					AND gle.Name IN('OperatingLeaseAsset', 'OTPLeasedAsset')
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 1
							   AND ec.ContractType = 'Operating'
							   AND gltt.Name IN ('OperatingLeaseChargeoff')
							   AND gle.Name IN('OperatingLeaseAsset', 'OTPLeasedAsset')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS Chargeoff_GL
     , SUM(CASE
               WHEN gld.IsDebit = 1
				    AND ec.ContractType = 'Operating'
					AND gltt.Name IN ('OperatingLeaseChargeoff')
					AND gle.Name IN('AccumulatedDepreciation','AccumulatedNBVImpairment')
               THEN Amount_Amount
               ELSE 0.00
           END) - SUM(CASE
                          WHEN gld.IsDebit = 0
							   AND ec.ContractType = 'Operating'
							   AND gltt.Name IN ('OperatingLeaseChargeoff')
							   AND gle.Name IN('AccumulatedDepreciation','AccumulatedNBVImpairment')
                          THEN Amount_Amount
                          ELSE 0.00
                      END) AS AccumulatedChargeoff_GL
INTO #GLDetails
FROM #EligibleContracts ec
	 INNER JOIN GLJournalDetails gld ON gld.EntityId = ec.ContractId
										AND gld.EntityType = 'Contract'
     INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
     INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
     INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
	 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON ec.ContractId = renewal.ContractId
     LEFT JOIN GLTemplateDetails mgltd ON mgltd.Id = gld.MatchingGLTemplateDetailId
     LEFT JOIN GLEntryItems mgle ON mgle.Id = mgltd.EntryItemId
     LEFT JOIN GLTransactionTypes mgltt ON mgle.GLTransactionTypeId = mgltt.Id
	 LEFT JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
WHERE gle.Name IN('Inventory', 'AccumulatedFixedTermDepreciation', 'AccumulatedDepreciation', 'AccumulatedAssetImpairment', 'AccumulatedNBVImpairment', 'AccumulatedOTPNBVImpairment', 'AccumulatedAssetDepreciation', 'LeasedAssetReturnedToInventory', 'CostOfGoodsSold'
				, 'FinancingCostOfGoodsSold', 'AccumulatedOTPDepreciation', 'ImpairmentatPayoff', 'Inventory', 'CapitalizedInterimRent', 'CapitalizedInterimInterest', 'SalesTaxPayable', 'CapitalizedAdditionalFee', 'OperatingLeaseAsset', 'FinancingLeasedAssetReturnedtoInventory', 'OTPLeasedAsset')
     AND gltt.Name IN('CapitalLeaseBooking', 'OperatingLeaseBooking', 'OperatingLeasePayoff', 'CapitalLeasePayoff', 'OperatingLeaseChargeOff', 'OTPIncome', 'OperatingLeaseIncome', 'NBVImpairment', 'CapitalLeaseChargeoff', 'InstallLeasePayoff', 'BlendedIncomeSetup')
GROUP BY ec.ContractId;
 
CREATE NONCLUSTERED INDEX IX_Id ON #GLDetails(ContractId);

SELECT DISTINCT 
       c.ContractId AS ContractId
     , avh.AssetId
     , SUM(CASE
               WHEN avh.IsCleared = 1
               THEN 1
               ELSE 0
           END) IsCleared
	 , avh.SourceModule
INTO #NotCleared
FROM #EligibleContracts c
     INNER JOIN LeaseFinances lf ON c.ContractId = lf.ContractId
     INNER JOIN LeaseAssets la ON lf.Id = la.LeaseFinanceId
     INNER JOIN Assets a ON a.Id = la.AssetId
     INNER JOIN AssetValueHistories avh ON a.Id = avh.AssetId
WHERE lf.IsCurrent = 1
GROUP BY c.ContractId
       , avh.AssetId
	   , avh.SourceModule

CREATE NONCLUSTERED INDEX IX_Id ON #NotCleared(ContractId);

SELECT c.ContractId
     , coa.AssetId 
	 , co.ChargeOffDate
	 , co.Id AS ChargeOffId
INTO #ChargedOffAssets
FROM #EligibleContracts c
     INNER JOIN ChargeOffs co ON co.ContractId = c.ContractId
     INNER JOIN ChargeOffAssetDetails coa ON coa.ChargeOffId = co.Id
WHERE co.IsActive = 1
      AND co.Status = 'Approved'
      AND co.IsRecovery = 0
      AND co.ReceiptId IS NULL
      AND coa.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_Id ON #ChargedOffAssets(ContractId);

SELECT DISTINCT
	   ec.ContractId AS ContractId
     , avh.AssetId
     , MAX(avh.IncomeDate) [FixedTermClearedTillIncomeDate]
INTO #ClearedAVHIncomeDateForImpairment
FROM #EligibleContracts ec
     INNER JOIN #Payoffs p ON p.ContractId = ec.ContractId
	 INNER JOIN PayoffAssets poa ON poa.PayoffId = p.PayoffId
     INNER JOIN LeaseAssets la ON la.Id = poa.LeaseAssetId
     INNER JOIN Assets a ON la.AssetId = a.Id
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = p.AssetsValueStatusChangeId
										   AND a.Id = avh.AssetId
WHERE avh.IsCleared = 1
	  AND avh.SourceModule IN ('AssetImpairment')
	  AND poa.IsActive = 1
GROUP BY ec.ContractId
       , avh.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedAVHIncomeDateForImpairment(ContractId);

SELECT DISTINCT
	 ec.ContractId AS ContractId
     , avh.AssetId
     , MAX(avh.IncomeDate) [FixedTermClearedTillIncomeDate]
INTO #ClearedAVHIncomeDateForNBVImpairment
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
	 INNER JOIN LeaseAmendments lam ON lf.Id = lam.CurrentLeaseFinanceId
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
     INNER JOIN Assets a ON la.AssetId = a.Id
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lam.Id
										   AND a.Id = avh.AssetId
WHERE avh.IsCleared = 1
	  AND avh.SourceModule IN ('NBVImpairments')
	  AND lam.AmendmentType = 'NBVImpairment'
GROUP BY ec.ContractId
       , avh.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedAVHIncomeDateForNBVImpairment(ContractId);

--(MAX) IsCleared =1
SELECT DISTINCT 
       avh.AssetId
     , MAX(avh.IncomeDate) AS IncomeDate
     , MAX(avh.Id) AS MaxId
	 , ec.ContractId
	 , avh.IsLeaseComponent
INTO #MaxCleared
FROM #EligibleContracts ec
	 INNER JOIN LeaseAssets la ON ec.LeaseFinanceId = la.LeaseFinanceId
	 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			                               AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
WHERE avh.IsAccounted = 1
      AND avh.IsCleared = 1
	  AND avh.IncomeDate <= ec.MaturityDate
GROUP BY avh.AssetId
	   , ec.ContractId
	   , avh.IsLeaseComponent;


CREATE NONCLUSTERED INDEX IX_Id ON #MaxCleared(ContractId);

-- (Second Max) IsCleared =1
SELECT avh.AssetId
     , MAX(avh.Id) AS MinId
	 , ec.ContractId
	 , avh.IsLeaseComponent
	 , CAST('' AS NVARCHAR(100)) AS SourceModule
INTO #MinCleared
FROM #EligibleContracts ec
	 INNER JOIN LeaseAssets la ON ec.LeaseFinanceId = la.LeaseFinanceId
	 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId 
			                               AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
	 INNER JOIN #MaxCleared t ON t.AssetId = avh.AssetId 
								 AND t.IsLeaseComponent = avh.IsLeaseComponent
WHERE avh.IsAccounted = 1
      AND avh.IsCleared = 1
      AND avh.Id < t.MaxId
GROUP BY avh.AssetId
       , ec.ContractId
	   , avh.IsLeaseComponent;

CREATE NONCLUSTERED INDEX IX_Id ON #MinCleared(ContractId);

UPDATE #MinCleared SET SourceModule = avh.SourceModule
FROM  #MinCleared  
INNER JOIN AssetValueHistories avh ON avh.Id = #MinCleared.MinId

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT ec.ContractId
      , SUM(CASE 
				WHEN avh.IsLeaseComponent = 1 
					 AND la.IsFailedSaleLeaseback = 0 
				THEN avh.Value_Amount
				ELSE 0.00 
			   END) * -1 AS NBVImpairment_LC_Table
	 , SUM(CASE
			   WHEN la.IsFailedSaleLeaseback = 1 
					OR avh.IsLeaseComponent = 0
				THEN avh.Value_Amount
				ELSE 0.00 
			   END) * -1 AS NBVImpairment_NLC_Table
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
	 INNER JOIN LeaseAmendments lam ON lf.Id = lam.CurrentLeaseFinanceId
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lam.Id
										   AND la.AssetId = avh.AssetId
WHERE avh.SourceModule IN(''NBVImpairments'')
     AND lam.AmendmentType = ''NBVImpairment''
     AND avh.IsAccounted = 1
	 AND avh.GLJournalId IS NOT NULL
	 AND avh.ReversalGLJournalId IS NULL
GROUP BY ec.ContractId;'
INSERT INTO #NBVImpairment
EXEC (@SQL)
END


IF @IsSku = 0
BEGIN
INSERT INTO #NBVImpairment
SELECT ec.ContractId
     , SUM(CASE
               WHEN avh.IsLeaseComponent = 1
                    AND la.IsFailedSaleLeaseback = 0
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS NBVImpairment_LC_Table
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1
                    OR avh.IsLeaseComponent = 0
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS NBVImpairment_NLC_Table
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
     INNER JOIN LeaseAmendments lam ON lf.Id = lam.CurrentLeaseFinanceId
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lam.Id
                                           AND la.AssetId = avh.AssetId
WHERE avh.SourceModule = 'NBVImpairments'
      AND lam.AmendmentType = 'NBVImpairment'
      AND avh.IsAccounted = 1
      AND avh.GLJournalId IS NOT NULL
      AND avh.ReversalGLJournalId IS NULL
GROUP BY ec.ContractId;
END

CREATE NONCLUSTERED INDEX IX_Id ON #NBVImpairment(ContractId);

INSERT INTO #Impairment_Asset
SELECT ec.ContractId
     , SUM(CASE
               WHEN avh.IsLeaseComponent = 1
                    AND la.IsFailedSaleLeaseback = 0
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS AssetImpairment_LC_Table
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1
                    OR avh.IsLeaseComponent = 0
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS AssetImpairment_NLC_Table
FROM #EligibleContracts ec
	 INNER JOIN #Payoffs p ON p.ContractId = ec.ContractId
     INNER JOIN PayoffAssets poa ON poa.PayoffId = p.PayoffId
     INNER JOIN LeaseAssets la ON la.Id = poa.LeaseAssetId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = p.AssetsValueStatusChangeId
                                           AND la.AssetId = avh.AssetId
WHERE avh.SourceModule IN('AssetImpairment')
      AND avh.IsAccounted = 1
      AND avh.GLJournalId IS NOT NULL
      AND avh.ReversalGLJournalId IS NULL
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #Impairment_Asset(ContractId);

 SET @SQL =
'DECLARE @ClearAccumulatedAccountsatPayoff NVARCHAR(50)
 SELECT @ClearAccumulatedAccountsatPayoff = ISNULL(Value,''True'') FROM GlobalParameters WHERE Name = ''ClearAccumulatedAccountsatPayoff''

 IF @ClearAccumulatedAccountsatPayoff IS NULL
 SET @ClearAccumulatedAccountsatPayoff = ''True''

 SELECT ec.ContractId
     , SUM(CASE 
               WHEN @ClearAccumulatedAccountsatPayoff =''True''
				    AND p.IsPaidOffInInstallPhase = 0
					AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
               THEN IIF(ec.SyndicationLeaseFinanceId IS NOT NULL AND ec.ReceivableForTransferType != ''SaleOfPayments'' AND p.LeaseFinanceId >= ec.SyndicationLeaseFinanceId, CAST(pa.AssetValuation_Amount * ec.RetainedPortion AS DECIMAL(16,2)), pa.AssetValuation_Amount)
			   WHEN @ClearAccumulatedAccountsatPayoff =''False''
			        AND p.IsPaidOffInInstallPhase = 0
					AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
               THEN CASE
						WHEN ec.ContractType = ''Operating'' AND pa.Status NOT IN (''Purchase'', ''ReturnToUpgrade'')
							 AND coa.ContractId IS NULL
					    THEN IIF(ec.SyndicationLeaseFinanceId IS NOT NULL AND p.LeaseFinanceId >= ec.SyndicationLeaseFinanceId, CAST(la.NBV_Amount * ec.RetainedPortion AS DECIMAL(16,2)), la.NBV_Amount)
						WHEN ec.ContractType = ''Operating'' AND pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
						THEN IIF(ec.SyndicationLeaseFinanceId IS NOT NULL AND p.LeaseFinanceId >= ec.SyndicationLeaseFinanceId, CAST(pa.AssetValuation_Amount * ec.RetainedPortion AS DECIMAL(16,2)), pa.AssetValuation_Amount)
						ELSE pa.LeaseComponentLessorOwnedNBV_Amount
					END  
               WHEN p.IsPaidOffInInstallPhase = 1
					AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
					AND pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
               THEN -pa.AssetValuation_Amount
               ELSE 0.00
           END) AS LeasedAssetReturnedtoInventory_LC_Table
     , SUM(CASE 
			   WHEN @ClearAccumulatedAccountsatPayoff =''False''
				    AND p.IsPaidOffInInstallPhase = 0
					AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND p.PayoffEffectiveDate > ec.MaturityDate
			   THEN	IIF(ec.SyndicationLeaseFinanceId IS NOT NULL AND p.LeaseFinanceId >= ec.SyndicationLeaseFinanceId, CAST(la.BookedResidual_Amount * ec.RetainedPortion AS DECIMAL(16,2)), la.BookedResidual_Amount)
               WHEN @ClearAccumulatedAccountsatPayoff =''True''
				    AND p.IsPaidOffInInstallPhase = 0
					AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
               THEN IIF(ec.SyndicationLeaseFinanceId IS NOT NULL AND p.LeaseFinanceId >= ec.SyndicationLeaseFinanceId, CAST(pa.AssetValuation_Amount * ec.RetainedPortion AS DECIMAL(16,2)), pa.AssetValuation_Amount)
			   WHEN @ClearAccumulatedAccountsatPayoff =''False''
			        AND p.IsPaidOffInInstallPhase = 0
					AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
               THEN pa.NonLeaseComponentLessorOwnedNBV_Amount
               WHEN p.IsPaidOffInInstallPhase = 1
					AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
               THEN -pa.AssetValuation_Amount
               ELSE 0.00
           END) AS LeasedAssetReturnedtoInventory_NLC_Table
	 , SUM(CASE 
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
					AND (lf.Id < ec.SyndicationLeaseFinanceId OR ec.SyndicationLeaseFinanceId IS NULL)
					AND ec.IsFromContract = 0
			   THEN pa.AssetValuation_Amount
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
					AND lf.Id >= ec.SyndicationLeaseFinanceId
					AND ec.IsFromContract = 0
			   THEN CAST(pa.AssetValuation_Amount * ec.RetainedPortion AS DECIMAL(16,2))
			   ELSE 0.00
		   END) AS CostofGoodsSold_LC_Table
	 , SUM(CASE 
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND (lf.Id < ec.SyndicationLeaseFinanceId OR ec.SyndicationLeaseFinanceId IS NULL)
					AND ec.IsFromContract = 0
			   THEN pa.AssetValuation_Amount
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND (la.IsFailedSaleLeaseback = 1 OR la.IsLeaseAsset = 0)
					AND lf.Id >= ec.SyndicationLeaseFinanceId
					AND ec.IsFromContract = 0
			   THEN CAST(pa.AssetValuation_Amount * ec.RetainedPortion AS DECIMAL(16,2))
			   ELSE 0.00
		   END) AS CostofGoodsSold_NLC_Table
FROM Payoffassets pa
     INNER JOIN Payoffs p ON p.id = pa.PayoffId
     INNER JOIN LeaseFinances lf ON p.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON pa.LeaseAssetId = la.Id
     INNER JOIN Assets a ON a.Id = la.AssetId
	 INNER JOIN #EligibleContracts ec ON lf.ContractId = ec.ContractId
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
								        AND la.AssetId = coa.AssetId
WHERE p.Status = ''Activated''
      AND pa.Isactive = 1
	  FilterCondition
GROUP BY ec.ContractId;'

IF @FilterCondition IS NOT NULL
BEGIN
	SET @sql = REPLACE(@sql, 'FilterCondition', @FilterCondition);
END;
ELSE
BEGIN
	SET @sql = REPLACE(@sql, 'FilterCondition', '');
END;

INSERT INTO #LeasedAssetReturnedtoInventory
EXEC (@SQL)

IF @IsSku = 1
BEGIN
SET @SQL = 
'DECLARE @ClearAccumulatedAccountsatPayoff NVARCHAR(50)
 SELECT @ClearAccumulatedAccountsatPayoff = ISNULL(Value,''True'') FROM GlobalParameters WHERE Name = ''ClearAccumulatedAccountsatPayoff''

  IF @ClearAccumulatedAccountsatPayoff IS NULL
  SET @ClearAccumulatedAccountsatPayoff = ''True''

 SELECT ec.ContractId
     , SUM(CASE 
               WHEN @ClearAccumulatedAccountsatPayoff =''True''
				    AND p.IsPaidOffInInstallPhase = 0
					AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
               THEN pas.SKUValuation_Amount
			   WHEN @ClearAccumulatedAccountsatPayoff =''False''
			        AND p.IsPaidOffInInstallPhase = 0
					AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
               THEN CASE
						WHEN ec.ContractType = ''Operating'' AND pa.Status NOT IN (''Purchase'', ''ReturnToUpgrade'')
						AND coa.AssetId IS NULL
					    THEN las.NBV_Amount
						WHEN ec.ContractType = ''Operating'' AND pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
						THEN pas.SKUValuation_Amount
						ELSE pas.NBVAsOfEffectiveDate_Amount
					END  
               WHEN p.IsPaidOffInInstallPhase = 1
					AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
					AND pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
               THEN -pas.SKUValuation_Amount
               ELSE 0.00
           END) AS LeasedAssetReturnedtoInventory_LC_Table
     , SUM(CASE 
			  WHEN @ClearAccumulatedAccountsatPayoff =''False''
				   AND p.IsPaidOffInInstallPhase = 0
				   AND (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
				   AND p.PayoffEffectiveDate > ec.MaturityDate
			  THEN las.BookedResidual_Amount
              WHEN @ClearAccumulatedAccountsatPayoff =''True''
				    AND p.IsPaidOffInInstallPhase = 0
					AND (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
               THEN pas.SKUValuation_Amount
			   WHEN @ClearAccumulatedAccountsatPayoff =''False''
			        AND p.IsPaidOffInInstallPhase = 0
					AND (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
               THEN pas.NBVAsOfEffectiveDate_Amount
               WHEN p.IsPaidOffInInstallPhase = 1
					 AND (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
					 AND pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
               THEN -pas.SKUValuation_Amount
               ELSE 0.00
           END) AS LeasedAssetReturnedtoInventory_NLC_Table
	 , SUM(CASE 
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
					AND (lf.Id < ec.SyndicationLeaseFinanceId OR ec.SyndicationLeaseFinanceId IS NULL)
					AND ec.IsFromContract = 0
			   THEN pas.SKUValuation_Amount
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
					AND lf.Id >= ec.SyndicationLeaseFinanceId
					AND ec.IsFromContract = 0
			   THEN CAST(pas.SKUValuation_Amount * ec.RetainedPortion AS DECIMAL(16,2))
			   ELSE 0.00
		   END) AS CostofGoodsSold_LC_Table
	 , SUM(CASE 
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
					AND (lf.Id < ec.SyndicationLeaseFinanceId OR ec.SyndicationLeaseFinanceId IS NULL)
					AND ec.IsFromContract = 0
			   THEN pas.SKUValuation_Amount
			   WHEN pa.Status IN (''Purchase'', ''ReturnToUpgrade'')
				    AND (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
					AND lf.Id >= ec.SyndicationLeaseFinanceId
					AND ec.IsFromContract = 0
			   THEN CAST(pas.SKUValuation_Amount * ec.RetainedPortion AS DECIMAL(16,2))
			   ELSE 0.00
		   END) AS CostofGoodsSold_NLC_Table
FROM Payoffassets pa
     INNER JOIN Payoffs p ON p.id = pa.PayoffId
     INNER JOIN LeaseFinances lf ON p.LeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON pa.LeaseAssetId = la.Id
     INNER JOIN Assets a ON a.Id = la.AssetId
	 INNER JOIN #EligibleContracts ec ON lf.ContractId = ec.ContractId
     INNER JOIN LeaseAssetSKUs las on las.LeaseAssetId = la.Id
     INNER JOIN PayoffAssetSKUs pas on pas.LeaseAssetSKUId = las.Id 
                                       AND pas.PayoffAssetId = pa.Id
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
								       AND la.AssetId = coa.AssetId
WHERE a.IsSKU = 1
      AND las.IsActive = 1
      AND p.Status = ''Activated''
      AND pa.Isactive = 1
GROUP BY ec.ContractId;'
INSERT INTO #LeasedAssetReturnedtoInventorySKUs
EXEC (@SQL)

CREATE NONCLUSTERED INDEX IX_Id ON #LeasedAssetReturnedtoInventorySKUs(ContractId);
END

MERGE #LeasedAssetReturnedtoInventory AS [Source]
USING (SELECT * FROM #LeasedAssetReturnedtoInventorySKUs) AS [Target]
ON [Source].ContractId = [Target].ContractId
WHEN MATCHED 
	 THEN UPDATE 
	 SET [Source].LeasedAssetReturnedtoInventory_LC_Table += [Target].LeasedAssetReturnedtoInventory_LC_Table
       , [Source].LeasedAssetReturnedtoInventory_NLC_Table += [Target].LeasedAssetReturnedtoInventory_NLC_Table
	   , [Source].CostofGoodsSold_LC_Table += [Target].CostofGoodsSold_LC_Table
	   , [Source].CostofGoodsSold_NLC_Table += [Target].CostofGoodsSold_NLC_Table
WHEN NOT MATCHED
	 THEN INSERT (ContractId, LeasedAssetReturnedtoInventory_LC_Table, LeasedAssetReturnedtoInventory_NLC_Table, CostofGoodsSold_LC_Table, CostofGoodsSold_NLC_Table)
	 VALUES ([Target].ContractId, [Target].LeasedAssetReturnedtoInventory_LC_Table, [Target].LeasedAssetReturnedtoInventory_NLC_Table, [Target].CostofGoodsSold_LC_Table, [Target].CostofGoodsSold_NLC_Table);

CREATE NONCLUSTERED INDEX IX_Id ON #LeasedAssetReturnedtoInventory(ContractId);

SELECT ec.ContractId
     , CAST(0.00 AS DECIMAL(16,2)) AS FixedTermDepreciation
     , CAST(0.00 AS DECIMAL(16,2)) AS OTPDepreciation_LC
	 , CAST(0.00 AS DECIMAL(16,2)) AS OTPDepreciation_NLC
     , CAST(0.00 AS DECIMAL(16,2)) AS ClearedFixedTermDepreciation
     , CAST(0.00 AS DECIMAL(16,2)) AS ClearedOTPDepreciation_LC
	 , CAST(0.00 AS DECIMAL(16,2)) AS ClearedOTPDepreciation_NLC
INTO #AssetDepreciation
FROM #EligibleContracts ec;

CREATE NONCLUSTERED INDEX IX_Id ON #AssetDepreciation(ContractId);

SELECT DISTINCT 
       ec.ContractId
     , avh.AssetId
INTO #OTPDepreciationExists
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
WHERE avh.IsAccounted = 1
      AND avh.SourceModule = 'OTPDepreciation';

CREATE NONCLUSTERED INDEX IX_Id ON #OTPDepreciationExists(ContractId, AssetId);

UPDATE ad SET  FixedTermDepreciation = t.FixedTermDepreciation
		     , OTPDepreciation_LC = t.OTPDepreciation_LC
			 , OTPDepreciation_NLC = t.OTPDepreciation_NLC
			 , ClearedFixedTermDepreciation = t.ClearedFixedTermDepreciation
FROM #AssetDepreciation ad
INNER JOIN
(SELECT 
	 ec.ContractId AS ContractId
     , CAST(SUM(CASE WHEN avh.SourceModule = 'FixedTermDepreciation'
						  AND avh.IsLessorOwned = 1
					 THEN avh.Value_Amount
					 ELSE 0.00
				 END)* -1 AS DECIMAL(16,2)) FixedTermDepreciation
	 , CAST(SUM(CASE WHEN avh.SourceModule IN ('FixedTermDepreciation', 'OTPDepreciation')
						  AND (ec.SyndicationDate IS NULL OR (avh.IncomeDate >= ec.SyndicationDate))
						  AND ((la.IsActive = 1 AND reclass.ContractId IS NOT NULL)
							    OR (la.IsActive = 0 AND la.TerminationDate > ec.MaturityDate AND reclass.ContractId IS NOT NULL))
						  AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						  AND (avh.SourceModuleId >= rd.RenewalFinanceId OR rd.RenewalFinanceId IS NULL)
					 THEN avh.Value_Amount
					 WHEN avh.SourceModule IN ('FixedTermDepreciation', 'OTPDepreciation')
						  AND avh.IncomeDate < ec.SyndicationDate
						  AND ((la.IsActive = 1 AND reclass.ContractId IS NOT NULL)
								OR (la.IsActive = 0 AND la.TerminationDate > ec.MaturityDate AND reclass.ContractId IS NOT NULL))
						  AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						  AND (avh.SourceModuleId >= rd.RenewalFinanceId OR rd.RenewalFinanceId IS NULL)
					 THEN avh.Value_Amount * ec.RetainedPortion
					 ELSE 0.00
				END)* -1 AS DECIMAL(16,2)) OTPDepreciation_LC
	 , CAST(SUM(CASE WHEN avh.SourceModule IN ('FixedTermDepreciation', 'OTPDepreciation')
						  AND (ec.SyndicationDate IS NULL OR (avh.IncomeDate >= ec.SyndicationDate))
						  AND ((la.IsActive = 1 AND reclass.ContractId IS NOT NULL)
							    OR (la.IsActive = 0 AND la.TerminationDate > ec.MaturityDate AND reclass.ContractId IS NOT NULL))
						  AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
						  AND (avh.SourceModuleId >= rd.RenewalFinanceId OR rd.RenewalFinanceId IS NULL)
					 THEN avh.Value_Amount
					 WHEN avh.SourceModule IN ('FixedTermDepreciation', 'OTPDepreciation')
						  AND avh.IncomeDate < ec.SyndicationDate
						  AND ((la.IsActive = 1 AND reclass.ContractId IS NOT NULL)
							    OR (la.IsActive = 0 AND la.TerminationDate > ec.MaturityDate))
						  AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
						  AND (avh.SourceModuleId >= rd.RenewalFinanceId OR rd.RenewalFinanceId IS NULL)
					 THEN avh.Value_Amount * ec.RetainedPortion
					 ELSE 0.00
				END)* -1 AS DECIMAL(16,2)) OTPDepreciation_NLC
     , SUM(CASE WHEN avh.SourceModule = 'FixedTermDepreciation'
					 AND reclass.ContractId IS NOT NULL
					 AND rd.ContractId IS NULL
					 AND (poa.ContractId IS NULL OR poa.PayoffEffectiveDate > ec.MaturityDate)
				THEN avh.Value_Amount
				ELSE 0.00
		   END)* -1 ClearedFixedTermDepreciation
	 , CAST(0.00 AS DECIMAL(16, 2)) AS ClearedOTPDepreciation_LC
	 , CAST(0.00 AS DECIMAL(16, 2)) AS ClearedOTPDepreciation_NLC
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
	 INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
	 INNER JOIN LeaseAssets la ON la.AssetId = avh.AssetId
								  AND la.LeaseFinanceId = ec.LeaseFinanceId
	 LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
	 LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
	 LEFT JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
											   AND avh.AssetId = poa.AssetId
	 LEFT JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
WHERE avh.IsAccounted = 1
	  AND avh.SourceModule IN ('FixedTermDepreciation', 'OTPDepreciation')
	  AND avh.GLJournalId IS NOT NULL
	  AND avh.ReversalGLJournalId IS NULL
GROUP BY ec.ContractId) AS t ON t.ContractId = ad.ContractId;

UPDATE ad SET ClearedFixedTermDepreciation = t.ClearedFixedTermDepreciation
FROM #AssetDepreciation ad
INNER JOIN
(
	SELECT ec.ContractId
		 , SUM(avh.Value_Amount)* -1 ClearedFixedTermDepreciation
	FROM #EligibleContracts ec
		 INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		 INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
		 INNER JOIN #ChargeOff co ON co.ContractId = ec.ContractId
		 LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
		 LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
	WHERE avh.IsAccounted = 1
		  AND avh.SourceModule IN('FixedTermDepreciation')
		  AND reclass.ContractId IS NULL
		  AND rd.ContractId IS NULL
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId

UPDATE ad SET ClearedFixedTermDepreciation += t.ClearedFixedTermDepreciation
FROM #AssetDepreciation ad
INNER JOIN
(
	SELECT ec.ContractId
		 , SUM(avh.Value_Amount)* -1 ClearedFixedTermDepreciation 
	FROM #EligibleContracts ec
		 INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		 INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
		 INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
											   AND avh.AssetId = poa.AssetId
		 LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
		 LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
	WHERE avh.IsAccounted = 1
		  AND avh.SourceModule IN('FixedTermDepreciation')
		  AND avh.IncomeDate <= poa.PayoffEffectiveDate
		  AND avh.IncomeDate > ec.CommencementDate
		  AND co.ContractId IS NULL
		  AND rd.ContractId IS NULL
		  AND poa.PayoffEffectiveDate <= ec.MaturityDate 
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId


-- To handle Reclass because of Renewal
UPDATE ad SET ClearedFixedTermDepreciation += t.ClearedFixedTermDepreciation
FROM #AssetDepreciation ad
INNER JOIN
(
	SELECT ec.ContractId
		 , SUM(avh.Value_Amount)* -1 ClearedFixedTermDepreciation 
	FROM #EligibleContracts ec
         INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
		 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation')
          AND avh.IncomeDate > renewal.CommencementDate
          AND avh.IncomeDate <= rd.RenewalDate
		  AND avh.IsAccounted = 1
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId


MERGE #AssetDepreciation AS [Source]
USING
(
	SELECT ec.ContractId
		 , CAST(SUM(avh.Value_Amount * ec.SoldPortion)* -1 AS DECIMAL(16, 2)) ClearedFixedTermDepreciation
	FROM #EligibleContracts ec
		 INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		 INNER JOIN LeaseFinances lf1 ON lf1.ContractId = ec.ContractId
		 INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf1.Id
											   AND avh.AssetId = la.AssetId
		 LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
		 LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
		 LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
		 LEFT JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
											   AND avh.AssetId = poa.AssetId
	WHERE avh.IsAccounted = 1
		  AND avh.SourceModule IN('FixedTermDepreciation')
		  AND co.ContractId IS NULL
		  AND reclass.ContractId IS NULL
		  AND rd.ContractId IS NULL
		  AND avh.IncomeDate < ec.SyndicationDate
		  AND poa.AssetId IS NULL
	GROUP BY ec.ContractId
) AS t
ON [Source].ContractId = t.ContractId
WHEN MATCHED 
	 THEN UPDATE 
	 SET ClearedFixedTermDepreciation += t.ClearedFixedTermDepreciation
WHEN NOT MATCHED
	 THEN
	 INSERT (ContractId, FixedTermDepreciation, OTPDepreciation_LC, OTPDepreciation_NLC, ClearedFixedTermDepreciation, ClearedOTPDepreciation_LC, ClearedOTPDepreciation_NLC)
	 VALUES (t.ContractId, 0.00, 0.00, 0.00, t.ClearedFixedTermDepreciation, 0.00, 0.00);	

-- To handle OTP Reclass after Renewal Logic
UPDATE ad SET ClearedFixedTermDepreciation += t.ClearedFixedTermDepreciation
FROM #AssetDepreciation ad
INNER JOIN
(
	SELECT ec.ContractId
		 , SUM(avh.Value_Amount) * -1 ClearedFixedTermDepreciation 
	FROM #EligibleContracts ec
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
		 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
		 INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
											   AND avh.AssetId = poa.AssetId
		 LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
    WHERE avh.SourceModule IN('FixedTermDepreciation')
          AND avh.IncomeDate > rd.RenewalDate
		  AND avh.IncomeDate <= poa.PayoffEffectiveDate
		  AND avh.IsAccounted = 1
		  AND co.ContractId IS NULL
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId


UPDATE ad SET ClearedFixedTermDepreciation += t.ClearedFixedTermDepreciation
FROM #AssetDepreciation ad
INNER JOIN
(
	SELECT ec.ContractId
		 , SUM(avh.Value_Amount) * -1 ClearedFixedTermDepreciation 
	FROM #EligibleContracts ec
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 1
		 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
		 INNER JOIN #LeaseFinanceForOTPReclass reclass ON reclass.ContractId = ec.ContractId
														  AND reclass.LeaseFinanceId >= rd.RenewalFinanceId 
		 LEFT JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
											   AND avh.AssetId = poa.AssetId
		 LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
    WHERE avh.SourceModule IN('FixedTermDepreciation')
          AND avh.IncomeDate > rd.RenewalDate
		  AND avh.IsAccounted = 1
		  AND co.ContractId IS NULL
		  AND poa.ContractId IS NULL
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId


UPDATE ad SET ClearedFixedTermDepreciation += t.ClearedFixedTermDepreciation
FROM #AssetDepreciation ad
INNER JOIN
(
	SELECT ec.ContractId
		 , SUM(avh.Value_Amount) * -1 ClearedFixedTermDepreciation 
	FROM #EligibleContracts ec
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 1
		 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
		 INNER JOIN #ChargeOff co ON co.ContractId = ec.ContractId
		 LEFT JOIN #LeaseFinanceForOTPReclass reclass ON reclass.ContractId = ec.ContractId
														  AND reclass.LeaseFinanceId >= rd.RenewalFinanceId 
		 LEFT JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
											   AND avh.AssetId = poa.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation')
          AND avh.IncomeDate > rd.RenewalDate
		  AND avh.IsAccounted = 1
		  AND reclass.ContractId IS NULL
		  AND poa.ContractId IS NULL
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId

SELECT t.ContractId
     , SUM(t.ClearedOTPDepreciation_LC) AS ClearedOTPDepreciation_LC
	 , SUM(t.ClearedOTPDepreciation_NLC) AS ClearedOTPDepreciation_NLC
INTO #ClearedOTPAmount
FROM
(SELECT ec.ContractId
     , CAST(SUM(CASE WHEN avh.IncomeDate < ec.SyndicationDate 
						  AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
					 THEN avh.Value_Amount * ec.RetainedPortion
					 WHEN (avh.IncomeDate >= ec.SyndicationDate 
						    OR ec.SyndicationDate IS NULL)
						   AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1	
					 THEN avh.Value_Amount
					 ELSE 0.00
				END)* -1 AS DECIMAL(16, 2)) ClearedOTPDepreciation_LC
     , CAST(SUM(CASE WHEN avh.IncomeDate < ec.SyndicationDate 
						  AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
					 THEN avh.Value_Amount * ec.RetainedPortion
					 WHEN (avh.IncomeDate >= ec.SyndicationDate 
						   OR ec.SyndicationDate IS NULL)
						  AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)	
					 THEN avh.Value_Amount
					 ELSE 0.00
				END)* -1 AS DECIMAL(16, 2)) ClearedOTPDepreciation_NLC
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
	 INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
										   AND avh.AssetId = poa.AssetId
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = poa.LeaseFinanceId
                                  AND avh.AssetId = la.AssetId
	 LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
	 LEFT JOIN #OTPDepreciationExists otpExists ON otpExists.ContractId = ec.ContractId
									               AND otpExists.AssetId = avh.AssetId
     LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
WHERE avh.IsAccounted = 1
	  AND ((avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation') AND (otpExists.ContractId IS NOT NULL OR reclass.ContractId IS NOT NULL)) 
			OR ((otpExists.ContractId IS NULL AND reclass.ContractId IS NULL) AND avh.SourceModule = 'OTPDepreciation'))
      AND avh.IncomeDate <= poa.PayoffEffectiveDate
      AND avh.IncomeDate > ec.CommencementDate
	  AND poa.PayoffEffectiveDate > ec.MaturityDate
      AND co.ContractId IS NULL
GROUP BY ec.ContractId
UNION ALL
SELECT ec.ContractId
     , CAST(SUM(CASE
                    WHEN(avh.IncomeDate < ec.SyndicationDate OR ec.SyndicationDate IS NULL)
                        AND la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                    THEN avh.Value_Amount * ec.RetainedPortion
                    ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) ClearedOTPDepreciation_LC
     , CAST(SUM(CASE
                    WHEN(avh.IncomeDate < ec.SyndicationDate OR ec.SyndicationDate IS NULL)
                        AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
                    THEN avh.Value_Amount * ec.RetainedPortion
                    ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) ClearedOTPDepreciation_NLC
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
     INNER JOIN #ChargeOff co ON co.ContractId = ec.ContractId
     INNER JOIN LeaseAssets la ON la.AssetId = avh.AssetId
                                  AND la.LeaseFinanceId = lf.Id
	 LEFT JOIN #OTPDepreciationExists otpExists ON otpExists.ContractId = ec.ContractId
									               AND otpExists.AssetId = avh.AssetId
     LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
WHERE avh.IsAccounted = 1
      AND avh.IncomeDate > ec.CommencementDate
	  AND ((avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation') AND (otpExists.ContractId IS NOT NULL OR reclass.ContractId IS NOT NULL)) 
			OR ((otpExists.ContractId IS NULL AND reclass.ContractId IS NULL) AND avh.SourceModule = 'OTPDepreciation'))
GROUP BY ec.ContractId) AS t
GROUP BY t.ContractId

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedOTPAmount(ContractId);


MERGE #AssetDepreciation AS Ad
USING (SELECT * FROM #ClearedOTPAmount) AS Cleared
ON ad.ContractId =  Cleared.ContractId
WHEN MATCHED
	 THEN
	 UPDATE SET ClearedOTPDepreciation_LC += Cleared.ClearedOTPDepreciation_LC
	          , ClearedOTPDepreciation_NLC += Cleared.ClearedOTPDepreciation_NLC
WHEN NOT MATCHED
	 THEN
	 INSERT (ContractId, FixedTermDepreciation, OTPDepreciation_LC, OTPDepreciation_NLC, ClearedFixedTermDepreciation, ClearedOTPDepreciation_LC, ClearedOTPDepreciation_NLC)
	 VALUES (Cleared.ContractId, 0.00, 0.00, 0.00, 0.00, Cleared.ClearedOTPDepreciation_LC, Cleared.ClearedOTPDepreciation_NLC);	

UPDATE ad SET 
              ClearedOTPDepreciation_LC += t.ClearedOTPDepreciation_LC
            , ClearedOTPDepreciation_NLC += t.ClearedOTPDepreciation_NLC
FROM #AssetDepreciation ad
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN avh.IncomeDate < ec.SyndicationDate
                             AND la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount * ec.RetainedPortion
                        WHEN(avh.IncomeDate >= ec.SyndicationDate OR ec.SyndicationDate IS NULL)
                            AND la.IsFailedSaleLeaseback = 0
                            AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) ClearedOTPDepreciation_LC
         , CAST(SUM(CASE
                        WHEN avh.IncomeDate < ec.SyndicationDate
                             AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
                        THEN avh.Value_Amount * ec.RetainedPortion
                        WHEN(avh.IncomeDate >= ec.SyndicationDate OR ec.SyndicationDate IS NULL)
                            AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) ClearedOTPDepreciation_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
         INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
         INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
                                               AND avh.AssetId = poa.AssetId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = poa.LeaseFinanceId
                                      AND avh.AssetId = la.AssetId
         LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
		 LEFT JOIN #OTPDepreciationExists otpExists ON otpExists.ContractId = ec.ContractId
									               AND otpExists.AssetId = avh.AssetId
		 LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
    WHERE avh.IsAccounted = 1
          AND avh.IncomeDate > poa.PayoffEffectiveDate
		  AND ((avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation') AND (otpExists.ContractId IS NOT NULL OR reclass.ContractId IS NOT NULL)) 
			    OR ((otpExists.ContractId IS NULL AND reclass.ContractId IS NULL) AND avh.SourceModule = 'OTPDepreciation'))
          AND avh.IncomeDate > ec.CommencementDate
          AND co.ContractId IS NULL
		  AND avh.IsLessorOwned = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId;


UPDATE cleared SET 
                   ClearedOTPDepreciation_LC += t.Amount_LC
                 , ClearedOTPDepreciation_NLC += t.Amount_NLC
FROM #AssetDepreciation cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
		 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
		 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 1
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
		 LEFT JOIN #OTPDepreciationExists otpExists ON otpExists.ContractId = ec.ContractId
									               AND otpExists.AssetId = avh.AssetId
		 LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
    WHERE avh.IncomeDate > renewal.CommencementDate
		AND rd.RenewalDate > renewal.MaturityDate
		  AND ((avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation') AND (otpExists.ContractId IS NOT NULL OR reclass.ContractId IS NOT NULL)) 
			    OR ((otpExists.ContractId IS NULL AND reclass.ContractId IS NULL) AND avh.SourceModule = 'OTPDepreciation'))
          AND avh.IncomeDate <= rd.RenewalDate
		  AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

UPDATE ad SET 
              FixedTermDepreciation = t.FixedTermDepreciation
FROM #AssetDepreciation ad
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN avh.IncomeDate < ec.SyndicationDate
                        THEN avh.Value_Amount * ec.RetainedPortion
                        WHEN(avh.IncomeDate >= ec.SyndicationDate OR ec.SyndicationDate IS NULL)
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) FixedTermDepreciation
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
         INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
         INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
                                               AND avh.AssetId = poa.AssetId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = poa.LeaseFinanceId
                                      AND avh.AssetId = la.AssetId
         LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
		 LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
		 LEFT JOIN #OTPDepreciationExists otpExists ON otpExists.ContractId = ec.ContractId
															AND otpExists.AssetId = la.AssetId
    WHERE avh.IsAccounted = 1
          AND ((la.IsActive = 1 AND	(reclass.ContractId IS NOT NULL OR otpExists.AssetId IS NOT NULL))
			    OR (la.IsActive = 0 AND la.TerminationDate > ec.MaturityDate))
          AND avh.IncomeDate > poa.PayoffEffectiveDate
		  AND avh.SourceModule IN ('FixedTermDepreciation')
          AND avh.IncomeDate > ec.CommencementDate
          AND co.ContractId IS NULL
		  AND avh.IsLessorOwned = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId;

UPDATE ad SET OTPDepreciation_LC += t.OTPDepreciation_LC
			, OTPDepreciation_NLC += t.OTPDepreciation_NLC
FROM #AssetDepreciation ad
INNER JOIN
(
		SELECT ec.ContractId
			 , SUM(CASE
					   WHEN la.IsFailedSaleLeaseback = 0
							AND avh.IsLeaseComponent = 1
					   THEN avh.Value_Amount
					   ELSE 0.00
				   END)* -1 OTPDepreciation_LC
			 , SUM(CASE
					   WHEN la.IsFailedSaleLeaseback = 1
							OR avh.IsLeaseComponent = 0
					   THEN avh.Value_Amount
					   ELSE 0.00
				   END)* -1 OTPDepreciation_NLC
		FROM #EligibleContracts ec
			 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
			 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
			 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
										  AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
			 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			 LEFT JOIN #OTPReclass reclass ON reclass.ContractId = ec.ContractId
			 LEFT JOIN #OTPDepreciationExists otpExists ON otpExists.ContractId = ec.ContractId
															AND otpExists.AssetId = la.AssetId
		WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
			 AND avh.IncomeDate > renewal.CommencementDate
			 AND avh.IncomeDate <= rd.RenewalDate
			 AND rd.RenewalDate > renewal.MaturityDate
			 AND avh.IsAccounted = 1
			 AND avh.ReversalGLJournalId IS NULL
			 AND avh.GLJournalId IS NOT NULL
			 AND ((la.IsActive = 1 AND (reclass.ContractId IS NOT NULL OR otpExists.AssetId IS NOT NULL))
				   OR (la.IsActive = 0 AND la.TerminationDate > ec.MaturityDate AND reclass.ContractId IS NOT NULL))
		GROUP BY ec.ContractId
) AS t ON t.ContractId = ad.ContractId

SELECT t.*
		, avh.IsCleared
INTO #LastRecordAVHForPayoff
FROM
(
	SELECT DISTINCT 
			ec.ContractId AS ContractId
			, avh.AssetId
			, MAX(avh.Id) AVHId
	FROM #EligibleContracts ec
			INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
			INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
										 AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL 
			INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
												  AND avh.AssetId = poa.AssetId
			LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											   AND coa.AssetId = avh.AssetId
	WHERE avh.IncomeDate <= poa.PayoffEffectiveDate
		  AND poa.PayoffAssetStatus NOT IN ('Purchase', 'ReturnToUpgrade')
		  AND coa.AssetId IS NULL
		  AND poa.IsPaidOffInInstallPhase = 0
	GROUP BY ec.ContractId
			, avh.AssetId
) AS t
INNER JOIN AssetValueHistories avh ON avh.Id = t.AVHId;


CREATE NONCLUSTERED INDEX IX_Id ON #LastRecordAVHForPayoff(ContractId);

SELECT DISTINCT 
       ec.ContractId AS ContractId
     , avh.AssetId
     , MAX(avh.IncomeDate) [FixedTermClearedTillIncomeDate]
INTO #ClearedAVHIncomeDate
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
     INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId
                                           AND avh.AssetId = poa.AssetId
WHERE avh.IncomeDate <= poa.PayoffEffectiveDate
      AND poa.PayoffAssetStatus NOT IN('Purchase', 'ReturnToUpgrade')
     AND avh.IsCleared = 1
GROUP BY ec.ContractId
       , avh.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedAVHIncomeDate(ContractId);

SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_LC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_NLC
INTO #AssetDepreciationAmount
FROM #LastRecordAVHForPayoff lastRecord
     INNER JOIN #EligibleContracts ec ON lastRecord.ContractId = ec.ContractId
     INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
     INNER JOIN AssetValueHistories avh ON lastRecord.AssetId = avh.AssetId
										   AND avh.SourceModuleId IN (SELECT Id FROM LeaseFinances WHERE ContractId = ec.ContractId)
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
								  AND la.AssetId = avh.AssetId
     LEFT JOIN #ClearedAVHIncomeDate cleared ON cleared.ContractId = ec.ContractId
                                                 AND avh.AssetId = cleared.AssetId
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											   AND coa.AssetId = avh.AssetId
WHERE lastRecord.IsCleared = 0
      AND ((cleared.FixedTermClearedTillIncomeDate IS NOT NULL AND avh.IncomeDate > cleared.FixedTermClearedTillIncomeDate) OR cleared.FixedTermClearedTillIncomeDate IS NULL)
      AND avh.Id <= lastRecord.AVHId
      AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
      AND avh.IsAccounted = 1
	  AND @ClearAccumulatedAccountsatPayoff  = 'False'
	  AND coa.AssetId IS NULL
GROUP BY ec.ContractId;

SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_LC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_NLC
INTO #ClearedAssetDepreciationAmount
FROM #LastRecordAVHForPayoff lastRecord
     INNER JOIN #EligibleContracts ec ON lastRecord.ContractId = ec.ContractId
     INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId IN (SELECT Id FROM LeaseFinances WHERE ContractId = ec.ContractId)
                                           AND lastRecord.AssetId = avh.AssetId
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
								  AND la.AssetId = avh.AssetId
     INNER JOIN #ClearedAVHIncomeDate cleared ON cleared.ContractId = ec.ContractId
                                                 AND avh.AssetId = cleared.AssetId
	 INNER JOIN #MaxCleared [max] ON [max].ContractId = lf.ContractId	
									 AND [max].AssetId = avh.AssetId
									 AND [max].IsLeaseComponent = avh.IsLeaseComponent
	 INNER JOIN #MinCleared [min] ON [min].ContractId = lf.ContractId	
									 AND [min].AssetId = avh.AssetId
									 AND [min].IsLeaseComponent = avh.IsLeaseComponent
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											   AND coa.AssetId = avh.AssetId
WHERE lastRecord.IsCleared = 1
      AND avh.Id <= lastRecord.AVHId
	  AND avh.Id > MinId
      AND avh.Id <= MaxId
      AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
      AND avh.IsAccounted = 1
	  AND @ClearAccumulatedAccountsatPayoff  = 'False'
	  AND coa.AssetId IS NULL
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedAssetDepreciationAmount(ContractId);

MERGE #AssetDepreciationAmount AS [Source]
USING (SELECT * FROM #ClearedAssetDepreciationAmount) AS [Target]
ON [Source].ContractId = [Target].ContractId
WHEN MATCHED
	 THEN UPDATE
			    SET [Source].AssetDepreciation_LC += [Target].AssetDepreciation_LC
				  , [Source].AssetDepreciation_NLC += [Target].AssetDepreciation_NLC
WHEN NOT MATCHED
	 THEN INSERT (ContractId, AssetDepreciation_LC, AssetDepreciation_NLC)
		  VALUES ([Target].ContractId, [Target].AssetDepreciation_LC, [Target].AssetDepreciation_NLC);


SELECT ec.ContractId
     , CAST(SUM(CASE
                    WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
                    THEN avh.Value_Amount * ec.RetainedPortion
                    ELSE 0
                END)* -1 AS DECIMAL(16, 2)) AS SyndicationAmount_LC
     , CAST(SUM(CASE
                    WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
                    THEN avh.Value_Amount * ec.RetainedPortion
                    ELSE 0
                END)* -1 AS DECIMAL(16, 2)) AS SyndicationAmount_NLC
INTO #SyndicationAssetDepreciationAmount
FROM #LastRecordAVHForPayoff payoff
     INNER JOIN #EligibleContracts ec ON ec.ContractId = payoff.ContractId
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id
                                           AND payoff.AssetId = avh.AssetId
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
                                  AND la.AssetId = avh.AssetId
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											   AND coa.AssetId = avh.AssetId
WHERE avh.IncomeDate < ec.SyndicationDate
      AND avh.IncomeDate > ec.CommencementDate
	  AND avh.SourceModule IN('FixedTermDepreciation')
	  AND coa.AssetId IS NULL
GROUP BY ec.ContractId;
CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationAssetDepreciationAmount(ContractId);

MERGE #AssetDepreciationAmount AS [Source]
USING (SELECT * FROM #SyndicationAssetDepreciationAmount) AS [Target]
ON [Source].ContractId = [Target].ContractId
WHEN MATCHED
	 THEN UPDATE
			    SET [Source].AssetDepreciation_LC += [Target].SyndicationAmount_LC
				  , [Source].AssetDepreciation_NLC += [Target].SyndicationAmount_NLC
WHEN NOT MATCHED
	 THEN INSERT (ContractId, AssetDepreciation_LC, AssetDepreciation_NLC)
		  VALUES ([Target].ContractId, [Target].SyndicationAmount_LC, SyndicationAmount_NLC);

CREATE NONCLUSTERED INDEX IX_Id ON #AssetDepreciationAmount(ContractId);

UPDATE ad SET 
              AssetDepreciation_LC += t.AssetDepreciation_LC
            , AssetDepreciation_NLC += t.AssetDepreciation_NLC
FROM #AssetDepreciationAmount ad
INNER JOIN 
(
SELECT  ec.ContractId
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_LC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_NLC
FROM #LastRecordAVHForPayoff lastRecord
     INNER JOIN #EligibleContracts ec ON lastRecord.ContractId = ec.ContractId
	 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON lastRecord.AssetId = avh.AssetId
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
								  AND la.AssetId = avh.AssetId
	 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											   AND coa.AssetId = avh.AssetId
WHERE lastRecord.IsCleared = 1
      AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
      AND avh.IsAccounted = 1
	  AND avh.IncomeDate > renewal.CommencementDate
      AND avh.IncomeDate < rd.RenewalDate
	  AND coa.AssetId IS NULL
	  AND @ClearAccumulatedAccountsatPayoff  = 'False'
GROUP BY ec.ContractId
) as t ON t.ContractId = ad.ContractId;

SELECT ec.ContractId
     , CAST(0.00 AS DECIMAL(16, 2)) AS ClearedImpairment_LC
     , CAST(0.00 AS DECIMAL(16, 2)) AS ClearedImpairment_NLC
INTO #ClearedAssetImpairment
FROM #EligibleContracts ec;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedAssetImpairment(ContractId);

SELECT ec.ContractId
     , CAST(0.00 AS DECIMAL(16, 2)) AS ClearedImpairment_LC
     , CAST(0.00 AS DECIMAL(16, 2)) AS ClearedImpairment_NLC
INTO #ClearedNBVImpairment
FROM #EligibleContracts ec;

CREATE NONCLUSTERED INDEX IX_Id ON #ClearedNBVImpairment(ContractId);

UPDATE ci SET ClearedImpairment_LC = t.ClearedImpairment_LC
			, ClearedImpairment_NLC = t.ClearedImpairment_NLC
FROM #ClearedAssetImpairment ci
INNER JOIN
(SELECT ec.ContractId
      , CAST(SUM(CASE WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
					  THEN CASE WHEN co.AssetId IS NOT NULL
								     AND avh.IncomeDate <= ec.MaturityDate
								     AND avh.IncomeDate > ec.CommencementDate
								THEN avh.Value_Amount
								WHEN co.AssetId IS NULL
									 AND assetDetails.AssetId IS NOT NULL
									 AND avh.IncomeDate <= assetDetails.PayoffEffectiveDate
									 AND avh.IncomeDate > ec.CommencementDate
								THEN avh.Value_Amount
								WHEN assetDetails.AssetId IS NULL
								     AND avh.IncomeDate <= ec.SyndicationDate
									 AND avh.IncomeDate > ec.CommencementDate
								THEN avh.Value_Amount * ec.ParticipatedPortion
								ELSE 0.00
						   END
					  ELSE 0.00 
				 END)* -1 AS DECIMAL(16, 2)) AS ClearedImpairment_LC
      , CAST(SUM(CASE WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
					  THEN CASE WHEN co.AssetId IS NOT NULL
								     AND avh.IncomeDate <= ec.MaturityDate
								     AND avh.IncomeDate > ec.CommencementDate
							    THEN avh.Value_Amount
								WHEN co.AssetId IS NULL
								     AND assetDetails.AssetId IS NOT NULL
									 AND avh.IncomeDate <= assetDetails.PayoffEffectiveDate
									 AND avh.IncomeDate > ec.CommencementDate
								THEN avh.Value_Amount
								WHEN assetDetails.AssetId IS NULL
									 AND avh.IncomeDate <= ec.SyndicationDate
									 AND avh.IncomeDate > ec.CommencementDate
								THEN avh.Value_Amount * ec.ParticipatedPortion
								ELSE 0.00
						   END
					  ELSE 0.00 
				 END)* -1 AS DECIMAL(16, 2)) AS ClearedImpairment_NLC
FROM #EligibleContracts ec
     INNER JOIN #Payoffs p ON p.ContractId = ec.ContractId
     INNER JOIN PayoffAssets poa ON poa.PayoffId = p.PayoffId
     INNER JOIN LeaseAssets la ON la.Id = poa.LeaseAssetId
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = p.AssetsValueStatusChangeId
                                           AND la.AssetId = avh.AssetId
     LEFT JOIN #ChargedOffAssets co ON co.ContractId = ec.ContractId
									   AND avh.AssetId = co.AssetId
	 LEFT JOIN #PayoffAssetDetails assetDetails ON assetDetails.ContractId = ec.ContractId
									   AND avh.AssetId = assetDetails.AssetId
									   AND p.PayoffId = assetDetails.PayoffId
WHERE avh.SourceModule IN('AssetImpairment')
	  AND avh.IsAccounted = 1
	  AND poa.IsActive = 1
GROUP BY ec.ContractId) as t ON t.ContractId = ci.ContractId

UPDATE ci SET ClearedImpairment_LC += t.ClearedImpairment_LC
			, ClearedImpairment_NLC += t.ClearedImpairment_NLC
FROM #ClearedNBVImpairment ci
INNER JOIN
(SELECT ec.ContractId
      , CAST(SUM(CASE WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent =1
					  THEN CASE WHEN co.AssetId IS NOT NULL
								     AND avh.IncomeDate <= ec.MaturityDate
								     AND avh.IncomeDate >= ec.CommencementDate
							    THEN avh.Value_Amount
								WHEN co.AssetId IS NULL
									 AND assetDetails.AssetId IS NOT NULL
									 AND avh.IncomeDate <= assetDetails.PayoffEffectiveDate
									 AND avh.IncomeDate >= ec.CommencementDate
								THEN avh.Value_Amount
								WHEN assetDetails.AssetId IS NULL
									 AND avh.IncomeDate <= ec.SyndicationDate
									 AND avh.IncomeDate >= ec.CommencementDate
								THEN avh.Value_Amount * ec.ParticipatedPortion
								ELSE 0.00
						   END
					  ELSE 0.00 
				 END)* -1 AS DECIMAL(16, 2)) AS ClearedImpairment_LC
      , CAST(SUM(CASE WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
					  THEN CASE WHEN co.AssetId IS NOT NULL
								     AND avh.IncomeDate <= ec.MaturityDate
								     AND avh.IncomeDate >= ec.CommencementDate
							    THEN avh.Value_Amount
								WHEN co.AssetId IS NULL
									 AND assetDetails.AssetId IS NOT NULL
									 AND avh.IncomeDate <= assetDetails.PayoffEffectiveDate
									 AND avh.IncomeDate >= ec.CommencementDate
								THEN avh.Value_Amount
								WHEN assetDetails.AssetId IS NULL
									 AND avh.IncomeDate <= ec.SyndicationDate
									 AND avh.IncomeDate >= ec.CommencementDate
								THEN avh.Value_Amount * ec.ParticipatedPortion
								ELSE 0.00
						   END
					  ELSE 0.00 
				 END)* -1 AS DECIMAL(16, 2)) AS ClearedImpairment_NLC
FROM #EligibleContracts ec
	 INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
	 INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lam.Id
									       AND avh.AssetId = la.AssetId
     LEFT JOIN #ChargedOffAssets co ON co.ContractId = ec.ContractId
									   AND avh.AssetId = co.AssetId
	 LEFT JOIN #PayoffAssetDetails assetDetails ON assetDetails.ContractId = ec.ContractId
									   AND avh.AssetId = assetDetails.AssetId
WHERE avh.SourceModule IN('NBVImpairments')
	  AND avh.IsAccounted = 1
GROUP BY ec.ContractId) as t ON t.ContractId = ci.ContractId

UPDATE ci SET 
              ClearedImpairment_LC += t.ClearedImpairment_LC
            , ClearedImpairment_NLC += t.ClearedImpairment_NLC
FROM #ClearedAssetImpairment ci
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount 
                   ELSE 0.00
               END) * -1 AS ClearedImpairment_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END)* -1 AS ClearedImpairment_NLC
    FROM #EligibleContracts ec
         INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
									  AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
    WHERE avh.SourceModule IN('AssetImpairment')
         AND avh.IsAccounted = 1
         AND avh.IncomeDate > renewal.CommencementDate
         AND avh.IncomeDate < rd.RenewalDate
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ci.ContractId;


UPDATE ci SET 
              ClearedImpairment_LC += t.ClearedImpairment_LC
            , ClearedImpairment_NLC += t.ClearedImpairment_NLC
FROM #ClearedNBVImpairment ci
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount 
                   ELSE 0.00
               END) * -1 AS ClearedImpairment_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END)* -1 AS ClearedImpairment_NLC
    FROM #EligibleContracts ec
         INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
									  AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
    WHERE avh.SourceModule IN('NBVImpairments')
         AND avh.IsAccounted = 1
         AND avh.IncomeDate > renewal.CommencementDate
         AND avh.IncomeDate < rd.RenewalDate
	GROUP BY ec.ContractId
) AS t ON t.ContractId = ci.ContractId;


INSERT INTO #AssetImpairment
SELECT ec.ContractId
     , 0.00
     , 0.00
	 , 0.00
	 , 0.00
FROM #EligibleContracts ec;

CREATE NONCLUSTERED INDEX IX_Id ON #AssetImpairment(ContractId);

UPDATE ai SET AssetImpairment_LC_Table = t.AssetImpairment_LC_Table
		    , AssetImpairment_NLC_Table = t.AssetImpairment_NLC_Table
			, NBVImpairment_LC_Table = t.NBVImpairment_LC_Table
			, NBVImpairment_NLC_Table = t.NBVImpairment_NLC_Table
FROM #AssetImpairment ai
INNER JOIN 
(SELECT ec.ContractId
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						 AND avh.SourceModule = 'AssetImpairment'
					THEN
					CASE WHEN coa.ChargeOffDate IS NOT NULL
						 THEN 0.00
						 WHEN avh.IncomeDate < ec.SyndicationDate
							   AND avh.IncomeDate > ec.CommencementDate
						 THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					END
					ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS AssetImpairment_LC_Table
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
						 AND avh.SourceModule = 'AssetImpairment'
					THEN
					CASE WHEN coa.ChargeOffDate IS NOT NULL
						 THEN 0.00
					     WHEN avh.IncomeDate < ec.SyndicationDate
							  AND avh.IncomeDate > ec.CommencementDate
						 THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					 END
					 ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS AssetImpairment_NLC_Table
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						 AND avh.SourceModule = 'NBVImpairments'
					THEN
					CASE WHEN coa.ChargeOffDate IS NOT NULL
						 THEN 0.00
						 WHEN avh.IncomeDate < ec.SyndicationDate
							   AND avh.IncomeDate > ec.CommencementDate
						 THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					END
					ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS NBVImpairment_LC_Table
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
						 AND avh.SourceModule = 'NBVImpairments'
					THEN
					CASE WHEN coa.ChargeOffDate IS NOT NULL
						 THEN 0.00
					     WHEN avh.IncomeDate < ec.SyndicationDate
							  AND avh.IncomeDate > ec.CommencementDate
						 THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					 END
					 ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS NBVImpairment_NLC_Table

FROM #EligibleContracts ec
	 INNER JOIN #LastRecordAVHForPayoff lastRecord ON lastRecord.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON avh.AssetId = lastRecord.AssetId
     INNER JOIN #PayoffAssetDetails assetDetails ON assetDetails.ContractId = ec.ContractId
                                                    AND avh.AssetId = assetDetails.AssetId
     LEFT JOIN #MaxCleared maxId ON maxId.AssetId = avh.AssetId
                                     AND maxId.ContractId = ec.ContractId
									 AND maxId.IsLeaseComponent = avh.IsLeaseComponent
	 INNER JOIN LeaseAssets la ON la.Id = assetDetails.LeaseAssetId
     LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
										AND coa.AssetId = avh.AssetId
WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
     AND avh.IsAccounted = 1
     AND lastRecord.IsCleared = 0
     AND assetDetails.PayoffAssetStatus NOT IN('Purchase', 'ReturnToUpgrade')
	 AND @ClearAccumulatedAccountsatPayoff = 'False'
	 AND avh.IncomeDate <= assetDetails.PayoffEffectiveDate
	 AND (avh.Id > maxId.MaxId OR maxId.MaxId IS NULL)
GROUP BY ec.ContractId) as t ON t.ContractId = ai.ContractId;

UPDATE ai SET AssetImpairment_LC_Table += t.AssetImpairment_LC_Table
		    , AssetImpairment_NLC_Table += t.AssetImpairment_NLC_Table
			, NBVImpairment_LC_Table += t.NBVImpairment_LC_Table
			, NBVImpairment_NLC_Table += t.NBVImpairment_NLC_Table
FROM #AssetImpairment ai
INNER JOIN 
(SELECT ec.ContractId
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						 AND avh.SourceModule = 'AssetImpairment'
					THEN
				    CASE WHEN coa.ChargeOffDate IS NOT NULL
					     THEN 0.00
						 WHEN avh.IncomeDate < ec.SyndicationDate
							   AND avh.IncomeDate > ec.CommencementDate
						 THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					END
					ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS AssetImpairment_LC_Table
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
						 AND avh.SourceModule = 'AssetImpairment'
					THEN
					CASE WHEN coa.ChargeOffDate IS NOT NULL
						 THEN 0.00
						 WHEN avh.IncomeDate < ec.SyndicationDate
							  AND avh.IncomeDate > ec.CommencementDate
					     THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					END
					ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS AssetImpairment_NLC_Table
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						 AND avh.SourceModule = 'NBVImpairments'
					THEN
				    CASE WHEN coa.ChargeOffDate IS NOT NULL
					     THEN 0.00
						 WHEN avh.IncomeDate < ec.SyndicationDate
							   AND avh.IncomeDate > ec.CommencementDate
						 THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					END
					ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS NBVImpairment_LC_Table
     , CAST(SUM(CASE
					WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
						 AND avh.SourceModule = 'NBVImpairments'
					THEN
					CASE WHEN coa.ChargeOffDate IS NOT NULL
						 THEN 0.00
						 WHEN avh.IncomeDate < ec.SyndicationDate
							  AND avh.IncomeDate > ec.CommencementDate
					     THEN avh.Value_Amount * ec.RetainedPortion
						 ELSE avh.Value_Amount
					END
					ELSE 0.00
                END)* -1 AS DECIMAL(16, 2)) AS NBVImpairment_NLC_Table
FROM #EligibleContracts ec
	 INNER JOIN #LastRecordAVHForPayoff lastRecord ON lastRecord.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON avh.AssetId = lastRecord.AssetId
     INNER JOIN #PayoffAssetDetails assetDetails ON assetDetails.ContractId = ec.ContractId
                                                    AND avh.AssetId = assetDetails.AssetId
     INNER JOIN #MaxCleared maxId ON maxId.AssetId = avh.AssetId
                                     AND maxId.ContractId = ec.ContractId
									 AND maxId.IsLeaseComponent = avh.IsLeaseComponent
	 INNER JOIN #MinCleared minId ON minId.AssetId = avh.AssetId
                                     AND minId.ContractId = ec.ContractId
									 AND minId.IsLeaseComponent = avh.IsLeaseComponent
	 INNER JOIN LeaseAssets la ON la.Id = assetDetails.LeaseAssetId
     LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
										AND coa.AssetId = avh.AssetId
WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
     AND avh.IsAccounted = 1
     AND lastRecord.IsCleared = 1
     AND assetDetails.PayoffAssetStatus NOT IN('Purchase', 'ReturnToUpgrade')
	 AND @ClearAccumulatedAccountsatPayoff = 'False'
	 AND avh.IncomeDate <= assetDetails.PayoffEffectiveDate
	 AND avh.Id <= lastRecord.AVHId
	 AND avh.Id > MinId
     AND avh.Id <= MaxId
GROUP BY ec.ContractId) as t ON t.ContractId = ai.ContractId;

SELECT t.*
     , c.Id AS PreviousContractId
	 , lfd.CommencementDate
     , rft.EffectiveDate AS [SyndicationDate]
	 , CAST(ISNULL(rft.RetainedPercentage / 100, 1) AS DECIMAL(16,2)) AS RetainedPortion
	 , lf.Id AS LeaseFinanceId
INTO #PreviousContact
FROM
(
    SELECT DISTINCT
		   ec.ContractId
         , la.AssetId
		 , a.PreviousSequenceNumber
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = LF.Id
         INNER JOIN Assets a ON a.Id = la.AssetId
    WHERE a.PreviousSequenceNumber IS NOT NULL
) AS t
INNER JOIN Contracts c ON c.SequenceNumber = t.PreviousSequenceNumber
					      AND c.Id != t.ContractId
INNER JOIN LeaseFinances lf ON lf.ContractId = c.Id
							   AND lf.IsCurrent = 1
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = c.Id
                                        AND rft.ApprovalStatus = 'Approved';

SELECT ec.ContractId
     , avh.AssetId
     , MAX(IncomeDate) AS IncomeDate
	 , avh.IsLeaseComponent
INTO #MaxBookValueAdjustment
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                  AND la.IsActive = 1
     INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                       AND pc.AssetId = la.AssetId
     INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
                                           AND pod.AssetId = pc.AssetId
     INNER JOIN AssetValueHistories avh ON avh.AssetId = pod.AssetId
WHERE SourceModule IN('AssetValueAdjustment', 'AssetImpairment')
     AND avh.IncomeDate < ec.CommencementDate
     AND avh.IncomeDate > pod.PayoffEffectiveDate
GROUP BY ec.ContractId
       , avh.AssetId
	   , avh.IsLeaseComponent;

INSERT INTO #MaxBookValueAdjustment(ContractId, AssetId, IncomeDate, IsLeaseComponent)
(
    SELECT ec.ContractId, avh.AssetId, MAX(IncomeDate) AS IncomeDate, avh.IsLeaseComponent
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.TerminationDate IS NOT NULL AND la.IsActive = 1))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         LEFT JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                          AND pc.AssetId = la.AssetId
    WHERE SourceModule IN('AssetValueAdjustment', 'AssetImpairment')
         AND avh.IncomeDate < ec.CommencementDate
         AND pc.AssetId IS NULL
GROUP BY ec.ContractId
       , avh.AssetId
	   , avh.IsLeaseComponent
);


CREATE NONCLUSTERED INDEX IX_Id ON #MaxBookValueAdjustment(ContractId, AssetId);

SELECT ec.ContractId
     , SUM(CASE WHEN @ClearAccumulatedAccountsatPayoff = 'False' AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation', 'InventoryBookDepreciation')
				     AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
			    THEN avh.Value_Amount
				WHEN @ClearAccumulatedAccountsatPayoff = 'True' AND avh.SourceModule = 'InventoryBookDepreciation'
					 AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
				THEN avh.Value_Amount
				ELSE 0.00
			   END)* -1 AS ClearedAmount_LC
     , SUM(CASE WHEN @ClearAccumulatedAccountsatPayoff = 'False' AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation', 'InventoryBookDepreciation')
				     AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
				THEN avh.Value_Amount
				WHEN @ClearAccumulatedAccountsatPayoff = 'True' AND avh.SourceModule = 'InventoryBookDepreciation'
					 AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
				THEN avh.Value_Amount
				ELSE 0.00
		   END)* -1 AS ClearedAmount_NLC  
INTO #ClearedAssetDepreciation
FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
     INNER JOIN LeaseAssets la ON lf.Id = la.LeaseFinanceId
     INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
                                           AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
     INNER JOIN #MaxCleared t ON t.AssetId = avh.AssetId
                                 AND t.ContractId = ec.ContractId
								 AND t.IsLeaseComponent = avh.IsLeaseComponent
     INNER JOIN #MinCleared minc ON avh.AssetId = minc.AssetId
                                    AND minc.ContractId = ec.ContractId
									AND minc.IsLeaseComponent = avh.IsLeaseComponent
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
										AND coa.AssetId = avh.AssetId
	 LEFT JOIN #MaxBookValueAdjustment maxBookValue ON avh.AssetId = maxBookValue.AssetId
													   AND maxBookValue.ContractId = ec.ContractId
													   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
WHERE ((maxBookValue.ContractId IS NOT NULL AND ((minc.SourceModule != 'InventoryBookDepreciation' AND avh.IncomeDate >= maxBookValue.IncomeDate) OR (minc.SourceModule = 'InventoryBookDepreciation' AND avh.Id >= MinId)))
        OR (maxBookValue.ContractId IS NULL AND ((minc.SourceModule != 'InventoryBookDepreciation' AND avh.Id > minc.MinId) OR (minc.SourceModule = 'InventoryBookDepreciation' AND avh.Id >= MinId))))
      AND avh.Id <= MaxId
	  AND avh.IncomeDate < ec.CommencementDate
      AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation', 'InventoryBookDepreciation')
      AND avh.IsAccounted = 1
	  AND coa.AssetId IS NULL
	  AND (ec.SyndicationDate IS NULL OR (avh.IncomeDate > ec.SyndicationDate))
GROUP BY ec.ContractId;
 
 CREATE NONCLUSTERED INDEX IX_Id ON #ClearedAssetDepreciation(ContractId);

MERGE #ClearedAssetDepreciation AS [Source]
USING(SELECT pc.ContractId
		   , CAST(SUM(CASE WHEN @ClearAccumulatedAccountsatPayoff = 'False' AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation', 'InventoryBookDepreciation')
								AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						   THEN avh.Value_Amount * pc.RetainedPortion
						   WHEN @ClearAccumulatedAccountsatPayoff = 'True' AND avh.SourceModule = 'InventoryBookDepreciation'
							    AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
						   THEN avh.Value_Amount * pc.RetainedPortion
						   ELSE 0.00
				      END) AS DECIMAL(16, 2)) AS Amount_LC
		   , CAST(SUM(CASE WHEN @ClearAccumulatedAccountsatPayoff = 'False' AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation', 'InventoryBookDepreciation')
								AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
						   THEN avh.Value_Amount * pc.RetainedPortion
						   WHEN @ClearAccumulatedAccountsatPayoff = 'True' AND avh.SourceModule = 'InventoryBookDepreciation'
							    AND (la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0)
						   THEN avh.Value_Amount * pc.RetainedPortion
						   ELSE 0.00
				      END) AS DECIMAL(16, 2)) AS Amount_NLC
	  FROM #PreviousContact pc
		   INNER JOIN AssetValueHistories avh ON pc.AssetId = avh.AssetId
		   INNER JOIN LeaseFinances lf ON lf.ContractId = pc.ContractId
		   INNER JOIN LeaseAssets la on la.LeaseFinanceId = lf.Id
										AND la.AssetId = avh.AssetId
		   LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = pc.PreviousContractId
										AND coa.AssetId = avh.AssetId	
	  WHERE avh.IncomeDate < pc.SyndicationDate
			AND avh.IncomeDate > pc.CommencementDate
			AND avh.IsAccounted = 1
			AND coa.AssetId IS NULL
			AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation', 'InventoryBookDepreciation')
	  GROUP BY pc.ContractId) AS [Target]
ON [Source].ContractId = [Target].ContractId
WHEN MATCHED
	 THEN UPDATE
			    SET [Source].ClearedAmount_LC += [Target].Amount_LC
				  , [Source].ClearedAmount_NLC += [Target].Amount_NLC
WHEN NOT MATCHED
	 THEN INSERT (ContractId, ClearedAmount_LC, ClearedAmount_NLC)
		  VALUES ([Target].ContractId, [Target].Amount_LC, [Target].Amount_NLC);

SELECT ec.ContractId
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS ClearedAssetImpairment_LC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS ClearedAssetImpairment_NLC
	, CAST(0.00  AS DECIMAL (16, 2)) AS ClearedNBVImpairment_LC
	, CAST(0.00  AS DECIMAL (16, 2)) AS ClearedNBVImpairment_NLC
INTO #Cleared_AssetImpairment
FROM #EligibleContracts ec
	 INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
     INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
                                           AND pod.AssetId = pc.AssetId
     INNER JOIN LeaseAssets la ON la.AssetId = pod.AssetId
								  AND la.LeaseFinanceId = pod.LeaseFinanceId
	 INNER JOIN #Payoffs p ON p.PayoffId = pod.PayoffId
     INNER JOIN Assets a ON la.AssetId = a.Id
     INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = p.AssetsValueStatusChangeId
                                           AND a.Id = avh.AssetId
     LEFT JOIN #ChargedOffAssets co ON co.ContractId = ec.ContractId
                                       AND avh.AssetId = co.AssetId
WHERE avh.SourceModule IN('AssetImpairment')
	  AND avh.IsAccounted = 1
	  AND (co.ContractId IS NULL OR (co.ContractId IS NOT NULL AND co.AssetId IS NULL))
	  AND avh.IsLessorOwned = 1
GROUP BY ec.ContractId;

MERGE #Cleared_AssetImpairment AS [Source]
USING (SELECT ec.ContractId
			, SUM(CASE
				      WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
					  THEN avh.Value_Amount
					  ELSE 0.00
				  END) * -1 AS ClearedAssetImpairment_LC
		    , SUM(CASE
					  WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
					  THEN avh.Value_Amount
					  ELSE 0.00
				  END) * -1 AS ClearedAssetImpairment_NLC
	 FROM #EligibleContracts ec
     INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
     INNER JOIN LeaseAssets la ON lf.Id = la.LeaseFinanceId
     INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
                                           AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
     INNER JOIN #MaxCleared t ON t.AssetId = avh.AssetId
                                 AND t.ContractId = ec.ContractId
								 AND t.IsLeaseComponent = avh.IsLeaseComponent
     INNER JOIN #MinCleared minc ON avh.AssetId = minc.AssetId
                                    AND minc.ContractId = ec.ContractId
									AND minc.IsLeaseComponent = avh.IsLeaseComponent
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
										AND coa.AssetId = avh.AssetId
	 LEFT JOIN #MaxBookValueAdjustment maxBookValue ON avh.AssetId = maxBookValue.AssetId
													   AND maxBookValue.ContractId = ec.ContractId
													   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
WHERE ((maxBookValue.ContractId IS NOT NULL AND avh.IncomeDate >= maxBookValue.IncomeDate)
        OR (maxBookValue.ContractId IS NULL AND avh.Id > minc.MinId))
      AND avh.Id <= MaxId
	  AND avh.IncomeDate < ec.CommencementDate
      AND avh.SourceModule IN('AssetImpairment')
      AND avh.IsAccounted = 1
	  AND coa.AssetId IS NULL
	  AND (ec.SyndicationDate IS NULL OR (avh.IncomeDate > ec.SyndicationDate))
GROUP BY ec.ContractId) AS [Target]
ON ([Source].ContractId = [Target].ContractId)
WHEN NOT MATCHED
	 THEN INSERT (ContractId, ClearedAssetImpairment_LC, ClearedAssetImpairment_NLC , ClearedNBVImpairment_LC, ClearedNBVImpairment_NLC)
		  VALUES ([Target].ContractId, [Target].ClearedAssetImpairment_LC,[Target].ClearedAssetImpairment_NLC, 0.00, 0.00);


-- Value between highest and second highest
SELECT ec.ContractId
     , CAST(SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS DECIMAL (16, 2)) AS Cleared_LC
     , CAST(SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
               THEN avh.Value_Amount
               ELSE 0.00
           END) * -1 AS DECIMAL (16, 2)) AS Cleared_NLC
INTO #Cleared_NBVImpairment
FROM #EligibleContracts ec
	 INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
     INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
                                           AND pod.AssetId = pc.AssetId
     INNER JOIN LeaseAssets la ON la.AssetId = pod.AssetId
								  AND la.LeaseFinanceId = pod.LeaseFinanceId
     INNER JOIN AssetValueHistories avh ON la.AssetId = avh.AssetId
	 INNER JOIN #MaxCleared [max] ON [max].ContractId = ec.ContractId
								     AND avh.AssetId = [max].AssetId
									 AND [max].IsLeaseComponent = avh.IsLeaseComponent
	 INNER JOIN #MinCleared [min] ON [min].ContractId = ec.ContractId
									 AND avh.AssetId = [min].AssetId
									 AND [min].IsLeaseComponent = avh.IsLeaseComponent
	 LEFT JOIN #MaxBookValueAdjustment maxBookValue ON avh.AssetId = maxBookValue.AssetId
													   AND maxBookValue.ContractId = ec.ContractId
													   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
WHERE((maxBookValue.ContractId IS NOT NULL AND avh.IncomeDate >= maxBookValue.IncomeDate)
        OR (maxBookValue.ContractId IS NULL AND avh.Id > [min].MinId))
      AND avh.SourceModule IN('NBVImpairments')
	  AND avh.IsAccounted = 1
      AND avh.Id <= [max].MaxId
	  AND @ClearAccumulatedAccountsatPayoff = 'False'
GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #Cleared_NBVImpairment(ContractId);

MERGE #Cleared_AssetImpairment AS [Source]
USING (SELECT * FROM #Cleared_NBVImpairment) AS [Target]
ON ([Source].ContractId = [Target].ContractId)
WHEN MATCHED
	 THEN UPDATE SET 
				    [Source].ClearedNBVImpairment_LC += [Target].Cleared_LC
			      , [Source].ClearedNBVImpairment_NLC += [Target].Cleared_NLC

WHEN NOT MATCHED
	 THEN INSERT (ContractId, ClearedAssetImpairment_LC, ClearedAssetImpairment_NLC , ClearedNBVImpairment_LC, ClearedNBVImpairment_NLC)
		  VALUES ([Target].ContractId, 0.00, 0.00, [Target].Cleared_LC, [Target].Cleared_NLC);

CREATE NONCLUSTERED INDEX IX_Id ON #Cleared_AssetImpairment(ContractId);


MERGE #Cleared_AssetImpairment AS [Source]
USING(SELECT pc.ContractId
		   , CAST(SUM(CASE WHEN la.IsFailedSaleLeaseback = 0 
								AND avh.IsLeaseComponent = 1
								AND avh.SourceModule = 'NBVImpairments'
						   THEN avh.Value_Amount * pc.RetainedPortion
						   ELSE 0.00
				      END)* -1 AS DECIMAL(16, 2)) AS NBVImpairment_LC
		   , CAST(SUM(CASE WHEN (la.IsFailedSaleLeaseback = 1 
								 OR avh.IsLeaseComponent = 0)
								AND avh.SourceModule = 'NBVImpairments'
						   THEN avh.Value_Amount * pc.RetainedPortion
						   ELSE 0.00
				      END) * -1 AS DECIMAL(16, 2)) AS NBVImpairment_NLC
		   , CAST(SUM(CASE WHEN la.IsFailedSaleLeaseback = 0 
								AND avh.IsLeaseComponent = 1
								AND avh.SourceModule = 'AssetImpairment'
						   THEN avh.Value_Amount * pc.RetainedPortion
						   ELSE 0.00
				      END)* -1 AS DECIMAL(16, 2)) AS AssetImpairment_LC
		   , CAST(SUM(CASE WHEN (la.IsFailedSaleLeaseback = 1 
								 OR avh.IsLeaseComponent = 0)
								AND avh.SourceModule = 'AssetImpairment'
						   THEN avh.Value_Amount * pc.RetainedPortion
						   ELSE 0.00
				      END) * -1 AS DECIMAL(16, 2)) AS AssetImpairment_NLC
	  FROM #PreviousContact pc
		   INNER JOIN AssetValueHistories avh ON pc.AssetId = avh.AssetId
		   INNER JOIN LeaseFinances lf ON lf.ContractId = pc.ContractId
		   INNER JOIN LeaseAssets la on la.LeaseFinanceId = lf.Id
										AND la.AssetId = avh.AssetId
	  WHERE avh.IncomeDate < pc.SyndicationDate
			AND avh.IncomeDate > pc.CommencementDate
			AND avh.IsAccounted = 1
			AND avh.SourceModule IN('NBVImpairments', 'AssetImpairment')
	  GROUP BY pc.ContractId) AS [Target]
ON [Source].ContractId = [Target].ContractId
WHEN MATCHED
	 THEN UPDATE
			    SET [Source].ClearedAssetImpairment_LC += [Target].AssetImpairment_LC
				  , [Source].ClearedAssetImpairment_NLC += [Target].AssetImpairment_NLC
				  , [Source].ClearedNBVImpairment_LC += [Target].NBVImpairment_LC
				  , [Source].ClearedNBVImpairment_NLC += [Target].NBVImpairment_NLC
WHEN NOT MATCHED
	 THEN INSERT (ContractId, ClearedAssetImpairment_LC, ClearedAssetImpairment_NLC , ClearedNBVImpairment_LC, ClearedNBVImpairment_NLC)
		  VALUES ([Target].ContractId, [Target].AssetImpairment_LC, [Target].AssetImpairment_NLC, [Target].NBVImpairment_LC, [Target].NBVImpairment_NLC);

UPDATE ca SET 
              ClearedAssetImpairment_LC += t.AssetImpairment_LC
            , ClearedAssetImpairment_NLC += t.AssetImpairment_NLC
			, ClearedNBVImpairment_LC += t.NBVImpairment_LC
			, ClearedNBVImpairment_NLC += t.NBVImpairment_NLC
FROM #Cleared_AssetImpairment ca
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        AND avh.IsLeaseComponent = 1
						AND avh.SourceModule = 'AssetImpairment'
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) AS AssetImpairment_LC
         , SUM(CASE
                   WHEN (la.IsFailedSaleLeaseback = 1
                         OR avh.IsLeaseComponent = 0)
						AND avh.SourceModule = 'AssetImpairment'
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) AS AssetImpairment_NLC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        AND avh.IsLeaseComponent = 1
						AND avh.SourceModule = 'AssetImpairment'
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) AS NBVImpairment_LC
         , SUM(CASE
                   WHEN (la.IsFailedSaleLeaseback = 1
                         OR avh.IsLeaseComponent = 0)
						AND avh.SourceModule = 'AssetImpairment'
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) AS NBVImpairment_NLC
    FROM #EligibleContracts ec
         INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
    WHERE avh.SourceModule IN('NBVImpairments', 'AssetImpairment')
         AND avh.IsAccounted = 1
         AND avh.IncomeDate > renewal.CommencementDate
         AND avh.IncomeDate < rd.RenewalDate
    GROUP BY ec.ContractId
) AS t ON t.ContractId = ca.ContractId;


UPDATE ad SET 
              ClearedAmount_LC += t.AssetDepreciation_LC
            , ClearedAmount_NLC += t.AssetDepreciation_NLC
FROM #ClearedAssetDepreciation ad
INNER JOIN 
(
SELECT  ec.ContractId
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_LC
     , SUM(CASE
               WHEN la.IsFailedSaleLeaseback = 1 OR avh.IsLeaseComponent = 0
               THEN AVH.Value_Amount
               ELSE 0
           END)* -1 AS AssetDepreciation_NLC
FROM #LastRecordAVHForPayoff lastRecord
     INNER JOIN #EligibleContracts ec ON lastRecord.ContractId = ec.ContractId
	 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
     INNER JOIN AssetValueHistories avh ON lastRecord.AssetId = avh.AssetId
	 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
								  AND la.AssetId = avh.AssetId
	 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
	 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											   AND coa.AssetId = avh.AssetId
WHERE lastRecord.IsCleared = 1
      AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
      AND avh.IsAccounted = 1
	  AND avh.IncomeDate > renewal.CommencementDate
      AND avh.IncomeDate < rd.RenewalDate
	  AND coa.AssetId IS NULL
	  AND @ClearAccumulatedAccountsatPayoff  = 'False'
GROUP BY ec.ContractId
) as t ON t.ContractId = ad.ContractId;

UPDATE #ClearedAssetDepreciation SET 
                                     ClearedAmount_LC = 0.00
								   , ClearedAmount_NLC = 0.00
FROM #ClearedAssetDepreciation cleared
INNER JOIN (
SELECT cleared.ContractId
     , SUM(avh.EndBookValue_Amount) AS Amount
FROM #MaxCleared cleared
INNER JOIN AssetValueHistories avh ON cleared.MaxId = avh.Id
GROUP BY cleared.ContractId
) as t ON cleared.ContractId = t.ContractId
INNER JOIN #GLDetails gl ON gl.ContractId = t.ContractId
WHERE IIF(ActualRenewalInventory_GL != 0.00, ActualRenewalInventory_GL, ActualBookingInventory_GL) = t.Amount;

SELECT DISTINCT 
       avh.AssetId
     , MAX(avh.IncomeDate) AS IncomeDate
     , MAX(avh.Id) AS MaxId
	 , ec.ContractId
	 , avh.IsLeaseComponent
INTO #MaxCleared_TrueCleared
FROM #EligibleContracts ec
	 INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
	 INNER JOIN LeaseAssets la ON ec.LeaseFinanceId = la.LeaseFinanceId
	 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			                               AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
WHERE avh.IsAccounted = 1
      AND avh.IsCleared = 1
	  AND avh.IncomeDate < ec.CommencementDate
GROUP BY avh.AssetId
	   , ec.ContractId
	   , avh.IsLeaseComponent;

CREATE NONCLUSTERED INDEX IX_Id ON #MaxCleared_TrueCleared(ContractId, AssetId);

SELECT avh.AssetId
     , MAX(avh.Id) AS MinId
	 , ec.ContractId
	 , avh.IsLeaseComponent
INTO #MinCleared_TrueCleared
FROM #EligibleContracts ec
	 INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
	 INNER JOIN LeaseAssets la ON ec.LeaseFinanceId = la.LeaseFinanceId
	 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			                               AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
	 INNER JOIN #MaxCleared_TrueCleared t ON t.AssetId = avh.AssetId 
											 AND t.IsLeaseComponent = avh.IsLeaseComponent
WHERE avh.IsAccounted = 1
      AND avh.IsCleared = 1
      AND avh.Id < t.MaxId
	  AND avh.IncomeDate <= ec.MaturityDate
GROUP BY avh.AssetId
       , ec.ContractId
	   , avh.IsLeaseComponent;

CREATE NONCLUSTERED INDEX IX_Id ON #MinCleared_TrueCleared(ContractId, AssetId);

SELECT ec.ContractId
     , CAST(0.00 AS DECIMAL(16, 2)) AS TrueCleared_LC
     , CAST(0.00 AS DECIMAL(16, 2)) AS TrueCleared_NLC
INTO #TrueClearedAmount
FROM #EligibleContracts ec;

CREATE NONCLUSTERED INDEX IX_Id ON #TrueClearedAmount(ContractId);

--SELECT 1,* FROM #TrueClearedAmount
-- InventoryBookDepreciation - Previous
UPDATE cleared SET 
                   TrueCleared_LC = t.Amount_LC
                 , TrueCleared_NLC = t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount
                   ELSE 0.00
               END)* -1 AS Amount_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END)* -1 AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                           AND pc.AssetId = la.AssetId
         INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
                                               AND pod.AssetId = pc.AssetId
         LEFT JOIN #MaxBookValueAdjustment maxBookValue ON maxBookValue.ContractId = pc.ContractId
                                                           AND maxBookValue.AssetId = avh.AssetId
														   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
    WHERE avh.SourceModule IN('InventoryBookDepreciation')
         AND avh.IncomeDate < ec.CommencementDate
		 AND avh.IsAccounted = 1
         AND ((maxBookValue.ContractId IS NOT NULL AND avh.IncomeDate >= maxBookValue.IncomeDate)
              OR (maxBookValue.ContractId IS NULL AND avh.IncomeDate >= pod.PayoffEffectiveDate))
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;


--SELECT 2,* FROM #TrueClearedAmount
-- InventoryBookDepreciation - Current
UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                       WHEN la.IsFailedSaleLeaseback = 0
                            AND avh.IsLeaseComponent = 1
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)* -1 AS Amount_LC
         , SUM(CASE
                       WHEN la.IsFailedSaleLeaseback = 1
                            OR avh.IsLeaseComponent = 0
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END)* -1 AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         LEFT JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                           AND pc.AssetId = la.AssetId
		 LEFT JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
                                               AND pod.AssetId = pc.AssetId
    WHERE avh.SourceModule IN('InventoryBookDepreciation')
         AND avh.IncomeDate < ec.CommencementDate
		 AND avh.IsAccounted = 1
		 AND pod.AssetId IS NULL
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 3,* FROM #TrueClearedAmount
-- Booking
UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
					   WHEN coa.ChargeOffDate IS NOT NULL
					   THEN 0.00
                       WHEN la.IsFailedSaleLeaseback = 0
                            AND avh.IsLeaseComponent = 1
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END) * -1 AS Amount_LC
         , SUM(CASE
					   WHEN coa.ChargeOffDate IS NOT NULL
					   THEN 0.00
                       WHEN la.IsFailedSaleLeaseback = 1
                            OR avh.IsLeaseComponent = 0
                       THEN avh.Value_Amount
                       ELSE 0.00
                   END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
		 INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
		 INNER JOIN LeaseAssets la ON pc.LeaseFinanceId = la.LeaseFinanceId
                                      AND la.AssetId = pc.AssetId
		 INNER JOIN AssetValueHistories avh ON avh.AssetId = pc.AssetId
         INNER JOIN #MaxCleared_TrueCleared [max] ON [max].ContractId = ec.ContractId
                                                     AND [max].AssetId = avh.AssetId
													 AND [max].IsLeaseComponent = avh.IsLeaseComponent
         INNER JOIN #MinCleared_TrueCleared [min] ON [min].ContractId = ec.ContractId
                                                     AND [min].AssetId = avh.AssetId
													 AND [min].IsLeaseComponent = avh.IsLeaseComponent
         LEFT JOIN #MaxBookValueAdjustment maxBookValue ON maxBookValue.ContractId = pc.ContractId
                                                           AND maxBookValue.AssetId = avh.AssetId
														   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
	     LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
                                            AND coa.AssetId = avh.AssetId
    WHERE avh.Id > MinId
          AND avh.Id <= MaxId
          AND ((maxBookValue.ContractId IS NOT NULL AND avh.IncomeDate >= maxBookValue.IncomeDate)
               OR (maxBookValue.ContractId IS NULL AND avh.IncomeDate >= pc.CommencementDate))
          AND avh.IncomeDate < ec.CommencementDate
          AND avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
          AND avh.IsAccounted = 1
          AND @ClearAccumulatedAccountsatPayoff = 'False'
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 4,* FROM #TrueClearedAmount
-- Previous contract syndicated
UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
					    WHEN coa.ChargeOffDate IS NOT NULL
						THEN 0.00
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount * pc.RetainedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN coa.ChargeOffDate IS NOT NULL
						THEN 0.00
						WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount * pc.RetainedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 1
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                           AND pc.AssetId = la.AssetId
         LEFT JOIN #MaxBookValueAdjustment maxBookValue ON maxBookValue.ContractId = ec.ContractId
                                                           AND maxBookValue.AssetId = avh.AssetId
														   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
	     LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
                                            AND coa.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation')
         AND avh.IncomeDate > pc.CommencementDate
		 AND @ClearAccumulatedAccountsatPayoff = 'False'
         AND avh.IncomeDate < pc.SyndicationDate
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 5,* FROM #TrueClearedAmount
-- Only syndicated
UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount * ec.ParticipatedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                         WHEN la.IsFailedSaleLeaseback = 1
                              OR avh.IsLeaseComponent = 0
                         THEN avh.Value_Amount * ec.ParticipatedPortion
                         ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
		 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											AND coa.AssetId = avh.AssetId
		 LEFT JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
                                               AND pod.AssetId = avh.AssetId
											   AND pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade')
    WHERE avh.SourceModule IN('FixedTermDepreciation')
		 AND avh.IncomeDate < ec.SyndicationDate
		 AND avh.IncomeDate > ec.CommencementDate
		 AND coa.AssetId IS NULL
		 AND (pod.AssetId IS NULL AND @ClearAccumulatedAccountsatPayoff = 'False')
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 7,* FROM #TrueClearedAmount

UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
                                               AND pod.AssetId = avh.AssetId
		  LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											 AND coa.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
         AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
         AND avh.IncomeDate <= pod.PayoffEffectiveDate
         AND avh.IncomeDate > ec.CommencementDate
		 AND avh.IsAccounted = 1
		 AND coa.AssetId IS NULL
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

 --SELECT 8,* FROM #TrueClearedAmount
UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
		 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
	     INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
                                               AND pod.AssetId = la.AssetId
         INNER JOIN AssetValueHistories avh ON avh.AssetId = pod.AssetId
												AND avh.SourceModuleId IN (SELECT Id FROM LeaseFinances WHERE ContractId = ec.ContractId)
		 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											AND coa.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
         AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
         AND avh.IncomeDate > pod.PayoffEffectiveDate
         AND avh.IncomeDate > ec.CommencementDate
		 AND avh.IsAccounted = 1
		 AND avh.ReversalGLJournalId IS NULL
		 AND coa.AssetId IS NULL
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount * ec.ParticipatedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount * ec.ParticipatedPortion
                            ELSE 0.00
                        END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 1
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         LEFT JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
                                              AND pod.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation')
         AND pod.AssetId IS NULL
         AND avh.IncomeDate < ec.SyndicationDate
         AND avh.IncomeDate > ec.CommencementDate
		 AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 9,* FROM #TrueClearedAmount
UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END)* -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                            WHEN la.IsFailedSaleLeaseback = 1
                                 OR avh.IsLeaseComponent = 0
                            THEN avh.Value_Amount
                            ELSE 0.00
                        END)* -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
		 INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = ec.LeaseFinanceId
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #ChargedOffAssets cod ON cod.ContractId = ec.ContractId
                                              AND cod.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
         AND ((lfd.LastExtensionARUpdateRunDate IS NOT NULL AND avh.IncomeDate <= lfd.LastExtensionARUpdateRunDate)
			   OR (lfd.LastExtensionARUpdateRunDate IS NULL AND avh.IncomeDate <= ec.MaturityDate))
         AND avh.IncomeDate >= ec.CommencementDate
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 10,* FROM #TrueClearedAmount

UPDATE cleared SET 
                   TrueCleared_LC += t.Amount_LC
                 , TrueCleared_NLC += t.Amount_NLC
FROM #TrueClearedAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
		 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
		 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
                                      AND la.IsActive = 1
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
    WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
         AND avh.IncomeDate > renewal.CommencementDate
         AND avh.IncomeDate <= rd.RenewalDate
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

-- True Asset Impairment

SELECT ec.ContractId
     , CAST(0.00 AS DECIMAL(16, 2)) AS TrueClearedAssetImpairment_LC
     , CAST(0.00 AS DECIMAL(16, 2)) AS TrueClearedAssetImpairment_NLC
INTO #TrueClearedAssetImpairmentAmount
FROM #EligibleContracts ec;

CREATE NONCLUSTERED INDEX IX_Id ON #TrueClearedAssetImpairmentAmount(ContractId);


--SELECT 1,* FROM #TrueClearedAssetImpairmentAmount

-- AssetImpairment -- Previous
UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC = t.Amount_LC
                 , TrueClearedAssetImpairment_NLC = t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                           AND pc.AssetId = la.AssetId
         INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
                                               AND pod.AssetId = pc.AssetId
         LEFT JOIN #MaxBookValueAdjustment maxBookValue ON maxBookValue.ContractId = ec.ContractId
                                                           AND maxBookValue.AssetId = avh.AssetId
														   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
    WHERE avh.SourceModule IN('AssetImpairment')
         AND avh.IncomeDate < ec.CommencementDate
		 AND avh.IsAccounted = 1
         AND ((maxBookValue.ContractId IS NOT NULL AND avh.IncomeDate >= maxBookValue.IncomeDate)
              OR (maxBookValue.ContractId IS NULL AND avh.IncomeDate > pod.PayoffEffectiveDate))
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;


--SELECT 2,* FROM #TrueClearedAssetImpairmentAmount

-- InventoryBookDepreciation - Current
UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         LEFT JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                           AND pc.AssetId = la.AssetId
		 LEFT JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
                                               AND pod.AssetId = pc.AssetId
    WHERE avh.SourceModule IN('AssetImpairment')
         AND avh.IncomeDate < ec.CommencementDate
		 AND avh.IsAccounted = 1
		 AND pod.AssetId IS NULL
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 3,* FROM #TrueClearedAssetImpairmentAmount

-- Booking
UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
				   WHEN coa.ChargeOffDate IS NOT NULL
				   THEN 0.00
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_LC
         , SUM(CASE
				   WHEN coa.ChargeOffDate IS NOT NULL
				   THEN 0.00
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
              END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
		 INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
		 INNER JOIN LeaseAssets la ON pc.LeaseFinanceId = la.LeaseFinanceId
                                      AND la.AssetId = pc.AssetId
		 INNER JOIN AssetValueHistories avh ON avh.AssetId = pc.AssetId
         INNER JOIN #MaxCleared_TrueCleared [max] ON [max].ContractId = ec.ContractId
                                                     AND [max].AssetId = avh.AssetId
													 AND [max].IsLeaseComponent = avh.IsLeaseComponent
         INNER JOIN #MinCleared_TrueCleared [min] ON [min].ContractId = ec.ContractId
                                                     AND [min].AssetId = avh.AssetId
													 AND [min].IsLeaseComponent = avh.IsLeaseComponent
         LEFT JOIN #MaxBookValueAdjustment maxBookValue ON maxBookValue.ContractId = pc.ContractId
                                                           AND maxBookValue.AssetId = avh.AssetId
														   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
	     LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
                                            AND coa.AssetId = avh.AssetId
    WHERE avh.Id > MinId
          AND avh.Id <= MaxId
          AND ((maxBookValue.ContractId IS NOT NULL AND avh.IncomeDate >= maxBookValue.IncomeDate)
               OR (maxBookValue.ContractId IS NULL AND avh.IncomeDate >= pc.CommencementDate))
          AND avh.IncomeDate < ec.CommencementDate
          AND avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
          AND avh.IsAccounted = 1
          AND @ClearAccumulatedAccountsatPayoff = 'False'
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 4,* FROM #TrueClearedAssetImpairmentAmount

-- Previous contract syndicated
UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
					    WHEN coa.ChargeOffDate IS NOT NULL
						THEN 0.00
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount * pc.RetainedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN coa.ChargeOffDate IS NOT NULL
						THEN 0.00
						WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount * pc.RetainedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 1
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
                                           AND pc.AssetId = la.AssetId
         LEFT JOIN #MaxBookValueAdjustment maxBookValue ON maxBookValue.ContractId = ec.ContractId
                                                           AND maxBookValue.AssetId = avh.AssetId
														   AND maxBookValue.IsLeaseComponent = avh.IsLeaseComponent
	     LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
                                            AND coa.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
         AND avh.IncomeDate > pc.CommencementDate
		 AND @ClearAccumulatedAccountsatPayoff = 'False'
         AND avh.IncomeDate < pc.SyndicationDate
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 5,* FROM #TrueClearedAssetImpairmentAmount

-- Only syndicated
UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount * ec.ParticipatedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount * ec.ParticipatedPortion
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
		 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											AND coa.AssetId = avh.AssetId
		 LEFT JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
                                               AND pod.AssetId = avh.AssetId
											   AND pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade')
    WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
		 AND avh.IncomeDate < ec.SyndicationDate
		 AND avh.IncomeDate > ec.CommencementDate
		 AND coa.AssetId IS NULL
		 AND (pod.AssetId IS NULL OR @ClearAccumulatedAccountsatPayoff = 'True')
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 6,* FROM #TrueClearedAssetImpairmentAmount

UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 0
                        AND avh.IsLeaseComponent = 1
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
	     INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = ec.LeaseFinanceId
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
                                             AND coa.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
         AND ((lfd.LastExtensionARUpdateRunDate IS NOT NULL AND avh.IncomeDate <= lfd.LastExtensionARUpdateRunDate)
			   OR (lfd.LastExtensionARUpdateRunDate IS NULL AND avh.IncomeDate <= ec.MaturityDate))
         AND avh.IncomeDate >= ec.CommencementDate
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 7,* FROM #TrueClearedAssetImpairmentAmount

UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , SUM(CASE
                    WHEN la.IsFailedSaleLeaseback = 0
                         AND avh.IsLeaseComponent = 1
                    THEN avh.Value_Amount
                    ELSE 0.00
               END) * -1 AS Amount_LC
         , SUM(CASE
                   WHEN la.IsFailedSaleLeaseback = 1
                        OR avh.IsLeaseComponent = 0
                   THEN avh.Value_Amount
                   ELSE 0.00
               END) * -1 AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
                                               AND pod.AssetId = avh.AssetId
         LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
											AND coa.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
         AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
         AND avh.IncomeDate <= pod.PayoffEffectiveDate
         AND avh.IncomeDate > ec.CommencementDate
		 AND avh.IsAccounted = 1
		 AND coa.AssetId IS NULL
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
         INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                      AND la.IsActive = 1
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
         LEFT JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
                                              AND pod.AssetId = avh.AssetId
    WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
         AND pod.AssetId IS NULL
         AND avh.IncomeDate < ec.SyndicationDate
         AND avh.IncomeDate > ec.CommencementDate
		 AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

--SELECT 10,* FROM #TrueClearedAssetImpairmentAmount

UPDATE cleared SET 
                   TrueClearedAssetImpairment_LC += t.Amount_LC
                 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
FROM #TrueClearedAssetImpairmentAmount cleared
     INNER JOIN
(
    SELECT ec.ContractId
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 0
                             AND avh.IsLeaseComponent = 1
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
         , CAST(SUM(CASE
                        WHEN la.IsFailedSaleLeaseback = 1
                             OR avh.IsLeaseComponent = 0
                        THEN avh.Value_Amount
                        ELSE 0.00
                    END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
    FROM #EligibleContracts ec
		 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
		 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
         INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
                                      AND la.IsActive = 1
         INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
    WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
         AND avh.IncomeDate > renewal.CommencementDate
         AND avh.IncomeDate <= rd.RenewalDate
		 AND avh.IsAccounted = 1
    GROUP BY ec.ContractId
) AS t ON t.ContractId = cleared.ContractId;

SELECT DISTINCT 
       c.Id AS ContractId
     , lam.OriginalLeaseFinanceId
     , lam.CurrentLeaseFinanceId
INTO #LeaseAmendmentInfo
FROM Contracts c
     INNER JOIN LeaseFinances lf ON c.Id = lf.ContractId
     INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
WHERE lam.AmendmentType = 'Renewal'
      AND lam.LeaseAmendmentStatus = 'Approved';

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseAmendmentInfo(ContractId);

 IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
	BEGIN
	SET @Sql = 
		'SELECT 
		ec.ContractId
		,SUM(CASE
				WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
				AND la.IsAdditionalChargeSoftAsset = 1
				THEN la.NBV_Amount
				WHEN la.IsLeaseAsset = 1 AND la.IsAdditionalChargeSoftAsset = 0
				THEN la.CapitalizedAdditionalCharge_Amount
				ELSE 0.00
		END) AS [CapitalizedAdditionalCharge_LeaseComponent]
		,SUM(CASE
				WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				AND la.IsAdditionalChargeSoftAsset = 1
				THEN la.NBV_Amount
				WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) 
				AND la.IsAdditionalChargeSoftAsset = 0
				THEN la.CapitalizedAdditionalCharge_Amount
				ELSE 0.00
		END) AS [CapitalizedAdditionalCharge_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_FinanceComponent]
		,SUM(CASE 
				WHEN la.CapitalizationType = ''CapitalizedProgressPayment'' AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE 0.00
			END) AS [CapitalizedProgressPayment_LeaseComponent]
		,SUM(CASE 
			WHEN la.CapitalizationType = ''CapitalizedProgressPayment'' AND la.CapitalizedForId IS NOT NULL
			AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE 0.00
		END) AS [CapitalizedProgressPayment_FinanceComponent]
		FROM #EligibleContracts ec
			INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = ec.LeaseFinanceId
			INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
				AND (la.IsActive = 1 
					OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate))
		GROUP BY ec.ContractId;'
	
	INSERT INTO #CapitalizedAmounts
	EXEC (@Sql)
	END
	
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME =	'CapitalizedAdditionalCharge_Amount')
	BEGIN
	INSERT INTO #CapitalizedAmounts
	SELECT
		ec.ContractId
		,0 CapitalizedAdditionalCharge_LeaseComponent
		,0 CapitalizedAdditionalCharge_FinanceComponent
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_FinanceComponent]
		 ,SUM(CASE 
				WHEN la.CapitalizationType = 'CapitalizedProgressPayment' AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE 0.00
			END) AS [CapitalizedProgressPayment_LeaseComponent]
		,SUM(CASE 
			WHEN la.CapitalizationType = 'CapitalizedProgressPayment' AND la.CapitalizedForId IS NOT NULL
			AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE 0.00
		END) AS [CapitalizedProgressPayment_FinanceComponent]
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = ec.LeaseFinanceId
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
			AND (la.IsActive = 1 
				OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate))
	GROUP BY ec.ContractId;
	END
	
	CREATE NONCLUSTERED INDEX IX_Id ON #CapitalizedAmounts(ContractId);
	
	UPDATE ca
		SET ca.CapitalizedInterimInterest_LeaseComponent = ca.CapitalizedInterimInterest_LeaseComponent + ca.CapitalizedProgressPayment_LeaseComponent
			,ca.CapitalizedInterimInterest_FinanceComponent = ca.CapitalizedInterimInterest_FinanceComponent + ca.CapitalizedProgressPayment_FinanceComponent
	FROM #CapitalizedAmounts ca;

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
	BEGIN
	SET @Sql = 
		'SELECT 
		ec.ContractId
		,SUM(CASE
				WHEN la.IsAdditionalChargeSoftAsset = 1 AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
				THEN la.NBV_Amount
				WHEN la.IsLeaseAsset = 1 AND la.IsAdditionalChargeSoftAsset = 0
				THEN la.CapitalizedAdditionalCharge_Amount
				ELSE 0.00
		END) AS [CapitalizedAdditionalCharge_LeaseComponent]
		,SUM(CASE
				WHEN la.IsAdditionalChargeSoftAsset = 1 AND la.IsLeaseAsset = 0 AND la.IsFailedSaleLeaseback = 1
				THEN la.NBV_Amount
				WHEN la.IsLeaseAsset = 0 AND la.IsAdditionalChargeSoftAsset = 0
				THEN la.CapitalizedAdditionalCharge_Amount
				ELSE 0.00
		END) AS [CapitalizedAdditionalCharge_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_FinanceComponent]
		,SUM(CASE 
				WHEN la.CapitalizationType = ''CapitalizedProgressPayment'' AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE 0.00
			END) AS [CapitalizedProgressPayment_LeaseComponent]
		,SUM(CASE 
			WHEN la.CapitalizationType = ''CapitalizedProgressPayment'' AND la.CapitalizedForId IS NOT NULL
			AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE 0.00
		END) AS [CapitalizedProgressPayment_FinanceComponent]
		,0 AS TotalAmount_Lease
		,0 AS TotalAmount_Finance
		FROM #EligibleContracts ec
			INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
			INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
			INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
			INNER JOIN #LeaseAmendmentInfo lam ON lam.OriginalLeaseFinanceId = lf.Id
				AND (la.IsActive = 1 
					OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate))
		GROUP BY ec.ContractId;'
	
	INSERT INTO #RenewalCapitalizedAmounts
	EXEC (@Sql)
	END
	
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME =	'CapitalizedAdditionalCharge_Amount')
	BEGIN
	INSERT INTO #RenewalCapitalizedAmounts
	SELECT
		ec.ContractId
		,0 CapitalizedAdditionalCharge_LeaseComponent
		,0 CapitalizedAdditionalCharge_FinanceComponent
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedSalesTax_Amount
				ELSE 0.00
		END) AS [CapitalizedSalesTax_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimInterest_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimInterest_FinanceComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 1
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_LeaseComponent]
		,SUM(CASE 
				WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
				THEN la.OriginalCapitalizedAmount_Amount
				WHEN la.CapitalizedForId IS NULL AND la.IsLeaseAsset = 0
				THEN la.CapitalizedInterimRent_Amount
				ELSE 0.00
			END) AS [CapitalizedInterimRent_FinanceComponent]
		 ,SUM(CASE 
				WHEN la.CapitalizationType = 'CapitalizedProgressPayment' AND la.CapitalizedForId IS NOT NULL
				AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
				THEN la.OriginalCapitalizedAmount_Amount
				ELSE 0.00
			END) AS [CapitalizedProgressPayment_LeaseComponent]
		,SUM(CASE 
			WHEN la.CapitalizationType = 'CapitalizedProgressPayment' AND la.CapitalizedForId IS NOT NULL
			AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
			THEN la.OriginalCapitalizedAmount_Amount
			ELSE 0.00
		END) AS [CapitalizedProgressPayment_FinanceComponent]
		,0 AS TotalAmount_Lease
		,0 AS TotalAmount_Finance
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		INNER JOIN #LeaseAmendmentInfo lam ON lam.OriginalLeaseFinanceId = lf.Id
			AND (la.IsActive = 1 
				OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL AND la.TerminationDate >= ec.CommencementDate))
	GROUP BY ec.ContractId;
	END
	
	CREATE NONCLUSTERED INDEX IX_Id ON #RenewalCapitalizedAmounts(ContractId);

UPDATE rca SET 
               rca.TotalAmount_Lease = CapitalizedAdditionalCharge_LeaseComponent + CapitalizedSalesTax_LeaseComponent + CapitalizedInterimInterest_LeaseComponent + CapitalizedInterimRent_LeaseComponent + CapitalizedProgressPayment_LeaseComponent
             , rca.TotalAmount_Finance = CapitalizedAdditionalCharge_FinanceComponent + CapitalizedSalesTax_FinanceComponent + CapitalizedInterimInterest_FinanceComponent + CapitalizedInterimRent_FinanceComponent + CapitalizedProgressPayment_FinanceComponent
FROM #RenewalCapitalizedAmounts rca;

SELECT ec.ContractId
	 ,SUM(CASE WHEN a.IsSKU = 1 AND la.IsFailedSaleLeaseback = 0 AND avh.IsLeaseComponent = 1
	 THEN (avh.Value_Amount) * -1
	 WHEN a.IsSKU = 0 AND la.IsFailedSaleLeaseback = 0 AND la.IsLeaseAsset = 1
	 THEN (avh.Value_Amount) * -1
	 ELSE 0.00
	 END) AS Chargeoff_LC
INTO #AVHChargeoff
FROM #EligibleContracts ec
     INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
                                  AND ((la.IsActive = 0 AND la.TerminationDate IS NOT NULL) OR la.IsActive = 1)
	 INNER JOIN Assets a ON la.AssetId = a.Id
     INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
	 INNER JOIN #Chargeoff co ON co.ChargeoffId = avh.SourceModuleId
	 INNER JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
										 AND avh.AssetId = coa.AssetId
WHERE avh.IsAccounted = 1
      AND avh.SourceModule = 'Chargeoff'
      AND ec.ContractType = 'Operating'
	  AND avh.GLJournalId IS NOT NULL
	  AND avh.ReversalGLJournalId IS NULL
GROUP BY ec.ContractId;

	CREATE NONCLUSTERED INDEX IX_Id ON #AVHChargeoff(ContractId);

SELECT *
     , CASE
           WHEN Inventory_Difference != 0.00
                OR ETC_Difference != 0.00
                OR TotalCapitalizedAmount_Difference != 0.00
                OR FixedTermDepreciation_Difference != 0.00
                OR ClearedFixedTermDepreciation_Difference != 0.00
                OR AccumulatedFixedTermDepreciation_Difference != 0.00
                OR OTPDepreciation_Difference != 0.00
                OR ClearedOTPDepreciation_Difference != 0.00
                OR AccumulatedOTPDepreciation_Difference != 0.00
                OR AssetDepreciation_Difference != 0.00
                OR ClearedAssetDepreciation_Difference != 0.00
                OR AccumulatedAssetDepreciation_Difference != 0.00
                OR NBVImpairment_Difference != 0.00
                OR ClearedNBVImpairment_Difference != 0.00
                OR AccumulatedNBVImpairment_Difference != 0.00
                OR ValueAdjustmentOnPayoff_Difference != 0.00
                OR ClearedValueAdjustmentOnPayoff_Difference != 0.00
                OR AccumulatedValueAdjustmentOnPayoff_Difference != 0.00
                OR AssetImpairment_Difference != 0.00
                OR ClearedNBVImpairment_AssetImpairment_Difference != 0.00
                OR ClearedBookValueAdjustment_AssetImpairment_Difference != 0.00
                OR AccumulatedAssetImpairment_Difference != 0.00
                OR LeasedAssetReturnedtoInventory_Difference != 0.00
                OR CostofGoodsSold_Difference != 0.00
                OR TrueClearedDepreciation_Difference != 0.00
                OR TrueClearedImpairment_Difference != 0.00
                OR OperatingLease_ChargeOff_Difference != 0.00
           THEN 'Problem Record'
           ELSE 'Not Problem Record'
       END AS Result
INTO #ResultList
FROM
(SELECT ec.SequenceNumber
     , ec.ContractAlias
     , ec.ContractId
     , ec.ContractType
     , le.Name AS LegalEntityName
     , lob.Name AS LineOfBusinessName
     , p.PartyName AS CustomerName
     , p.PartyNumber AS CustomerNumber
     , ec.IsMigrated
     , ec.AccountingStandard
     , ec.ContractStatus
     , ec.CommencementDate
     , ec.MaturityDate
     , IIF(otp.ContractId IS NOT NULL, 'Yes', 'No') AS IsOTPLease
     , amendemnents.AmendmentType [LeaseAmendments]
	 , ec.SyndicationType
     , ec.SyndicationDate
     , IIF(co.ContractId IS NOT NULL, 'Yes', 'No') AS IsChargedoff
     , co.ChargeOffDate
     , IIF(rd.ContractId IS NOT NULL, 'Yes', 'No') AS IsRenewalLease 
	 , ISNULL(assetValues.Booking_Inventory_LC, 0.00) + ISNULL(renewalassetValues.Renewal_Inventory_LC, 0.00) AS Inventory_LeaseComponent_Table
	 , ISNULL(assetValues.Booking_Inventory_NLC, 0.00) + ISNULL(renewalassetValues.Renewal_Inventory_NLC, 0.00) AS Inventory_FinanceComponent_Table
	 , ISNULL(gld.BookingInventory_GL, 0.00) + ISNULL(gld.RenewalInventory_GL, 0.00) AS Inventory_GL
	 , (ISNULL(assetValues.Booking_Inventory_LC, 0.00) + ISNULL(assetValues.Booking_Inventory_NLC, 0.00) + ISNULL(renewalassetValues.Renewal_Inventory_LC, 0.00) + ISNULL(renewalassetValues.Renewal_Inventory_NLC, 0.00)) - (ISNULL(gld.BookingInventory_GL, 0.00) + ISNULL(gld.RenewalInventory_GL, 0.00)) AS Inventory_Difference
	  , ISNULL(amount.ETCAmount_LeaseComponent, 0.00) + ISNULL(rbamount.ETCAmount_LeaseComponent, 0.00) AS ETC_LC_Table
     , ISNULL(amount.ETCAmount_NonLeaseComponent, 0.00) + ISNULL(rbamount.ETCAmount_NonLeaseComponent, 0.00) AS ETC_FC_Table
     , ISNULL(gld.BlendedIncomeSetUp_ETC_GL, 0.00) AS ETC_GL
     , ISNULL(amount.ETCAmount_LeaseComponent, 0.00) + ISNULL(rbamount.ETCAmount_NonLeaseComponent, 0.00) + ISNULL(rbamount.ETCAmount_LeaseComponent, 0.00) + ISNULL(amount.ETCAmount_NonLeaseComponent, 0.00) - ISNULL(gld.BlendedIncomeSetUp_ETC_GL, 0.00) AS ETC_Difference
	 , ISNULL(ca.CapitalizedInterimInterest_LeaseComponent,0.00) + ISNULL(ca.CapitalizedInterimRent_LeaseComponent,0.00) + ISNULL(ca.CapitalizedSalesTax_LeaseComponent,0.00)
	   + ISNULL(ca.CapitalizedAdditionalCharge_LeaseComponent,0.00) + ISNULL(rca.TotalAmount_Lease,0.00) AS TotalCapitalizedAmount_LeaseComponentTable
	 , ISNULL(ca.CapitalizedInterimInterest_FinanceComponent,0.00) + ISNULL(ca.CapitalizedInterimRent_FinanceComponent,0.00) + ISNULL(ca.CapitalizedSalesTax_FinanceComponent,0.00)
	   + ISNULL(ca.CapitalizedAdditionalCharge_FinanceComponent,0.00) + ISNULL(rca.TotalAmount_Finance,0.00) AS TotalCapitalizedAmount_FinanceComponentTable
	 , ISNULL(gld.TotalCapitalizedAmount_GL,0.00) AS TotalCapitalizedAmount_GL
	 , (ISNULL(ca.CapitalizedInterimInterest_LeaseComponent,0.00) + ISNULL(ca.CapitalizedInterimRent_LeaseComponent,0.00) + ISNULL(ca.CapitalizedSalesTax_LeaseComponent,0.00)
	   + ISNULL(ca.CapitalizedAdditionalCharge_LeaseComponent,0.00) + ISNULL(rca.TotalAmount_Lease,0.00)) +(ISNULL(ca.CapitalizedInterimInterest_FinanceComponent,0.00) + ISNULL(ca.CapitalizedInterimRent_FinanceComponent,0.00) + ISNULL(ca.CapitalizedSalesTax_FinanceComponent,0.00)
	   + ISNULL(ca.CapitalizedAdditionalCharge_FinanceComponent,0.00) + ISNULL(rca.TotalAmount_Finance,0.00))  - ISNULL(gld.TotalCapitalizedAmount_GL,0.00) TotalCapitalizedAmount_Difference
	 , ISNULL(depreciation.FixedTermDepreciation, 0.00) AS FixedTermDepreciation_Table
	 , ISNULL(gld.FixedTermDepreciation_GL, 0.00) AS FixedTermDepreciation_GL
	 , ISNULL(depreciation.FixedTermDepreciation, 0.00) - ISNULL(gld.FixedTermDepreciation_GL, 0.00) AS FixedTermDepreciation_Difference
	 , ISNULL(depreciation.ClearedFixedTermDepreciation, 0.00) AS [ClearedFixedTermDepreciation_Table]
	 , ISNULL(gld.ClearedFixedTermDepreciation_GL, 0.00) AS [ClearedFixedTermDepreciation_GL]
	 , ISNULL(depreciation.ClearedFixedTermDepreciation, 0.00) - ISNULL(gld.ClearedFixedTermDepreciation_GL, 0.00)  AS [ClearedFixedTermDepreciation_Difference]
	 , ISNULL(depreciation.FixedTermDepreciation, 0.00) - ISNULL(depreciation.ClearedFixedTermDepreciation, 0.00) AS [AccumulatedFixedTermDepreciation_Table]
	 , ISNULL(gld.FixedTermDepreciation_GL, 0.00) - ISNULL(gld.ClearedFixedTermDepreciation_GL, 0.00) AS [AccumulatedFixedTermDepreciation_GL]
	 , (ISNULL(depreciation.FixedTermDepreciation, 0.00) - ISNULL(depreciation.ClearedFixedTermDepreciation, 0.00)) - (ISNULL(gld.FixedTermDepreciation_GL, 0.00) - ISNULL(gld.ClearedFixedTermDepreciation_GL, 0.00))   AS [AccumulatedFixedTermDepreciation_Difference]
	 , ISNULL(depreciation.OTPDepreciation_LC, 0.00) AS OTPDepreciation_LeaseComponent_Table
	 , ISNULL(depreciation.OTPDepreciation_NLC, 0.00) AS OTPDepreciation_FinanceComponent_Table
	 , ISNULL(gld.OTPDepreciation_GL, 0.00) AS OTPDepreciation_GL
	 , ISNULL(depreciation.OTPDepreciation_LC, 0.00) + ISNULL(depreciation.OTPDepreciation_NLC, 0.00) - ISNULL(gld.OTPDepreciation_GL, 0.00) AS OTPDepreciation_Difference
	 , ISNULL(depreciation.ClearedOTPDepreciation_LC, 0.00) AS [ClearedOTPDepreciation_LeaseComponent_Table]
	 , ISNULL(depreciation.ClearedOTPDepreciation_NLC, 0.00) AS [ClearedOTPDepreciation_FinanceComponent_Table]
	 , ISNULL(gld.ClearedOTPDepreciation_GL, 0.00) AS [ClearedOTPDepreciation_GL]
	 , (ISNULL(depreciation.ClearedOTPDepreciation_LC, 0.00) + ISNULL(depreciation.ClearedOTPDepreciation_NLC, 0.00)) - ISNULL(gld.ClearedOTPDepreciation_GL, 0.00)  AS [ClearedOTPDepreciation_Difference]
	 , ISNULL(depreciation.OTPDepreciation_LC, 0.00) - ISNULL(depreciation.ClearedOTPDepreciation_LC, 0.00) AS [AccumulatedOTPDepreciation_LeaseComponent_Table]
	 , ISNULL(depreciation.OTPDepreciation_NLC, 0.00) - ISNULL(depreciation.ClearedOTPDepreciation_NLC, 0.00) AS [AccumulatedOTPDepreciation_FinanceComponent_Table]
	 , ISNULL(gld.OTPDepreciation_GL, 0.00) - ISNULL(gld.ClearedOTPDepreciation_GL, 0.00) AS [AccumulatedOTPDepreciation_GL]
	 , (ISNULL(depreciation.OTPDepreciation_LC, 0.00) - ISNULL(depreciation.ClearedOTPDepreciation_LC, 0.00) + (ISNULL(depreciation.OTPDepreciation_NLC, 0.00) - ISNULL(depreciation.ClearedOTPDepreciation_NLC, 0.00))) - (ISNULL(gld.OTPDepreciation_GL, 0.00) - ISNULL(gld.ClearedOTPDepreciation_GL, 0.00)) AS [AccumulatedOTPDepreciation_Difference]
	 , ISNULL(assetDepreciation.AssetDepreciation_LC, 0.00) AS AssetDepreciation_LeaseComponent_Table
	 , ISNULL(assetDepreciation.AssetDepreciation_NLC, 0.00) AS AssetDepreciation_FinanceComponent_Table
	 , ISNULL(gld.AssetDepreciation_GL, 0.00) AS AssetDepreciation_GL
	 , ISNULL(assetDepreciation.AssetDepreciation_LC, 0.00) + ISNULL(assetDepreciation.AssetDepreciation_NLC, 0.00) - ISNULL(gld.AssetDepreciation_GL, 0.00) AS AssetDepreciation_Difference
	 , ISNULL(cleared.ClearedAmount_LC, 0.00) AS [ClearedAssetDepreciation_LeaseComponent_Table]
	 , ISNULL(cleared.ClearedAmount_NLC, 0.00) AS [ClearedAssetDepreciationFinanceComponent_Table]
	 , ISNULL(gld.ClearedAssetDepreciation_GL, 0.00) AS [ClearedAssetDepreciation_GL]
	 , ISNULL(cleared.ClearedAmount_LC, 0.00) + ISNULL(cleared.ClearedAmount_NLC, 0.00) - ISNULL(gld.ClearedAssetDepreciation_GL, 0.00) AS [ClearedAssetDepreciation_Difference]
	 , ISNULL(assetDepreciation.AssetDepreciation_LC, 0.00) - ISNULL(cleared.ClearedAmount_LC, 0.00) AS [AccumulatedAssetDepreciation_LeaseComponent_Table]
	 , ISNULL(assetDepreciation.AssetDepreciation_NLC, 0.00) - ISNULL(cleared.ClearedAmount_NLC, 0.00) AS [AccumulatedAssetDepreciation_FinanceComponent_Table]
	 , ISNULL(gld.AssetDepreciation_GL, 0.00) - ISNULL(gld.ClearedAssetDepreciation_GL, 0.00) AS [AccumulatedAssetDepreciation_GL]
	 , (ISNULL(assetDepreciation.AssetDepreciation_LC, 0.00) - ISNULL(cleared.ClearedAmount_LC, 0.00))
	   + (ISNULL(assetDepreciation.AssetDepreciation_NLC, 0.00) - ISNULL(cleared.ClearedAmount_NLC, 0.00))
	   - (ISNULL(gld.AssetDepreciation_GL, 0.00) - ISNULL(gld.ClearedAssetDepreciation_GL, 0.00)) AS [AccumulatedAssetDepreciation_Difference]
	 , ISNULL(nbvImpairment.NBVImpairment_LC_Table, 0.00) AS NBVImpairment_LC_Table
	 , ISNULL(nbvImpairment.NBVImpairment_NLC_Table, 0.00) AS NBVImpairment_NLC_Table
	 , ISNULL(gld.NBVImpairment_GL, 0.00) AS NBVImpairment_GL
	 , ISNULL(nbvImpairment.NBVImpairment_LC_Table, 0.00) + ISNULL(nbvImpairment.NBVImpairment_NLC_Table, 0.00) - ISNULL(gld.NBVImpairment_GL, 0.00) AS [NBVImpairment_Difference]
	 , ISNULL(clearedNBV.ClearedImpairment_LC, 0.00)  AS ClearedNBVImpairment_LC_Table
	 , ISNULL(clearedNBV.ClearedImpairment_NLC, 0.00) AS ClearedNBVImpairment_NLC_Table
	 , ISNULL(gld.ClearedNBVImp_GL, 0.00) AS ClearedNBVImpairment_GL
	 , ISNULL(clearedNBV.ClearedImpairment_LC, 0.00) + ISNULL(clearedNBV.ClearedImpairment_NLC, 0.00)  - ISNULL(gld.ClearedNBVImp_GL, 0.00) AS [ClearedNBVImpairment_Difference]
	 , ISNULL(nbvImpairment.NBVImpairment_LC_Table, 0.00) - ISNULL(clearedNBV.ClearedImpairment_LC, 0.00) AS AccumulatedNBVImpairment_LeaseComponent_Table
	 , ISNULL(nbvImpairment.NBVImpairment_NLC_Table, 0.00) - ISNULL(clearedNBV.ClearedImpairment_NLC, 0.00) AS AccumulatedNBVImpairment_FinanceComponent_Table
	 , ISNULL(gld.NBVImpairment_GL, 0.00) - ISNULL(gld.ClearedNBVImp_GL, 0.00)  AS AccumulatedNBVImpairment_GL
	 , ((ISNULL(nbvImpairment.NBVImpairment_LC_Table, 0.00) - ISNULL(clearedNBV.ClearedImpairment_LC, 0.00)) + (ISNULL(nbvImpairment.NBVImpairment_NLC_Table, 0.00) - ISNULL(clearedNBV.ClearedImpairment_NLC, 0.00)))
		- (ISNULL(gld.NBVImpairment_GL, 0.00) - ISNULL(gld.ClearedNBVImp_GL, 0.00)) AS AccumulatedNBVImpairment_Difference
     , ISNULL(Impairment_Asset.AssetImpairment_LC_Table, 0.00)  AS ValueAdjustmentOnPayoff_LC_Table
	 , ISNULL(Impairment_Asset.AssetImpairment_NLC_Table, 0.00) AS ValueAdjustmentOnPayoff_NLC_Table
	 , ISNULL(gld.AssetImpairment_Setup_GL, 0.00) AS ValueAdjustmentOnPayoff_GL
	 , ISNULL(Impairment_Asset.AssetImpairment_LC_Table, 0.00) + ISNULL(Impairment_Asset.AssetImpairment_NLC_Table, 0.00)  - ISNULL(gld.AssetImpairment_Setup_GL, 0.00) AS [ValueAdjustmentOnPayoff_Difference]
	 , ISNULL(clearedImp.ClearedImpairment_LC, 0.00)  AS ClearedValueAdjustmentOnPayoff_LC_Table
	 , ISNULL(clearedImp.ClearedImpairment_NLC, 0.00) AS ClearedValueAdjustmentOnPayoff_NLC_Table
	 , ISNULL(gld.ClearedAssetImp_GL, 0.00) AS ClearedValueAdjustmentOnPayoff_GL
	 , ISNULL(clearedImp.ClearedImpairment_LC, 0.00) + ISNULL(clearedImp.ClearedImpairment_NLC, 0.00)  - ISNULL(gld.ClearedAssetImp_GL, 0.00) AS [ClearedValueAdjustmentOnPayoff_Difference]
	 , ISNULL(Impairment_Asset.AssetImpairment_LC_Table, 0.00) - ISNULL(clearedImp.ClearedImpairment_LC, 0.00) AS AccumulatedValueAdjustmentOnPayoff_LC_Table
	 , ISNULL(Impairment_Asset.AssetImpairment_NLC_Table, 0.00) - ISNULL(clearedImp.ClearedImpairment_NLC, 0.00) AS AccumulatedValueAdjustmentOnPayoff_NLC_Table
	 , ISNULL(gld.AssetImpairment_Setup_GL, 0.00) - ISNULL(gld.ClearedAssetImp_GL, 0.00)  AS AccumulatedValueAdjustmentOnPayoff_GL
	 , ((ISNULL(Impairment_Asset.AssetImpairment_LC_Table, 0.00) - ISNULL(clearedImp.ClearedImpairment_LC, 0.00)) + (ISNULL(Impairment_Asset.AssetImpairment_NLC_Table, 0.00) - ISNULL(clearedImp.ClearedImpairment_NLC, 0.00)))
		- (ISNULL(gld.AssetImpairment_Setup_GL, 0.00) - ISNULL(gld.ClearedAssetImp_GL, 0.00)) AS AccumulatedValueAdjustmentOnPayoff_Difference
	 , ISNULL(ai.AssetImpairment_LC_Table, 0.00) AS BookValueAdjustment_AssetImpairment_LC_Table
	 , ISNULL(ai.AssetImpairment_NLC_Table, 0.00) AS BookValueAdjustment_AssetImpairment_NLC_Table
	 , ISNULL(ai.NBVImpairment_LC_Table, 0.00) AS NBVImpairment_AssetImpairment_LC_Table
	 , ISNULL(ai.NBVImpairment_NLC_Table, 0.00) AS NBVImpairment_AssetImpairment_NLC_Table
	 , ISNULL(gld.AssetImpairment_GL, 0.00) AS AssetImpairment_GL
	 , (ISNULL(ai.AssetImpairment_LC_Table, 0.00) + ISNULL(ai.AssetImpairment_NLC_Table, 0.00) + ISNULL(ai.NBVImpairment_LC_Table, 0.00) + ISNULL(ai.NBVImpairment_NLC_Table, 0.00))
	   - ISNULL(gld.AssetImpairment_GL, 0.00) AS AssetImpairment_Difference
	 , ISNULL(ClearedImpairment.ClearedNBVImpairment_LC, 0.00) AS ClearedNBVImpairment_AssetImpairment_LC_Table
	 , ISNULL(ClearedImpairment.ClearedNBVImpairment_NLC, 0.00) AS ClearedNBVImpairment_AssetImpairment_NLC_Table
	 , ISNULL(gld.ClearedAccumulatedNBVImpairment_GL, 0.00) AS ClearedNBVImpairment_AssetImpairment_GL
	 , ISNULL(ClearedImpairment.ClearedNBVImpairment_LC, 0.00) + ISNULL(ClearedImpairment.ClearedNBVImpairment_NLC, 0.00) - ISNULL(gld.ClearedAccumulatedNBVImpairment_GL, 0.00) AS ClearedNBVImpairment_AssetImpairment_Difference
	 , ISNULL(ClearedImpairment.ClearedAssetImpairment_LC, 0.00) AS ClearedBookValueAdjustment_AssetImpairment_LC_Table
	 , ISNULL(ClearedImpairment.ClearedAssetImpairment_NLC, 0.00) AS ClearedBookValueAdjustment_AssetImpairment_NLC_Table
	 , ISNULL(gld.ClearedAccumulatedAssetImpairment_GL, 0.00) AS ClearedBookValueAdjustment_AssetImpairment_GL
	 , ISNULL(ClearedImpairment.ClearedAssetImpairment_LC, 0.00) + ISNULL(ClearedImpairment.ClearedAssetImpairment_NLC, 0.00) - ISNULL(gld.ClearedAccumulatedAssetImpairment_GL, 0.00) AS ClearedBookValueAdjustment_AssetImpairment_Difference
	 , ISNULL(ai.NBVImpairment_LC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedNBVImpairment_LC, 0.00) AS AccumulatedNBVImpairment_AssetImpairment_LC_Table 
	 , ISNULL(ai.NBVImpairment_NLC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedNBVImpairment_NLC, 0.00) AS AccumulatedNBVImpairment_AssetImpairment_FC_Table 
	 , ISNULL(ai.AssetImpairment_LC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedAssetImpairment_LC, 0.00) AS AccumulatedBookValueAdjustment_AssetImpairment_LC_Table 
	 , ISNULL(ai.AssetImpairment_NLC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedAssetImpairment_NLC, 0.00) AS AccumulatedBookValueAdjustment_AssetImpairment_FC_Table 
	 , ISNULL(gld.AssetImpairment_GL, 0.00) - ISNULL(gld.ClearedAccumulatedNBVImpairment_GL, 0.00) - ISNULL(gld.ClearedAccumulatedAssetImpairment_GL, 0.00) AS AccumulatedAssetImpairment_GL
	 , ABS((ISNULL(ai.NBVImpairment_LC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedNBVImpairment_LC, 0.00)) + (ISNULL(ai.NBVImpairment_NLC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedNBVImpairment_NLC, 0.00)) +
		(ISNULL(ai.AssetImpairment_LC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedAssetImpairment_LC, 0.00)) + ( ISNULL(ai.AssetImpairment_NLC_Table, 0.00) - ISNULL(ClearedImpairment.ClearedAssetImpairment_NLC, 0.00)))
	  - ABS(ISNULL(gld.AssetImpairment_GL, 0.00) - ISNULL(gld.ClearedAccumulatedNBVImpairment_GL, 0.00) - ISNULL(gld.ClearedAccumulatedAssetImpairment_GL, 0.00)) AS AccumulatedAssetImpairment_Difference
     , ISNULL(renewalassetValues.Renewal_Inventory_LC, 0.00) + ISNULL(inventory.LeasedAssetReturnedtoInventory_LC_Table, 0.00) + ISNULL(assetValues.LeasedAssetReturnToInventory_LC, 0.00) + ec.SoldNBV_Amount AS LeasedAssetReturnedtoInventory_LeaseComponent_Table
	 , ISNULL(renewalassetValues.Renewal_Inventory_NLC, 0.00) + ISNULL(inventory.LeasedAssetReturnedtoInventory_NLC_Table, 0.00) + ISNULL(assetValues.LeasedAssetReturnToInventory_NLC, 0.00) + ec.FinancingSoldNBV_Amount AS LeasedAssetReturnedtoInventory_FinanceComponent_Table
	 , ISNULL(gld.LeasedAssetReturnedtoInventory_GL, 0.00) AS LeasedAssetReturnedtoInventory_GL
	 , ISNULL(renewalassetValues.Renewal_Inventory_LC, 0.00) + ISNULL(renewalassetValues.Renewal_Inventory_NLC, 0.00) + ISNULL(inventory.LeasedAssetReturnedtoInventory_LC_Table, 0.00) + ISNULL(inventory.LeasedAssetReturnedtoInventory_NLC_Table, 0.00) 
	   + ISNULL(assetValues.LeasedAssetReturnToInventory_LC, 0.00) + ISNULL(assetValues.LeasedAssetReturnToInventory_NLC, 0.00) + ec.SoldNBV_Amount + ec.FinancingSoldNBV_Amount
	   - ISNULL(gld.LeasedAssetReturnedtoInventory_GL, 0.00) AS LeasedAssetReturnedtoInventory_Difference
	 , ISNULL(inventory.CostofGoodsSold_LC_Table, 0.00) + ec.SoldNBV_Amount + ec.FinancingSoldNBV_Amount AS CostofGoodsSold_LeaseComponent_Table
	 , ISNULL(inventory.CostofGoodsSold_NLC_Table, 0.00) AS CostofGoodsSold_FinanceComponent_Table
	 , ISNULL(gld.CostOfGoodsSold_GL, 0.00) + ISNULL(gld.FinancingCostOfGoodsSold_GL, 0.00) AS CostofGoodsSold_GL
	 , ISNULL(inventory.CostofGoodsSold_LC_Table, 0.00) + ec.SoldNBV_Amount + ec.FinancingSoldNBV_Amount + ISNULL(inventory.CostofGoodsSold_NLC_Table, 0.00) - ISNULL(gld.CostOfGoodsSold_GL, 0.00) - ISNULL(gld.FinancingCostOfGoodsSold_GL, 0.00) AS CostofGoodsSold_Difference
	 , ISNULL(trueCleared.TrueCleared_LC, 0.00) AS [TrueClearedDepreciation_LC_Table]
	 , ISNULL(trueCleared.TrueCleared_NLC, 0.00) AS [TrueClearedDepreciation_NLC_Table] 
	 , ISNULL(gld.ClearedAssetDepreciation_GL ,0.00) + ISNULL(gld.AccumulatedDepreciation_GL, 0.00) - ISNULL(gld.AssetDepreciation_GL, 0.00) AS TrueClearedDepreciation_GL
	 , ISNULL(trueCleared.TrueCleared_LC, 0.00) + ISNULL(trueCleared.TrueCleared_NLC, 0.00) - (ISNULL(gld.ClearedAssetDepreciation_GL ,0.00) + ISNULL(gld.AccumulatedDepreciation_GL, 0.00) - ISNULL(gld.AssetDepreciation_GL, 0.00)) AS TrueClearedDepreciation_Difference
	 , ISNULL(trueClearedImpairment.TrueClearedAssetImpairment_LC, 0.00) AS [TrueClearedImpairment_LC_Table]
	 , ISNULL(trueClearedImpairment.TrueClearedAssetImpairment_NLC, 0.00) AS [TrueClearedImpairment_NLC_Table] 
	 , ISNULL(gld.ClearedAccumulatedAssetImpairment_GL ,0.00) + ISNULL(gld.ClearedImp_GL, 0.00) - ISNULL(gld.AccumulatedAssetImpairment_GL, 0.00) AS TrueClearedImpairment_GL
	 , ISNULL(trueClearedImpairment.TrueClearedAssetImpairment_LC, 0.00) + ISNULL(trueClearedImpairment.TrueClearedAssetImpairment_NLC, 0.00) - (ISNULL(gld.ClearedAccumulatedAssetImpairment_GL ,0.00) + ISNULL(gld.ClearedImp_GL, 0.00) - ISNULL(gld.AccumulatedAssetImpairment_GL, 0.00)) AS TrueClearedImpairment_Difference
	 , ISNULL(chargeoff.Chargeoff_LC, 0.00) AS OperatingLease_ChargeOff_LeaseComponent_Table
	 , ISNULL(gld.Chargeoff_GL, 0.00) - ISNULL(gld.AccumulatedChargeoff_GL, 0.00) AS OperatingLease_ChargeOff_GL
	 , ISNULL(chargeoff.Chargeoff_LC, 0.00) - (ISNULL(gld.Chargeoff_GL, 0.00) - ISNULL(gld.AccumulatedChargeoff_GL, 0.00)) AS OperatingLease_ChargeOff_Difference
FROM #EligibleContracts ec
     INNER JOIN LegalEntities le ON ec.LegalEntityId = le.Id
     INNER JOIN LineofBusinesses lob ON lob.Id = ec.LineofBusinessId
     INNER JOIN Parties p ON p.Id = ec.CustomerId
     LEFT JOIN #OverTerm otp ON otp.ContractId = ec.ContractId
     LEFT JOIN #AmendmentList amendemnents ON amendemnents.ContractId = ec.ContractId
     LEFT JOIN #ChargeOff co ON co.ContractId = ec.ContractId
     LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
	 LEFT JOIN #LeaseAssetValues assetValues ON assetValues.ContractId = ec.ContractId
	 LEFT JOIN #GLDetails gld ON gld.ContractId = ec.ContractId
	 LEFT JOIN #LeasedAssetReturnedtoInventory inventory ON inventory.ContractId = ec.ContractId
	 LEFT JOIN #Cleared_AssetImpairment ClearedImpairment ON ClearedImpairment.ContractId = ec.ContractId
	 LEFT JOIN #AssetDepreciation depreciation ON depreciation.ContractId = ec.ContractId
	 LEFT JOIN #AssetDepreciationAmount assetDepreciation ON assetDepreciation.ContractId = ec.ContractId
	 LEFT JOIN #ClearedAssetDepreciation AS cleared ON cleared.ContractId = ec.ContractId
	 LEFT JOIN #RenewalLeaseAssetValues renewalassetValues ON renewalassetValues.ContractId = ec.ContractId
	 LEFT JOIN #NBVImpairment nbvImpairment ON nbvImpairment.ContractId = ec.ContractId
	 LEFT JOIN #ClearedAssetImpairment clearedImp ON clearedImp.ContractId = ec.ContractId
	 LEFT JOIN #ClearedNBVImpairment clearedNBV ON clearedNBV.ContractId = ec.ContractId
	 LEFT JOIN #AssetImpairment ai ON ai.ContractId = ec.ContractId
	 LEFT JOIN #TrueClearedAmount trueCleared ON trueCleared.ContractId = ec.ContractId
	 LEFT JOIN #TrueClearedAssetImpairmentAmount trueClearedImpairment ON trueClearedImpairment.ContractId = ec.ContractId
	 LEFT JOIN #ContractETCAmount amount ON ec.ContractId = amount.ContractId
	 LEFT JOIN #RebookContractETCAmount rbamount ON ec.ContractId = rbamount.ContractId
	 LEFT JOIN #CapitalizedAmounts ca ON ec.ContractId = ca.ContractId 
	 LEFT JOIN #RenewalCapitalizedAmounts rca ON ec.ContractId = rca.ContractId
	 LEFT JOIN #Impairment_Asset Impairment_Asset ON Impairment_Asset.ContractId = ec.ContractId
	 LEFT JOIN #AVHChargeoff chargeoff ON chargeoff.ContractId = ec.ContractId) as t;


CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(ContractId);

SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label, column_Id AS ColumnId
INTO #ContractSummary
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..#ResultList')
	  AND Name LIKE '%Difference'

DECLARE @query NVARCHAR(MAX);
DECLARE @TableName NVARCHAR(max);
WHILE EXISTS (SELECT 1 FROM #ContractSummary WHERE IsProcessed = 0)
BEGIN
SELECT TOP 1 @TableName = Name FROM #ContractSummary WHERE IsProcessed = 0

SET @query = 'UPDATE #ContractSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
				WHERE Name = '''+ @TableName+''' ;'
EXEC (@query)
END

UPDATE #ContractSummary 
		SET
			Label = CASE
				WHEN Name = 'Inventory_Difference'
				THEN '1_Inventory_Difference'
				WHEN Name ='ETC_Difference'
				THEN '2_ETC_Difference'
				WHEN Name = 'TotalCapitalizedAmount_Difference'
				THEN '3_Total Capitalized Amount_Difference'
				WHEN Name = 'FixedTermDepreciation_Difference'
				THEN '4_Fixed Term Depreciation_Difference'
				WHEN Name = 'ClearedFixedTermDepreciation_Difference'
				THEN '5_Cleared Fixed Term Depreciation_Difference'
				WHEN Name = 'AccumulatedFixedTermDepreciation_Difference'
				THEN '6_Accumulated Fixed Term Depreciation_Difference'
				WHEN Name = 'OTPDepreciation_Difference'
				THEN '7_OTP Depreciation_Difference'
				WHEN Name = 'ClearedOTPDepreciation_Difference'
				THEN '8_Cleared OTP Depreciation_Difference'
				WHEN Name = 'AccumulatedOTPDepreciation_Difference'
				THEN '9_Accumulated OTP Depreciation_Difference'
				WHEN Name = 'AssetDepreciation_Difference'
				THEN '10_Asset Depreciation_Difference'
				WHEN Name ='ClearedAssetDepreciation_Difference'
				THEN '11_Cleared Asset Depreciation_Difference'
				WHEN Name ='AccumulatedAssetDepreciation_Difference'
				THEN '12_Accumulated Asset Depreciation_Difference'
				WHEN Name ='NBVImpairment_Difference'
				THEN '13_NBV Impairment_Difference'
				WHEN Name = 'ClearedNBVImpairment_Difference'
				THEN '14_Cleared NBV Impairment_Difference'
				WHEN Name ='AccumulatedNBVImpairment_Difference'
				THEN '15_Accumulated NBV Impairment_Difference'
				WHEN Name ='ValueAdjustmentOnPayoff_Difference'
				THEN '16_Value Adjustment On Payoff_Difference'
				WHEN Name ='ClearedValueAdjustmentOnPayoff_Difference'
				THEN '17_Cleared Value Adjustment On Payoff_Difference'
				WHEN Name ='AccumulatedValueAdjustmentOnPayoff_Difference'
				THEN '18_Accumulated Value Adjustment On Payoff_Difference'
				WHEN Name ='AssetImpairment_Difference'
				THEN '19_Asset Impairment_Difference'
				WHEN Name = 'ClearedNBVImpairment_AssetImpairment_Difference'
				THEN '20_Cleared NBV Impairment_Asset Impairment_Difference'
				WHEN Name ='ClearedBookValueAdjustment_AssetImpairment_Difference'
				THEN '21_Cleared Book Value Adjustment_Asset Impairment_Difference'
				WHEN Name = 'AccumulatedAssetImpairment_Difference'
				THEN '22_Accumulated Asset Impairment_Difference'
				WHEN Name ='LeasedAssetReturnedtoInventory_Difference'
				THEN '23_Leased Asset Returned To Inventory_Difference'
				WHEN Name ='CostofGoodsSold_Difference'
				THEN '24_Cost Of Goods Sold_Difference'
				WHEN Name='TrueClearedDepreciation_Difference'
				THEN '25_True Cleared Depreciation_Difference'
				WHEN Name='TrueClearedImpairment_Difference'
				THEN '26_True Cleared Impairment_Difference'
				WHEN Name = 'OperatingLease_ChargeOff_Difference'
				THEN '27_Operating Lease_ChargeOff_Difference'
				END

        IF @IsFromLegalEntity = 0
            BEGIN
                SELECT Label AS Name
                     , Count
                FROM #ContractSummary
                ORDER BY ColumnId;

                IF(@ResultOption = 'All')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        ORDER BY ContractId;
                END;

                IF(@ResultOption = 'Failed')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Problem Record'
                        ORDER BY ContractId;
                END;

                IF(@ResultOption = 'Passed')
                    BEGIN
                        SELECT *
                        FROM #ResultList
                        WHERE Result = 'Not Problem Record'
                        ORDER BY ContractId;
                END;

                DECLARE @TotalCount BIGINT;
                SELECT @TotalCount = ISNULL(COUNT(*), 0)
                FROM #ResultList;
                DECLARE @InCorrectCount BIGINT;
                SELECT @InCorrectCount = ISNULL(COUNT(*), 0)
                FROM #ResultList
                WHERE Result = 'Problem Record';
                DECLARE @Messages STOREDPROCMESSAGE;

                INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('TotalContracts',(SELECT 'Contracts=' + CONVERT(NVARCHAR(40), @TotalCount)));
                INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('ContractsSuccessful',(SELECT 'ContractsSuccessful=' + CONVERT(NVARCHAR(40), (@TotalCount - @InCorrectCount))));
                INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('ContractsIncorrect', (SELECT 'ContractsIncorrect=' + CONVERT(NVARCHAR(40), @InCorrectCount)));
                INSERT INTO @Messages (Name, ParameterValuesCsv)
                VALUES ('ContractsResultOption',(SELECT 'ResultOption=' + CONVERT(NVARCHAR(40), @ResultOption)));

                SELECT * FROM @Messages;
        END;
		
		SELECT
			ec.ContractId
			,SUM(poa.SyndicatedNBV_Amount) AS SyndicatedNBVAmount
		INTO #SyndicatedPayoffAmount
		FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN Payoffs po ON po.LeaseFinanceId = lf.Id
		INNER JOIN PayoffAssets poa ON po.Id = poa.PayoffId
		WHERE ec.ReceivableForTransfersId IS NOT NULL
		AND ec.SyndicationLeaseFinanceId <= po.LeaseFinanceId
		GROUP BY ec.ContractId

		CREATE NONCLUSTERED INDEX IX_Id ON #SyndicatedPayoffAmount(ContractId);
		
		SELECT
			rl.ContractId
			,SUM(CASE
					WHEN gld.IsDebit = 1
					THEN Amount_Amount
					ELSE 0.00
				END)
			- SUM(CASE
					WHEN gld.IsDebit = 0
					THEN Amount_Amount
                    ELSE 0.00
				END) AS SyndicationLARTI_GL
		INTO #SyndicationLeaseAssetReturnedToInventory
		FROM #ResultList rl
		INNER JOIN GLJournalDetails gld ON rl.ContractId = gld.EntityId AND gld.EntityType = 'Contract'
		INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
		INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
		INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id
		INNER JOIN ReceivableForTransfers rft ON gld.SourceId = rft.Id
		WHERE gld.Description LIKE '%Syndication%' AND gltt.Name IN ('OperatingLeasePayoff', 'CapitalLeasePayoff') 
		AND gle.Name IN ('LeasedAssetReturnedToInventory')
		GROUP BY rl.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationLeaseAssetReturnedToInventory(ContractId);
		
		SELECT 
			DISTINCT le.Id AS LegalEntityId
			,le.Name AS LegalEntityName
		INTO #HaveCapitalLeaseLEInfo
		FROM LegalEntities le
		INNER JOIN #ResultList rl ON le.Name = rl.LegalEntityName
		WHERE rl.ContractType != 'Operating'

		CREATE NONCLUSTERED INDEX IX_Id ON #HaveCapitalLeaseLEInfo(LegalEntityId,LegalEntityName);

		SELECT
			rl.ContractId
			,SUM(CASE WHEN la.IsActive = 1 AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0) THEN la.NBV_Amount ELSE 0.00 END) AS RenewalLease_Inventory_LC
			,SUM(CASE WHEN la.IsActive = 1 AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) THEN la.NBV_Amount ELSE 0.00 END) AS RenewalLease_Inventory_NLC
			,SUM(CASE WHEN la.IsActive = 1 AND poa.AssetId IS NOT NULL AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 
					THEN la.NBV_Amount ELSE 0.00 END) AS RenewalPO_Inventory_LC
			,SUM(CASE WHEN la.IsActive = 1 AND poa.AssetId IS NOT NULL AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
					THEN la.NBV_Amount ELSE 0.00 END) AS RenewalPO_Inventory_NLC
		INTO #RenewalPaidOffInventory
		FROM #ResultList rl
		INNER JOIN #LeaseAmendmentInfo lam ON rl.ContractId = lam.ContractId
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId
		LEFT JOIN #PayoffAssetDetails poa ON poa.AssetId = la.AssetId AND poa.ContractId = lam.ContractId
		GROUP BY rl.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #RenewalPaidOffInventory(ContractId);

		SELECT
			ec.ContractId
			,SUM(ISNULL(la.PaidOffAssets_Inventory_LC,0.00) + ISNULL(rla.PaidOffAssets_Inventory_LC,0.00) + ISNULL(rp.RenewalPO_Inventory_LC,0.00)) AS PaidOffAssets_InventoryLC_Table
			,SUM(ISNULL(la.PaidOffAssets_Inventory_NLC,0.00) + ISNULL(rla.PaidOffAssets_Inventory_NLC,0.00) + ISNULL(rp.RenewalPO_Inventory_NLC,0.00)) AS PaidOffAssets_InventoryNLC_Table
			,SUM(ISNULL(la.Booking_Inventory_LC,0.00) + ISNULL(rla.Renewal_Inventory_LC,0.00)) - SUM(ISNULL(la.PaidOffAssets_Inventory_LC,0.00) + ISNULL(rla.PaidOffAssets_Inventory_LC,0.00))
			- ISNULL(SUM(CASE WHEN rd.ContractId IS NOT NULL THEN rp.RenewalLease_Inventory_LC ELSE 0.00 END),0.00) AS ActiveAssets_InventoryLC_Table
			,SUM(ISNULL(la.Booking_Inventory_NLC,0.00) + ISNULL(rla.Renewal_Inventory_NLC,0.00)) - SUM(ISNULL(la.PaidOffAssets_Inventory_NLC,0.00) + ISNULL(rla.PaidOffAssets_Inventory_NLC,0.00))
			- ISNULL(SUM(CASE WHEN rd.ContractId IS NOT NULL THEN rp.RenewalLease_Inventory_NLC ELSE 0.00 END),0.00) AS ActiveAssets_InventoryNLC_Table
			,SUM(ISNULL(la.PaidOffAssets_Inventory_LC,0.00) + ISNULL(rla.PaidOffAssets_Inventory_LC,0.00) + ISNULL(rp.RenewalLease_Inventory_LC,0.00)) AS PaidOffAssets_Amort_InventoryLC_Table
			,SUM(ISNULL(la.PaidOffAssets_Inventory_NLC,0.00) + ISNULL(rla.PaidOffAssets_Inventory_NLC,0.00) + ISNULL(rp.RenewalLease_Inventory_NLC,0.00)) AS PaidOffAssets_Amort_InventoryNLC_Table
			,CAST (0 AS DECIMAL (16, 2)) AS SoldPaidOffAssets_Inventory_Table
		INTO #PayoffAmort_Table
		FROM #EligibleContracts ec
		LEFT JOIN #LeaseAssetValues la ON la.ContractId = ec.ContractId
		LEFT JOIN #RenewalLeaseAssetValues rla ON rla.ContractId = ec.ContractId
		LEFT JOIN #HaveCapitalLeaseLEInfo cle ON cle.LegalEntityId = ec.LegalEntityId
		LEFT JOIN #RenewalPaidOffInventory rp ON rp.ContractId = ec.ContractId
		LEFT JOIN #RenewalDone rd ON rd.ContractId = ec.ContractId
		GROUP BY ec.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #PayoffAmort_Table(ContractId);

		UPDATE pa
		SET pa.ActiveAssets_InventoryLC_Table = 
				CASE WHEN ec.ReceivableForTransfersId IS NOT NULL
					THEN pa.ActiveAssets_InventoryLC_Table * ec.RetainedPortion
					ELSE pa.ActiveAssets_InventoryLC_Table
				END
			, pa.ActiveAssets_InventoryNLC_Table = 
				CASE WHEN ec.ReceivableForTransfersId IS NOT NULL
					THEN pa.ActiveAssets_InventoryNLC_Table * ec.RetainedPortion
					ELSE pa.ActiveAssets_InventoryNLC_Table
				END
		FROM #PayoffAmort_Table pa
		INNER JOIN #EligibleContracts ec ON pa.ContractId = ec.ContractId;
		
		UPDATE pa
		SET pa.SoldPaidOffAssets_Inventory_Table = t.SoldPaidOffAssets_Inventory_Table
		FROM #PayoffAmort_Table pa
		INNER JOIN (
		SELECT 
			poa.ContractId
			,SUM(
				CASE WHEN ec.ReceivableForTransferType = 'ParticipatedSale' 
					THEN CAST((la.NBV_Amount + la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount 
					+ la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount) * ec.SoldPortion AS decimal (16,2))
					WHEN ec.ReceivableForTransferType = 'SaleOfPayments'
					THEN CAST((la.NBV_Amount + la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount 
					+ la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount - la.BookedResidual_Amount) * ec.SoldPortion AS decimal (16,2))
					ELSE 0.00
				END) AS SoldPaidOffAssets_Inventory_Table
		FROM #PayoffAssetDetails poa
		INNER JOIN #EligibleContracts ec ON poa.ContractId = ec.ContractId
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId AND poa.LeaseFinanceId = lf.Id
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id AND poa.AssetId = la.AssetId
		WHERE ec.ReceivableForTransfersId IS NOT NULL AND poa.LeaseFinanceId >= ec.SyndicationLeaseFinanceId
			AND ec.ReceivableForTransferType != 'FullSale'
		GROUP BY poa.ContractId) AS t ON t.ContractId = pa.ContractId

		BEGIN
		SET @Sql = '
		SELECT
			ec.ContractId
		 , SUM(CASE WHEN po.LeaseFinanceId >= ec.SyndicationLeaseFinanceId AND ec.ReceivableForTransfersId IS NOT NULL
					THEN la.NBV_Amount * ec.RetainedPortion 
					ELSE la.NBV_Amount END)
		 + SUM(CASE
					WHEN la.CapitalizedForId IS NOT NULL 
						AND po.LeaseFinanceId >= ec.SyndicationLeaseFinanceId AND ec.ReceivableForTransfersId IS NOT NULL
				   THEN (la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + AdditionalCapitalizedCost) * ec.RetainedPortion
				   WHEN la.CapitalizedForId IS NOT NULL AND ec.ReceivableForTransfersId IS NULL
				   THEN (la.CapitalizedInterimInterest_Amount + la.CapitalizedInterimRent_Amount + la.CapitalizedSalesTax_Amount + la.CapitalizedProgressPayment_Amount + AdditionalCapitalizedCost)
				   ELSE 0.00
			   END)
		- SUM(CASE WHEN po.LeaseFinanceId >= ec.SyndicationLeaseFinanceId AND ec.ReceivableForTransfersId IS NOT NULL
					THEN la.ETCAdjustmentAmount_Amount * ec.RetainedPortion ELSE la.ETCAdjustmentAmount_Amount END) AS PaidOffNotCOAmount
		FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		INNER JOIN Payoffs po ON po.LeaseFinanceId = lf.Id
		INNER JOIN PayoffAssets poa ON poa.LeaseAssetId = la.Id AND po.Id = poa.PayoffId
		LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId AND coa.AssetId = la.AssetId
		WHERE coa.AssetId IS NULL AND ec.ChargeOffStatus = ''ChargedOff''
		GROUP BY ec.ContractId'		
		IF @CapitalizedAdditionalCharge IS NOT NULL
		BEGIN
			SET @sql = REPLACE(@sql, 'AdditionalCapitalizedCost', @CapitalizedAdditionalCharge);
		END;
		ELSE
		BEGIN
			SET @sql = REPLACE(@sql, 'AdditionalCapitalizedCost', '0');
		END;		
		INSERT INTO #PaidOffNotCOAmountInfo
		EXEC (@Sql)
		END;

		CREATE NONCLUSTERED INDEX IX_Id ON #PaidOffNotCOAmountInfo(ContractId);

		BEGIN
		SET @Sql = '
		SELECT
			ec.ContractId
			,SUM(CASE WHEN ec.ReceivableForTransfersId IS NOT NULL AND ec.ContractType != ''Operating''
					THEN avh.Value_Amount * ec.RetainedPortion
					ELSE avh.Value_Amount
				END) AS FinanceChargeOffAmount
		FROM #EligibleContracts ec
		INNER JOIN #ChargedOffAssets coa ON ec.ContractId = coa.ContractId
		INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = coa.ChargeOffId AND avh.AssetId = coa.AssetId
		INNER JOIN 
			(SELECT DISTINCT ec.ContractId,la.AssetId,la.IsLeaseAsset,la.IsFailedSaleLeaseback
			FROM #EligibleContracts ec
			INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
			INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
			) AS t ON t.ContractId = ec.ContractId AND t.AssetId = avh.AssetId
		WHERE avh.SourceModule = ''ChargeOff''
		AND (ec.ContractType != ''Operating'' OR (ec.ContractType = ''Operating'' AND ComponentCondition))
		GROUP BY ec.ContractId'		
		IF @IsSku = 0
			BEGIN
			SET @Sql = REPLACE(@Sql,'ComponentCondition','t.IsLeaseAsset = 0 OR t.IsFailedSaleLeaseback = 1')
			END
		ELSE
			BEGIN
			SET @Sql = REPLACE(@Sql,'ComponentCondition','avh.IsLeaseComponent = 0 OR t.IsFailedSaleLeaseback = 1')
			END
		INSERT INTO #FinanceChargeOffAmount_Info
		EXEC(@Sql)
		END;

		CREATE NONCLUSTERED INDEX IX_Id ON #FinanceChargeOffAmount_Info(ContractId);

		SELECT
			rl.ContractId
			,SUM(ISNULL(amount.ActiveAssets_ETCAmount_LC,0.00) + ISNULL(rbamount.ActiveAssets_ETCAmount_LC,0.00)) AS ActiveAssets_ETCAmount_LC_Table
			,SUM(ISNULL(amount.ActiveAssets_ETCAmount_NLC,0.00) + ISNULL(rbamount.ActiveAssets_ETCAmount_NLC,0.00)) AS ActiveAssets_ETCAmount_NLC_Table
			,CAST (0 AS decimal (16,2)) AS PaidOffAssets_SoldETCAmount_Table
		INTO #ETCAmort_Table
		FROM #ResultList rl
		LEFT JOIN #ContractETCAmount amount ON rl.ContractId = amount.ContractId
		LEFT JOIN #RebookContractETCAmount rbamount ON rl.ContractId = rbamount.ContractId
		GROUP BY rl.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #ETCAmort_Table(ContractId);

		UPDATE etc
		SET etc.ActiveAssets_ETCAmount_LC_Table = etc.ActiveAssets_ETCAmount_LC_Table * ec.RetainedPortion
			,etc.ActiveAssets_ETCAmount_NLC_Table = etc.ActiveAssets_ETCAmount_NLC_Table * ec.RetainedPortion
		FROM #ETCAmort_Table etc
		INNER JOIN #EligibleContracts ec ON etc.ContractId = ec.ContractId
		WHERE ec.ReceivableForTransfersId IS NOT NULL 
		AND (etc.ActiveAssets_ETCAmount_LC_Table != 0.00 OR etc.ActiveAssets_ETCAmount_NLC_Table != 0.00);

		UPDATE etc
		SET etc.PaidOffAssets_SoldETCAmount_Table = t.PaidOffAssets_SoldETCAmount_Table
		FROM #ETCAmort_Table etc
		INNER JOIN (
		SELECT
			ec.ContractId
			,SUM(CAST(bia.TaxCredit_Amount * ec.SoldPortion AS DECIMAL (16, 2))) AS PaidOffAssets_SoldETCAmount_Table
		FROM #EligibleContracts ec
		INNER JOIN #PayoffAssetDetails poa ON ec.ContractId = poa.ContractId
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id AND poa.AssetId = la.AssetId
		INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
		INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
		WHERE ec.ReceivableForTransfersId IS NOT NULL AND poa.LeaseFinanceId >= ec.SyndicationLeaseFinanceId
		AND bi.IsActive = 1 AND bia.IsActive = 1 AND bi.IsETC = 1
		GROUP BY ec.ContractId) AS t ON t.ContractId = etc.ContractId;

		SELECT DISTINCT rl.ContractId
		INTO #AmortizeContract
		FROM #ResultList rl
		INNER JOIN LeaseFinances lf ON rl.ContractId = lf.ContractId
		INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
		WHERE lam.LeaseAmendmentStatus = 'Approved' AND lam.AmendmentType IN ('Payoff','Renewal')

		CREATE NONCLUSTERED INDEX IX_Id ON #AmortizeContract(ContractId);

		BEGIN
		SET @Sql =
		'SELECT 
			DISTINCT ec.ContractId
		FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		INNER JOIN Assets a ON la.AssetId = a.Id
		INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId AND poa.LeaseAssetId = la.Id
		WHERE ((la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND lfd.LeaseContractType = ''Operating'')
		FilterCondition'
		IF @IsSku = 1
			SET @Sql = REPLACE(@Sql,'FilterCondition', @FilterCondition)
		ELSE
			SET @Sql = REPLACE(@Sql,'FilterCondition', '')
		INSERT INTO #OperatingPaidOffContract
		EXEC (@Sql)
		END

		IF @IsSku = 1
		BEGIN
		SET @Sql =
		'SELECT 
			DISTINCT ec.ContractId
		FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
		INNER JOIN Assets a ON la.AssetId = a.Id
		INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId AND poa.LeaseAssetId = la.Id
		WHERE ((las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND lfd.LeaseContractType = ''Operating'')
		AND a.IsSKU = 1'
		INSERT INTO #OperatingPaidOffContractSKU
		EXEC (@Sql)
		END

		CREATE NONCLUSTERED INDEX IX_Id ON #OperatingPaidOffContractSKU(ContractId);

		MERGE #OperatingPaidOffContract op
		USING (SELECT * FROM #OperatingPaidOffContractSKU) AS ops
		ON (op.ContractId = ops.ContractId)
		WHEN NOT MATCHED THEN INSERT (ContractId)
		VALUES (ops.ContractId);

		MERGE #OperatingPaidOffContract op
		USING (
			SELECT DISTINCT ec.ContractId
			FROM #RenewalDone rd
			INNER JOIN #EligibleContracts ec ON rd.ContractId = ec.ContractId
			WHERE ec.ContractType = 'Operating') AS t ON (t.ContractId = op.ContractId)
		WHEN NOT MATCHED THEN INSERT (ContractId)
		VALUES (t.ContractId);
		
		CREATE NONCLUSTERED INDEX IX_Id ON #OperatingPaidOffContract(ContractId);

		INSERT INTO #CapitalPaidOffContract
		SELECT 
			DISTINCT ec.ContractId
		FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		INNER JOIN Assets a ON la.AssetId = a.Id
		INNER JOIN AssetValueHistories avh ON a.Id = avh.AssetId
		INNER JOIN #PayoffAssetDetails poa ON poa.ContractId = ec.ContractId AND poa.LeaseAssetId = la.Id
		WHERE lfd.LeaseContractType != 'Operating' AND poa.PayoffEffectiveDate > lfd.MaturityDate
		AND avh.SourceModule = 'OTPDepreciation' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
		
		MERGE #CapitalPaidOffContract cp
		USING (
			SELECT DISTINCT ec.ContractId
			FROM #RenewalDone rd
			INNER JOIN #EligibleContracts ec ON rd.ContractId = ec.ContractId
			WHERE ec.ContractType != 'Operating') AS t ON (t.ContractId = cp.ContractId)
		WHEN NOT MATCHED THEN INSERT (ContractId)
		VALUES (t.ContractId);
		
		CREATE NONCLUSTERED INDEX IX_Id ON #CapitalPaidOffContract(ContractId);

		SELECT ec.ContractId
				, SUM(CASE WHEN avh.SourceModule = 'InventoryBookDepreciation' THEN avh.Value_Amount ELSE 0.00 END)* -1 AS OperatingInventoryDep_Table
				, SUM(CASE WHEN avh.SourceModule = 'AssetImpairment' THEN avh.Value_Amount ELSE 0.00 END)* -1 AS OperatingInventoryImp_Table
		INTO #OperatingInventory
		FROM #EligibleContracts ec
				INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
				INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
											AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
				INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
				LEFT JOIN #PreviousContact pc ON pc.ContractId = ec.ContractId
												AND pc.AssetId = la.AssetId
				LEFT JOIN #PayoffAssetDetails pod ON pod.ContractId = pc.PreviousContractId
													AND pod.AssetId = pc.AssetId
		WHERE avh.SourceModule IN('InventoryBookDepreciation','AssetImpairment')
				AND avh.IncomeDate < ec.CommencementDate
				AND avh.IsAccounted = 1
				AND pod.AssetId IS NULL
		GROUP BY ec.ContractId

		CREATE NONCLUSTERED INDEX IX_Id ON #OperatingInventory(ContractId);

		SELECT DISTINCT ec.ContractId
		INTO #PayoffandSynContract
		FROM #EligibleContracts ec
		INNER JOIN #PayoffAssetDetails poa ON ec.ContractId = poa.ContractId
		WHERE poa.PayoffEffectiveDate <= ec.SyndicationDate

		CREATE NONCLUSTERED INDEX IX_Id ON #PayoffandSynContract(ContractId);

		SELECT 
			ec.ContractId
			,SUM(CASE WHEN ec.ContractType = 'Operating' THEN avh.Value_Amount * -1 ELSE 0.00 END) AS OperatingCOAmount_Table
			,SUM(CASE WHEN ec.ContractType != 'Operating' THEN avh.Value_Amount * -1 ELSE 0.00 END) AS CapitalCOAmount_Table
		INTO #AmortChargeOffInfo
		FROM #EligibleContracts ec
			INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
			INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			INNER JOIN #Chargeoff co ON co.ContractId = ec.ContractId
			INNER JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId AND avh.AssetId = coa.AssetId
		WHERE avh.IsAccounted = 1
			AND avh.GLJournalId IS NOT NULL
			AND avh.ReversalGLJournalId IS NULL
			AND la.IsActive = 1
			AND avh.SourceModule IN ('OTPDepreciation','FixedTermDepreciation')
		GROUP BY ec.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #AmortChargeOffInfo(ContractId);

		SELECT DISTINCT ec.ContractId,gld.SourceId
		INTO #AccumulatedNotClearedPayoff
		FROM #EligibleContracts ec
		INNER JOIN GLJournalDetails gld ON gld.EntityId = ec.ContractId AND gld.EntityType = 'Contract'
		INNER JOIN GLTemplateDetails gltd ON gltd.Id = gld.GLTemplateDetailId
		INNER JOIN GLEntryItems gle ON gle.Id = gltd.EntryItemId
		INNER JOIN GLTransactionTypes gltt ON gle.GLTransactionTypeId = gltt.Id 
		WHERE gle.Name IN ('AccumulatedAssetDepreciation','AccumulatedAssetImpairment')
		AND gltt.Name IN ('OperatingLeasePayoff','CapitalLeasePayoff')

		CREATE NONCLUSTERED INDEX IX_Id ON #AccumulatedNotClearedPayoff(ContractId);

		SELECT
			ec.ContractId
			,SUM(poa.NBVAsOfEffectiveDate_Amount - poa.AssetValuation_Amount) AS ImpairedValueOnPayoff
		INTO #ImpairmentOnPayoff
		FROM #EligibleContracts ec
			INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
			INNER JOIN Payoffs po ON po.LeaseFinanceId = lf.Id
			INNER JOIN PayoffAssets poa ON poa.PayoffId = po.Id
			INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
			LEFT JOIN #AccumulatedNotClearedPayoff ap ON ap.ContractId = ec.ContractId AND ap.SourceId = po.Id
		WHERE po.Status = 'Activated' AND poa.IsActive = 1
			AND (ec.ContractType = 'Operating' OR (ec.ContractType != 'Operating' AND po.PayoffEffectiveDate > lfd.MaturityDate))
			AND ap.SourceId IS NULL
		GROUP BY ec.ContractId;

		CREATE NONCLUSTERED INDEX IX_Id ON #ImpairmentOnPayoff(ContractId);

		--True Cleared Depreciation for PaidoffAssets and Not ChargedOffAssets
		SELECT ec.ContractId
			 , CAST(0.00 AS DECIMAL(16, 2)) AS TrueCleared_LC
			 , CAST(0.00 AS DECIMAL(16, 2)) AS TrueCleared_NLC
		INTO #PayoffNoCOTrueClearedAmount
		FROM #EligibleContracts ec;

		CREATE NONCLUSTERED INDEX IX_Id ON #PayoffNoCOTrueClearedAmount(ContractId);

		--SELECT 7,* FROM #PayoffNoCOTrueClearedAmount
				UPDATE cleared SET 
						   TrueCleared_LC += t.Amount_LC
						 , TrueCleared_NLC += t.Amount_NLC
		FROM #PayoffNoCOTrueClearedAmount cleared
			 INNER JOIN
		(
			SELECT ec.ContractId
				 , SUM(CASE
						   WHEN la.IsFailedSaleLeaseback = 0
								AND avh.IsLeaseComponent = 1
						   THEN avh.Value_Amount
						   ELSE 0.00
					   END) * -1 AS Amount_LC
				 , SUM(CASE
						   WHEN la.IsFailedSaleLeaseback = 1
								OR avh.IsLeaseComponent = 0
						   THEN avh.Value_Amount
						   ELSE 0.00
					   END) * -1 AS Amount_NLC
			FROM #EligibleContracts ec
				 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
											  AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
				 INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
				 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
				 INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
													   AND pod.AssetId = avh.AssetId
				  LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
													 AND coa.AssetId = avh.AssetId
			WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
				 AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
				 AND avh.IncomeDate <= pod.PayoffEffectiveDate
				 AND avh.IncomeDate > ec.CommencementDate
				 AND avh.IsAccounted = 1
				 AND coa.AssetId IS NULL
				 AND (lfd.LeaseContractType = 'Operating' OR (lfd.LeaseContractType != 'Operating' AND pod.PayoffEffectiveDate > lfd.MaturityDate))
			GROUP BY ec.ContractId
		) AS t ON t.ContractId = cleared.ContractId;

		--To Subract the Clearing happened because of Syndication 
		UPDATE cleared SET 
						   TrueCleared_LC -= t.Amount_LC
						 , TrueCleared_NLC -= t.Amount_NLC
		FROM #PayoffNoCOTrueClearedAmount cleared
			 INNER JOIN
		( SELECT 
				ec.ContractId
				, SUM(CASE
						   WHEN la.IsFailedSaleLeaseback = 0
								AND avh.IsLeaseComponent = 1
						   THEN CAST(avh.Value_Amount * ec.SoldPortion AS DECIMAL (16, 2))
						   ELSE 0.00
					   END) * -1 AS Amount_LC
				 , SUM(CASE
						   WHEN la.IsFailedSaleLeaseback = 1
								OR avh.IsLeaseComponent = 0
						   THEN CAST(avh.Value_Amount * ec.SoldPortion AS DECIMAL (16, 2))
						   ELSE 0.00
					   END) * -1 AS Amount_NLC
		FROM #EligibleContracts ec
				 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
											  AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
				 INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
				 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
				 INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
													   AND pod.AssetId = avh.AssetId
				  LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
													 AND coa.AssetId = avh.AssetId
			WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
				 AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
				 AND avh.IncomeDate <= pod.PayoffEffectiveDate
				 AND avh.IncomeDate > ec.CommencementDate
				 AND avh.IsAccounted = 1
				 AND coa.AssetId IS NULL
				 AND ec.ReceivableForTransfersId IS NOT NULL
				 AND avh.IncomeDate <= ec.SyndicationDate
				 AND pod.LeaseFinanceId >= ec.SyndicationLeaseFinanceId
				 AND (lfd.LeaseContractType = 'Operating' OR (lfd.LeaseContractType != 'Operating' AND pod.PayoffEffectiveDate > lfd.MaturityDate))
			GROUP BY ec.ContractId
		) AS t ON t.ContractId = cleared.ContractId;

		 --SELECT 8,* FROM #PayoffNoCOTrueClearedAmount
		UPDATE cleared SET 
						   TrueCleared_LC += t.Amount_LC
						 , TrueCleared_NLC += t.Amount_NLC
		FROM #PayoffNoCOTrueClearedAmount cleared
			 INNER JOIN
		(
			SELECT ec.ContractId
				 , SUM(CASE
						   WHEN la.IsFailedSaleLeaseback = 0
								AND avh.IsLeaseComponent = 1
						   THEN avh.Value_Amount
						   ELSE 0.00
					   END) * -1 AS Amount_LC
				 , SUM(CASE
						   WHEN la.IsFailedSaleLeaseback = 1
								OR avh.IsLeaseComponent = 0
						   THEN avh.Value_Amount
						   ELSE 0.00
					   END) * -1 AS Amount_NLC
			FROM #EligibleContracts ec
				 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
											  AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
				 INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
													   AND pod.AssetId = la.AssetId
				 INNER JOIN AssetValueHistories avh ON avh.AssetId = pod.AssetId
														AND avh.SourceModuleId IN (SELECT Id FROM LeaseFinances WHERE ContractId = ec.ContractId)
				 INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
				 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
													AND coa.AssetId = avh.AssetId
			WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
				 AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
				 AND avh.IncomeDate > pod.PayoffEffectiveDate
				 AND avh.IncomeDate > ec.CommencementDate
				 AND avh.IsAccounted = 1
				 AND avh.ReversalGLJournalId IS NULL
				 AND coa.AssetId IS NULL
				 AND (lfd.LeaseContractType = 'Operating' OR (lfd.LeaseContractType != 'Operating' AND pod.PayoffEffectiveDate > lfd.MaturityDate))	  
			GROUP BY ec.ContractId
		) AS t ON t.ContractId = cleared.ContractId;

		--SELECT 10,* FROM #PayoffNoCOTrueClearedAmount
		UPDATE cleared SET 
						   TrueCleared_LC += t.Amount_LC
						 , TrueCleared_NLC += t.Amount_NLC
		FROM #PayoffNoCOTrueClearedAmount cleared
			 INNER JOIN
		(
			SELECT ec.ContractId
				 , CAST(SUM(CASE
								WHEN la.IsFailedSaleLeaseback = 0
									 AND avh.IsLeaseComponent = 1
								THEN avh.Value_Amount
								ELSE 0.00
							END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
				 , CAST(SUM(CASE
								WHEN la.IsFailedSaleLeaseback = 1
									 OR avh.IsLeaseComponent = 0
								THEN avh.Value_Amount
								ELSE 0.00
							END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
			FROM #EligibleContracts ec
				 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
				 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
				 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
											  AND la.IsActive = 1
				 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			WHERE avh.SourceModule IN('FixedTermDepreciation', 'OTPDepreciation')
				 AND avh.IncomeDate > renewal.CommencementDate
				 AND avh.IncomeDate <= rd.RenewalDate
				 AND avh.IsAccounted = 1
			GROUP BY ec.ContractId
		) AS t ON t.ContractId = cleared.ContractId;
		
		SELECT ec.ContractId
			 , CAST(0.00 AS DECIMAL(16, 2)) AS TrueClearedAssetImpairment_LC
			 , CAST(0.00 AS DECIMAL(16, 2)) AS TrueClearedAssetImpairment_NLC
		INTO #PayoffNoCOTrueClearedAssetImpairmentAmount
		FROM #EligibleContracts ec;

		CREATE NONCLUSTERED INDEX IX_Id ON #PayoffNoCOTrueClearedAssetImpairmentAmount(ContractId);

		--SELECT 7,* FROM #PayoffNoCOTrueClearedAssetImpairmentAmount
		UPDATE cleared SET 
						   TrueClearedAssetImpairment_LC += t.Amount_LC
						 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
		FROM #PayoffNoCOTrueClearedAssetImpairmentAmount cleared
			 INNER JOIN
		(
			SELECT ec.ContractId
				 , SUM(CASE
							WHEN la.IsFailedSaleLeaseback = 0
								 AND avh.IsLeaseComponent = 1
							THEN avh.Value_Amount
							ELSE 0.00
					   END) * -1 AS Amount_LC
				 , SUM(CASE
						   WHEN la.IsFailedSaleLeaseback = 1
								OR avh.IsLeaseComponent = 0
						   THEN avh.Value_Amount
						   ELSE 0.00
					   END) * -1 AS Amount_NLC
			FROM #EligibleContracts ec
				 INNER JOIN LeaseFinances lf ON lf.Id = ec.LeaseFinanceId
				 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = ec.LeaseFinanceId
											  AND la.IsActive = 0 AND la.TerminationDate IS NOT NULL
				 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
				 INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
				 INNER JOIN #PayoffAssetDetails pod ON pod.ContractId = ec.ContractId
													   AND pod.AssetId = avh.AssetId
				 LEFT JOIN #ChargedOffAssets coa ON coa.ContractId = ec.ContractId
													AND coa.AssetId = avh.AssetId
			WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
				 AND (@ClearAccumulatedAccountsatPayoff = 'True' OR pod.PayoffAssetStatus IN ('Purchase', 'ReturnToUpgrade'))
				 AND avh.IncomeDate <= pod.PayoffEffectiveDate
				 AND avh.IncomeDate > ec.CommencementDate
				 AND avh.IsAccounted = 1
				 AND coa.AssetId IS NULL
				 AND (lfd.LeaseContractType = 'Operating' OR (lfd.LeaseContractType != 'Operating' AND pod.PayoffEffectiveDate > lfd.MaturityDate))
			GROUP BY ec.ContractId
		) AS t ON t.ContractId = cleared.ContractId;

		--SELECT 10,* FROM #PayoffNoCOTrueClearedAssetImpairmentAmount
		UPDATE cleared SET 
						   TrueClearedAssetImpairment_LC += t.Amount_LC
						 , TrueClearedAssetImpairment_NLC += t.Amount_NLC
		FROM #PayoffNoCOTrueClearedAssetImpairmentAmount cleared
			 INNER JOIN
		(
			SELECT ec.ContractId
				 , CAST(SUM(CASE
								WHEN la.IsFailedSaleLeaseback = 0
									 AND avh.IsLeaseComponent = 1
								THEN avh.Value_Amount
								ELSE 0.00
							END) * -1 AS DECIMAL(16, 2)) AS Amount_LC
				 , CAST(SUM(CASE
								WHEN la.IsFailedSaleLeaseback = 1
									 OR avh.IsLeaseComponent = 0
								THEN avh.Value_Amount
								ELSE 0.00
							END) * -1 AS DECIMAL(16, 2)) AS Amount_NLC
			FROM #EligibleContracts ec
				 INNER JOIN #LeaseFinanceIdBeforeRenewal renewal ON renewal.ContractId = ec.ContractId
				 INNER JOIN #RenewalDetails rd ON rd.ContractId = ec.ContractId
				 INNER JOIN LeaseAssets la ON la.LeaseFinanceId = renewal.LeaseFinanceId
											  AND la.IsActive = 1
				 INNER JOIN AssetValueHistories avh ON avh.AssetId = la.AssetId
			WHERE avh.SourceModule IN('AssetImpairment', 'NBVImpairments')
				 AND avh.IncomeDate > renewal.CommencementDate
				 AND avh.IncomeDate <= rd.RenewalDate
				 AND avh.IsAccounted = 1
			GROUP BY ec.ContractId
		) AS t ON t.ContractId = cleared.ContractId;

        IF @IsFromLegalEntity = 1
            BEGIN
				
                SELECT rl.LegalEntityName
					 /*LAC*/
                     , SUM(CASE WHEN rl.ContractStatus != 'FullyPaidOff' THEN rl.Inventory_GL ELSE 0.00 END) AS Inventory_CT_GL
					 , SUM(CASE WHEN rl.ContractStatus != 'FullyPaidOff' THEN rl.ETC_GL ELSE 0.00 END) AS ETC_LAC_CT_GL
					 , SUM(CASE WHEN rl.ContractStatus != 'FullyPaidOff' THEN rl.TotalCapitalizedAmount_GL ELSE 0.00 END) AS CapitalizedCost_LAC_CT_GL
					 , ISNULL(SUM(CASE WHEN rl.ContractStatus != 'FullyPaidOff' THEN sa.SyndicationLARTI_GL ELSE 0.00 END),0.00) AS SyndicationLARTI_CT_GL
					 , SUM(CASE WHEN rl.ContractStatus != 'FullyPaidOff' THEN (opp.PaidOffAssets_InventoryLC_Table + opp.PaidOffAssets_InventoryNLC_Table) - opp.SoldPaidOffAssets_Inventory_Table ELSE 0.00 END) AS PaidOffAssets_LAC_Table
					 , SUM(CASE WHEN rl.ContractStatus != 'FullyPaidOff' AND al.ContractId IS NOT NULL AND ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) THEN rl.ETC_GL - (etc.ActiveAssets_ETCAmount_LC_Table + etc.ActiveAssets_ETCAmount_NLC_Table) - etc.PaidOffAssets_SoldETCAmount_Table ELSE 0.00 END) PaidOffAssets_LAC_ETC_Table
					 /*Other*/
					 , SUM(rl.LeasedAssetReturnedtoInventory_GL) AS LeasedAssetReturnedtoInventory_CT_GL
					 , SUM(rl.ETC_GL) AS ETC_CT_GL
					 , SUM(rl.TotalCapitalizedAmount_GL) AS CapitalizedCost_CT_GL
                     , SUM(rl.TrueClearedDepreciation_GL) AS ClearedDepreciation_CT_GL
                     , SUM(rl.TrueClearedImpairment_GL) AS ClearedImpairment_CT_GL
                     , SUM(rl.AccumulatedFixedTermDepreciation_GL) AS AccumulatedFixedTermDepreciation_CT_GL
                     , SUM(rl.AccumulatedOTPDepreciation_GL) AS AccumulatedOTPDepreciation_CT_GL
                     , SUM(rl.AccumulatedAssetDepreciation_GL) AS AccumulatedAssetDepreciation_CT_GL
                     , SUM(rl.AccumulatedNBVImpairment_GL) AS AccumulatedNBVImpairment_CT_GL
                     , SUM(rl.AccumulatedAssetImpairment_GL) AS AccumulatedAssetImpairment_CT_GL
                     , SUM(rl.CostofGoodsSold_GL) AS CostofGoodsSold_CT_GL
					 , SUM(rl.OperatingLease_ChargeOff_GL) AS ChargeOff_CT_GL
					/*AssetAmort*/
					, SUM(CASE 
						WHEN rl.ContractType = 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND opc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN (rl.TrueClearedDepreciation_GL + rl.TrueClearedImpairment_GL)
						WHEN rl.ContractType = 'Operating' AND co.ContractId IS NOT NULL
						THEN (ptd.TrueCleared_LC + ptd.TrueCleared_NLC + pti.TrueClearedAssetImpairment_LC + pti.TrueClearedAssetImpairment_NLC)
						ELSE 0.00
					END)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType = 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND opc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN oi.OperatingInventoryDep_Table
						ELSE 0.00
					END),0.00)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType = 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND opc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN oi.OperatingInventoryImp_Table
						ELSE 0.00
					END),0.00)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType = 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND opc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN aci.OperatingCOAmount_Table
						ELSE 0.00
					END),0.00)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType = 'Operating' AND al.ContractId IS NOT NULL
						AND opc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN iop.ImpairedValueOnPayoff
						ELSE 0.00
					END),0.00) AS OperatingAmortCleared_CT_GL
					, SUM(CASE 
						WHEN rl.ContractType != 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND cpc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN (rl.TrueClearedDepreciation_GL + rl.TrueClearedImpairment_GL)
						WHEN rl.ContractType != 'Operating' AND co.ContractId IS NOT NULL
						THEN (ptd.TrueCleared_LC + ptd.TrueCleared_NLC + pti.TrueClearedAssetImpairment_LC + pti.TrueClearedAssetImpairment_NLC)
						ELSE 0.00
					END)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType != 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND cpc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN oi.OperatingInventoryDep_Table
						ELSE 0.00
					END),0.00)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType != 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND cpc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN oi.OperatingInventoryImp_Table
						ELSE 0.00
					END),0.00)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType != 'Operating' AND al.ContractId IS NOT NULL AND co.ContractId IS NULL
						AND opc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN aci.CapitalCOAmount_Table
						ELSE 0.00
					END),0.00)
					- ISNULL(SUM(CASE 
						WHEN rl.ContractType != 'Operating' AND al.ContractId IS NOT NULL
						AND opc.ContractId IS NOT NULL
						AND (rl.SyndicationType != 'FullSale' OR (rl.SyndicationType = 'FullSale' AND pos.ContractId IS NOT NULL))
						THEN iop.ImpairedValueOnPayoff
						ELSE 0.00
					END),0.00) AS CapitalAmortCleared_CT_GL
					, SUM(CASE WHEN co.ContractId IS NULL AND ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) 
						THEN ((opp.PaidOffAssets_Amort_InventoryLC_Table + opp.PaidOffAssets_Amort_InventoryNLC_Table) - opp.SoldPaidOffAssets_Inventory_Table)
						WHEN co.ContractId IS NOT NULL AND ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) 
						THEN ISNULL(poc.PaidOffNotCOAmount,0.00)
						ELSE 0.00 END) AS PaidOffAssets_Inventory_Table
					, SUM(CASE WHEN al.ContractId IS NOT NULL AND co.ContractId IS NULL AND ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) THEN (opp.ActiveAssets_InventoryLC_Table + opp.ActiveAssets_InventoryNLC_Table) ELSE 0.00 END) AS LeasedAssets_Inventory_Table
					, SUM(CASE WHEN ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) THEN rl.LeasedAssetReturnedtoInventory_GL ELSE 0.00 END) - ISNULL(SUM(CASE WHEN ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) THEN sa.SyndicationLARTI_GL ELSE 0.00 END),0.00) AS PaidOffAssets_LARTI_GL
					, SUM(CASE WHEN al.ContractId IS NOT NULL AND co.ContractId IS NULL AND ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) THEN (etc.ActiveAssets_ETCAmount_LC_Table + etc.ActiveAssets_ETCAmount_NLC_Table) ELSE 0.00 END) AS ActiveAssets_ETC_Table
					, SUM(CASE WHEN al.ContractId IS NOT NULL AND ((rl.ContractType = 'Operating' AND opc.ContractId IS NOT NULL) OR (rl.ContractType != 'Operating')) THEN rl.ETC_GL - (etc.ActiveAssets_ETCAmount_LC_Table + etc.ActiveAssets_ETCAmount_NLC_Table) - etc.PaidOffAssets_SoldETCAmount_Table ELSE 0.00 END) PaidOffAssets_ETC_Table
					, ISNULL(SUM(fco.FinanceChargeOffAmount),0.00) AS FinanceChargeOffAmount_Table
                FROM #ResultList rl
					LEFT JOIN #SyndicationLeaseAssetReturnedToInventory sa ON rl.ContractId = sa.ContractId
					LEFT JOIN #PayoffAmort_Table opp ON opp.ContractId = rl.ContractId
					LEFT JOIN #AmortizeContract al ON al.ContractId = rl.ContractId
					LEFT JOIN #OperatingPaidOffContract opc ON opc.ContractId = rl.ContractId
					LEFT JOIN #CapitalPaidOffContract cpc ON cpc.ContractId = rl.ContractId
					LEFT JOIN #ETCAmort_Table etc ON etc.ContractId = rl.ContractId
					LEFT JOIN #ChargeOff co ON co.ContractId = rl.ContractId
					LEFT JOIN #HaveCapitalLeaseLEInfo cle ON cle.LegalEntityName = rl.LegalEntityName
					LEFT JOIN #OperatingInventory oi ON oi.ContractId = rl.ContractId
					LEFT JOIN #PayoffandSynContract pos ON pos.ContractId = rl.ContractId
					LEFT JOIN #AmortChargeOffInfo aci ON aci.ContractId = rl.ContractId
					LEFT JOIN #ImpairmentOnPayoff iop ON iop.ContractId = rl.ContractId
					LEFT JOIN #PaidOffNotCOAmountInfo poc ON poc.ContractId = rl.ContractId
					LEFT JOIN #FinanceChargeOffAmount_Info fco ON fco.ContractId = rl.ContractId
					LEFT JOIN #PayoffNoCOTrueClearedAmount ptd ON ptd.ContractId = rl.ContractId
					LEFT JOIN #PayoffNoCOTrueClearedAssetImpairmentAmount pti ON pti.ContractId = rl.ContractId
                GROUP BY rl.LegalEntityName;
			END;

DROP TABLE #EligibleContracts
DROP TABLE #OverTerm
DROP TABLE #ChargeOff
DROP TABLE #AmendmentList
DROP TABLE #ClearedFixedTermAVHIncomeDate
DROP TABLE #PayOffDetails
DROP TABLE #OTPReclass
DROP TABLE #FullPaidOffContracts
DROP TABLE #SyndicationAVHInfo
DROP TABLE #RenewalDetails
DROP TABLE #ReclassDetails
DROP TABLE #LeaseAssetValues
DROP TABLE #LeaseAssetSkus
DROP TABLE #GLDetails
DROP TABLE #NotCleared
DROP TABLE #ChargedOffAssets
DROP TABLE #ClearedAVHIncomeDate
DROP TABLE #NBVAssetValueHistoriesInfo
DROP TABLE #LeasedAssetReturnedtoInventory
DROP TABLE #LeasedAssetReturnedtoInventorySKUs
DROP TABLE #ClearedFixedTermAVHIncomeDateCO
DROP TABLE #Payoffs
DROP TABLE #MaxCleared
DROP TABLE #MinCleared
DROP TABLE #ContractSummary
DROP TABLE #Cleared_AssetImpairment
DROP TABLE #Cleared_NBVImpairment
DROP TABLE #ClearedAVHIncomeDateForImpairment
DROP TABLE #ClearedAVHIncomeDateForNBVImpairment
DROP TABLE #NBVImpairment
DROP TABLE #AssetDepreciation
DROP TABLE #ClearedOTPAmount
DROP TABLE #LastRecordAVHForPayoff
DROP TABLE #ClearedAssetDepreciationAmount
DROP TABLE #AssetDepreciationAmount
DROP TABLE #SyndicationAssetDepreciationAmount
DROP TABLE #ClearedAssetDepreciation
DROP TABLE #PreviousContact
DROP TABLE #LeaseFinanceIdBeforeRenewal
DROP TABLE #RenewalLeaseAssetValues
DROP TABLE #RenewalLeaseAssetSkus
DROP TABLE #PayoffAssetDetails
DROP TABLE #ClearedAssetImpairment
DROP TABLE #ClearedNBVImpairment
DROP TABLE #AssetImpairment
DROP TABLE #MaxBookValueAdjustment
DROP TABLE #TrueClearedAmount
DROP TABLE #MaxCleared_TrueCleared
DROP TABLE #MinCleared_TrueCleared
DROP TABLE #OTPDepreciationExists
DROP TABLE #TrueClearedAssetImpairmentAmount
DROP TABLE #ContractETCAmount
DROP TABLE #RebookContractETCAmount
DROP TABLE #RebookContractSKUETCAmount
DROP TABLE #CapitalizedAmounts
DROP TABLE #RenewalCapitalizedAmounts
DROP TABLE #LeaseAmendmentInfo
DROP TABLE #LeaseFinanceForOTPReclass
DROP TABLE #Impairment_Asset
DROP TABLE #AVHChargeoff
DROP TABLE #SyndicatedPayoffAmount
DROP TABLE #SyndicationLeaseAssetReturnedToInventory
DROP TABLE #PayoffAmort_Table
DROP TABLE #PaidOffNotCOAmountInfo
DROP TABLE #FinanceChargeOffAmount_Info
DROP TABLE #ETCAmort_Table
DROP TABLE #AmortizeContract
DROP TABLE #OperatingPaidOffContract
DROP TABLE #OperatingPaidOffContractSKU
DROP TABLE #CapitalPaidOffContract
DROP TABLE #OperatingInventory
DROP TABLE #PayoffandSynContract
DROP TABLE #AmortChargeOffInfo
DROP TABLE #AccumulatedNotClearedPayoff
DROP TABLE #ImpairmentOnPayoff
DROP TABLE #HaveCapitalLeaseLEInfo
DROP TABLE #RenewalPaidOffInventory
DROP TABLE #PayoffNoCOTrueClearedAmount
DROP TABLE #PayoffNoCOTrueClearedAssetImpairmentAmount
DROP TABLE #ResultList
    END;

GO
