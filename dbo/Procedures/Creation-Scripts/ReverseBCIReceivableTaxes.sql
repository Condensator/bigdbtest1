SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReverseBCIReceivableTaxes]
(@ReceivableTaxesBCIReversalParameters      ReceivableTaxesBCIReversalParameters READONLY,
@ClearTaxBasisType						 BIT,
@IsToReverseBCI						 BIT,
@CreatedById                            BIGINT,
@CreatedTime                            DATETIMEOFFSET,
@ErrorMessage							 NVARCHAR(MAX) OUT)
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION ProcessReceivableTax
IF @IsToReverseBCI = 1
BEGIN
UPDATE ReceivableTaxes
SET IsActive = 1, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxes RT
JOIN @ReceivableTaxesBCIReversalParameters RTP ON RT.Id = RTP.ReceivableTaxId
END
ELSE
BEGIN
UPDATE ReceivableTaxes
SET IsActive = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxes RT
JOIN @ReceivableTaxesBCIReversalParameters RTP ON RT.Id = RTP.ReceivableTaxId
WHERE IsActive = 1
;
UPDATE ReceivableTaxDetails
SET IsActive = 0 , UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxDetails RTD
JOIN @ReceivableTaxesBCIReversalParameters RTP ON RTD.ReceivableDetailId = RTP.ReceivableDetailId
WHERE IsActive = 1
;
UPDATE ReceivableDetails
SET IsTaxAssessed = 0 , UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableDetails RD
JOIN @ReceivableTaxesBCIReversalParameters RTP ON RD.Id = RTP.ReceivableDetailId
WHERE IsActive = 1
;
IF(@clearTaxBasisType = 1)
BEGIN
UPDATE AssetLocations
SET TaxBasisType = '_', UpfrontTaxMode = '_'
FROM AssetLocations AL
JOIN ReceivableTaxDetails RTD ON AL.Id = RTD.AssetLocationId
JOIN @ReceivableTaxesBCIReversalParameters RTP ON RTD.ReceivableTaxId = RTP.ReceivableTaxId
;
END
END
COMMIT TRANSACTION ProcessReceivableTax
END TRY
BEGIN CATCH
SET @ErrorMessage = CAST(ERROR_MESSAGE() AS NVARCHAR(MAX));
PRINT  CAST(ERROR_MESSAGE() AS NVARCHAR(MAX));
ROLLBACK TRANSACTION ProcessReceivableTax
;
END CATCH
END

GO
