SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AssetsValueChangeReconFailures]
AS
BEGIN

SELECT	[Status]='Failed',
		stgAVS.Id [Intermediate Id],
		stgAVS.AssetAlias, 
		AVS.Reason, 
		CAST(stgAVS.PostDate AS varchar) AS [Intermediate.IncomeDate], 
		CAST(AVH.IncomeDate AS varchar) AS [Target.IncomeDate], 
		CAST(stgAVS.AdjustmentAmount AS varchar) AS [Intermediate.Adjustment_Amount], 
		CAST(-1*AVH.Value_Amount  AS varchar) AS [Target.Value_Value]
FROM	stgAssetsValueChange AS stgAVS INNER JOIN
		AssetsValueStatusChanges AS AVS ON stgAVS.Id = AVS.MigrationId INNER JOIN
		AssetValueHistories AS AVH ON AVS.Id = AVH.SourceModuleId
WHERE	AVH.SourceModule IN ('NBVImpairments', 'AssetValueAdjustment') AND 
		(stgAVS.PostDate <> AVH.IncomeDate  OR (-1* AVH.Value_Amount <> stgAVS.AdjustmentAmount)) AND
		stgAVS.IsMigrated=1

UNION

SELECT	[Status]='Unable to Reconcile',
		stgAVS.Id [Intermediate Id],
		stgAVS.AssetAlias, 
		stgAVS.Reason, 
		CAST(stgAVS.PostDate AS VARCHAR) AS [Intermediate.IncomeDate], 
		'' AS [Target.IncomeDate], 
		CAST(stgAVS.AdjustmentAmount AS VARCHAR) AS [Intermediate.Adjustment_Amount], 
		'' AS [Target.Value_Value]
FROM	stgAssetsValueChange AS stgAVS LEFT JOIN
		AssetsValueStatusChanges AS AVS ON stgAVS.Id = AVS.MigrationId
WHERE	AVS.Id IS NULL AND stgAVS.IsMigrated=1

END

GO
