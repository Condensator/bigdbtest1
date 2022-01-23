SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[updateFederalIncomeTaxBankQualifiedHoldingStatus]
(
@CreditApprovedStructureId NVARCHAR(MAX),
@BankQualified NVARCHAR(MAX),
@HoldingStatus NVARCHAR(MAX),
@LineofBusinessId BIGINT,
@FederalIncomeTaxExempt BIT
)
AS
DECLARE @UpdateQuery NVARCHAR(MAX)
SET @UpdateQuery =''
BEGIN
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--Update LoanFinances
SET @UpdateQuery = 'UPDATE LoanFinances
SET BankQualified = ''' + CAST(@BankQualified AS NVARCHAR(MAX)) + ''',
HoldingStatus = ''' + CAST(@HoldingStatus AS NVARCHAR(MAX)) + ''' ,
LineofBusinessId = ' + CAST(@LineofBusinessId AS NVARCHAR(MAX)) + ' ,
IsFederalIncomeTaxExempt = ''' + CAST(@FederalIncomeTaxExempt AS NVARCHAR(MAX)) + '''
FROM LoanFinances
JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
WHERE Contracts.CreditApprovedStructureId IN (' + @CreditApprovedStructureId + ') AND
LoanFinances.Status NOT IN (''Commenced'',''FullyPaid'',''Terminated'',''FullyPaidOff'',''Cancelled'');'
EXEC(@UpdateQuery);
--Update LeaseFinances
SET @UpdateQuery = 'UPDATE LeaseFinances
SET BankQualified = ''' + CAST(@BankQualified AS NVARCHAR(MAX)) + ''',
HoldingStatus = ''' + CAST(@HoldingStatus AS NVARCHAR(MAX)) + ''' ,
LineofBusinessId = ' + CAST(@LineofBusinessId AS NVARCHAR(MAX)) + ' ,
IsFederalIncomeTaxExempt = ''' + CAST(@FederalIncomeTaxExempt AS NVARCHAR(MAX)) + '''
FROM LeaseFinances
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
WHERE Contracts.CreditApprovedStructureId IN (' + @CreditApprovedStructureId + ') AND
LeaseFinances.BookingStatus NOT IN (''Commenced'',''Terminated'',''Inactive'',''FullyPaidOff'');'
EXEC(@UpdateQuery);
--Update Contracts
SET @UpdateQuery = 'UPDATE Contracts
SET LineofBusinessId = ' + CAST(@LineofBusinessId AS NVARCHAR(MAX)) + '
WHERE Contracts.CreditApprovedStructureId IN (' + @CreditApprovedStructureId + ') AND
Contracts.Status NOT IN (''Commenced'',''FullyPaid'',''Terminated'',''FullyPaidOff'',''Cancelled'');'
EXEC(@UpdateQuery);
END

GO
