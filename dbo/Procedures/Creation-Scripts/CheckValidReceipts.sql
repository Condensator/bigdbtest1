SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CheckValidReceipts]
(
@JobStepInstanceId		BIGINT,
@Count					BIGINT OUT
)
AS
BEGIN
SET @Count = (SELECT COUNT(*) FROM Receipts_Extract
WHERE IsValid = 1 AND JobStepInstanceId = @JobStepInstanceId)
END

GO
