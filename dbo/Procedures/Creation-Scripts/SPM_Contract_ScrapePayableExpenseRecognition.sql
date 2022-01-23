SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_ScrapePayableExpenseRecognition]
AS
BEGIN	
	UPDATE TGT
	SET TGT.ScrapePayableExpenseRecognition = SRC.ScrapePayableExpenseRecognition
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT Payables.EntityID AS ContractId,
			Sum(Sundries.Amount_Amount) AS ScrapePayableExpenseRecognition
			FROM Sundries WITH (NOLOCK)
			INNER JOIN Payables WITH (NOLOCK) ON Payables.Id = Sundries.PayableId 
				AND Sundries.Memo like '%Origination Scrape Payable%' AND Sundries.SundryType='PayableOnly' AND Sundries.IsActive=1 AND Sundries.Status='Approved' 
				AND Sundries.TYPE='Sundry' And Payables.IsGlPosted=1 AND Payables.EntityType='CT'
			INNER JOIN ##ContractMeasures CB ON CB.Id = Payables.EntityID

     		GROUP BY Payables.EntityID

		) SRC
		ON TGT.Id = SRC.ContractId

END

GO
