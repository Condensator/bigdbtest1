SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_CollateralLoanScrapedAssets]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 A.Id as AssetId INTO ##Asset_CollateralLoanScrapedAssets
FROM
	Assets A
INNER JOIN
	Contracts C ON A.PreviousSequenceNumber = C.SequenceNumber 
	AND C.ContractType = 'Loan' AND A.Status NOT IN ('Inventory')

CREATE NONCLUSTERED INDEX IX_CollateralLoanScrapedAssets_AssetId ON ##Asset_CollateralLoanScrapedAssets(AssetId);

END

GO
