SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_LeaseIncome_AssetValueHistories]
(
@LegalEntityIds LeaseIncome_AssetValueHistories_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
-- Fetches and Stores Total Scheduled Value per Asset
SELECT
A.Alias,
SUM(V.Value_Amount) [TotalScheduledValue]
INTO #SV
FROM AssetValueHistories V
JOIN Assets A ON A.Id = V.AssetId
WHERE V.IsSchedule = 1
AND V.IsLessorOwned = 1
AND (NOT EXISTS(SELECT * FROM @LegalEntityIds) OR A.LegalEntityId IN (SELECT LegalEntityId FROM @LegalEntityIds))
GROUP BY A.Alias
-- Fetches and Stores Total Accounted Value per Asset
SELECT
A.Alias,
SUM(V.Value_Amount) [TotalAccountedValue]
INTO #AV
FROM AssetValueHistories V
JOIN Assets A ON A.Id = V.AssetId
WHERE V.IsAccounted = 1
AND V.IsLessorOwned = 1
AND (NOT EXISTS (SELECT * FROM @LegalEntityIds) OR A.LegalEntityId IN (SELECT LegalEntityId FROM @LegalEntityIds))
GROUP BY A.Alias
-- Preparing Failed List
SELECT
#SV.Alias,
#SV.[TotalScheduledValue],
#AV.[TotalAccountedValue],
#SV.[TotalScheduledValue] -#AV.[TotalAccountedValue] AS Delta
INTO #ErrorList
FROM #SV
JOIN #AV ON #AV.Alias = #SV.Alias
WHERE #SV.[TotalScheduledValue] != #AV.[TotalAccountedValue]
SELECT @ErrorCount = count(*) FROM #ErrorList ;
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('LeaseError', 'Count=' + str(@ErrorCount));
END
ELSE
BEGIN
INSERT INTO @Messages VALUES ('SuccessMessage', null);
END
SELECT * FROM #ErrorList;
SELECT Name, ParameterValuesCsv FROM @Messages;

GO
