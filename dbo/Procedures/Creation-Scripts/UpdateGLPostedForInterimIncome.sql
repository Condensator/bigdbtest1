SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateGLPostedForInterimIncome]
(
@ContractId BIGINT,
@IncomeTypes NVARCHAR(MAX),
@UpdatedById BIGINT,
@UpdatedTime DateTimeOffset,
@PostDate DATE
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE LeaseIncomeSchedules SET IsGLPosted = 1, PostDate = @PostDate, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM LeaseIncomeSchedules
JOIN LeaseFinances ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN ConvertCSVToStringTable(@IncomeTypes, ',') IncomeType ON LeaseIncomeSchedules.IncomeType = IncomeType.Item
WHERE Contracts.Id = @ContractId
AND LeaseIncomeSchedules.IsAccounting = 1
AND LeaseIncomeSchedules.IsGLPosted = 0;
END

GO
