SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AssetLocationHistoryReconSummary]
AS
BEGIN

CREATE  TABLE #AssetLocationHistorysummary( 
  [id] bigint,
  [AssetAlias] nvarchar(200),
  [Intermediate.NewLocation] nvarchar(200),
  [Target.NewLocation]  nvarchar(200),
  [Intermediate.EffectiveFromDate] nvarchar(20),
  [Target.EffectiveFromDate] nvarchar(20), 
  [Intermediate.IsFLStampTaxExempt]  nvarchar(20),
  [Target.IsFLStampTaxExempt]  nvarchar(20),
  [Intermediate.UpfrontTaxAssessedInLegacySystem] nvarchar(20),
  [Target.UpfrontTaxAssessedInLegacySystem]  nvarchar(20), 
  [Intermediate.ReciprocityAmount_Amount]  nvarchar(20),
  [Target.ReciprocityAmount_Amount] nvarchar(20),
  [Intermediate.LienCredit_Amount] nvarchar(20),
  [Target.LienCredit_Amount] nvarchar(20),
  [MigrationId] bigint,
)
INSERT INTO #AssetLocationHistorysummary exec AssetLocationHistoryRecon

DECLARE @IntermediateCount bigint;
SELECT @IntermediateCount=COUNT(Id) from #AssetLocationHistorysummary 

CREATE  TABLE #summary( 
  [Id] bigint IDENTITY(1,1),
  Intermediate_Total_Records nvarchar(20),
  [Status] nvarchar(20),
  Target_Total_Records  nvarchar(20))

INSERT INTO #Summary (Intermediate_Total_Records,[Status],Target_Total_Records)
SELECT  Intermediate_Total_Records=CAST(@IntermediateCount AS varchar) ,'Success' [Status],CAST(COUNT(Id) AS VARCHAR) Target_Total_Records FROM #AssetLocationHistorysummary t WHERE
  t.[Intermediate.NewLocation]= t.[Target.NewLocation] AND
  t.[Intermediate.EffectiveFromDate]=t.[Target.EffectiveFromDate] AND
  t.[Intermediate.IsFLStampTaxExempt]=t.[Target.IsFLStampTaxExempt] AND
  t.[Intermediate.UpfrontTaxAssessedInLegacySystem]=t.[Target.UpfrontTaxAssessedInLegacySystem] AND
  t.[Intermediate.ReciprocityAmount_Amount]=t.[Target.ReciprocityAmount_Amount] AND
  t.[Intermediate.LienCredit_Amount]=t.[Target.LienCredit_Amount] 

UNION
SELECT Intermediate_Total_Records='' ,'Failed' [Status],CAST(COUNT(Id) AS VARCHAR) Target_Total_Records FROM #AssetLocationHistorysummary t WHERE
  t.[Intermediate.NewLocation]!= t.[Target.NewLocation] OR
  t.[Intermediate.EffectiveFromDate]!=t.[Target.EffectiveFromDate] OR
  t.[Intermediate.IsFLStampTaxExempt]!=t.[Target.IsFLStampTaxExempt] OR
  t.[Intermediate.UpfrontTaxAssessedInLegacySystem]!=t.[Target.UpfrontTaxAssessedInLegacySystem] OR
  t.[Intermediate.ReciprocityAmount_Amount]!=t.[Target.ReciprocityAmount_Amount] OR
  t.[Intermediate.LienCredit_Amount]!=t.[Target.LienCredit_Amount] 

INSERT INTO #Summary (Intermediate_Total_Records,[Status],Target_Total_Records)
SELECT Intermediate_Total_Records='' ,'Unable to reconcile' [Recon Status], CAST(COUNT(Id) AS VARCHAR) Target_Total_Records FROM #AssetLocationHistorysummary t WHERE
  t.MigrationId is NULL

SELECT Intermediate_Total_Records,[Status],Target_Total_Records FROM #summary
DROP Table #AssetLocationHistorysummary
DROP TABLE #summary
END;

GO
