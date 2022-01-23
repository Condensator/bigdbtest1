SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 CREATE PROCEDURE [dbo].[AssetLocationHistoryRecon] 
 AS
 BEGIN
 SELECT slh.Id 
 ,salh.AssetAlias
 ,slh.NewLocation AS [Intermediate.NewLocation]
 ,l.code AS [Target.NewLocation]
 ,slh.effectivefromdate AS [Intermediate.EffectiveFromDate]
 ,al.effectivefromdate AS [Target.EffectiveFromDate]
 ,salh.IsFLStampTaxExempt AS [Intermediate.IsFLStampTaxExempt]
 ,al.IsFLStampTaxExempt AS [Target.IsFLStampTaxExempt]
 ,salh.UpfrontTaxAssessedInLegacySystem AS [Intermediate.UpfrontTaxAssessedInLegacySystem]
 ,al.UpfrontTaxAssessedInLegacySystem AS[Target.UpfrontTaxAssessedInLegacySystem]
 ,salh.ReciprocityAmount_Amount AS [Intermediate.ReciprocityAmount_Amount]
 ,al.ReciprocityAmount_Amount AS [Target.ReciprocityAmount_Amount]
 ,salh.LienCredit_Amount AS [Intermediate.LienCredit_Amount]
 ,al.LienCredit_Amount AS [Target.LienCredit_Amount]
 ,alc.MigrationId
 FROM stglocationhistory slh 
 JOIN stgAssetLocationHistory salh ON salh.LocationHistoryId=slh.Id
 JOIN Locations l ON l.code=slh.NewLocation
 JOIN Assets a ON a.Alias=salh.AssetAlias
 LEFT JOIN AssetsLocationChanges alc on alc.MigrationId=slh.id
 LEFT JOIN AssetsLocationChangeDetails alcd ON alcd.AssetsLocationChangeId=alc.Id
 LEFT JOIN AssetLocations al ON al.AssetId=alcd.AssetId AND al.LocationId=alc.NewLocationId AND al.EffectiveFromDate=alc.EffectiveFromDate
 WHERE slh.IsMigrated=1 
 END;

GO
