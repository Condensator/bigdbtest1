SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReverseReceivableTaxes]
(@ReceivableTaxesReversalParameters      ReceivableTaxesReversalParameters READONLY,
@ClearTaxBasisType						 BIT,
@CreatedById                            BIGINT,
@CreatedTime                            DATETIMEOFFSET,
@ErrorMessage							 NVARCHAR(MAX) OUT)
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION ProcessReceivableTax
UPDATE ReceivableTaxes
SET IsActive = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxes RT
JOIN @ReceivableTaxesReversalParameters RTP ON RT.Id = RTP.ReceivableTaxId
;
UPDATE ReceivableTaxDetails
SET IsActive = 0 , UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxDetails RTD
JOIN @ReceivableTaxesReversalParameters RTP ON RTD.ReceivableTaxId = RTP.ReceivableTaxId
;
UPDATE ReceivableDetails
SET IsTaxAssessed = 0 , UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableDetails RD
JOIN ReceivableTaxes RT ON RD.ReceivableId = RT.ReceivableId
JOIN @ReceivableTaxesReversalParameters RTP ON RT.Id = RTP.ReceivableTaxId
;
IF(@clearTaxBasisType = 1)
BEGIN
UPDATE AssetLocations
SET TaxBasisType = '_', UpfrontTaxMode = '_'
FROM AssetLocations AL
JOIN ReceivableTaxDetails RTD ON AL.Id = RTD.AssetLocationId
JOIN @ReceivableTaxesReversalParameters RTP ON RTD.ReceivableTaxId = RTP.ReceivableTaxId
;
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
