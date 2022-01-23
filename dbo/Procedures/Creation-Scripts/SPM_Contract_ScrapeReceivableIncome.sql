SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_ScrapeReceivableIncome]
AS
BEGIN
	UPDATE TGT
	SET TGT.ScrapeReceivableIncome = SRC.ScrapeReceivableIncome
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT Receivables.EntityId AS ContractId,
				   Sum(Sundries.Amount_Amount) AS ScrapeReceivableIncome 
				   FROM Sundries WITH (NOLOCK)
				   INNER JOIN Receivables WITH (NOLOCK) ON Receivables.Id = Sundries.ReceivableId AND Sundries.SundryType='ReceivableOnly' 
						AND Sundries.IsActive=1 AND Sundries.Status='Approved' and Sundries.Type='Scrape' AND Receivables.IsGLPosted=1
						AND Receivables.EntityType='CT'
				   INNER JOIN ##ContractMeasures CB ON CB.Id = Receivables.EntityId
			GROUP BY Receivables.EntityId

		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
