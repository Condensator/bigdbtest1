SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AssetLocationHistoryReconFailures]
AS
BEGIN
CREATE TABLE #AssetLocationHistoryFailedRecord( 
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
INSERT INTO #AssetLocationHistoryFailedRecord EXEC AssetLocationHistoryRecon

SELECT Id AS [IntermediateId],
  'Failed' Status,
  [AssetAlias],
  [Intermediate.NewLocation],
  [Target.NewLocation],
  [Intermediate.EffectiveFromDate],
  [Target.EffectiveFromDate], 
  [Intermediate.IsFLStampTaxExempt],
  [Target.IsFLStampTaxExempt],
  [Intermediate.UpfrontTaxAssessedInLegacySystem],
  [Target.UpfrontTaxAssessedInLegacySystem], 
  [Intermediate.ReciprocityAmount_Amount],
  [Target.ReciprocityAmount_Amount],
  [Intermediate.LienCredit_Amount],
  [Target.LienCredit_Amount]
FROM #AssetLocationHistoryFailedRecord t WHERE
  t.[Intermediate.NewLocation]!= t.[Target.NewLocation] OR
  t.[Intermediate.EffectiveFromDate]!=t.[Target.EffectiveFromDate] OR
  t.[Intermediate.IsFLStampTaxExempt]!=t.[Target.IsFLStampTaxExempt] OR
  t.[Intermediate.UpfrontTaxAssessedInLegacySystem]!=t.[Target.UpfrontTaxAssessedInLegacySystem] OR
  t.[Intermediate.ReciprocityAmount_Amount]!=t.[Target.ReciprocityAmount_Amount] OR
  t.[Intermediate.LienCredit_Amount]!=t.[Target.LienCredit_Amount]
UNION
SELECT Id AS [IntermediateId],
  'Unable to Reconcile' Status,
  [AssetAlias],
  [Intermediate.NewLocation],
  [Target.NewLocation],
  [Intermediate.EffectiveFromDate],
  [Target.EffectiveFromDate], 
  [Intermediate.IsFLStampTaxExempt],
  [Target.IsFLStampTaxExempt],
  [Intermediate.UpfrontTaxAssessedInLegacySystem],
  [Target.UpfrontTaxAssessedInLegacySystem], 
  [Intermediate.ReciprocityAmount_Amount],
  [Target.ReciprocityAmount_Amount],
  [Intermediate.LienCredit_Amount],
  [Target.LienCredit_Amount]
FROM #AssetLocationHistoryFailedRecord t WHERE
  t.MigrationId is NULL

DROP TABLE #AssetLocationHistoryFailedRecord
END;

GO
