SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivateAssetSaleFromPayoffReversal]
(
@AssetIds NVARCHAR(MAX)
,@UserId BIGINT
,@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
IF (@AssetIds IS NOT NULL AND @AssetIds != '')
BEGIN
UPDATE AssetSales SET Status = 'Inactive' , UpdatedById = @UserId , UpdatedTime = @CurrentTime FROM AssetSales
JOIN AssetSaleDetails ASD ON AssetSales.Id = ASD.AssetSaleId
WHERE AssetSales.Status = 'Pending' AND
ASD.AssetId IN (SELECT ID  FROM ConvertCSVToBigIntTable(@AssetIds, ','))
END
END

GO
