SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_SaleProceeds]
AS
BEGIN

	UPDATE TGT
	SET TGT.SaleProceeds = SRC.SaleProceeds
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT Contracts.Id AS ContractId,
			SUM(Receivables.TotalAmount_Amount) AS SaleProceeds 
			FROM Receivables WITH (NOLOCK) 
			INNER JOIN AssetSaleReceivables WITH (NOLOCK) ON Receivables.Id = AssetSaleReceivables.ReceivableId 			
			INNER JOIN AssetSales WITH (NOLOCK) ON AssetSales.Id = AssetSaleReceivables.AssetSaleId
			INNER JOIN AssetSaleDetails WITH (NOLOCK) ON AssetSales.Id = AssetSaleDetails.AssetSaleId
			INNER JOIN Assets WITH (NOLOCK) ON AssetSaleDetails.AssetId = Assets.Id
				AND AssetSales.AssetSaleReceivableCodeId IS NOT NULL  AND AssetSales.Status = 'Completed'
			INNER JOIN Contracts WITH (NOLOCK) on Assets.PreviousSequenceNumber = Contracts.SequenceNumber
				AND Receivables.FunderId IS NULL and Receivables.IsActive=1 and AssetSaleReceivables.IsActive =1
			INNER JOIN ##ContractMeasures CB ON CB.Id = Contracts.Id

     		GROUP BY  Contracts.Id

		) SRC
		ON TGT.Id = SRC.ContractId

END

GO
