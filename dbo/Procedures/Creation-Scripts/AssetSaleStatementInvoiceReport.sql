SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AssetSaleStatementInvoiceReport]
(
@AssetSaleId Bigint
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
InstallmentNumber
,Amount_Amount [Amount]
,Amount_Currency [Amount_Currency]
,Tax_Amount [Tax]
,Tax_Currency [Tax_Currency]
,DueDate [DueDate]
FROM
AssetSaleReceivables
WHERE
AssetSaleId = @AssetSaleId
AND IsActive = 1
ORDER BY InstallmentNumber
END

GO
