SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateBilledStatusForCreditReceivablesInPaydown]
(
@LoanPaydownId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE ARD SET ARD.BilledStatus= 'Invoiced',ARD.UpdatedById = @UpdatedById, ARD.UpdatedTime = @UpdatedTime FROM
LoanPayDowns LPD
JOIN LoanPaydownSundries LPS ON LPD.Id = LPS.LoanPayDownId
JOIN Sundries SD ON LPS.SundryId = SD.Id
JOIN Receivables R ON SD.ReceivableId = R.Id
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableDetails ARD ON Rd.Id = ARD.AdjustmentBasisReceivableDetailId
WHERE LPD.Id = @LoanPaydownId
AND LPS.IncludeInPaydownInvoice = 1
AND LPS.SundryType = 'ReceivableOnly'
AND LPS.IsActive = 1
AND LPD.Id = @LoanPaydownId
UPDATE ARD SET ARD.BilledStatus= 'Invoiced',ARD.UpdatedById = @UpdatedById, ARD.UpdatedTime = @UpdatedTime FROM
LoanPayDowns LPD
INNER JOIN Receivables R ON LPD.Id = R.SourceId AND R.SourceTable = 'LoanPaydown' AND R.IsActive = 1
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
INNER JOIN ReceivableDetails ARD ON RD.Id = ARD.AdjustmentBasisReceivableDetailId
INNER JOIN Receivables AR ON ARD.ReceivableId = AR.Id
INNER JOIN Sundries SD ON R.Id = SD.ReceivableId
WHERE
LPD.Id = @LoanPaydownId
UPDATE ARD SET ARD.BilledStatus= 'Invoiced',ARD.UpdatedById = @UpdatedById, ARD.UpdatedTime = @UpdatedTime FROM
LoanPayDowns LPD
JOIN Receivables R ON LPD.Id = R.SourceId AND R.SourceTable = 'LoanPaydown'
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableDetails ARD ON RD.Id = ARD.AdjustmentBasisReceivableDetailId
JOIN Receivables AR ON ARD.ReceivableId = AR.ID
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND  RT.Name = 'LoanPrincipal'
WHERE LPD.Id = @LoanPaydownId
AND (LPD.PaydownReason ='VoluntaryPrePayment' OR LPD.PaydownReason ='FullPaydown')
UPDATE ARD SET ARD.BilledStatus= 'Invoiced',ARD.UpdatedById = @UpdatedById, ARD.UpdatedTime = @UpdatedTime FROM
LoanPayDowns LPD
JOIN Receivables R ON LPD.Id = R.SourceId AND R.SourceTable = 'LoanPaydown'
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableDetails ARD ON RD.Id = ARD.AdjustmentBasisReceivableDetailId
JOIN Receivables AR ON ARD.ReceivableId = AR.Id
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND  RT.Name = 'LoanInterest'
WHERE LPD.Id = @LoanPaydownId
AND (LPD.PaydownReason ='VoluntaryPrePayment' OR LPD.PaydownReason ='FullPaydown' OR LPD.PaydownReason ='CollateralRelease')
END

GO
