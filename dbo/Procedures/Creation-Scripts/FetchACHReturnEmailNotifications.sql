SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[FetchACHReturnEmailNotifications]
(
 @JobStepInstanceId                BIGINT
)
AS
  BEGIN
    SET NOCOUNT ON;
	 
    CREATE TABLE #EmailDetails
    (ReceiptId                     BIGINT,
     ToEmailId                     NVARCHAR(2000),
     EmailTemplateId               BIGINT
    );

	SELECT 
		R.Id AS ReceiptId, 
		R.ContractId, 
		R.CustomerId, 
		ARE.NSFBillToId AS BillToId,
		CAST(0 AS BIT) AS IsEmailNotification
	INTO #ACHReturnDetails
	FROM ACHReturn_Extract ARE
	INNER JOIN Receipts R ON ARE.ReceiptId = R.Id
	INNER JOIN ACHRunDetails ARD ON ARE.ReceiptId = ARD.EntityId
	WHERE ARE.JobStepInstanceId = @JobStepInstanceId AND ARD.IsReversed = 1
	GROUP BY R.Id, R.ContractId, R.CustomerId, ARE.NSFBillToId

	INSERT INTO #EmailDetails
	SELECT 
		 A.ReceiptId,
	     C.ReturnACHNotificationEmailTo AS ToEmailId,
		 C.ReturnACHNotificationEmailTemplateId AS EmailTemplateId
	FROM #ACHReturnDetails A
	INNER JOIN Customers C ON A.CustomerId = C.Id
	WHERE IsEmailNotification = 0 AND IsReturnACHNotification = 1
	GROUP BY A.ReceiptId,C.ReturnACHNotificationEmailTo,C.ReturnACHNotificationEmailTemplateId

	UPDATE #ACHReturnDetails
	SET  
	   IsEmailNotification = CAST(1 AS BIT) 
	FROM #ACHReturnDetails A
	INNER JOIN #EmailDetails E ON A.ReceiptId = E.ReceiptId
	WHERE A.IsEmailNotification = 0

    INSERT INTO #EmailDetails
	SELECT 
	      A.ReceiptId,
		  B.ReturnACHNotificationEmailTo AS ToEmailId,
		  B.ReturnACHNotificationEmailTemplateId AS EmailTemplateId
	FROM #ACHReturnDetails A
	INNER JOIN BillToes B ON A.BillToId = B.Id
	WHERE IsEmailNotification = 0 AND IsReturnACHNotification = 1
	GROUP BY A.ReceiptId,B.ReturnACHNotificationEmailTo,B.ReturnACHNotificationEmailTemplateId

	UPDATE #ACHReturnDetails
	SET 
	   IsEmailNotification = CAST(1 AS BIT)
	FROM #ACHReturnDetails A
	INNER JOIN #EmailDetails E ON A.ReceiptId = E.ReceiptId
    WHERE A.IsEmailNotification = 0

    INSERT INTO #EmailDetails
	SELECT 
	      A.ReceiptId,
		  C.ReturnACHNotificationEmailTo AS ToEmailId,
		  C.ReturnACHNotificationEmailTemplateId AS EmailTemplateId
	FROM #ACHReturnDetails A
	INNER JOIN ContractBillings C ON A.ContractId = C.Id
	WHERE IsEmailNotification = 0 AND IsReturnACHNotification = 1
	GROUP BY A.ReceiptId,C.ReturnACHNotificationEmailTo,C.ReturnACHNotificationEmailTemplateId

	UPDATE #ACHReturnDetails
	SET 
	   IsEmailNotification = CAST(1 AS BIT)
	FROM #ACHReturnDetails A
	INNER JOIN #EmailDetails E ON A.ReceiptId = E.ReceiptId
	WHERE A.IsEmailNotification = 0


    SELECT 
	  ReceiptId
	 ,ToEmailId
	 ,E.Name AS EmailTemplateName
	FROM #EmailDetails ED
	INNER JOIN EmailTemplates E ON ED.EmailTemplateId = E.Id
END

GO
