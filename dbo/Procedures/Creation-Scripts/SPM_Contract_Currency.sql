SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_Currency]
AS
BEGIN
	
	UPDATE TGT
	SET TGT.Currency = SRC.Currency
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT Contracts.Id AS ContractId, 
				   CurrencyCodes.ISO AS Currency
			FROM Contracts WITH (NOLOCK)
				INNER JOIN Currencies WITH (NOLOCK) ON Currencies.Id = Contracts.CurrencyId    
				INNER JOIN CurrencyCodes WITH (NOLOCK) ON Currencies.CurrencyCodeId = CurrencyCodes.Id  

		) SRC
		ON TGT.Id = SRC.ContractId 
END

GO
