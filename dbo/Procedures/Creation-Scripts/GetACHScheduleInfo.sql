SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetACHScheduleInfo]
(
@ContractId BIGINT,
@CustomerId BIGINT,
@ContractType Nvarchar(8),
@ReceivableTypeLeaseFloatRate Nvarchar(84),
@ProcessedTillDate DATETIME=NULL,
@ConsiderInputReceivables Bit,
@ReceivableIds ReceivableIdParam READONLY,
@ReceivableTypeNames ReceivableTypeParam READONLY,
@CompletedACHSchedules ReceivableIdParam READONLY
)
AS
SELECT
Receivables.Id AS ReceivableId
,ReceivableTypes.Id  AS ReceivableTypeId
,ISNULL(ReceivableTaxes.Amount_Amount,0.00) AS TaxBalance
,Receivables.TotalBalance_Amount AS ReceivableBalance
,Receivables.DueDate
,Receivables.PaymentScheduleId
,Receivables.CustomerId CustomerId
FROM Receivables WITH (NOLOCK)
JOIN ReceivableCodes WITH (NOLOCK) on Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes WITH (NOLOCK) on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
LEFT JOIN ReceivableTaxes WITH (NOLOCK) ON Receivables.Id = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
WHERE Receivables.EntityId = @ContractId
AND Receivables.EntityType = @ContractType
AND (@ProcessedTillDate IS NULL OR Receivables.DueDate > @ProcessedTillDate)
AND (@ConsiderInputReceivables=0 OR Receivables.Id IN(SELECT ReceivableId FROM @ReceivableIds))
AND Receivables.IsActive=1
AND Receivables.IsCollected=1
AND (Receivables.IsDummy=0 OR Receivables.IsDSL=1)
AND ((Receivables.TotalBalance_Amount + ISNULL(ReceivableTaxes.Balance_Amount,0.00)) <> 0)
AND (ReceivableTypes.Name IN(SELECT ReceivableTypeName FROM @ReceivableTypeNames))
AND (Receivables.Id NOT IN(SELECT ReceivableId FROM @CompletedACHSchedules))

GO
