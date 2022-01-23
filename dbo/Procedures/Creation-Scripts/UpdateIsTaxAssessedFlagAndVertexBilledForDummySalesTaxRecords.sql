SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateIsTaxAssessedFlagAndVertexBilledForDummySalesTaxRecords]
(
@ReceivableIdsToUpdate ReceivableIdToUpdateCollection READONLY
)
AS
BEGIN

SELECT 
	DISTINCT RD.ReceivableId
INTO #ReceivableIdsToUpdate
FROM ReceivableDetails RD INNER JOIN @ReceivableIdsToUpdate CT
ON CT.ReceivableId = RD.ReceivableId AND RD.BilledStatus != 'Invoiced'

SELECT 
	IV.ReceivableId
INTO #InvoicedReceivables
FROM @ReceivableIdsToUpdate IV WHERE IV.ReceivableId NOT IN
(Select ReceivableId from #ReceivableIdsToUpdate)

UPDATE RD 
SET 
	RD.IsTaxAssessed = 0
FROM ReceivableDetails RD INNER JOIN #ReceivableIdsToUpdate CT
ON CT.ReceivableId = RD.ReceivableId 

UPDATE VT
SET 
	VT.IsActive = 0
FROM VertexBilledRentalReceivables VT Inner Join ReceivableDetails RD
ON VT.ReceivableDetailId = RD.Id INNER JOIN #ReceivableIdsToUpdate R
ON R.ReceivableId = RD.ReceivableId

Select ReceivableId AS Id from #InvoicedReceivables

DROP TABLE #ReceivableIdsToUpdate
DROP TABLE #InvoicedReceivables

END

GO
