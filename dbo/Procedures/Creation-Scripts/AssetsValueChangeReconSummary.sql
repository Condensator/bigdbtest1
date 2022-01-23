SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  PROC [dbo].[AssetsValueChangeReconSummary]
AS
BEGIN

DECLARE @IntermediateCount bigint;
DECLARE @Intermediate_AdjustmentAmount decimal(32,2);
SELECT @IntermediateCount = Count(Id) , @Intermediate_AdjustmentAmount = SUM(AdjustmentAmount)  from stgAssetsValueChange where IsMigrated=1

IF OBJECT_ID('tempdb..#AssetsValueChangeReconFailures') IS NOT NULL
	DROP TABLE #AssetsValueChangeReconFailures;

CREATE TABLE #AssetsValueChangeReconFailures
([Status] nvarchar(100) ,[StagingID] bigint,[AssetAlias] nvarchar(100), [Reason] nvarchar(100),[Intermediate.IncomeDate] nvarchar(100),[Target.IncomeDate] nvarchar(100),[Intermediate.Adjustment_Amount] nvarchar(100),[Target.Value_Value] nvarchar(100))

INSERT INTO #AssetsValueChangeReconFailures
EXEC AssetsValueChangeReconFailures

SELECT [Intermediate_Count]=CAST (@IntermediateCount AS varchar),
	   [Intermediate_AdjustmentAmount] =CAST(@Intermediate_AdjustmentAmount AS varchar),
	   [Recon Status]='Success',
	   [Target_Count]=Count(AVH.Id) , 
	   [Target_Value_Amount]=SUM(-1*AVH.Value_Amount)  
FROM	stgAssetsValueChange AS stgAVS INNER JOIN
		AssetsValueStatusChanges AS AVS ON stgAVS.Id = AVS.MigrationId INNER JOIN
		Assetvaluehistories AVH on AVS.Id=AVH.SourceModuleId 
WHERE	AVH.SourceModule IN ('NBVImpairments', 'AssetValueAdjustment') AND 
		stgAVS.PostDate = AVH.IncomeDate  AND (-1* AVH.Value_Amount=stgAVS.AdjustmentAmount) AND
		stgAVS.IsMigrated=1

UNION


SELECT [Intermediate_Count]='', 
	   [Intermediate_AdjustmentAmount] ='', 
	   [Recon Status]='Failed',
	   [Target_Count]=Count([Status]) , 
	   [Target_Value_Amount]=CASE WHEN Count([Status]) = 0 THEN 0 ELSE SUM(CAST([Target.Value_Value] as decimal(32,2)))  END
FROM	#AssetsValueChangeReconFailures 
WHERE [Status]='Failed'
		
UNION

SELECT [Intermediate_Count]='', 
	   [Intermediate_AdjustmentAmount] ='', 
	   [Recon Status]='Unable to Reconcile',
	   [Target_Count]=Count([status]) , 
	   [Target_Value_Amount]=0 
FROM	#AssetsValueChangeReconFailures 
WHERE	[Status]='Unable to Reconcile'

DROP TABLE #AssetsValueChangeReconFailures;

END

GO
