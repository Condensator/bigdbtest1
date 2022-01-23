SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateStopInvoicingForCPUReceivables]
(
@ContractId BIGINT,
@StopInvoicingRentals BIT,
@EffectiveDate DATE,
@AssetIds NVARCHAR(MAX),
@CPUScheduleSourceTable NVARCHAR(11),
@CT NVARCHAR(2),
@NotInvoicedBilledStatus NVARCHAR(11)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT Id INTO #AssetIds FROM dbo.ConvertCSVToBigIntTable(@AssetIds,',')
UPDATE
[dbo].[ReceivableDetails]
SET
StopInvoicing = @StopInvoicingRentals
FROM
ReceivableDetails
JOIN Receivables	ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN #AssetIds		ON ReceivableDetails.AssetId = #AssetIds.Id
LEFT JOIN CPUPaymentSchedules ON Receivables.PaymentScheduleId = CPUPaymentSchedules.Id
WHERE
Receivables.SourceTable = @CPUScheduleSourceTable
AND Receivables.EntityType = @CT
AND Receivables.EntityId = @ContractId
AND ReceivableDetails.BilledStatus = @NotInvoicedBilledStatus
AND ReceivableDetails.StopInvoicing <> @StopInvoicingRentals
AND ReceivableDetails.IsActive = 1
AND @EffectiveDate <
(
CASE
WHEN CPUPaymentSchedules.Id IS NULL
THEN
DATEADD(DAY, -1, Receivables.DueDate)
ELSE
CPUPaymentSchedules.EndDate
END
)
DROP TABLE #AssetIds
SET NOCOUNT OFF;
END

GO
