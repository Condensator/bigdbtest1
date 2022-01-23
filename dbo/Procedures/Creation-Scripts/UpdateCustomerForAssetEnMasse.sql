SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[UpdateCustomerForAssetEnMasse]
(
@AssetCustomerEnMasseTable UpdateAssetCustomerTempTable READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
As
Begin
Set NoCount On;
Set Transaction Isolation Level Read UnCommitted;
CREATE TABLE #AssetCustomerDetailTable(
AssetId BIGINT
,CustomerId BIGINT
)
INSERT INTO #AssetCustomerDetailTable (AssetId,CustomerId)
SELECT AssetId,CustomerId FROM @AssetCustomerEnMasseTable
Update Assets Set CustomerId = AC.CustomerId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
From #AssetCustomerDetailTable AC
Join Assets on Assets.Id = AC.AssetId
Update Assets Set CustomerId = AC.CustomerId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
From #AssetCustomerDetailTable AC
Join Assets on Assets.ParentAssetId=AC.AssetId
Update AssetLocations Set IsCurrent=0
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
From #AssetCustomerDetailTable AC
Join AssetLocations on AssetLocations.AssetId=AC.AssetId and AssetLocations.IsCurrent=1
Update AssetLocations Set IsCurrent=0
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
From Assets assets
Join #AssetCustomerDetailTable AC on AC.AssetId=assets.ParentAssetId
Join AssetLocations on AssetLocations.AssetId=assets.Id
And AssetLocations.IsCurrent=1
End

GO
