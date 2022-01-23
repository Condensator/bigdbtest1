SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CustomerLevelLoanInvoiceWithInterestAccrualAddendumHeader]
(
@InvoiceId BIGINT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @InvoiceID BigInt = 8092;
SELECT
customer.InvoiceId
,customer.InvoiceType
,customer.InvoiceNumber
,customer.InvoiceNumberLabel
,customer.InvoiceRunDateLabel
,customer.InvoiceRunDate
,customer.DueDate
,customer.CustomerNumber
FROM
InvoiceExtractCustomerDetails customer
WHERE customer.InvoiceID = @InvoiceID
END

GO
