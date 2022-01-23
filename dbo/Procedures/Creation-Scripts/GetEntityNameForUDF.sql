SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetEntityNameForUDF]
(
@ContractId int,
@InvoiceId int,
@ContractSequenceNumber nvarchar(100) output,
@InvoiceNumber nvarchar(100) output
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT @ContractSequenceNumber = SequenceNumber FROM Contracts WHERE Id = @ContractId;
SELECT @InvoiceNumber = InvoiceNumber FROM PayableInvoices WHERE Id = @InvoiceId;
END

GO
