SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateACHReceiptStatusFromACHReturns]
(@CreatedBy                  BIGINT,
 @CreatedTime                DATETIME,
 @ACHReturnReceiptInfo                ACHReturnReceiptInfo ReadOnly
)
AS
BEGIN

SELECT * INTO #ReceiptIds FROM @ACHReturnReceiptInfo

UPDATE ACHR
SET Status = R.Status,
IsActive = 0,
UpdatedById = @CreatedBy,
UpdatedTime = @CreatedTime
FROM AChReceipts ACHR
JOIN #ReceiptIds R ON ACHR.ReceiptId = R.ReceiptId
WHERE ACHR.IsActive = 1

DROP TABLE #ReceiptIds 
END

GO
