SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetDSLReceiptIds]
(
@ReceiptClassificationValue_DSL NVARCHAR(3),
@ReceiptBatchIds IdCollection READONLY,
@ReceiptStatus_Posted NVARCHAR(40)
)
AS
BEGIN
SELECT
RBD.ReceiptId Id
FROM @ReceiptBatchIds RBI
JOIN ReceiptBatchDetails RBD
ON RBI.Id = RBD.ReceiptBatchId
JOIN ReceiptBatches RB
ON RB.Id = RBD.ReceiptBatchId
JOIN Receipts R
ON RBD.ReceiptId = R.Id
WHERE
R.ReceiptClassification = @ReceiptClassificationValue_DSL AND
RBD.IsActive = 1 AND
R.Status <> @ReceiptStatus_Posted
GROUP BY
RBD.ReceiptId
--To Accomodate All or None Functionality
END

GO
