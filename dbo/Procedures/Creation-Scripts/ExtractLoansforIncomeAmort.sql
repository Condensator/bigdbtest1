SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[ExtractLoansforIncomeAmort]
(
@EntityType NVARCHAR(30),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@FilterOption NVARCHAR(10),
@CustomerId BIGINT,
@ContractId BIGINT,
@JobInstanceId BIGINT,
@AllFilterOption NVARCHAR(10),
@OneFilterOption NVARCHAR(10),
@CustomerEntityType NVARCHAR(15),
@LoanEntityType NVARCHAR(15),
@CommencedBookingStatus NVARCHAR(20),
@TerminatedBookingStatus NVARCHAR(20),
@ActiveLegalEntityStatus NVARCHAR(20),
@LegalEntityIds LegalEntityIdList READONLY,
@ProcessThroughDate AS DATE
)
AS
BEGIN
DECLARE @True BIT = 1;
INSERT INTO LoanIncomeAmortJobExtracts(LoanFinanceId,SequenceNumber,JobInstanceId, CreatedById, CreatedTime,
ContractId,LegalEntityId,InvoiceLeadDays,IsSubmitted)
SELECT lf.Id LoanFinanceId,
c.SequenceNumber,
@JobInstanceId,
@CreatedById,
@CreatedTime,
lf.ContractId,
lf.LegalEntityId,
ISNULL(cb.InvoiceLeaddays,ISNULL(c2.InvoiceLeadDays,0)) InvoiceLeadDays,
0 AS IsSubmitted
FROM LoanFinances lf
INNER JOIN Contracts c ON lf.ContractId = c.Id
INNER JOIN LegalEntities le ON lf.LegalEntityId = le.Id
INNER JOIN @LegalEntityIds AS legalEntity ON lf.LegalEntityId = legalEntity.LegalEntityId
INNER JOIN Customers c2 ON lf.CustomerId = c2.Id
LEFT JOIN  ContractBillings cb ON c.Id = cb.Id
WHERE  lf.STATUS =@CommencedBookingStatus
AND lf.STATUS <>@TerminatedBookingStatus
AND lf.IsCurrent	=@True
AND @ProcessThroughDate>=lf.CommencementDate
AND le.STATUS =@ActiveLegalEntityStatus
AND (@FilterOption = @AllFilterOption
OR (@EntityType = @CustomerEntityType AND @FilterOption = @OneFilterOption AND c2.Id = @CustomerId)
OR (@EntityType = @LoanEntityType AND @FilterOption = @OneFilterOption AND c.Id = @ContractId))
END

GO
