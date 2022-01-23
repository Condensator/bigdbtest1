SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CloneMigratedReceivableTaxesForAdjustment]
(
@ReceivableToClone MigratedReceivableTaxDetailsToAdjust READONLY,
@CreatedById bigint,
@CreatedTime datetimeoffset
)
AS
BEGIN
SET NOCOUNT ON;
SELECT DISTINCT OldReceivableDetailId,NewReceivableDetailId INTO #ReceivableValues FROM @ReceivableToClone

INSERT INTO dbo.VertexBilledRentalReceivables
(
RevenueBilledToDate_Amount,
RevenueBilledToDate_Currency,
CumulativeAmount_Amount,
CumulativeAmount_Currency,
IsActive,
CreatedById,
CreatedTime,
ContractId,
ReceivableDetailId,
AssetId,
StateId,
AssetSKUId
)
SELECT
vt.RevenueBilledToDate_Amount * -1,
vt.RevenueBilledToDate_Currency,
CASE 
WHEN vt.CumulativeAmount_Amount != 0
THEN vt.CumulativeAmount_Amount - vt.RevenueBilledToDate_Amount
ELSE 0
END,
vt.CumulativeAmount_Currency,
vt.IsActive,
@CreatedById,
@CreatedTime,
vt.ContractId,
rd.NewReceivableDetailId,
vt.AssetId,
vt.StateId,
vt.AssetSKUId
FROM VertexBilledRentalReceivables vt
JOIN #ReceivableValues rd ON vt.ReceivableDetailId = rd.OldReceivableDetailId
WHERE vt.IsActive = 1
END

GO
