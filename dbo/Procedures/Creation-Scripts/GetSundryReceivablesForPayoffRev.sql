SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetSundryReceivablesForPayoffRev]
(
@PayoffId BIGINT,
@ContractId BIGINT
)
AS
BEGIN
SELECT ReceivableId = R.Id
FROM Receivables R
JOIN ReceivableCodes RC on RC.Id = R.ReceivableCodeId
JOIN ReceivableTypes RT on RC.ReceivableTypeId = RT.Id
JOIN ReceivableCategories RCT on RCT.Id = RC.ReceivableCategoryId
WHERE R.EntityId = @ContractId
AND (RT.Name = 'Sundry' OR RT.Name = 'SundrySeparate' OR RT.Name = 'PropertyTaxEscrow')
--AND RCT.Name <> 'Payoff'
AND R.EntityType = 'CT'
AND R.IsActive = 1
AND R.SourceId = @PayoffId
AND R.SourceTable = 'LeasePayoff'
AND R.TotalAmount_Amount < 0.0
END

GO
