SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetTerminationDate]
(
@ContractId BIGINT
)
RETURNS DATETIME
AS
BEGIN
DECLARE @ChargeOffDate DATETIME
DECLARE @FinanceDate DATETIME
DECLARE @TerminationDate DATETIME
DECLARE @AccountingDate DATETIME
DECLARE @syndicationType NVARCHAR(32)
DECLARE @LeaseFinanceId BIGINT
DECLARE @LoanFinanceId BIGINT
SET @LeaseFinanceId =( SELECT MIN(Id) FROM LeaseFinances WHERE ContractId=@ContractId AND IsCurrent=1)
SET @LoanFinanceId =( SELECT MIN(Id) FROM LoanFinances WHERE ContractId=@ContractId AND IsCurrent=1)
SET @syndicationType=(SELECT syndicationType FROM Contracts WHERE Id=@ContractId)
SET @ChargeOffDate=(SELECT MIN(ChargeOffDate) FROM ChargeOffs WHERE IsActive=1 AND Status='Approved'AND ContractId=@ContractId)
IF @ChargeOffDate IS NOT NULL
SET @TerminationDate=@ChargeOffDate
IF @LeaseFinanceId IS NOT NULL
SET @FinanceDate=(SELECT MIN(PayoffEffectiveDate) FROM Payoffs WHERE Status='Activated' AND PayoffEffectiveDate IS NOT NULL AND FullPayoff=1 AND LeaseFinanceId=@LeaseFinanceId)
ELSE
SET @FinanceDate=(SELECT MIN(PaydownDate) FROM LoanPaydowns WHERE Status='Active' AND PaydownDate IS NOT NULL AND PaydownReason='FullPaydown' AND LoanFinanceId=@LoanFinanceId)
IF @FinanceDate IS NOT NULL
SET @TerminationDate=@FinanceDate
IF @ChargeOffDate IS NOT NULL AND @FinanceDate IS NOT NULL AND @ChargeOffDate<=@FinanceDate
SET @TerminationDate=@ChargeOffDate
IF @syndicationType='FullSale'
BEGIN
SET @AccountingDate=(SELECT MIN(AccountingDate) FROM ReceivableForTransfers WHERE  ApprovalStatus='Approved' AND ContractId=@ContractId)
IF @AccountingDate IS NOT NULL AND @AccountingDate<=@TerminationDate
SET @TerminationDate=@AccountingDate
END
RETURN @TerminationDate
END

GO
