SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PopulateStatementInvoiceAssociationForLockbox]  
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
		ReceivableInvoiceId, RD.ReceiptId, @JobStepInstanceId, GETDATE(), @UserId
	FROM Receipts_Extract RD
	INNER JOIN ReceiptPostByLockBox_Extract RPBF 
		ON RD.DumpId = RPBF.Id AND RD.JobStepInstanceId = RPBF.JobStepInstanceId
	WHERE RD.JobStepInstanceId = @JobStepInstanceId AND RD.IsNewReceipt = 1 AND IsStatementInvoice =1
	GROUP BY ReceivableInvoiceId,rd.ReceiptId 
END

GO
