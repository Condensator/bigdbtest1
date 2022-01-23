SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PopulateStatementInvoiceAssociationForPostByFile]  
(  
 @JobStepInstanceId BIGINT,   
 @UserId    BIGINT  
)  
AS  
BEGIN  
SET NOCOUNT OFF;  

	INSERT INTO ReceiptStatmentInvoiceAssociations_Extract 
	(StatementInvoiceId, ReceiptId, JobStepInstanceId, CreatedTime, CreatedById)
	SELECT 
		ComputedReceivableInvoiceId, RD.ReceiptId, @JobStepInstanceId, GETDATE(), @UserId
	FROM Receipts_Extract RD
	INNER JOIN ReceiptPostByFileExcel_Extract RPBF 
		ON RD.ReceiptId = RPBF.GroupNumber AND RD.JobStepInstanceId = RPBF.JobStepInstanceId
	WHERE RD.JobStepInstanceId = @JobStepInstanceId AND RD.IsNewReceipt = 1 AND IsStatementInvoice =1
	GROUP BY ComputedReceivableInvoiceId,RD.ReceiptId
END

GO
