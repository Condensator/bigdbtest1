SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetLeaseIncomeSchedulesForNonAccrual]  
(    
 @NonAccrualContractInfo IdDateCollection READONLY,    
 @FetchAssetIncomeSchedules BIT,    
 @ContractDetailsForDeferredRentals ContractDetailsToFetchAISForDeferredRentals READONLY,    
 @LeaseIncomeType_FixedTerm NVARCHAR(10),    
 @LeaseIncomeType_OverTerm NVARCHAR(10),    
 @LeaseIncomeType_Supplemental NVARCHAR(13)    
)    
AS     
BEGIN    
 SET NOCOUNT ON;

 SELECT * INTO #NonAccrualContractInfo FROM @NonAccrualContractInfo
 Create Index IX_Id On #NonAccrualContractInfo(Id)
    
 SELECT     
    LF.ContractId,  
	LIS.Id,
	Info.[Date] AS NonAccrualDate,
	LIS.IncomeDate,
	LIS.IsSchedule,
	LIS.IncomeType
 INTO #LeaseIncomeSchedules    
 FROM #NonAccrualContractInfo Info    
 JOIN LeaseFinances LF ON Info.Id = LF.ContractId    
 JOIN LeaseIncomeSchedules LIS ON LF.Id = LIS.LeaseFinanceId    
 WHERE (LIS.IsAccounting=1 OR LIS.IsSchedule=1) AND LIS.IsLessorOwned=1 AND LIS.IncomeType IN (@LeaseIncomeType_FixedTerm, @LeaseIncomeType_OverTerm, @LeaseIncomeType_Supplemental)    

 Create Index IX_Id ON #LeaseIncomeSchedules(Id)
    
 SELECT   
  L.ContractId,    
  LIS.LeaseFinanceId,    
  LIS.Id,    
  LIS.IncomeDate,    
  LIS.IsSchedule,    
  LIS.IsAccounting,    
  LIS.IsGLPosted,    
  LIS.AdjustmentEntry,    
  LIS.IncomeType,    
  LIS.AccountingTreatment,    
  LIS.PostDate,    
  LIS.IsReclassOTP,    
  LIS.IsNonAccrual,    
  LIS.Income_Amount AS Income,    
  LIS.FinanceIncome_Amount AS FinanceIncome,    
  LIS.ResidualIncome_Amount AS ResidualIncome,    
  LIS.FinanceResidualIncome_Amount AS FinanceResidualIncome,    
  LIS.RentalIncome_Amount AS RentalIncome,    
  LIS.FinanceRentalIncome_Amount AS FinanceRentalIncome,    
  LIS.DeferredRentalIncome_Amount AS DeferredRentalIncome,    
  LIS.FinanceDeferredRentalIncome_Amount AS FinanceDeferredRentalIncome,    
  LIS.DeferredSellingProfitIncome_Amount AS DSPIncome,    
  LIS.DeferredSellingProfitIncomeBalance_Amount AS DSPIncomeBalance,    
  LIS.BeginNetBookValue_Amount AS BeginNetBookValue,    
  LIS.EndNetBookValue_Amount AS EndNetBookValue,    
  LIS.FinanceBeginNetBookValue_Amount AS FinanceBeginNetBookValue,    
  LIS.FinanceEndNetBookValue_Amount AS FinanceEndNetBookValue,    
  LIS.OperatingBeginNetBookValue_Amount AS OperatingBeginNetBookValue,    
  LIS.OperatingEndNetBookValue_Amount AS OperatingEndNetBookValue,    
  LIS.Depreciation_Amount AS Depreciation,    
  LIS.IncomeAccrued_Amount AS IncomeAccrued,    
  LIS.IncomeBalance_Amount AS IncomeBalance,    
  LIS.ResidualIncomeBalance_Amount AS ResidualIncomeBalance,    
  LIS.Payment_Amount AS Payment,    
  LIS.FinanceIncomeAccrued_Amount AS FinanceIncomeAccrued,    
  LIS.FinanceIncomeBalance_Amount AS FinanceIncomeBalance,    
  LIS.FinanceResidualIncomeBalance_Amount AS FinanceResidualIncomeBalance,    
  LIS.FinancePayment_Amount AS FinancePayment   
 FROM #LeaseIncomeSchedules L  
 INNER JOIN LeaseIncomeSchedules LIS ON L.Id = LIS.Id  
    
 IF (@FetchAssetIncomeSchedules = 1)    
 BEGIN    
    
  SELECT AIS.Id  
  INTO #AssetIncomeScheduleIds
  FROM #LeaseIncomeSchedules LIS    
  JOIN AssetIncomeSchedules AIS ON LIS.Id = AIS.LeaseIncomeScheduleId   
  AND LIS.IncomeDate >= LIS.NonAccrualDate 
  WHERE AIS.IsActive=1   

  Create Index IX_Id ON #AssetIncomeScheduleIds(Id)
   
  SELECT     
   AIS.Id,    
   AIS.AssetId,    
   AIS.LeaseIncomeScheduleId,    
   AIS.BeginNetBookValue_Amount AS BeginNetBookValue,    
   AIS.EndNetBookValue_Amount AS EndNetBookValue,    
   AIS.Income_Amount AS Income,    
   AIS.IncomeAccrued_Amount AS IncomeAccrued,    
   AIS.IncomeBalance_Amount AS IncomeBalance,    
   AIS.ResidualIncome_Amount AS ResidualIncome,    
   AIS.ResidualIncomeBalance_Amount AS ResidualIncomeBalance,    
   AIS.OperatingBeginNetBookValue_Amount AS OperatingBeginNetBookValue,    
   AIS.OperatingEndNetBookValue_Amount AS OperatingEndNetBookValue,    
   AIS.RentalIncome_Amount AS RentalIncome,    
   AIS.DeferredRentalIncome_Amount AS DeferredRentalIncome,    
   AIS.Depreciation_Amount AS Depreciation,    
   AIS.Payment_Amount AS Payment,    
   AIS.DeferredSellingProfitIncome_Amount AS DSPIncome,    
   AIS.DeferredSellingProfitIncomeBalance_Amount AS DSPIncomeBalance,    
   AIS.FinanceBeginNetBookValue_Amount AS FinanceBeginNetBookValue,    
   AIS.FinanceEndNetBookValue_Amount AS FinanceEndNetBookValue,    
   AIS.FinancePayment_Amount AS FinancePayment,    
   AIS.FinanceIncome_Amount AS FinanceIncome,    
   AIS.FinanceIncomeAccrued_Amount AS FinanceIncomeAccrued,    
   AIS.FinanceIncomeBalance_Amount AS FinanceIncomeBalance,    
   AIS.FinanceResidualIncome_Amount AS FinanceResidualIncome,    
   AIS.FinanceResidualIncomeBalance_Amount AS FinanceResidualIncomeBalance,    
   AIS.FinanceRentalIncome_Amount AS FinanceRentalIncome,    
   AIS.FinanceDeferredRentalIncome_Amount AS FinanceDeferredRentalIncome,    
   AIS.LeaseBeginNetBookValue_Amount AS LeaseBeginNetBookValue,    
   AIS.LeaseEndNetBookValue_Amount AS LeaseEndNetBookValue,    
   AIS.LeasePayment_Amount AS LeasePayment,    
   AIS.LeaseIncome_Amount AS LeaseIncome,    
   AIS.LeaseIncomeAccrued_Amount AS LeaseIncomeAccrued,    
   AIS.LeaseIncomeBalance_Amount AS LeaseIncomeBalance,    
   AIS.LeaseResidualIncome_Amount AS LeaseResidualIncome,    
   AIS.LeaseResidualIncomeBalance_Amount AS LeaseResidualIncomeBalance,    
   AIS.LeaseRentalIncome_Amount AS LeaseRentalIncome,    
   AIS.LeaseDeferredRentalIncome_Amount AS LeaseDeferredRentalIncome    
  FROM #AssetIncomeScheduleIds A    
  JOIN AssetIncomeSchedules AIS ON A.Id = AIS.Id 
  OPTION (LOOP JOIN)
 END    
    
 SELECT ContractId, CurrentLeaseFinanceId, IncomeDateForDeferredRental INTO #ContractDetailsForDeferredRentals   
 FROM @ContractDetailsForDeferredRentals    
    
 IF EXISTS (Select TOP 1 1 FROM #ContractDetailsForDeferredRentals)    
 BEGIN    
  
  SELECT C.ContractId,    
       C.CurrentLeaseFinanceId,    
       LIS.Id LeaseIncomeScheduleId 
   INTO #LeaseIncomeScheduleForDeferredRental
   FROM #ContractDetailsForDeferredRentals C    
   JOIN #LeaseIncomeSchedules LIS ON C.ContractId = LIS.ContractId AND C.IncomeDateForDeferredRental = LIS.IncomeDate AND LIS.IsSchedule = 1  AND LIS.IncomeType = @LeaseIncomeType_FixedTerm
   
  SELECT AIS.Id AssetIncomeScheduleId,    
      AIS.AssetId,    
      LIS.LeaseIncomeScheduleId,    
      AIS.LeaseDeferredRentalIncome_Amount LeaseDeferredRentalIncome    
  FROM #LeaseIncomeScheduleForDeferredRental LIS    
  JOIN AssetIncomeSchedules AIS ON LIS.LeaseIncomeScheduleId = AIS.LeaseIncomeScheduleId AND AIS.IsActive = 1    
  JOIN LeaseAssets LA ON LIS.CurrentLeaseFinanceId = LA.LeaseFinanceId AND AIS.AssetId = LA.AssetId AND LA.IsActive = 1    
  
  DROP TABLE #ContractDetailsForDeferredRentals    
 END    
    
 DROP TABLE #LeaseIncomeSchedules    
END

GO
