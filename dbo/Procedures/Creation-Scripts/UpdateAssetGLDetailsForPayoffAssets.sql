SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateAssetGLDetailsForPayoffAssets]
(
@AssetsToUpdate AssetsFromPayoffToUpdateGLDetails READONLY,
@InstrumentTypeId BIGINT,
@LineOfBusinessId BIGINT,
@CostCenterId BIGINT
)
AS
BEGIN
SET NOCOUNT ON
UPDATE AG SET AG.InstrumentTypeId = (CASE WHEN AG.InstrumentTypeId IS NULL THEN @InstrumentTypeId ELSE AG.InstrumentTypeId END),
AG.LineofBusinessId = (CASE WHEN AG.LineofBusinessId IS NULL THEN @LineOfBusinessId ELSE AG.LineofBusinessId END),
AG.CostCenterId = (CASE WHEN AG.CostCenterId IS NULL THEN @CostCenterId ELSE AG.CostCenterId END)
FROM AssetGLDetails AG
JOIN @AssetsToUpdate AU ON AG.Id = AU.Id;
END

GO
