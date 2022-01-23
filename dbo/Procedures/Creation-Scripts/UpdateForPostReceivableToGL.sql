SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateForPostReceivableToGL]
(
 @UpdatedBy   BIGINT,
 @UpdatedTime DATETIME,
 @ReceivableUpdateIds  ReceivableUpdateIds ReadOnly
)
AS
BEGIN

SELECT * INTO #ReceivableUpdateIds FROM @ReceivableUpdateIds

IF((SELECT COUNT(*) FROM #ReceivableUpdateIds) > 0)
BEGIN
UPDATE R
SET R.IsGLPosted = RI.IsGLPosted,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM Receivables R
JOIN #ReceivableUpdateIds RI ON R.Id = RI.Id
END

DROP TABLE #ReceivableUpdateIds 

END

GO
