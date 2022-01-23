SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[FetchACHReceiptEmailNotifications]
(
 @PostedReceiptStatus              NVARCHAR(10),
 @JobStepInstanceId                BIGINT
)
AS
  BEGIN
    SET NOCOUNT ON;
	 
    CREATE TABLE #EmailDetails
    (ACHReceiptId                  BIGINT,
     ReceiptId                     BIGINT,
     ToEmailId                     NVARCHAR(2000),
     EmailTemplateId               BIGINT
    );

    SELECT  
	      R.ACHReceiptId,
		  R.ReceiptId,
		  R.CustomerId,
		  ARD.ContractId,
		  RD.BillToId,
		  CAST('' AS nvarchar) AS EmailNotificationLevel,
		  CAST(0 AS BIT) AS IsEmailNotification
	INTO #ACHDetails
    FROM Receipts_Extract R
    INNER JOIN ACHReceipts AR ON R.ACHReceiptId = AR.Id
	INNER JOIN ACHReceiptApplicationReceivableDetails ARD ON R.ACHReceiptId = ARD.ACHReceiptId 
	INNER JOIN ReceivableDetails RD ON ARD.ReceivableDetailId = RD.Id
	WHERE R.JobStepInstanceId = @JobStepInstanceId
          AND R.IsValid = 1 AND AR.Status = @PostedReceiptStatus
    GROUP BY R.ACHReceiptId,R.ReceiptId,R.CustomerId,ARD.ContractId,RD.BillToId

    INSERT INTO #EmailDetails
	SELECT 
	      A.ACHReceiptId,
	      A.ReceiptId,
		  C.PostACHNotificationEmailTo AS ToEmailId,
		  C.PostACHNotificationEmailTemplateId AS EmailTemplateId
	FROM #ACHDetails A
	INNER JOIN Customers C ON A.CustomerId = C.Id
	WHERE IsEmailNotification = 0 AND IsPostACHNotification = 1
	GROUP BY A.ACHReceiptId, A.ReceiptId,C.PostACHNotificationEmailTo,C.PostACHNotificationEmailTemplateId

	UPDATE #ACHDetails
	SET 
	   IsEmailNotification = CAST(1 AS BIT)
	FROM #ACHDetails A
	INNER JOIN #EmailDetails E ON A.ACHReceiptId = E.ACHReceiptId
	WHERE A.IsEmailNotification = 0

    INSERT INTO #EmailDetails
	SELECT 
		  A.ACHReceiptId,
	      A.ReceiptId,
		  B.PostACHNotificationEmailTo AS ToEmailId,
		  B.PostACHNotificationEmailTemplateId AS EmailTemplateId
	FROM #ACHDetails A
	INNER JOIN BillToes B ON A.BillToId = B.Id
	WHERE IsEmailNotification = 0 AND IsPostACHNotification = 1
	GROUP BY A.ACHReceiptId,A.ReceiptId,B.PostACHNotificationEmailTo,B.PostACHNotificationEmailTemplateId

	UPDATE #ACHDetails
	SET 
	   IsEmailNotification = CAST(1 AS BIT)
	FROM #ACHDetails A
	INNER JOIN #EmailDetails E ON A.ACHReceiptId = E.ACHReceiptId
    WHERE A.IsEmailNotification = 0

	INSERT INTO #EmailDetails
	SELECT 
	     A.ACHReceiptId,
		 A.ReceiptId,
	     C.PostACHNotificationEmailTo AS ToEmailId,
		 C.PostACHNotificationEmailTemplateId AS EmailTemplateId
	FROM #ACHDetails A
	INNER JOIN ContractBillings C ON A.ContractId = C.Id
	WHERE IsEmailNotification = 0 AND IsPostACHNotification = 1
	GROUP BY A.ACHReceiptId,A.ReceiptId,C.PostACHNotificationEmailTo,C.PostACHNotificationEmailTemplateId

	UPDATE #ACHDetails
	SET  
	   IsEmailNotification = CAST(1 AS BIT) 
	FROM #ACHDetails A
	INNER JOIN #EmailDetails E ON A.ACHReceiptId = E.ACHReceiptId
	WHERE A.IsEmailNotification = 0

    SELECT 
	  ReceiptId
	 ,ToEmailId
	 ,E.Name AS EmailTemplateName
	FROM #EmailDetails ED
	INNER JOIN EmailTemplates E ON ED.EmailTemplateId = E.Id
END

GO
