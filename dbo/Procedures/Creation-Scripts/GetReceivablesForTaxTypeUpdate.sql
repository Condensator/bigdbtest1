SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceivablesForTaxTypeUpdate]
(
	@BatchSize INT
)
AS 
BEGIN
	SET NOCOUNT ON;
	SELECT TOP (@BatchSize) Id FROM Receivables 
	WHERE ReceivableTaxType = 'None'
END

GO
