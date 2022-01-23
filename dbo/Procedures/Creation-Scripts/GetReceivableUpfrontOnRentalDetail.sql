SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[GetReceivableUpfrontOnRentalDetail]
(
@ContractTable ContractIdTableType READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- _urReceivableInfo
SELECT
DISTINCT
R.DueDate,
RD.AssetId,
R.CustomerId,
RD.ReceivableId,
R.EntityId ContractId,
RD.Id ReceivableDetailId,
RD.AdjustmentBasisReceivableDetailId
FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN @ContractTable C ON R.EntityId = C.ContractId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE R.EntityType = 'CT' AND RT.IsRental = 1 AND R.IsActive = 1
AND (RT.Name = 'CapitalLeaseRental' OR RT.Name = 'OperatingLeaseRental')
;
--UR Value
SELECT
R.DueDate,
RD.AssetId,
R.Id ReceivableId,
RD.Amount_Amount ReceivableAmount,
0.00 BeginNetBookValueAmount,
0.00 OperatingBeginNetBookValueAmount,
R.CustomerId,
C.ContractId
FROM Receivables R
JOIN @ContractTable C ON R.EntityId = C.ContractId
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE (RT.Name = 'CapitalLeaseRental'
OR RT.Name = 'OperatingLeaseRental') AND R.IsActive = 1
END

GO
