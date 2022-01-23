SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_ScheduledPayment_HealthCheck]
(
	@ResultOption NVARCHAR(20),
	@LegalEntityIds ReconciliationId READONLY,
	@ContractIds ReconciliationId READONLY,  
	@CustomerIds ReconciliationId READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

IF OBJECT_ID('tempdb..#EligibleContracts') IS NOT NULL
DROP TABLE #EligibleContracts;

IF OBJECT_ID('tempdb..#HasFinanceAsset') IS NOT NULL
DROP TABLE #HasFinanceAsset;

IF OBJECT_ID('tempdb..#FullPaidOffContracts') IS NOT NULL
DROP TABLE #FullPaidOffContracts;

IF OBJECT_ID('tempdb..#OverTerm') IS NOT NULL
DROP TABLE #OverTerm;

IF OBJECT_ID('tempdb..#RenewalContracts') IS NOT NULL
DROP TABLE #RenewalContracts;

IF OBJECT_ID('tempdb..#ReceivableAmount') IS NOT NULL
DROP TABLE #ReceivableAmount;

IF OBJECT_ID('tempdb..#PaymentAmount') IS NOT NULL
DROP TABLE #PaymentAmount;

IF OBJECT_ID('tempdb..#LeaseAssetInfo') IS NOT NULL
DROP TABLE #LeaseAssetInfo;

IF OBJECT_ID('tempdb..#LeaseAssets') IS NOT NULL
DROP TABLE #LeaseAssets;

IF OBJECT_ID('tempdb..#LeaseAssetSKUs') IS NOT NULL
DROP TABLE #LeaseAssetSKUs;

IF OBJECT_ID('tempdb..#InterimPaymentAmount') IS NOT NULL
DROP TABLE #InterimPaymentAmount;

IF OBJECT_ID('tempdb..#IncomeSchPaymentAmount') IS NOT NULL
DROP TABLE #IncomeSchPaymentAmount;

IF OBJECT_ID('tempdb..#LessorOwnedCount') IS NOT NULL
DROP TABLE #LessorOwnedCount;

IF OBJECT_ID('tempdb..#NonLessorOwnedIncomeSchPaymentAmount') IS NOT NULL
DROP TABLE #NonLessorOwnedIncomeSchPaymentAmount;

IF OBJECT_ID('tempdb..#ContractCount') IS NOT NULL
DROP TABLE #ContractCount;

IF OBJECT_ID('tempdb..#ServicingDetails') IS NOT NULL
DROP TABLE #ServicingDetails;

IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
DROP TABLE #ResultList;

IF OBJECT_ID('tempdb..#SchedulePaymentSummary') IS NOT NULL
DROP TABLE #SchedulePaymentSummary;

CREATE TABLE #LeaseAssets
(ContractId                                     BIGINT NOT NULL,
 BookedResidualAmount                           DECIMAL (16, 2) NOT NULL,
 ThirdPartyGuaranteedResidualAmount             DECIMAL (16, 2) NOT NULL,
 CustomerGuaranteedResidualAmount               DECIMAL (16, 2) NOT NULL,
 LeaseAssetBookedResidualAmount                 DECIMAL (16, 2) NOT NULL,
 FinanceAssetBookedResidualAmount               DECIMAL (16, 2) NOT NULL,
 LeaseAssetThirdPartyGuaranteedResidualAmount   DECIMAL (16, 2) NOT NULL,
 FinanceAssetThirdPartyGuaranteedResidualAmount DECIMAL (16, 2) NOT NULL,
 LeaseAssetCustomerGuaranteedResidualAmount     DECIMAL (16, 2) NOT NULL,
 FinanceAssetCustomerGuaranteedResidualAmount   DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #LeaseAssetSKUs
(ContractId                                     BIGINT NOT NULL,
 BookedResidualAmount                           DECIMAL (16, 2) NOT NULL,
 ThirdPartyGuaranteedResidualAmount             DECIMAL (16, 2) NOT NULL,
 CustomerGuaranteedResidualAmount               DECIMAL (16, 2) NOT NULL,
 LeaseAssetBookedResidualAmount                 DECIMAL (16, 2) NOT NULL,
 FinanceAssetBookedResidualAmount               DECIMAL (16, 2) NOT NULL,
 LeaseAssetThirdPartyGuaranteedResidualAmount   DECIMAL (16, 2) NOT NULL,
 FinanceAssetThirdPartyGuaranteedResidualAmount DECIMAL (16, 2) NOT NULL,
 LeaseAssetCustomerGuaranteedResidualAmount     DECIMAL (16, 2) NOT NULL,
 FinanceAssetCustomerGuaranteedResidualAmount   DECIMAL (16, 2) NOT NULL
);

DECLARE @u_ConversionSource nvarchar(50); 
SELECT @u_ConversionSource = Value FROM GlobalParameters WHERE Category ='Migration' AND Name = 'ConversionSource';
DECLARE @DeferInterimInterestSingleInstallment nvarchar(6);
SELECT @DeferInterimInterestSingleInstallment = ISNULL(VALUE,'FALSE') FROM GlobalParameters WHERE Name = 'DeferInterimInterestIncomeRecognitionForSingleInstallment';
DECLARE @DeferInterimRentSingleInstallment nvarchar(6);
SELECT @DeferInterimRentSingleInstallment = ISNULL(VALUE,'FALSE') FROM GlobalParameters WHERE Name = 'DeferInterimRentIncomeRecognitionForSingleInstallment';
DECLARE @DeferInterimInterest nvarchar(6);
SELECT @DeferInterimInterest = ISNULL(VALUE,'FALSE') FROM GlobalParameters WHERE Name = 'DeferInterimInterestIncomeRecognition';
DECLARE @DeferInterimRent nvarchar(6);
SELECT @DeferInterimRent = ISNULL(VALUE,'FALSE') FROM GlobalParameters WHERE Name = 'DeferInterimRentIncomeRecognition';

DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)
DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0)
DECLARE @True BIT = 1;
DECLARE @False BIT = 1;
DECLARE @All NVARCHAR(20) = 'All'
DECLARE @Passed NVARCHAR(20) = 'Passed'
DECLARE @Failed NVARCHAR(20) = 'Failed'

DECLARE @IsSku BIT= 0;
DECLARE @Sql NVARCHAR(MAX)= ''; 
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
	SET @IsSku = 1;
END;
 
SELECT 
	c.Id AS ContractId
	,c.SequenceNumber AS SequenceNumber
	,c.Alias AS ContractAlias
	,c.u_ConversionSource
	,c.AccountingStandard
	,c.Status
	,lf.Id AS LeaseFinanceId
	,rft.Id AS ReceivableForTransfersId
	,lf.CustomerId AS CustomerId
	,lf.LegalEntityId AS LegalEntityId
	,lfd.CommencementDate AS CommencementDate
	,lfd.MaturityDate AS MaturityDate
	,lf.HoldingStatus AS HoldingStatus
	,lfd.IsOverTermLease AS IsOverTermLease
	,lf.IsCurrent AS IsCurrent
	,lfd.LeaseContractType
	,lfd.IsAdvance
	,lfd.InterimAssessmentMethod
	,lfd.InterimInterestBillingType
	,lfd.InterimRentBillingType
	,lfd.BillInterimAsOf
	,lfd.InterimPaymentFrequency
	,lfd.IsInterimRentInAdvance
	,lfd.DueDay
	,lfd.PaymentFrequency
	,rft.ReceivableForTransferType As ReceivableForTransferType
	,ISNULL(rft.RetainedPercentage,0.00) AS RetainedPercentage
	,ISNULL(('100'-rft.RetainedPercentage),0.00) AS ParticipationPercentage
	,rft.EffectiveDate AS SyndicationDate
	,CASE
		WHEN rft.Id IS NULL
		THEN 'NA'
		WHEN rft.Id IS NOT NULL AND lfd.CommencementDate = rft.EffectiveDate
		THEN 'True'
		ELSE 'False'
	END [SyndicatedAtInception]
	INTO #EligibleContracts
	FROM Contracts c
		INNER JOIN LeaseFinances lf ON lf.ContractId = c.Id
			AND lf.IsCurrent = 1
		INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id 
			AND c.Status NOT IN ('InstallingAssets','Pending','Inactive','Terminated')
		INNER JOIN LegalEntities le ON le.Id = lf.LegalEntityId
		LEFT JOIN ReceivableForTransfers rft ON rft.ContractId = c.Id 
			AND rft.ApprovalStatus = 'Approved'
			WHERE (@LegalEntitiesCount = 0 OR (@LegalEntitiesCount > 0 AND lf.LegalEntityId in (SELECT Id FROM @LegalEntityIds)))
		      AND (@CustomersCount = 0 OR (@CustomersCount > 0 AND lf.CustomerId in (SELECT Id FROM @CustomerIds)))
			  AND (@ContractsCount = 0 OR (@ContractsCount > 0 AND lf.ContractId in (SELECT Id FROM @ContractIds)));

CREATE NONCLUSTERED INDEX IX_Id ON #EligibleContracts(ContractId);

SELECT DISTINCT
	ec.ContractId
	INTO #HasFinanceAsset
	FROM #EligibleContracts ec
		JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
	WHERE la.IsLeaseAsset = 0
GROUP BY ec.ContractId;

SELECT 
	ec.ContractId
	,p.PayoffEffectiveDate
	,CASE WHEN p.PayoffEffectiveDate < lfd.MaturityDate THEN 'Yes' ELSE 'No' END [FullPayoffEarlyTerminatedContract]
	INTO #FullPaidOffContracts
	FROM #EligibleContracts ec
		INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
			AND p.Status = 'Activated'
			AND p.FullPayoff = 1;

SELECT 
	ec.ContractId
	INTO #OverTerm
	FROM #EligibleContracts ec
		INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = ec.LeaseFinanceId
	WHERE lis.IncomeType = 'OverTerm'
		AND lis.IsSchedule = 1
GROUP BY ec.ContractId;

SELECT
	ec.ContractId,lfd.CommencementDate
	INTO #RenewalContracts
	FROM LeaseAmendments la
		JOIN LeaseFinanceDetails lfd ON la.CurrentLeaseFinanceId = lfd.Id
		JOIN LeaseFinances lf ON lfd.Id = lf.Id
		JOIN #EligibleContracts ec ON lf.ContractId = ec.ContractId
	WHERE la.AmendmentType = 'Renewal'
		AND la.LeaseAmendmentStatus = 'Approved';

SELECT
	ec.ContractId
	,SUM(
		CASE WHEN r.FunderId IS NOT NULL THEN
			CASE WHEN rnc.ContractId IS NULL
				THEN r.TotalAmount_Amount
			WHEN rnc.ContractId IS NOT NULL AND lps.StartDate >= rnc.CommencementDate
				THEN r.TotalAmount_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END) [NonLessorOwnedReceivableAmount]
	,SUM(
		CASE WHEN r.FunderId IS NULL THEN
			CASE WHEN rnc.ContractId IS NULL
				THEN r.TotalAmount_Amount
			WHEN rnc.ContractId IS NOT NULL AND lps.StartDate >= rnc.CommencementDate
				THEN r.TotalAmount_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END) [LessorOwnedReceivableAmount]
	,SUM(
		CASE WHEN rnc.ContractId IS NULL
				THEN r.TotalAmount_Amount
			WHEN rnc.ContractId IS NOT NULL AND lps.StartDate >= rnc.CommencementDate
				THEN r.TotalAmount_Amount
		ELSE 0.00
		END) [ReceivableAmount]
	INTO #ReceivableAmount
	FROM #EligibleContracts ec
		INNER JOIN Receivables r ON ec.ContractId = r.EntityId 
			AND r.EntityType = 'CT' 
			AND r.IsActive = 1
		INNER JOIN ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
		INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
			AND rt.Name IN ('CapitalLeaseRental','OperatingLeaseRental')
		INNER JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId
		LEFT JOIN #RenewalContracts rnc ON rnc.ContractId = ec.ContractId
GROUP BY ec.ContractId;

SELECT 
	ec.ContractId
	,SUM(lps.Amount_Amount) [PaymentAmount]
	INTO #PaymentAmount
	FROM #EligibleContracts ec
		JOIN LeasePaymentSchedules lps ON ec.LeaseFinanceId = lps.LeaseFinanceDetailId
			AND lps.IsActive = 1
			AND lps.PaymentType IN ('FixedTerm','DownPayment','MaturityPayment')
GROUP BY ec.ContractId;

SELECT
	ec.ContractId
	,la.Id AS LeaseAssetId
	,la.AssetId
	,la.TerminationDate
	,la.IsActive
	,la.IsLeaseAsset
	,lfd.MaturityDate
	,CAST (0 AS BIT) AS IsSKU
	,la.BookedResidual_Amount
	,la.ThirdPartyGuaranteedResidual_Amount
	,la.CustomerGuaranteedResidual_Amount
INTO #LeaseAssetInfo
FROM #EligibleContracts ec
	INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
	INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
	INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
		AND lf.IsCurrent = 1;

IF @IsSku = 1
BEGIN
SET @Sql = '
UPDATE lai
SET lai.IsSKU = 1
FROM #LeaseAssetInfo lai
INNER JOIN Assets a ON lai.AssetId = a.Id AND a.IsSKU = 1'
INSERT INTO #LeaseAssetInfo
EXEC (@Sql)
END;

INSERT INTO #LeaseAssets
SELECT ec.ContractId AS ContractId
	,SUM(
		CASE 
			WHEN lai.IsActive = 1 
			THEN lai.BookedResidual_Amount
			WHEN lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate 
			THEN lai.BookedResidual_Amount
			ELSE 0
		END
	) [BookedResidualAmount]
	,SUM(
		CASE 
			WHEN lai.IsActive = 1 
			THEN lai.ThirdPartyGuaranteedResidual_Amount
			WHEN lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate 
			THEN lai.ThirdPartyGuaranteedResidual_Amount
			ELSE 0
		END
	) [ThirdPartyGuaranteedResidualAmount]
	,SUM(
		CASE 
			WHEN lai.IsActive = 1 
			THEN lai.CustomerGuaranteedResidual_Amount
			WHEN lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate 
			THEN lai.CustomerGuaranteedResidual_Amount
			ELSE 0
		END
	) [CustomerGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN lai.IsLeaseAsset = 1 AND lai.IsActive = 1
			THEN lai.BookedResidual_Amount
			WHEN lai.IsLeaseAsset = 1 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN lai.BookedResidual_Amount
			ELSE 0
		END
	) [LeaseAssetBookedResidualAmount]
	,SUM(
		CASE
			WHEN lai.IsLeaseAsset = 0 AND lai.IsActive = 1
			THEN lai.BookedResidual_Amount
			WHEN lai.IsLeaseAsset = 0 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN lai.BookedResidual_Amount
			ELSE 0
		END
	) [FinanceAssetBookedResidualAmount]
	,SUM(
		CASE
			WHEN lai.IsLeaseAsset = 1 AND lai.IsActive = 1
			THEN lai.ThirdPartyGuaranteedResidual_Amount
			WHEN lai.IsLeaseAsset = 1 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN lai.ThirdPartyGuaranteedResidual_Amount
			ELSE 0
		END
	) [LeaseAssetThirdPartyGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN lai.IsLeaseAsset = 0 AND lai.IsActive = 1
			THEN lai.ThirdPartyGuaranteedResidual_Amount
			WHEN lai.IsLeaseAsset = 0 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN lai.ThirdPartyGuaranteedResidual_Amount
			ELSE 0
		END
	) [FinanceAssetThirdPartyGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN lai.IsLeaseAsset = 1 AND lai.IsActive = 1
			THEN lai.CustomerGuaranteedResidual_Amount
			WHEN lai.IsLeaseAsset = 1 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN lai.CustomerGuaranteedResidual_Amount
			ELSE 0
		END
	) [LeaseAssetCustomerGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN lai.IsLeaseAsset = 0 AND lai.IsActive = 1
			THEN lai.CustomerGuaranteedResidual_Amount
			WHEN lai.IsLeaseAsset = 0 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN lai.CustomerGuaranteedResidual_Amount
			ELSE 0
		END
	) [FinanceAssetCustomerGuaranteedResidualAmount]
FROM #EligibleContracts ec
	INNER JOIN #LeaseAssetInfo lai ON ec.ContractId = lai.ContractId
WHERE lai.IsSKU = 0
GROUP BY ec.ContractId;

IF @IsSKU = 1
BEGIN
SET @Sql = '
SELECT ec.ContractId AS ContractId
	,SUM(
		CASE 
			WHEN lai.IsActive = 1 
			THEN las.BookedResidual_Amount
			WHEN lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate 
			THEN las.BookedResidual_Amount
			ELSE 0
		END
	) [BookedResidualAmount]
	,SUM(
		CASE 
			WHEN lai.IsActive = 1 
			THEN las.ThirdPartyGuaranteedResidual_Amount
			WHEN lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate 
			THEN las.ThirdPartyGuaranteedResidual_Amount
			ELSE 0
		END
	) [ThirdPartyGuaranteedResidualAmount]
	,SUM(
		CASE 
			WHEN lai.IsActive = 1 
			THEN las.CustomerGuaranteedResidual_Amount
			WHEN lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate 
			THEN las.CustomerGuaranteedResidual_Amount
			ELSE 0
		END
	) [CustomerGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN las.IsLeaseComponent = 1 AND lai.IsActive = 1
			THEN las.BookedResidual_Amount
			WHEN las.IsLeaseComponent = 1 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN las.BookedResidual_Amount
			ELSE 0
		END
	) [LeaseAssetBookedResidualAmount]
	,SUM(
		CASE
			WHEN las.IsLeaseComponent = 0 AND lai.IsActive = 1
			THEN las.BookedResidual_Amount
			WHEN las.IsLeaseComponent = 0 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN las.BookedResidual_Amount
			ELSE 0
		END
	) [FinanceAssetBookedResidualAmount]
	,SUM(
		CASE
			WHEN las.IsLeaseComponent = 1 AND lai.IsActive = 1
			THEN las.ThirdPartyGuaranteedResidual_Amount
			WHEN las.IsLeaseComponent = 1 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN las.ThirdPartyGuaranteedResidual_Amount
			ELSE 0
		END
	) [LeaseAssetThirdPartyGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN las.IsLeaseComponent = 0 AND lai.IsActive = 1
			THEN las.ThirdPartyGuaranteedResidual_Amount
			WHEN las.IsLeaseComponent = 0 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN las.ThirdPartyGuaranteedResidual_Amount
			ELSE 0
		END
	) [FinanceAssetThirdPartyGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN las.IsLeaseComponent = 1 AND lai.IsActive = 1
			THEN las.CustomerGuaranteedResidual_Amount
			WHEN las.IsLeaseComponent = 1 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN las.CustomerGuaranteedResidual_Amount
			ELSE 0
		END
	) [LeaseAssetCustomerGuaranteedResidualAmount]
	,SUM(
		CASE
			WHEN las.IsLeaseComponent = 0 AND lai.IsActive = 1
			THEN las.CustomerGuaranteedResidual_Amount
			WHEN las.IsLeaseComponent = 0 AND lai.IsActive = 0 AND lai.TerminationDate >= lai.MaturityDate
			THEN las.CustomerGuaranteedResidual_Amount
			ELSE 0
		END
	) [FinanceAssetCustomerGuaranteedResidualAmount]
FROM #EligibleContracts ec
	INNER JOIN #LeaseAssetInfo lai ON ec.ContractId = lai.ContractId
	INNER JOIN LeaseAssetSKUs las ON lai.LeaseAssetId = las.LeaseAssetId
WHERE lai.IsSKU = 1
GROUP BY ec.ContractId;'
INSERT INTO #LeaseAssetSKUs
EXEC (@Sql)
END

MERGE #LeaseAssets la
USING (SELECT * FROM #LeaseAssetSKUs) las
ON (la.ContractId = las.ContractId)
	WHEN MATCHED
	THEN
	UPDATE SET la.BookedResidualAmount += las.BookedResidualAmount
			   ,la.ThirdPartyGuaranteedResidualAmount += las.ThirdPartyGuaranteedResidualAmount
			   ,la.CustomerGuaranteedResidualAmount += las.CustomerGuaranteedResidualAmount
			   ,la.LeaseAssetBookedResidualAmount += las.LeaseAssetBookedResidualAmount
			   ,la.FinanceAssetBookedResidualAmount += las.FinanceAssetBookedResidualAmount
			   ,la.LeaseAssetThirdPartyGuaranteedResidualAmount += las.LeaseAssetThirdPartyGuaranteedResidualAmount
			   ,la.FinanceAssetThirdPartyGuaranteedResidualAmount += las.FinanceAssetThirdPartyGuaranteedResidualAmount
			   ,la.LeaseAssetCustomerGuaranteedResidualAmount += las.LeaseAssetCustomerGuaranteedResidualAmount
			   ,la.FinanceAssetCustomerGuaranteedResidualAmount += las.FinanceAssetCustomerGuaranteedResidualAmount
	WHEN NOT MATCHED
	THEN
	INSERT (ContractId
		,BookedResidualAmount
		,ThirdPartyGuaranteedResidualAmount
		,CustomerGuaranteedResidualAmount
		,LeaseAssetBookedResidualAmount
		,FinanceAssetBookedResidualAmount
		,LeaseAssetThirdPartyGuaranteedResidualAmount
		,FinanceAssetThirdPartyGuaranteedResidualAmount
		,LeaseAssetCustomerGuaranteedResidualAmount
		,FinanceAssetCustomerGuaranteedResidualAmount
		)
	VALUES (las.ContractId
		,las.BookedResidualAmount
		,las.ThirdPartyGuaranteedResidualAmount
		,las.CustomerGuaranteedResidualAmount
		,las.LeaseAssetBookedResidualAmount
		,las.FinanceAssetBookedResidualAmount
		,las.LeaseAssetThirdPartyGuaranteedResidualAmount
		,las.FinanceAssetThirdPartyGuaranteedResidualAmount
		,las.LeaseAssetCustomerGuaranteedResidualAmount
		,las.FinanceAssetCustomerGuaranteedResidualAmount
		);

SELECT 
	ec.ContractId
	,SUM(CASE WHEN lis.IncomeType IN ('InterimInterest') 
		AND (lfd.InterimAssessmentMethod = 'Both' OR lfd.InterimAssessmentMethod = 'Interest')
		AND lfd.InterimInterestBillingType != 'Capitalize'
	THEN lis.Payment_Amount + lis.FinancePayment_Amount
	ELSE 0.00
	END) [InterimInterestPaymentAmount]
	,SUM(CASE WHEN lis.IncomeType IN ('InterimRent')
		AND (lfd.InterimAssessmentMethod = 'Both' OR lfd.InterimAssessmentMethod = 'Rent')
		AND lfd.InterimRentBillingType != 'Capitalize' 
	THEN lis.Payment_Amount + lis.FinancePayment_Amount 
	ELSE 0.00 END) [InterimRentPaymentAmount]
	INTO #InterimPaymentAmount
	FROM #EligibleContracts ec
		JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		JOIN LeaseIncomeSchedules lis ON lf.Id = lis.LeaseFinanceId
			AND lis.IsSchedule = 1
			AND lis.AdjustmentEntry = 0 
			AND lis.IsLessorOwned = 1
GROUP BY ec.ContractId;

SELECT
	ec.ContractId
	,SUM(CASE WHEN lis.IsLessorOwned = 1 THEN
			CASE 
				WHEN rnc.ContractId IS NULL THEN lis.Payment_Amount
				WHEN rnc.ContractId IS NOT NULL AND lis.IncomeDate >= rnc.CommencementDate THEN lis.Payment_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END) 
	+ SUM(CASE WHEN lis.IsLessorOwned = 1 THEN
			CASE 
				WHEN rnc.ContractId IS NULL THEN lis.FinancePayment_Amount
				WHEN rnc.ContractId IS NOT NULL AND lis.IncomeDate >= rnc.CommencementDate THEN lis.FinancePayment_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END) [LessorOwnedIncomeSchPaymentAmount]
	,CASE WHEN ec.ReceivableForTransfersId IS NOT NULL 
	THEN (SUM(CASE WHEN lis.IsLessorOwned = 0 THEN
			CASE 
				WHEN rnc.ContractId IS NULL THEN lis.Payment_Amount
				WHEN rnc.ContractId IS NOT NULL AND lis.IncomeDate >= rnc.CommencementDate THEN lis.Payment_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END) 
		+ SUM(CASE WHEN lis.IsLessorOwned = 0 THEN
			CASE 
				WHEN rnc.ContractId IS NULL THEN lis.FinancePayment_Amount
				WHEN rnc.ContractId IS NOT NULL AND lis.IncomeDate >= rnc.CommencementDate THEN lis.FinancePayment_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END))
	ELSE (SUM(CASE WHEN lis.IsLessorOwned = 1 THEN
			CASE 
				WHEN rnc.ContractId IS NULL THEN lis.Payment_Amount
				WHEN rnc.ContractId IS NOT NULL AND lis.IncomeDate >= rnc.CommencementDate THEN lis.Payment_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END) 
		+ SUM(CASE WHEN lis.IsLessorOwned = 1 THEN
			CASE 
				WHEN rnc.ContractId IS NULL THEN lis.FinancePayment_Amount
				WHEN rnc.ContractId IS NOT NULL AND lis.IncomeDate >= rnc.CommencementDate THEN lis.FinancePayment_Amount
			ELSE 0.00
			END
		ELSE 0.00
		END)) 
	END AS [IncomeSchPaymentAmount]
	INTO #IncomeSchPaymentAmount
	FROM #EligibleContracts ec
		JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		JOIN LeaseIncomeSchedules lis ON lf.Id = lis.LeaseFinanceId
			AND lis.IsSchedule = 1
			AND lis.IncomeType IN ('FixedTerm')
			AND lis.AdjustmentEntry = 0
		LEFT JOIN #RenewalContracts rnc ON rnc.ContractId = ec.ContractId
GROUP BY ec.ContractId,ec.ReceivableForTransfersId;

SELECT 
	ec.ContractId as ContractId
	,ISNULL(COUNT(DISTINCT lis.Id),0) as LessorOwnedCount 
	INTO #LessorOwnedCount
	FROM #EligibleContracts ec
		JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
		LEFT JOIN LeaseIncomeSchedules lis ON lf.Id = lis.LeaseFinanceId
			AND lis.IsSchedule = 1
			AND lis.IncomeType IN ('FixedTerm')
			AND lis.AdjustmentEntry = 0
			AND lis.IsLessorOwned = 1
GROUP BY ec.ContractId
HAVING ISNULL(COUNT(DISTINCT lis.Id),0) = 0
ORDER BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_Id ON #IncomeSchPaymentAmount(ContractId); 
CREATE NONCLUSTERED INDEX IX_Id ON #InterimPaymentAmount(ContractId);  
CREATE NONCLUSTERED INDEX IX_Id ON #LessorOwnedCount(ContractId); 

UPDATE isp
	SET LessorOwnedIncomeSchPaymentAmount = 
	(CASE WHEN lc.ContractId IS NULL
	THEN isp.LessorOwnedIncomeSchPaymentAmount - ISNULL(ipa.InterimRentPaymentAmount,0.00)
	ELSE isp.LessorOwnedIncomeSchPaymentAmount
	END)
	,IncomeSchPaymentAmount = isp.IncomeSchPaymentAmount - ISNULL(ipa.InterimRentPaymentAmount,0.00)
	FROM #IncomeSchPaymentAmount isp
		INNER JOIN #EligibleContracts ec ON ec.ContractId = isp.ContractId
		LEFT JOIN #InterimPaymentAmount ipa ON ec.ContractId = ipa.ContractId
		LEFT JOIN #LessorOwnedCount lc ON ec.ContractId = lc.ContractId
	WHERE (ec.InterimAssessmentMethod = 'Rent'
		AND ((ec.InterimRentBillingType = 'SingleInstallment' AND @DeferInterimRentSingleInstallment = 'True')
			OR (ec.InterimRentBillingType IN ('Periodic','Capitalize') AND @DeferInterimRent = 'True')))
		OR
		(ec.InterimAssessmentMethod = 'Both'
		AND ((ec.InterimInterestBillingType = 'SingleInstallment' AND @DeferInterimInterestSingleInstallment= 'False'
				AND ec.InterimRentBillingType = 'SingleInstallment' AND @DeferInterimRentSingleInstallment = 'True')
			OR (ec.InterimInterestBillingType = 'SingleInstallment' AND @DeferInterimInterestSingleInstallment = 'False'
				AND ec.InterimRentBillingType IN ('Periodic','Capitalize') AND @DeferInterimRent = 'True')
			OR (ec.InterimInterestBillingType IN ('Periodic','Capitalize') AND @DeferInterimInterest = 'False'
				AND ec.InterimRentBillingType = 'SingleInstallment' AND @DeferInterimRentSingleInstallment = 'True')
			OR (ec.InterimInterestBillingType IN ('Periodic','Capitalize') AND @DeferInterimInterest = 'False')
				AND ec.InterimRentBillingType IN ('Periodic','Capitalize') AND @DeferInterimRent = 'True'));

UPDATE isp
	SET LessorOwnedIncomeSchPaymentAmount = 
	(CASE WHEN lc.ContractId IS NULL
	THEN isp.LessorOwnedIncomeSchPaymentAmount - ISNULL(ipa.InterimInterestPaymentAmount,0.00)
	ELSE isp.LessorOwnedIncomeSchPaymentAmount
	END)
	,IncomeSchPaymentAmount = isp.IncomeSchPaymentAmount - ISNULL(ipa.InterimInterestPaymentAmount,0.00)
	FROM #IncomeSchPaymentAmount isp
		INNER JOIN #EligibleContracts ec ON ec.ContractId = isp.ContractId
		LEFT JOIN #InterimPaymentAmount ipa ON ec.ContractId = ipa.ContractId
		LEFT JOIN #LessorOwnedCount lc ON ec.ContractId = lc.ContractId
	WHERE (ec.InterimAssessmentMethod = 'Interest'
		AND ((ec.InterimInterestBillingType = 'SingleInstallment' AND @DeferInterimInterestSingleInstallment = 'True')
			OR (ec.InterimInterestBillingType IN ('Periodic','Capitalize') AND @DeferInterimInterest = 'True')))
		OR
		(ec.InterimAssessmentMethod = 'Both'
		AND ((ec.InterimInterestBillingType = 'SingleInstallment' AND @DeferInterimInterestSingleInstallment= 'True'
				AND ec.InterimRentBillingType = 'SingleInstallment' AND @DeferInterimRentSingleInstallment = 'False')
			OR (ec.InterimInterestBillingType = 'SingleInstallment' AND @DeferInterimInterestSingleInstallment = 'True'
				AND ec.InterimRentBillingType IN ('Periodic','Capitalize') AND @DeferInterimRent = 'False')
			OR (ec.InterimInterestBillingType IN ('Periodic','Capitalize') AND @DeferInterimInterest = 'True'
				AND ec.InterimRentBillingType = 'SingleInstallment' AND @DeferInterimRentSingleInstallment = 'False')
			OR (ec.InterimInterestBillingType IN ('Periodic','Capitalize') AND @DeferInterimInterest = 'True')
				AND ec.InterimRentBillingType IN ('Periodic','Capitalize') AND @DeferInterimRent = 'False'));

UPDATE isp
	SET LessorOwnedIncomeSchPaymentAmount = 
	(CASE WHEN lc.ContractId IS NULL
	THEN isp.LessorOwnedIncomeSchPaymentAmount - ISNULL(ipa.InterimRentPaymentAmount,0.00) - ISNULL(ipa.InterimInterestPaymentAmount,0.00)
	ELSE isp.LessorOwnedIncomeSchPaymentAmount
	END)
	,IncomeSchPaymentAmount = isp.IncomeSchPaymentAmount - ISNULL(ipa.InterimRentPaymentAmount,0.00) - ISNULL(ipa.InterimInterestPaymentAmount,0.00)
	FROM #IncomeSchPaymentAmount isp
		INNER JOIN #EligibleContracts ec ON ec.ContractId = isp.ContractId
		LEFT JOIN #InterimPaymentAmount ipa ON ec.ContractId = ipa.ContractId
		LEFT JOIN #LessorOwnedCount lc ON ec.ContractId = lc.ContractId
	WHERE ec.InterimAssessmentMethod = 'Both'
		AND ((ec.InterimInterestBillingType = 'SingleInstallment' AND @DeferInterimInterestSingleInstallment = 'True'
				AND ec.InterimRentBillingType = 'SingleInstallment' AND @DeferInterimRentSingleInstallment = 'True')
			OR (ec.InterimInterestBillingType = 'SingleInstallment' AND @DeferInterimInterestSingleInstallment = 'True'
				AND ec.InterimRentBillingType IN ('Periodic','Capitalize') AND @DeferInterimRent = 'True')
			OR (ec.InterimInterestBillingType IN ('Periodic','Capitalize') AND @DeferInterimInterest = 'True'
				AND ec.InterimRentBillingType = 'SingleInstallment' AND @DeferInterimRentSingleInstallment = 'True')
			OR (ec.InterimInterestBillingType IN ('Periodic','Capitalize') AND @DeferInterimInterest = 'True'
				AND ec.InterimRentBillingType IN ('Periodic','Capitalize') AND @DeferInterimRent = 'True'));

SELECT
	ec.ContractId
	,ISNULL(isp.IncomeSchPaymentAmount,0.00) - ISNULL(isp.LessorOwnedIncomeSchPaymentAmount,0.00) [NonLessorOwnedIncomeSchPaymentAmount]
	INTO #NonLessorOwnedIncomeSchPaymentAmount
	FROM #EligibleContracts ec
	   LEFT JOIN #IncomeSchPaymentAmount isp ON isp.ContractId = ec.ContractId
	WHERE ec.ReceivableForTransfersId IS NOT NULL;

SELECT 
	ec.ContractId as ContractId
	,COUNT(DISTINCT lf.ContractId) as ContractCount 
	INTO #ContractCount
	FROM Receivables r 
		INNER JOIN #EligibleContracts ec ON r.EntityId = ec.ContractId AND r.EntityType ='CT'
		INNER JOIN LeasePaymentSchedules lps ON lps.Id = r.PaymentScheduleId
			AND r.PaymentScheduleId IS NOT NULL
		INNER JOIN LeaseFinances lf ON lf.Id = lps.LeaseFinanceDetailId
		INNER JOIN ReceivableCodes rc ON rc.Id = r.ReceivableCodeId
		INNER JOIN ReceivableTypes rt ON rt.Id = rc.ReceivableTypeId
	WHERE rt.Name IN ('CapitalLeaseRental', 'OperatingLeaseRental')
GROUP BY ec.ContractId
HAVING COUNT(DISTINCT lf.ContractId) > 1;

SELECT 
	t.ContractId,t.IsServiced
	INTO #ServicingDetails
	FROM (
		SELECT 
			ec.ContractId
			,rfts.IsServiced
			,ROW_NUMBER() OVER(PARTITION BY ec.ReceivableForTransfersId ORDER BY rfts.EffectiveDate) AS rn
			FROM #EligibleContracts ec
				JOIN ReceivableForTransferServicings rfts ON rfts.ReceivableForTransferId = ec.ReceivableForTransfersId
					AND rfts.IsActive = 1
		) AS t
WHERE t.rn = 1;


SELECT *
	,CASE
		WHEN [BC] != 0.00
			OR [AC] != 0.00
			OR [BA] != 0.00
			OR [B1C1] != 0.00
			OR [B2C2] != 0.00
			OR [HasMultipleContractId] = 'Yes'
		THEN 'Problem Record'
		ELSE 'Not a Problem Record'
	END [Result]
	INTO #ResultList
	FROM
		(SELECT 
			  ec.ContractId [ContractId]
			  ,ec.SequenceNumber [SequenceNumber]
			  ,ec.ContractAlias [ContractAlias]
			  ,p.PartyName [CustomerName]
			  ,le.Name [LegalEntityName]
			  ,ec.HoldingStatus [HoldingStatus]
			  ,ec.AccountingStandard [AccountingStandard]
			  ,ec.LeaseContractType [LeaseContractType]
			  ,ec.Status [ContractStatus]
			  ,IIF(ec.u_conversionsource = u_ConversionSource, 'Yes', 'No') AS [IsMigrated]
			  ,IIF(hfa.ContractId IS NOT NULL, 'Yes', 'No')AS [HasFinanceAsset]
			  ,ec.ReceivableForTransferType [SyndicationType]
			  ,ec.RetainedPercentage [RetainedPercentage]
			  ,ec.ParticipationPercentage [ParticipationPercentage]
			  ,ec.SyndicatedAtInception [SyndicatedAtInception]
			  ,CASE
			  	WHEN ec.ReceivableForTransfersId IS NOT NULL AND sd.IsServiced = 1
			  	THEN 'Yes'
			  	WHEN ec.ReceivableForTransfersId IS NOT NULL AND sd.IsServiced = 0
			  	THEN 'No'
			  	ELSE 'NA'
			  END [ServicedContract]
			  ,ec.SyndicationDate [SyndicationDate]
			  ,ec.InterimAssessmentMethod [InterimAssessmentMethod]
			  ,ec.InterimInterestBillingType [InterimInterestBillingType]
			  ,ec.InterimRentBillingType [InterimRentBillingType]
			  ,ec.BillInterimAsOf [BillInterimAsOf]
			  ,ec.IsInterimRentInAdvance [InterimRentDueInAdvance]
			  ,ec.InterimPaymentFrequency [InterimPaymentFrequency]
			  ,ec.CommencementDate [CommencementDate]
			  ,ec.IsAdvance [FixedTermDueInAdvance]
			  ,ec.PaymentFrequency [PaymentFrequency]
			  ,ec.DueDay [DueDay]
			  ,ec.MaturityDate [MaturityDate]
			  ,IIF(ot.ContractId IS NULL, 'No', 'Yes') AS [OverTermLease]
			  ,ISNULL(la.BookedResidualAmount,0.00) [BookedResidualAmount]
			  ,ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) [ThirdPartyGuaranteedResidualAmount]
			  ,ISNULL(la.CustomerGuaranteedResidualAmount,0.00) [CustomerGuaranteedResidualAmount]
			  ,ISNULL(la.BookedResidualAmount,0.00) - ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.CustomerGuaranteedResidualAmount,0.00) [LessorRisk]
			  ,ISNULL(la.LeaseAssetBookedResidualAmount,0.00) [LeaseAssetBookedResidualAmount]
			  ,ISNULL(la.LeaseAssetThirdPartyGuaranteedResidualAmount,0.00) [LeaseAssetThirdPartyGuaranteedResidualAmount]
			  ,ISNULL(la.LeaseAssetCustomerGuaranteedResidualAmount,0.00) [LeaseAssetCustomerGuaranteedResidualAmount]
			  ,ISNULL(la.LeaseAssetBookedResidualAmount,0.00) - ISNULL(la.LeaseAssetThirdPartyGuaranteedResidualAmount,0.00) -ISNULL(LeaseAssetCustomerGuaranteedResidualAmount,0.00) [LeaseAssetLessorRisk]
			  ,ISNULL(la.FinanceAssetBookedResidualAmount,0.00) [FinanceAssetBookedResidualAmount]
			  ,ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) [FinanceAssetThirdPartyGuaranteedResidualAmount]
			  ,ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00) [FinanceAssetCustomerGuaranteedResidualAmount]
			  ,ISNULL(la.FinanceAssetBookedResidualAmount,0.00) - ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00) [FinanceAssetLessorRisk]
			  ,ISNULL(ipa.InterimInterestPaymentAmount,0.00) [InterimInterestPaymentAmount]
			  ,ISNULL(ipa.InterimRentPaymentAmount,0.00) [InterimRentPaymentAmount]
			  ,fpoc.PayoffEffectiveDate [FullPayoffEffectiveDate]
			  ,IIF(cc.ContractId IS NOT NULL, 'Yes', 'No') AS [HasMultipleContractId] 
			  ,ISNULL(pa.PaymentAmount,0.00) [PaymentSchedulesTotalFixedTermPaymentAmount]
			  ,ISNULL(ra.ReceivableAmount,0.00) [ReceivablesTotalFixedTermPaymentAmount]
			  ,CASE
			  	WHEN ec.LeaseContractType = 'Operating'
			  	THEN ISNULL(isp.IncomeSchPaymentAmount,0.00) - ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00)
			  	ELSE isp.IncomeSchPaymentAmount - ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.CustomerGuaranteedResidualAmount,0.00) 
			  END [IncomeSchedulesTotalFixedTermPaymentAmount]
			  ,ISNULL(ra.LessorOwnedReceivableAmount,0.00) [ReceivablesTotalLessorOwnedFixedTermPaymentAmount]
			  ,ISNULL(isp.LessorOwnedIncomeSchPaymentAmount,0.00) [IncomeSchedulesTotalLessorOwnedFixedTermPaymentAmount]
			  ,ISNULL(ra.NonLessorOwnedReceivableAmount,0.00) [ReceivablesTotalNonLessorOwnedFixedTermPaymentAmount]
			  ,ISNULL(nisp.NonLessorOwnedIncomeSchPaymentAmount,0.00) [IncomeSchedulesTotalNonLessorOwnedFixedTermPaymentAmount]
			  ,ISNULL(ra.ReceivableAmount,0.00) - ISNULL(pa.PaymentAmount,0.00) [BA]
			  ,CASE
			  	WHEN ec.LeaseContractType = 'Operating'
			  	THEN ISNULL(pa.PaymentAmount,0.00) - (ISNULL(isp.IncomeSchPaymentAmount,0.00) - ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00))
			  	ELSE ISNULL(pa.PaymentAmount,0.00) - (ISNULL(isp.IncomeSchPaymentAmount,0.00) - ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.CustomerGuaranteedResidualAmount,0.00)) 
			  END [AC]
			  ,CASE
			  	WHEN ec.LeaseContractType = 'Operating'
			  	THEN ISNULL(ra.ReceivableAmount,0.00) - (ISNULL(isp.IncomeSchPaymentAmount,0.00) - ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00))
			  	ELSE ISNULL(ra.ReceivableAmount,0.00) - (ISNULL(isp.IncomeSchPaymentAmount,0.00) - ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.CustomerGuaranteedResidualAmount,0.00))
			  END [BC]
			  ,CASE
			  	WHEN ec.ReceivableForTransfersId IS NOT NULL AND ec.ReceivableForTransferType IN ('FullSale','ParticipatedSale') 
			  	AND ec.LeaseContractType = 'Operating'
			  		THEN ISNULL(ra.LessorOwnedReceivableAmount,0.00) - (ISNULL(isp.LessorOwnedIncomeSchPaymentAmount,0.00) - ((ec.RetainedPercentage/100) * (ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) + ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00))))
			  	WHEN ec.ReceivableForTransfersId IS NOT NULL AND ec.ReceivableForTransferType IN ('FullSale','ParticipatedSale') 
			  	AND ec.LeaseContractType != 'Operating'
			  		THEN ISNULL(ra.LessorOwnedReceivableAmount,0.00) - (ISNULL(isp.LessorOwnedIncomeSchPaymentAmount,0.00) - ((ec.RetainedPercentage/100) * (ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) + ISNULL(la.CustomerGuaranteedResidualAmount,0.00))))
			  	WHEN (ec.ReceivableForTransfersId IS NOT NULL AND ec.ReceivableForTransferType IN ('SaleOfPayments') 
			  	AND ec.LeaseContractType = 'Operating') 
			  	OR (ec.ReceivableForTransfersId IS NULL AND ec.LeaseContractType = 'Operating')
			  		THEN ISNULL(ra.LessorOwnedReceivableAmount,0.00) - (ISNULL(isp.LessorOwnedIncomeSchPaymentAmount,0.00) - ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00))
			  	WHEN (ec.ReceivableForTransfersId IS NOT NULL AND ec.ReceivableForTransferType IN ('SaleOfPayments')
			  	AND ec.LeaseContractType != 'Operating') 
			  	OR (ec.ReceivableForTransfersId IS NULL AND ec.LeaseContractType != 'Operating')
			  		THEN ISNULL(ra.LessorOwnedReceivableAmount,0.00) - (ISNULL(isp.LessorOwnedIncomeSchPaymentAmount,0.00) - ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) - ISNULL(la.CustomerGuaranteedResidualAmount,0.00))
			  	ELSE 0.00
			  END [B1C1]
			  ,CASE
			  	WHEN ec.ReceivableForTransfersId IS NOT NULL AND ec.ReceivableForTransferType IN ('FullSale','ParticipatedSale') 
			  	AND ec.LeaseContractType = 'Operating'
			  		THEN ISNULL(ra.NonLessorOwnedReceivableAmount,0.00) - (ISNULL(nisp.NonLessorOwnedIncomeSchPaymentAmount,0.00) - ((ec.ParticipationPercentage/100) * (ISNULL(la.FinanceAssetThirdPartyGuaranteedResidualAmount,0.00) + ISNULL(la.FinanceAssetCustomerGuaranteedResidualAmount,0.00))))
			  	WHEN ec.ReceivableForTransfersId IS NOT NULL AND ec.ReceivableForTransferType IN ('FullSale','ParticipatedSale') 
			  	AND ec.LeaseContractType != 'Operating' 
			  		THEN ISNULL(ra.NonLessorOwnedReceivableAmount,0.00) - (ISNULL(nisp.NonLessorOwnedIncomeSchPaymentAmount,0.00) - ((ec.ParticipationPercentage/100) * (ISNULL(la.ThirdPartyGuaranteedResidualAmount,0.00) + ISNULL(la.CustomerGuaranteedResidualAmount,0.00))))
			  	WHEN (ec.ReceivableForTransfersId IS NOT NULL AND ec.ReceivableForTransferType IN ('SaleOfPayments')) OR (ec.ReceivableForTransfersId IS NULL)
			  		THEN ISNULL(ra.NonLessorOwnedReceivableAmount,0.00) - ISNULL(nisp.NonLessorOwnedIncomeSchPaymentAmount,0.00)
			  	ELSE 0.00
			  END [B2C2]
			FROM #EligibleContracts ec
				INNER JOIN LegalEntities le ON le.Id = ec.LegalEntityId
				INNER JOIN Parties p ON ec.CustomerId = p.Id
				LEFT JOIN #HasFinanceAsset hfa ON ec.ContractId = hfa.ContractId
				LEFT JOIN #FullPaidOffContracts fpoc ON ec.ContractId = fpoc.ContractId
				LEFT JOIN #OverTerm ot ON ec.ContractId = ot.ContractId
				LEFT JOIN #ReceivableAmount ra ON ec.ContractId = ra.ContractId
				LEFT JOIN #PaymentAmount pa ON ec.ContractId = pa.ContractId
				LEFT JOIN #LeaseAssets la ON ec.ContractId = la.ContractId
				LEFT JOIN #InterimPaymentAmount ipa ON ec.ContractId = ipa.ContractId
				LEFT JOIN #IncomeSchPaymentAmount isp ON ec.ContractId = isp.ContractId
				LEFT JOIN #NonLessorOwnedIncomeSchPaymentAmount nisp ON ec.ContractId = nisp.ContractId
				LEFT JOIN #ContractCount cc ON ec.ContractId = cc.ContractId
				LEFT JOIN #ServicingDetails sd ON ec.ContractId = sd.ContractId
	)AS t;

		DECLARE @TotalCount BIGINT;
		SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList
		DECLARE @InCorrectCount BIGINT;
		SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result = 'Problem Record'
		DECLARE @Messages StoredProcMessage
		
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalLeases', (Select 'Leases=' + CONVERT(nvarchar(40), @TotalCount)))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LeaseSuccessful', (Select 'LeaseSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LeaseIncorrect', (Select 'LeaseIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))

		INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('LeaseResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))


		SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label
		INTO #SchedulePaymentSummary
		FROM tempdb.sys.columns
		WHERE object_id = OBJECT_ID('tempdb..#ResultList')
		AND Name IN ('BC', 'BA', 'AC', 'B1C1', 'B2C2', 'HasMultipleContractId');


		DECLARE @query NVARCHAR(MAX);
		DECLARE @TableName NVARCHAR(max);
		WHILE EXISTS (SELECT 1 FROM #SchedulePaymentSummary WHERE IsProcessed = 0 AND Name != 'HasMultipleContractId')
		BEGIN
		SELECT TOP 1 @TableName = Name FROM #SchedulePaymentSummary WHERE IsProcessed = 0

		SET @query = 'UPDATE #SchedulePaymentSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
						WHERE Name = '''+ @TableName+''' ;'
		EXEC (@query)
		END

		UPDATE #SchedulePaymentSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE HasMultipleContractId = 'Yes')
		WHERE Name = 'HasMultipleContractId'

		UPDATE #SchedulePaymentSummary SET Label = CASE WHEN Name = 'BC'
												        THEN 'B-C'
														WHEN Name = 'AC'
														THEN 'A-C'
														WHEN Name = 'B1C1'
														THEN 'B1-C1'
														WHEN Name = 'B2C2'
														THEN 'B2-C2'
														WHEN Name ='BA'
														THEN 'B-A'
														WHEN Name ='HasMultipleContractId'
														THEN 'Has Multiple Contract Id'
													END

		SELECT Label AS Name, Count
		FROM #SchedulePaymentSummary

		IF(@ResultOption = @All)
		BEGIN
			SELECT * FROM #ResultList ORDER BY ContractId
		END

		IF(@ResultOption = @Passed)
		BEGIN
			SELECT * FROM #ResultList WHERE Result != 'Problem Record' ORDER BY ContractId
		END
		
		IF(@ResultOption = @Failed)
		BEGIN
			SELECT * FROM #ResultList WHERE Result = 'Problem Record' ORDER BY ContractId
		END

		SELECT * FROM @Messages


		DROP TABLE #EligibleContracts;
		DROP TABLE #HasFinanceAsset;
		DROP TABLE #FullPaidOffContracts;
					 
		DROP TABLE #RenewalContracts;
		DROP TABLE #ReceivableAmount;
		DROP TABLE #PaymentAmount;
		DROP TABLE #LeaseAssets;
		DROP TABLE #InterimPaymentAmount;
		DROP TABLE #IncomeSchPaymentAmount;
		DROP TABLE #LessorOwnedCount;
		DROP TABLE #NonLessorOwnedIncomeSchPaymentAmount;
		DROP TABLE #ContractCount;
		DROP TABLE #ServicingDetails;
		DROP TABLE #ResultList;
		DROP TABLE #SchedulePaymentSummary;
		SET NOCOUNT OFF
		SET ANSI_WARNINGS ON 
	END

GO
