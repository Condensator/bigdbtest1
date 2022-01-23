SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateContractIncomeSchedules]
(
@GLTransferDate DATE,
@IsLease BIT,
@ContractId BIGINT,
@FinanceId BIGINT,
@IncomeDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
IF(@IsLease = 1)
BEGIN
UPDATE LIS SET LIS.LeaseFinanceId = @FinanceId , LIS.UpdatedById = @UpdatedById, LIS.UpdatedTime = @UpdatedTime
FROM LeaseIncomeSchedules LIS
JOIN LeaseFinances LF ON LF.Id = LIS.LeaseFinanceId
WHERE LF.ContractId = @ContractId AND LIS.IncomeDate > @IncomeDate
UPDATE LFRI SET LFRI.LeaseFinanceId = @FinanceId, LFRI.UpdatedById = @UpdatedById, LFRI.UpdatedTime = @UpdatedTime
FROM LeaseFloatRateIncomes LFRI
JOIN LeaseFinances LF ON LFRI.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId AND LFRI.IncomeDate > @IncomeDate
UPDATE BIS SET BIS.LeaseFinanceId = @FinanceId, BIS.UpdatedById = @UpdatedById, BIS.UpdatedTime = @UpdatedTime
FROM BlendedIncomeSchedules BIS
JOIN LeaseFinances LF ON BIS.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId AND BIS.IncomeDate > @IncomeDate
END
ELSE
BEGIN
UPDATE LIS SET LIS.LoanFinanceId = @FinanceId , LIS.UpdatedById = @UpdatedById, LIS.UpdatedTime = @UpdatedTime
FROM LoanIncomeSchedules LIS
JOIN LoanFinances LF ON LIS.LoanFinanceId = LF.Id
WHERE LF.ContractId = @ContractId AND LIS.IncomeDate > @IncomeDate
UPDATE BIS SET BIS.LoanFinanceId = @FinanceId , BIS.UpdatedById = @UpdatedById, BIS.UpdatedTime = @UpdatedTime
FROM BlendedIncomeSchedules BIS
JOIN LoanFinances LF ON BIS.LoanFinanceId = LF.Id
WHERE LF.ContractId = @ContractId  AND BIS.IncomeDate > @IncomeDate
END
END

GO
