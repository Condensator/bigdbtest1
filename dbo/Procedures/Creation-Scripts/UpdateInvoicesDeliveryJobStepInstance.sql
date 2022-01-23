SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateInvoicesDeliveryJobStepInstance]
(
@UpdatedBy VARCHAR(30),
@UpdatedTime DATETIMEOFFSET,
@DeliveryDate DATE,
@DeliveryJobStepInstanceId BIGINT,
@FailedInvoiceIds VARCHAR(MAX)
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @FailedInvoices TABLE(ID Bigint)
INSERT INTO @FailedInvoices
SELECT * FROM ConvertCSVToBigIntTable(@FailedInvoiceIds, ',')
/*For Activity Center GE01-2571*/
UPDATE RI
SET RI.UpdatedById = @UpdatedBy,
RI.UpdatedTime = @UpdatedTime,
RI.DeliveryDate = @DeliveryDate,
RI.DeliveryJobStepInstanceId = @DeliveryJobStepInstanceId
FROM ReceivableInvoices RI
INNER JOIN @FailedInvoices Inv ON RI.Id = Inv.ID

GO
