SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateBilledRentalReceivables]
(
@BilledRentalReceivableDetails BilledRentalReceivableTableType READONLY
)
AS
DECLARE @CustomerId BIGINT = 0;
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
INSERT INTO VertexBilledRentalReceivables
(RevenueBilledToDate_Amount,
RevenueBilledToDate_Currency,
CumulativeAmount_Amount,
CumulativeAmount_Currency,
ContractId,
ReceivableDetailId,
StateId,
AssetId,
CreatedById,
CreatedTime,
IsActive)
SELECT
RevenueBilledToDate_Amount,
RevenueBilledToDate_Currency,
CumulativeAmount_Amount,
CumulativeAmount_Currency,
ContractId,
ReceivableDetailId,
StateId,
AssetId,
CreatedById,
CreatedTime,
IsActive
FROM @BilledRentalReceivableDetails;
END

GO
