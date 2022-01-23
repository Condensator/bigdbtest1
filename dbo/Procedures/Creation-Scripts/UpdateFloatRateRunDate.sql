SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateFloatRateRunDate]
(
@LeaseFinanceId BIGINT,
@FloatRateUpdateRunDate DATETIMEOFFSET,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE LeaseFinances SET FloatRateUpdateRunDate = @FloatRateUpdateRunDate,UpdatedById = @UpdatedById,UpdatedTime = @UpdatedTime WHERE Id =  @LeaseFinanceId
END

GO
