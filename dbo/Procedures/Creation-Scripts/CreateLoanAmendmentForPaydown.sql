SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateLoanAmendmentForPaydown]
(
@FinanceId BIGINT
,@ReceivableAmendmentType NVARCHAR(50)
,@AmendmentDate DATETIMEOFFSET
,@Comment NVARCHAR(200)
,@AmendmentAtInception BIT
,@CurrencyCode NVARCHAR(3)
,@CreatedId BIGINT
,@CreatedTime DATETIMEOFFSET
,@LoanPaydownId BIGINT
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN
INSERT INTO LoanAmendments(QuoteName,QuoteStatus,AmendmentType,AmendmentDate,Comment,AmendmentAtInception
,ReceivableAmendmentType,CreatedById,CreatedTime,LoanFinanceId,LoanPaymentScheduleId
,IsLienFilingRequired,IsLienFilingException,TDRReason,IsTDR,IsRestructureDateConfirmed,PreRestructureDateLoanNBV_Amount
,PreRestructureDateLoanNBV_Currency,PostRestructureDateLoanNBV_Amount,PostRestructureDateLoanNBV_Currency,PreRestructureFAS91Balance_Amount
,PreRestructureFAS91Balance_Currency,PostRestructureFAS91Balance_Amount,PostRestructureFAS91Balance_Currency,NetWritedown_Amount
,NetWritedown_Currency,IsModified,SourceId)
VALUES
('Paydown','Approved','Paydown',@AmendmentDate,@Comment,@AmendmentAtInception,@ReceivableAmendmentType
,@CreatedId,@CreatedTime,@FinanceId,null,CAST (0 AS BIT),CAST (0 AS BIT),'_',CAST (0 AS BIT),CAST (0 AS BIT),0.0
,@CurrencyCode,0.0,@CurrencyCode,0.0
,@CurrencyCode,0.0,@CurrencyCode,0.0
,@CurrencyCode,0,@LoanPaydownId)
END

GO
