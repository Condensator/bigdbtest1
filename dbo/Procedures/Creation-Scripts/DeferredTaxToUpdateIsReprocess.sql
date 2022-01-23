SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DeferredTaxToUpdateIsReprocess]
(
@DeferredTaxes DeferredTaxToUpdate READONLY
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE DFT SET IsReprocess = DF.IsReProcess, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM DeferredTaxes DFT
JOIN @DeferredTaxes DF ON DFT.Id = DF.DeferredTaxId;
SET NOCOUNT OFF;
END

GO
