SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TruncateAssetLocationTaxBasisExtractTable]
AS
BEGIN
TRUNCATE TABLE AssetLocationTaxBasisProcessingDetail_Extract
END

GO
