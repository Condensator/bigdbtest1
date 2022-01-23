SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdatePayableInvoiceFromRebook]
(
@LoanFinanceId BIGINT
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE PayableInvoices
SET  ParentPayableInvoiceId = PI.Id
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM PayableInvoices PI
JOIN dbo.LoanFundings LF  On PI.Id = LF.FundingId
WHERE LF.LoanFinanceId = @LoanFinanceId
AND PI.ParentPayableInvoiceId IS NULL
END

GO
