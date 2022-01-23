SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReceivableInvoicesEmailSentFlag]
(
@InvoiceIds VARCHAR(MAX),
@UpdatedBy VARCHAR(30),
@UpdatedTime DATETIMEOFFSET,
@DeliveryDate DATE,
@DeliveryMethod NVARCHAR(5),
@DeliveryJobStepInstanceId BIGINT,
@FailedInvoiceIds VARCHAR(MAX)
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @Invoices TABLE(ID Bigint)
DECLARE @FailedInvoices TABLE(ID Bigint)
INSERT INTO @Invoices
SELECT * FROM ConvertCSVToBigIntTable(@InvoiceIds, ',')
INSERT INTO @FailedInvoices
SELECT * FROM ConvertCSVToBigIntTable(@FailedInvoiceIds, ',')
UPDATE RI
SET RI.IsEmailSent = 1,
RI.UpdatedById = @UpdatedBy,
RI.UpdatedTime = @UpdatedTime,
RI.DeliveryDate = @DeliveryDate,
RI.DeliveryMethod = @DeliveryMethod,
RI.DeliveryJobStepInstanceId = @DeliveryJobStepInstanceId
FROM ReceivableInvoices RI
INNER JOIN @Invoices Inv ON RI.Id = Inv.ID
WHERE RI.Id NOT IN(SELECT ID FROM @FailedInvoices)
/*For Activity Center GE01-2571*/
UPDATE RI
SET RI.UpdatedById = @UpdatedBy,
RI.UpdatedTime = @UpdatedTime,
RI.DeliveryDate = @DeliveryDate,
RI.DeliveryJobStepInstanceId = @DeliveryJobStepInstanceId
FROM ReceivableInvoices RI
INNER JOIN @FailedInvoices Inv ON RI.Id = Inv.ID

GO
