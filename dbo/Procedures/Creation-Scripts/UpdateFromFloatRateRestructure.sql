SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateFromFloatRateRestructure]
(
@LeaseFinanceId bigint,
@ContractId bigint,
@FloatRateTillDate DateTime NULL,
@UpdatedById bigint,
@UpdatedTime DateTimeOffset
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE ContractFloatRates SET IsAutoRestructureProcessed= 1 ,UpdatedById=@UpdatedById,UpdatedTime=@UpdatedTime
WHERE ContractId = @ContractId
AND EffectiveDate <= @FloatRateTillDate
AND IsAutoRestructureProcessed=0
UPDATE LeaseFinances SET RestructureOnFloatRateRunTillDate = @FloatRateTillDate,UpdatedById=@UpdatedById,UpdatedTime=@UpdatedTime WHERE Id = @LeaseFinanceId
END

GO
