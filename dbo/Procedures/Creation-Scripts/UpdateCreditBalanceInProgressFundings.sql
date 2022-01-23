SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateCreditBalanceInProgressFundings]
(
@progressFundingDetails ProgressFundingDetails READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
MERGE PayableInvoiceOtherCosts AS Funding
USING @progressFundingDetails AS progressfunding
ON (Funding.Id = progressfunding.ProgressFundingId)
WHEN MATCHED THEN
UPDATE SET
Funding.CreditBalance_Amount = Funding.CreditBalance_Amount - progressfunding.TakeDownAmount,
--Funding.CapitalizedProgressPayment_Amount = Funding.CapitalizedProgressPayment_Amount + progressfunding.CapitalizedProgressPayment,
Funding.UpdatedById = @UpdatedById,
Funding.UpdatedTime = @UpdatedTime
;
END

GO
