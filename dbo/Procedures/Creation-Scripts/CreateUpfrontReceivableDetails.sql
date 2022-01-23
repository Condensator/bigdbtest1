SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[CreateUpfrontReceivableDetails]  
(
	@UpfrontLeaseAssetDetails		PreCapitalizationRentDetails READONLY,
	@UpfrontLeaseAssetSKUs			PreCapitalizationRentDetails READONLY,
	@RecreatedReceivableDetails		RecreatedReceivableDetailData READONLY,
	@RecreatedReceivableSKUDetails	RecreatedReceivableDetailData READONLY,
	@CreatedTime					DATETIMEOFFSET,  
	@CreatedById					BIGINT,
	@NumberOfPayments				INT,
	@Currency						NVARCHAR(3)
)
AS
BEGIN
SET NOCOUNT ON;
	
	UPDATE RD 
		SET PreCapitalizationRent_Amount = ROUND(ULA.PreCapitalizationRent / @NumberOfPayments, 2),
			PreCapitalizationRent_Currency = @Currency
	FROM ReceivableDetails RD
	INNER JOIN @RecreatedReceivableDetails RRD ON RD.Id = RRD.Id
	INNER JOIN LeaseAssets LA ON RRD.AssetId = LA.AssetId
	INNER JOIN @UpfrontLeaseAssetDetails ULA ON LA.Id = ULA.Id
	;

	UPDATE RSKU
		SET PreCapitalizationRent_Amount = ROUND(ULAS.PreCapitalizationRent / @NumberOfPayments, 2),
			PreCapitalizationRent_Currency = @Currency
	FROM ReceivableSKUs RSKU
	INNER JOIN @RecreatedReceivableSKUDetails RRSKU ON RSKU.Id = RRSKU.Id
	INNER JOIN LeaseAssetSKUs LAS ON RRSKU.AssetId = LAS.AssetSKUId
	INNER JOIN @UpfrontLeaseAssetSKUs ULAS ON LAS.Id = ULAS.Id

END

GO
