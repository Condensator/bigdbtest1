SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[FileBasedReceiptPosting_LogInformation]  
(  
	@JobStepInstanceId   BIGINT,
	@ReceiptPostedTowardsCustomerMsg NVARCHAR(MAX)
)  
AS  
BEGIN  
	IF EXISTS(	SELECT * 
				FROM Receipts_Extract RE
				JOIN CommonExternalReceipt_Extract CEX ON RE.DumpId = CEX.Id
				JOIN ReceivableInvoices RI ON CEX.EntityType = 'Customer' AND RI.CustomerId = CEX.EntityId 
				JOIN Receipts R ON R.Number = RE.ReceiptNumber
				WHERE RE.JobStepInstanceId = @JobStepInstanceId
				AND RE.IsValid = 1 AND CEX.IsValid = 1
				AND RE.CurrencyId != RI.CurrencyId
				AND R.Status != 'Inactive'
			 ) 
	BEGIN
		INSERT INTO JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,JobStepInstanceId) VALUES (@ReceiptPostedTowardsCustomerMsg,'Information',1,GETDATE(),@JobStepInstanceId)
	END
END

GO
