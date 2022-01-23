SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetDepreciationDetailsForNonAccrual]  
(    
 @ContractsToProcess  ContractsToProcess    READONLY,    
 @AssetValueSourceModuleValues_FixedTermDepreciation  NVARCHAR(24),    
 @AssetValueSourceModuleValues_OTPDepreciation   NVARCHAR(24)    
)    
AS    
BEGIN
SET NOCOUNT ON;      
      
 SELECT * INTO #ContractIds FROM @ContractsToProcess      
      
 SELECT       
  C.ContractId AS ContractId,      
  C.NonAccrualDate,      
  LA.AssetId      
 INTO #LeaseAssets      
 FROM #ContractIds C      
 JOIN LeaseFinances LF ON C.ContractId = LF.ContractId AND LF.IsCurrent=1
 JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND LA.IsActive=1      
     
 CREATE TABLE #AVH (
	ContractId BIGINT,
	IsAccounted BIT,
	SourceModule NVARCHAR(25),
	Value_Amount DECIMAL(16,2),
	IncomeDate DATE,
	IsSchedule BIT,
	AdjustmentEntry BIT,
	GLJournalId BIGINT,
	ReversalGLJournalId BIGINT
 )

 INSERT INTO #AVH(ContractId, IsAccounted, SourceModule, Value_Amount, IncomeDate, IsSchedule, AdjustmentEntry, GLJournalId, ReversalGLJournalId)
 SELECT       
  LA.ContractId, 
  AVH.IsAccounted,
  AVH.SourceModule,
  AVH.Value_Amount,
  AVH.IncomeDate,    
  AVH.IsSchedule,
  AVH.AdjustmentEntry,
  AVH.GLJournalId,
  AVH.ReversalGLJournalId     
 FROM #LeaseAssets LA      
 JOIN AssetValueHistories AVH WITH(FORCESEEK) ON LA.AssetId = AVH.AssetId   
 WHERE   
 AVH.IsLessorOwned=1 AND   
 AVH.SourceModule IN (@AssetValueSourceModuleValues_FixedTermDepreciation, @AssetValueSourceModuleValues_OTPDepreciation) AND     
 AVH.IncomeDate >= LA.NonAccrualDate      

 DROP TABLE #ContractIds   
 DROP TABLE #LeaseAssets   

 SELECT       
  AVH.ContractId AS ContractId,      
  MAX(AVH.IncomeDate) MaxRecognizedDate      
 INTO #MaxIncomeRecognizedInfo      
 FROM #AVH AVH   
 WHERE     
 AVH.IsAccounted = 1 AND  
 AVH.AdjustmentEntry = 0 AND
 AVH.GLJournalId IS NOT NULL AND   
 AVH.ReversalGLJournalId IS NULL AND 
 AVH.SourceModule = @AssetValueSourceModuleValues_FixedTermDepreciation     
 GROUP BY AVH.ContractId      
      
 SELECT ContractId,      
  SUM(RecognizedDepreciationPostNonAccrual) AS RecognizedDepreciationPostNonAccrual      
 FROM      
 (      
  SELECT       
   AVH.ContractId,      
   SUM(AVH.Value_Amount) AS RecognizedDepreciationPostNonAccrual      
  FROM #MaxIncomeRecognizedInfo MaxRecognizationInfo      
  INNER JOIN #AVH AVH ON MaxRecognizationInfo.ContractId = AVH.ContractId         
  WHERE 
  AVH.IncomeDate <= MaxRecognizationInfo.MaxRecognizedDate AND 
  AVH.SourceModule = @AssetValueSourceModuleValues_FixedTermDepreciation AND 
  AVH.IsSchedule = 1
  GROUP BY AVH.ContractId      
      
  UNION ALL     
      
  SELECT       
   AVH.ContractId AS ContractId,      
   SUM(AVH.Value_Amount) RecognizedDepreciationPostNonAccrual      
  FROM #AVH AVH     
  WHERE       
  AVH.SourceModule = @AssetValueSourceModuleValues_OTPDepreciation AND 
  AVH.IsSchedule = 1 AND 
  AVH.AdjustmentEntry = 0 AND
  AVH.GLJournalId IS NOT NULL AND   
  AVH.ReversalGLJournalId IS NULL   
  GROUP BY AVH.ContractId      
 )    
 RecognizedDepreciation      
 GROUP BY ContractId      
      
 DROP TABLE #MaxIncomeRecognizedInfo  
 DROP TABLE #AVH           
END

GO
