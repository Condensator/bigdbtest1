SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAssetDataForAutoPayoffCreation]
(
	@PayoffInputsForAssetExtract PayoffInputForAssetExtract READONLY,
	@ReceivableEntityType NVARCHAR(10),
	@AVHSourceModule_NBVImpairment NVARCHAR(30),
	@AVHSourceModule_FixedTermDepreciation NVARCHAR(30),
	@AVHSourceModule_Syndications NVARCHAR(20),
	@CapitalLeaseRentalType NVARCHAR(40),
	@OperatingLeaseRentalType NVARCHAR(40),
	@SyndicationFullSaleStatus NVARCHAR(40),
	@SyndicationNoneStatus NVARCHAR(40),
	@SyndicationUnknownStatus NVARCHAR(40),
	@WritedownApprovedStatus NVARCHAR(40),
	@SyndicationType_ParticipatedSale NVARCHAR(20),
	@LeaseAmendmentApprovalStatus_Approved NVARCHAR(20),
	@LeaseAmendment_NBVImpairment NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON;

	--Load Assets Details
	SELECT 
		LeaseFinanceId = LA.LeaseFinanceId,
		LeaseAssetId = LA.Id, 
		AssetId = LA.AssetId,
		AssociatedLeaseAssetId = LA.CapitalizedForId,
		AssetTypeId = A.TypeId,
		NBV = LA.NBV_Amount,
		FMV = LA.FMV_Amount,
		CustomerCost = LA.CustomerCost_Amount,
		FinancialType = A.FinancialType,
		BookedResidual = CASE WHEN PIA.IsChargedOffLease = 0 THEN LA.BookedResidual_Amount ELSE 0.00 END,
		CustomerGuaranteedResidual = CASE WHEN PIA.IsChargedOffLease = 0 THEN LA.CustomerGuaranteedResidual_Amount ELSE 0.00 END,
		CustomerExpectedResidual = CASE WHEN PIA.IsChargedOffLease = 0 THEN LA.CustomerExpectedResidual_Amount ELSE 0.00 END,
		ThirdPartyGuaranteedResidual = CASE WHEN PIA.IsChargedOffLease = 0 THEN LA.ThirdPartyGuaranteedResidual_Amount ELSE 0.00 END,
		AssetStatus = A.[Status],
		UsefulLife = COALESCE(AC.UsefulLife, 0),
		AcquisitionDate = A.AcquisitionDate,
		HoldingStatus = AGL.HoldingStatus,
		AssetBookValueAdjustmentGLTemplateId = AGL.AssetBookValueAdjustmentGLTemplateId,
		BookDepSetupTemplateId = LA.BookDepreciationTemplateId,
		BookDepreciationGLTemplateId = CASE WHEN AGL.BookDepreciationGLTemplateId IS NOT NULL AND GLT.IsActive = 1 THEN AGL.BookDepreciationGLTemplateId ELSE NULL END,
		BookDepreciationYears = COALESCE(BDT.BookDepreciationYears, 0),
		IsLeaseAsset = LA.IsLeaseAsset,
		BookedResidualFactor = LA.BookedResidualFactor
	INTO #LeaseAssetDetails
	FROM @PayoffInputsForAssetExtract PIA 
	JOIN LeaseAssets LA ON PIA.LeaseFinanceId = LA.LeaseFinanceId
	JOIN Assets A ON LA.AssetId = A.Id
	JOIN AssetGLDetails AGL ON A.Id = AGL.Id
	LEFT JOIN GLTemplates GLT ON AGL.BookDepreciationGLTemplateId = GLT.Id 
	LEFT JOIN BookDepreciationTemplates BDT ON LA.BookDepreciationTemplateId = BDT.Id
	LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
	WHERE LA.IsActive = 1;

	SELECT 
		LeaseFinanceId = PIA.LeaseFinanceId,
		LeaseIncomeScheduleId = LI.Id
	INTO #LastIncomeScheduleInfoAtMaturity_Owned
	FROM @PayoffInputsForAssetExtract PIA
	JOIN LeaseIncomeSchedules LI ON PIA.LeaseFinanceId = LI.LeaseFinanceId AND LI.IncomeDate = PIA.MaturityDate
	WHERE PIA.IsChargedOffLease = 0
	AND PIA.SyndicationType <> @SyndicationFullSaleStatus
	AND LI.IsSchedule = 1
	AND LI.IsLessorOwned = 1;

	SELECT 
		LeaseFinanceId = PIA.LeaseFinanceId,
		LeaseIncomeScheduleId = LI.Id
	INTO #LastIncomeScheduleInfo_100Percent
	FROM @PayoffInputsForAssetExtract PIA
	JOIN LeaseIncomeSchedules LI ON PIA.LeaseFinanceId = LI.LeaseFinanceId AND LI.IncomeDate = PIA.PayoffEffectiveDate
	WHERE PIA.IsChargedOffLease = 0
	AND PIA.SyndicationType NOT IN (@SyndicationNoneStatus,@SyndicationUnknownStatus) 
	AND LI.IsSchedule = 1
	AND LI.IsLessorOwned = 0;

	SELECT 
		LeaseAssetId = LeaseAsset.LeaseAssetId,
		AssetValueHistoryId = AVH.Id,
		IsLessorOwned = AVH.IsLessorOwned,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY LeaseAsset.LeaseAssetId, AVH.IsLessorOwned ORDER BY AVH.IncomeDate DESC,AVH.ID DESC)
	INTO #AVH_LastIncomeScheduleInfo_Ungrouped
	FROM @PayoffInputsForAssetExtract PIA
	JOIN #LeaseAssetDetails LeaseAsset ON PIA.LeaseFinanceId = LeaseAsset.LeaseFinanceId
	JOIN AssetValueHistories AVH ON LeaseAsset.AssetId = AVH.AssetId AND AVH.IncomeDate <= PIA.PayoffEffectiveDate
	WHERE PIA.IsChargedOffLease = 0 
	AND AVH.IsSchedule = 1
	AND ((LeaseAsset.IsLeaseAsset = 1 AND (PIA.PayoffEffectiveDate <= PIA.MaturityDate)) OR (PIA.PayoffEffectiveDate > PIA.MaturityDate));

	SELECT 
		LeaseAssetId,
		AssetValueHistoryId,
		IsLessorOwned
	INTO #AVH_LastIncomeScheduleInfo
	FROM #AVH_LastIncomeScheduleInfo_Ungrouped
	WHERE Row_Num = 1;

	SELECT 
		LeaseAssetId = LastIncome.LeaseAssetId, 
		OperatingEndNBV_Owned =  AVH.EndBookValue_Amount 
	INTO #OperatingEndNBVInfo_Owned
	FROM #AVH_LastIncomeScheduleInfo LastIncome
	JOIN AssetValueHistories AVH ON LastIncome.AssetValueHistoryId = AVH.Id AND LastIncome.IsLessorOwned = 1;

	SELECT 
		LeaseAssetId = LastIncome.LeaseAssetId, 
		OperatingEndNBV_100Percent =  AVH.EndBookValue_Amount 
	INTO #OperatingEndNBVInfo_100Percent
	FROM #AVH_LastIncomeScheduleInfo LastIncome
	JOIN AssetValueHistories AVH ON LastIncome.AssetValueHistoryId = AVH.Id AND LastIncome.IsLessorOwned = 0;

	SELECT 
		LeaseAssetId = LeaseAsset.LeaseAssetId,
		AssetValueHistoryId = AVH.Id,
		IsLessorOwned = AVH.IsLessorOwned,
		Row_Num = ROW_NUMBER() OVER (PARTITION BY LeaseAsset.LeaseAssetId, AVH.IsLessorOwned ORDER BY AVH.Id DESC)
	INTO #AVH_LastIncomeScheduleInfoAtMaturity_Ungrouped
	FROM @PayoffInputsForAssetExtract PIA
	JOIN #LeaseAssetDetails LeaseAsset ON PIA.LeaseFinanceId = LeaseAsset.LeaseFinanceId
	JOIN AssetValueHistories AVH ON LeaseAsset.AssetId = AVH.AssetId AND AVH.IncomeDate = PIA.MaturityDate
	WHERE PIA.IsChargedOffLease = 0 
	AND AVH.IsSchedule = 1
	AND LeaseAsset.IsLeaseAsset = 1;

	SELECT 
		LeaseAssetId,
		AssetValueHistoryId,
		IsLessorOwned
	INTO #AVH_LastIncomeScheduleInfoAtMaturity
	FROM #AVH_LastIncomeScheduleInfoAtMaturity_Ungrouped
	WHERE Row_Num = 1;

	SELECT 
		LeaseAssetId = LastIncome.LeaseAssetId, 
		OperatingEndNBVAsOfMaturity_Owned =  AVH.EndBookValue_Amount 
	INTO #OperatingEndNBVInfoAtMaturity_Owned
	FROM #AVH_LastIncomeScheduleInfoAtMaturity LastIncome
	JOIN AssetValueHistories AVH ON LastIncome.AssetValueHistoryId = AVH.Id AND LastIncome.IsLessorOwned = 1;

	
	SELECT 
		LeaseAssetId = LeaseAsset.LeaseAssetId, 
		FixedTermDepreciation = CASE WHEN PIA.SyndicationEffectiveDate IS NOT NULL AND PIA.SyndicationType = @SyndicationType_ParticipatedSale AND AVH.IncomeDate < PIA.SyndicationEffectiveDate THEN (0 - AVH.Value_Amount) * (PIA.LessorRetainedPercentage/100)
										ELSE 0 - AVH.Value_Amount
								END
	INTO #FixedTermDepreciations_Ungrouped
	FROM @PayoffInputsForAssetExtract PIA
	JOIN #LeaseAssetDetails LeaseAsset ON PIA.LeaseFinanceId = LeaseAsset.LeaseFinanceId
	JOIN AssetValueHistories AVH ON LeaseAsset.AssetId = AVH.AssetId 
	WHERE PIA.IsOperatingLease = 1
	AND PIA.IsChargedOffLease = 0
	AND LeaseAsset.IsLeaseAsset = 1 
	AND AVH.SourceModule = @AVHSourceModule_FixedTermDepreciation
	AND AVH.IncomeDate >= PIA.CommencementDate
	AND AVH.IncomeDate <= PIA.PayoffEffectiveDate
	AND AVH.IsSchedule = 1
	AND AVH.IsLessorOwned = 1;

	SELECT 
		LeaseAssetId,
		AccumulatedFixedTermDepreciation = ROUND(SUM(FixedTermDepreciation),2)
	INTO #AccumulatedFixedTermDepreciations
	FROM #FixedTermDepreciations_Ungrouped
	GROUP BY LeaseAssetId;
	
	SELECT 
		LeaseAssetId = #LeaseAssetDetails.LeaseAssetId,
		OTPDepreciation = ROUND(SUM(AIS.Depreciation_Amount)*-1,2)
	INTO 
		#OTPDepreciations
	FROM 
		@PayoffInputsForAssetExtract PIA
		JOIN LeaseIncomeSchedules LI ON PIA.LeaseFinanceId = LI.LeaseFinanceId
		JOIN AssetIncomeSchedules AIS ON LI.Id = AIS.LeaseIncomeScheduleId AND AIS.IsActive = 1
		JOIN #LeaseAssetDetails ON AIS.AssetId = #LeaseAssetDetails.AssetId
	WHERE 
		PIA.IsChargedOffLease = 0	
		AND LI.IsSchedule = 1
		AND LI.IsLessorOwned = 1
		AND LI.IncomeDate > PIA.MaturityDate
		AND LI.IncomeDate <= PIA.PayoffEffectiveDate
		AND PIA.PayoffEffectiveDate > PIA.MaturityDate
	GROUP BY 
		#LeaseAssetDetails.LeaseAssetId

	SELECT 
		AssetId = LeaseAsset.AssetId, 
		GLTemplateId = LA.GLTemplateId,
		NBVImpairment =  CASE WHEN PIA.SyndicationEffectiveDate IS NOT NULL AND PIA.SyndicationType = @SyndicationType_ParticipatedSale AND AVH.IncomeDate < PIA.SyndicationEffectiveDate THEN (0 - AVH.Value_Amount) * (PIA.LessorRetainedPercentage/100)
									 ELSE 0 - AVH.Value_Amount
						 END
	INTO #NBVImpairments_Ungrouped
	FROM @PayoffInputsForAssetExtract PIA
	JOIN #LeaseAssetDetails LeaseAsset ON PIA.LeaseFinanceId = LeaseAsset.LeaseFinanceId
	JOIN AssetValueHistories AVH ON LeaseAsset.AssetId = AVH.AssetId 
	JOIN LeaseAmendmentImpairmentAssetDetails ImpDetail ON AVH.AssetId = ImpDetail.AssetId AND ImpDetail.IsActive = 1
	JOIN LeaseAmendments LA ON AVH.SourceModuleId = LA.Id AND ImpDetail.LeaseAmendmentId = LA.Id
	WHERE PIA.IsOperatingLease = 1
	AND PIA.IsChargedOffLease = 0 
	AND AVH.SourceModule = @AVHSourceModule_NBVImpairment
	AND AVH.IncomeDate >= PIA.CommencementDate
	AND AVH.IncomeDate <= PIA.PayoffEffectiveDate
	AND AVH.IsSchedule = 1
	AND AVH.IsLessorOwned = 1
	AND LA.AmendmentType = @LeaseAmendment_NBVImpairment
	AND LA.LeaseAmendmentStatus = @LeaseAmendmentApprovalStatus_Approved
	AND LA.AmendmentDate <= PIA.PayoffEffectiveDate
	AND ((LeaseAsset.IsLeaseAsset = 1 AND (PIA.PayoffEffectiveDate <= PIA.MaturityDate)) OR (PIA.PayoffEffectiveDate > PIA.MaturityDate));

	SELECT 
		AssetId,
		GLTemplateId,
		AccumulatedNBVImpairment = ROUND(SUM(NBVImpairment),2)
	INTO #AccumulatedNBVImpairments
	FROM #NBVImpairments_Ungrouped
	GROUP BY AssetId, GLTemplateId;

	SELECT LeaseAssetId = LAD.LeaseAssetId, 
		   EndNBVAsOfMaturity_Owned = AIS.EndNetBookValue_Amount
	INTO #IncomeSchedulesEndNBVAsOfMaturity_Owned
	FROM @PayoffInputsForAssetExtract PIA
	JOIN #LeaseAssetDetails LAD ON PIA.LeaseFinanceId = LAD.LeaseFinanceId
	JOIN AssetIncomeSchedules AIS ON LAD.AssetId = AIS.AssetId
	JOIN #LastIncomeScheduleInfoAtMaturity_Owned LIO ON AIS.LeaseIncomeScheduleId = LIO.LeaseIncomeScheduleId
	WHERE AIS.IsActive = 1;

	--Write Down Amount 
	SELECT 
		LeaseAssetId = LeaseAsset.LeaseAssetId , 
		WriteDownAmount = SUM(WDAD.WriteDownAmount_Amount) 
	INTO #WriteDownAmountDetails
	FROM @PayoffInputsForAssetExtract LPD
	JOIN #LeaseAssetDetails LeaseAsset ON LPD.LeaseFinanceId = LeaseAsset.LeaseFinanceId
	JOIN WriteDownAssetDetails WDAD ON LeaseAsset.AssetId = WDAD.AssetId
	JOIN WriteDowns WD ON WDAD.WriteDownId = WD.Id
	WHERE WD.[Status] = @WritedownApprovedStatus 
	AND WDAD.IsActive = 1
	GROUP BY LeaseAsset.LeaseAssetId;

	--ETC Details

	SELECT 
		LeaseAsset.LeaseAssetId, 
		ETC = SUM(BIA.TaxCredit_Amount)	
	INTO #ETCDetails
	FROM @PayoffInputsForAssetExtract PIA
	JOIN LeaseBlendedItems LBI ON PIA.LeaseFinanceId = LBI.LeaseFinanceId
	JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id
	JOIN BlendedItemAssets BIA ON BI.Id = BIA.BlendedItemId
	JOIN #LeaseAssetDetails LeaseAsset ON PIA.LeaseFinanceId = LeaseAsset.LeaseFinanceId AND BIA.LeaseAssetId = LeaseAsset.LeaseAssetId
	WHERE BI.IsActive = 1
	AND BIA.IsActive = 1
	GROUP BY LeaseAsset.LeaseAssetId;

	--Result Set
	SELECT 
	   LeaseFinanceId = LeaseAsset.LeaseFinanceId,
	   LeaseAssetId = LeaseAsset.LeaseAssetId,
	   AssetId = LeaseAsset.AssetId,
	   AssociatedLeaseAssetId = LeaseAsset.AssociatedLeaseAssetId,
	   AssetTypeId = LeaseAsset.AssetTypeId,
	   AssetBookValueAdjustmentGLTemplateId = LeaseAsset.AssetBookValueAdjustmentGLTemplateId,
	   BookDepreciationGLTemplateId = LeaseAsset.BookDepreciationGLTemplateId,
	   BookDepreciationYears = LeaseAsset.BookDepreciationYears,
	   NBV = LeaseAsset.NBV,
	   ETC = ISNULL(ET.ETC, 0.0),
	   FMV = LeaseAsset.FMV,
	   CustomerCost = LeaseAsset.CustomerCost,
	   BookedResidual = LeaseAsset.BookedResidual,
	   CustomerGuaranteedResidual = LeaseAsset.CustomerGuaranteedResidual,
	   CustomerExpectedResidual = LeaseAsset.CustomerExpectedResidual,
	   ThirdPartyGuaranteedResidual = LeaseAsset.ThirdPartyGuaranteedResidual,
	   FinancialType = LeaseAsset.FinancialType,
	   AssetStatus = LeaseAsset.AssetStatus,
	   UsefulLife = LeaseAsset.UsefulLife,
	   AcquisitionDate = LeaseAsset.AcquisitionDate,
	   HoldingStatus = LeaseAsset.HoldingStatus,
	   BookDepSetupTemplateId = LeaseAsset.BookDepSetupTemplateId,
	   IsLeaseAsset = LeaseAsset.IsLeaseAsset,
	   BookedResidualFactor = LeaseAsset.BookedResidualFactor,
	   WriteDownAmount = WD.WriteDownAmount,
	   OperatingEndNBV = ISNULL(OEN_Owned.OperatingEndNBV_Owned, 0.0), --Check
	   OperatingEndNBV_100Percent = ISNULL(OEN_100Percent.OperatingEndNBV_100Percent, 0.0),--Check
	   OperatingEndNBVAsOfMaturity = ISNULL(OENAM_Owned.OperatingEndNBVAsOfMaturity_Owned, 0.0), --Check
	   AccumulatedFixedTermDepreciation = ISNULL(FD.AccumulatedFixedTermDepreciation, 0.0),
	   OTPDepreciation = ISNULL(OD.OTPDepreciation, 0.0),
	   EndNBVAsOfMaturity_Owned = ISNULL(ISNM.EndNBVAsOfMaturity_Owned,0.0)
	FROM #LeaseAssetDetails LeaseAsset
	LEFT JOIN #OperatingEndNBVInfo_Owned OEN_Owned ON LeaseAsset.LeaseAssetId = OEN_Owned.LeaseAssetId
	LEFT JOIN #OperatingEndNBVInfo_100Percent OEN_100Percent ON LeaseAsset.LeaseAssetId = OEN_100Percent.LeaseAssetId
	LEFT JOIN #AccumulatedFixedTermDepreciations FD ON LeaseAsset.LeaseAssetId = FD.LeaseAssetId
	LEFT JOIN #OTPDepreciations OD ON LeaseAsset.LeaseAssetId = OD.LeaseAssetId
	LEFT JOIN #IncomeSchedulesEndNBVAsOfMaturity_Owned ISNM ON LeaseAsset.LeaseAssetId = ISNM.LeaseAssetId
	LEFT JOIN #WriteDownAmountDetails WD ON LeaseAsset.LeaseAssetId = WD.LeaseAssetId
	LEFT JOIN #ETCDetails ET ON LeaseAsset.LeaseAssetId = ET.LeaseAssetId
	LEFT JOIN #OperatingEndNBVInfoAtMaturity_Owned OENAM_Owned ON LeaseAsset.LeaseAssetId = OENAM_Owned.LeaseAssetId
	
	SELECT * FROM #AccumulatedNBVImpairments;

DROP TABLE
#LeaseAssetDetails,
#LastIncomeScheduleInfoAtMaturity_Owned,
#LastIncomeScheduleInfo_100Percent,
#OperatingEndNBVInfo_Owned,
#OperatingEndNBVInfo_100Percent,
#OperatingEndNBVInfoAtMaturity_Owned,
#AccumulatedFixedTermDepreciations,
#AccumulatedNBVImpairments,
#IncomeSchedulesEndNBVAsOfMaturity_Owned,
#WriteDownAmountDetails,
#AVH_LastIncomeScheduleInfo_Ungrouped,
#AVH_LastIncomeScheduleInfo,
#AVH_LastIncomeScheduleInfoAtMaturity_Ungrouped,
#AVH_LastIncomeScheduleInfoAtMaturity,
#OTPDepreciations;

END

GO
