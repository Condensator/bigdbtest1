SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateBilltoLocationIdInReceivables]
(
@BillToId BIGINT,
@ReceivableType NVARCHAR(MAX),
@LocationId BIGINT Null = null
)
AS
BEGIN
SET NOCOUNT ON
SELECT ID into #TypeTemp from dbo.ConvertCSVToBigIntTable(@ReceivableType,',')
SELECT
r.Id ReceivableId
INTO #ReceivableIdsToUpdate
FROM
Receivables r
INNER JOIN dbo.ReceivableDetails rd ON r.Id = rd.ReceivableId
INNER JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
INNER JOIN dbo.#TypeTemp tt ON rt.Id = tt.ID
WHERE r.IsActive = 1 AND rd.IsActive = 1 AND rc.IsActive = 1 AND rt.IsActive = 1
AND rd.BillToId = @BillToId AND rd.IsTaxAssessed =0
UPDATE dbo.Receivables
SET
dbo.Receivables.LocationId = @LocationId
WHERE dbo.Receivables.Id IN (SELECT ReceivableId FROM #ReceivableIdsToUpdate ritu)
END

GO
