SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTaxBasisTypeDetail]
(
@AssetLocationDetail AssetLocationTableType READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
MERGE AssetLocations AS ALTarget
USING @AssetLocationDetail AS ALSource
ON(ALTarget.Id = ALSource.AssetLocationId)
WHEN MATCHED THEN
UPDATE SET
[UpfrontTaxMode] = ALSource.[UpfrontTaxMode],
[TaxBasisType] = ALSource.[TaxBasisType],
[UpdatedById] = ALSource.[UpdatedById],
[UpdatedTime] = ALSource.[UpdatedTime];
SET NOCOUNT OFF;
END

GO
