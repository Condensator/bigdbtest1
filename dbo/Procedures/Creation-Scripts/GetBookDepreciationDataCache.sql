SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetBookDepreciationDataCache]
(
	@BookDepreciationDataCacheInputs BookDepreciationDataCacheInput READONLY
)
AS
BEGIN      
SET NOCOUNT ON;      
    
SELECT * INTO #BookDepreciationDataCacheInputs FROM @BookDepreciationDataCacheInputs    
      
 SELECT       
  BookDepreciationId = BD.Id,      
  BD.ContractId,      
  BD.AssetId,      
  BD.GLTemplateId,      
  BD.IsLessorOwned,      
  BD.IsActive,      
  BD.IsInOTP,      
  BD.LastAmortRunDate,      
  BD.BeginDate,      
  BD.EndDate,      
  BD.TerminatedDate      
 FROM BookDepreciations BD      
 JOIN #BookDepreciationDataCacheInputs BDI ON BD.AssetId = BDI.AssetId AND BD.ContractId = BDI.ContractId      
 WHERE BD.EndDate > BDI.TerminationDate      
 AND BD.IsActive = 1      
 AND (BD.TerminatedDate IS NULL OR (BD.TerminatedDate > BDI.TerminationDate));      
    
  SELECT  
  AVH.Id,BDDCI.ContractId, BDDCI.TerminationDate  
  INTO #AVHIds  
 FROM AssetValueHistories AVH      
 JOIN #BookDepreciationDataCacheInputs BDDCI ON BDDCI.AssetId = AVH.AssetId      
  
 SELECT      
  AssetValueHistoryId = AVH.Id,      
  BDDCI.ContractId,      
  AVH.AssetId,      
  AVH.IncomeDate,      
  AVH.IsSchedule,      
  AVH.IsAccounted,      
  AVH.IsLessorOwned,      
  AVH.SourceModule,      
  AVH.SourceModuleId,      
  AVH.GLJournalId,      
  AVH.ReversalGLJournalId,      
  [Value] = AVH.Value_Amount,      
  Cost = AVH.Cost_Amount,      
  EndBookValue = AVH.EndBookValue_Amount      
 FROM AssetValueHistories AVH      
 JOIN #AVHIds BDDCI ON BDDCI.Id = AVH.Id      
  WHERE       
 AVH.IncomeDate > BDDCI.TerminationDate      
 AND (IsAccounted = 1 OR IsSchedule = 1)      
 AND AdjustmentEntry <> 1;  
  
      
 SELECT DISTINCT LegalEntityId      
 INTO #DistinctLegalEntities      
 FROM #BookDepreciationDataCacheInputs;      
      
 SELECT       
  FromDate = GLFinancialOpenPeriods.FromDate,      
  ToDate = GLFinancialOpenPeriods.ToDate,      
  LegalEntityId = GLFinancialOpenPeriods.LegalEntityId      
 FROM GLFinancialOpenPeriods      
 JOIN #DistinctLegalEntities ON #DistinctLegalEntities.LegalEntityId = GLFinancialOpenPeriods.LegalEntityId      
 WHERE GLFinancialOpenPeriods.IsCurrent = 1      
      
 SELECT DISTINCT ContractId, TerminationDate      
 INTO #ContractDetails      
 FROM #BookDepreciationDataCacheInputs;      
      
 SELECT      
  LeaseIncomeScheduleId = LeaseIncomeSchedules.Id,      
  LeaseIncomeSchedules.IncomeDate,      
  #ContractDetails.ContractId      
 FROM LeaseIncomeSchedules      
 JOIN LeaseFinances ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id      
 JOIN #ContractDetails ON #ContractDetails.ContractId = LeaseFinances.ContractId      
 WHERE LeaseIncomeSchedules.IsAccounting = 1      
 AND LeaseIncomeSchedules.IsGLPosted = 1      
 AND LeaseIncomeSchedules.AdjustmentEntry = 0      
 AND LeaseIncomeSchedules.IsReclassOTP = 1      
 AND LeaseIncomeSchedules.IncomeDate > #ContractDetails.TerminationDate      
      
 DROP TABLE #DistinctLegalEntities;      
      
END

GO
