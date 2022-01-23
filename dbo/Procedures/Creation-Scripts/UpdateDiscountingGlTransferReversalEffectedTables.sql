SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateDiscountingGlTransferReversalEffectedTables]
(
@ReceivableTaxIds IdList READONLY,
@PayableIdsIds IdList READONLY,
@ReceivableIds IdList READONLY,
@CapitalizedInterestIds IdList READONLY,
@AmortScheduleIds  IdList READONLY
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE ReceivableTaxes SET IsGLPosted = 0
FROM ReceivableTaxes RT
JOIN @ReceivableTaxIds RIds ON RT.Id = RIds.Id
UPDATE ReceivableTaxDetails SET IsGLPosted = 0
FROM ReceivableTaxDetails RTD
JOIN ReceivableTaxes RT ON RTD.ReceivableTaxId = RT.Id
JOIN @ReceivableTaxIds RIds ON RT.Id = RIds.Id
UPDATE Payables SET IsGLPosted = 0
FROM Payables P
JOIN @PayableIdsIds PIds ON P.Id = PIds.Id
UPDATE Receivables SET IsGLPosted = 0
FROM Receivables R
JOIN @ReceivableIds RIds ON R.Id = RIds.Id
UPDATE DiscountingCapitalizedInterests SET GLJournalId = null
FROM DiscountingCapitalizedInterests DCI
JOIN @CapitalizedInterestIds CIIds ON DCI.Id = CIIds.Id
UPDATE DiscountingAmortizationSchedules SET IsGLPosted = 0
FROM DiscountingAmortizationSchedules DAS
JOIN @AmortScheduleIds ASIds ON DAS.Id = ASIds.Id
END

GO
