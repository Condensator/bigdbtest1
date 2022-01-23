SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--To fetch receivable code and type level details
CREATE PROCEDURE [dbo].[InsertVertexReceivableCodeDetail]
(
@BuyOutReceivableType NVARCHAR(100),
@AssetSaleReceivableType NVARCHAR(100),
@JobStepInstanceId BIGINT
)
AS
BEGIN
;WITH CTE_ReceivableCodes AS
(
SELECT
DISTINCT ReceivableCodeId
FROM
SalesTaxReceivableDetailExtract
WHERE IsVertexSupported = 1 AND InvalidErrorCode IS NULL AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO VertexReceivableCodeDetailExtract
(IsExemptAtReceivableCode, SundryReceivableCode, TaxReceivableName, IsRental, ReceivableCodeId, TransactionType,JobStepInstanceId)
SELECT
IsExemptAtReceivableCode = RC.IsTaxExempt,
SundryReceivableCode = RC.Name,
TaxReceivableName = RT.Name,
IsRental = RT.IsRental,
ReceivableCodeId = RC.Id,
TransactionType = CASE WHEN RT.Name IN (@BuyOutReceivableType, @AssetSaleReceivableType) THEN 'SALE' ELSE 'LEASE' END,
JobStepInstanceId = @JobStepInstanceId
FROM CTE_ReceivableCodes RD
INNER JOIN ReceivableCodes RC ON RD.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
;
END

GO
