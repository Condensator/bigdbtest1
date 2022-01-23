SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReceiptContractPayoffPaydownDetailsForPosting]
(
	@ReceiptIds										ReceiptIdModel READONLY,
	@JobStepInstanceId								BIGINT
)
AS
BEGIN
	
	SET NOCOUNT OFF;

	SELECT RE.ReceiptId, RE.PayOffId AS PayoffId 
	FROM Receipts_Extract RE INNER JOIN @ReceiptIds R ON RE.ReceiptId=R.Id
	WHERE RE.JobStepInstanceId=@JobStepInstanceId AND RE.IsValid=1 AND RE.PayOffId IS NOT NULL

	SELECT RE.ReceiptId, RE.PayDownId AS PaydownId 
	FROM Receipts_Extract RE INNER JOIN @ReceiptIds R ON RE.ReceiptId=R.Id
	WHERe RE.JobStepInstanceId=@JobStepInstanceId AND RE.IsValid=1 AND RE.PayDownId IS NOT NULL

END

GO
