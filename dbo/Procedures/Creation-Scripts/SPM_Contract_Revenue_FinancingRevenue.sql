SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_Revenue_FinancingRevenue]
AS
BEGIN

	UPDATE TGT 
	SET Revenue = SRC.Revenue,  
	    FinancingRevenue = SRC.FinancingRevenue
    FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
				SELECT	Sum(ReceivableDetails.LeaseComponentAmount_Amount) AS Revenue, Sum(ReceivableDetails.NonLeaseComponentAmount_Amount) As FinancingRevenue,  EC.ContractId As ContractId  
				FROM ReceivableDetails WITH (NOLOCK)
				INNER JOIN Receivables WITH (NOLOCK) ON Receivables.Id = ReceivableDetails.ReceivableId 
				INNER JOIN ReceivableCodes WITH (NOLOCK) on Receivables.ReceivableCodeId = ReceivableCodes.Id 
				INNER JOIN ReceivableTypes WITH (NOLOCK) ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id 
				INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId = Receivables.EntityId
				AND (ReceivableTypes.Name  = 'BuyOut' or ReceivableTypes.Name  = 'LeasePayoff')
				Where Receivables.IsGLPosted=1 AND Receivables.FunderId is Null  and Receivables.IsActive=1
				GROUP BY  EC.ContractId

			) SRC
		ON (TGT.Id = SRC.ContractId)  
					
END

GO
