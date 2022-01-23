SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdatePayableInvoiceBalance]
(
@ParentPayableInvoiceId BIGINT,
@BalanceAmount Decimal,
@CurrentUserId BIGINT,
@CurrentTime DateTimeOffSet
)
AS
BEGIN
SET NOCOUNT ON
UPDATE PayableInvoices SET Balance_Amount=Balance_Amount-@BalanceAmount ,
UpdatedById=@CurrentUserId,
UpdatedTime=@CurrentTime
FROM PayableInvoices
WHERE PayableInvoices.ParentPayableInvoiceId=@ParentPayableInvoiceId
And PayableInvoices.Status='Completed'
END

GO
