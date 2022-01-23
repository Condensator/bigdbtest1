SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetTransactionTypeDetails]
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
DPT.Name AS TransactionTypeValue,
DPT.Name AS TransactionTypeLabel,
DT.Name AS DealType
FROM DealProductTypes DPT
JOIN DealTypes DT on DPT.DealTypeId = DT.Id
WHERE DPT.IsActive = 1
AND DT.IsActive = 1
AND DPT.Name <> 'LeveragedLease'
AND DT.Name <> 'Leveraged Lease'
END

GO
