SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ClearExposureTables]
(
@IncludeVendorExposure BIT,
@BatchSize BIGINT
)
AS
BEGIN
SET NOCOUNT OFF
DECLARE @DeletedCount BIGINT;
SET @DeletedCount = @BatchSize
WHILE (@BatchSize = @DeletedCount)
BEGIN
DELETE TOP(@BatchSize) FROM DealExposures ;
SELECT @DeletedCount = @@ROWCOUNT
END

SET @DeletedCount = @BatchSize
WHILE (@BatchSize = @DeletedCount)
BEGIN
DELETE TOP(@BatchSize) FROM CustomerExposures;
SELECT @DeletedCount = @@ROWCOUNT
END 

IF(	@IncludeVendorExposure = 1	)
BEGIN
SET @DeletedCount = @BatchSize  
WHILE (@BatchSize = @DeletedCount)
BEGIN
DELETE TOP(@BatchSize) FROM VendorExposures;
SELECT @DeletedCount = @@ROWCOUNT
END 

SET @DeletedCount = @BatchSize  
WHILE (@BatchSize = @DeletedCount)
BEGIN
DELETE TOP(@BatchSize) FROM SyndicatedDealExposures;
SELECT @DeletedCount = @@ROWCOUNT
END 
END
END

GO
