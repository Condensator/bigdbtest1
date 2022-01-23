SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetOldCPUFinanceInfoForRestructure]
(
@CPUFinanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
/*CPU Finance Info*/
SELECT
CPUBillings.BasePassThroughPercent,
CPUBillings.OveragePassThroughPercent,
CPUFinances.BasePaymentFrequency,
CPUAccountings.BaseFeePayableCodeId,
CPUAccountings.OverageFeePayableCodeId
FROM
CPUFinances
JOIN CPUBillings ON CPUFinances.Id = CPUBillings.Id
JOIN CPUAccountings ON CPUFinances.Id = CPUAccountings.Id
WHERE
CPUFinances.Id = @CPUFinanceId
SET NOCOUNT OFF;
END

GO
