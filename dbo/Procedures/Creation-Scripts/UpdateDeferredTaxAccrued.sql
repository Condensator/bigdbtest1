SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateDeferredTaxAccrued]
(
@LeveragedLeaseAmortId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE LeveragedLeaseAmorts SET DeferredTaxes_Amount = 0.00 , UpdatedTime = @UpdatedTime , UpdatedById = @UpdatedById
WHERE Id = @LeveragedLeaseAmortId
END

GO
