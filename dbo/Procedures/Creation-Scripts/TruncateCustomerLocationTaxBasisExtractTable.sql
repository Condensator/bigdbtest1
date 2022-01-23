SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TruncateCustomerLocationTaxBasisExtractTable]
AS
BEGIN
TRUNCATE TABLE CustomerLocationTaxBasisProcessingDetail_Extract
END

GO
