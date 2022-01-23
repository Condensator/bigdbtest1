SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SaveAssetIncome]
(
@AssetIncome AssetIncomeScheduleToSave READONLY,
@CurrencyCode NVARCHAR(3),
@CreatedByUserId BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO [AssetIncomeSchedules]
([BeginNetBookValue_Amount]
,[BeginNetBookValue_Currency]
,[EndNetBookValue_Amount]
,[EndNetBookValue_Currency]
,[Income_Amount]
,[Income_Currency]
,[IncomeAccrued_Amount]
,[IncomeAccrued_Currency]
,[IncomeBalance_Amount]
,[IncomeBalance_Currency]
,[ResidualIncome_Amount]
,[ResidualIncome_Currency]
,[ResidualIncomeBalance_Amount]
,[ResidualIncomeBalance_Currency]
,[OperatingBeginNetBookValue_Amount]
,[OperatingBeginNetBookValue_Currency]
,[OperatingEndNetBookValue_Amount]
,[OperatingEndNetBookValue_Currency]
,[RentalIncome_Amount]
,[RentalIncome_Currency]
,[DeferredRentalIncome_Amount]
,[DeferredRentalIncome_Currency]
,[Depreciation_Amount]
,[Depreciation_Currency]
,[Payment_Amount]
,[Payment_Currency]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[AssetId]
,[LeaseIncomeScheduleId])
SELECT
[BeginNetBookValue_Amount],
@CurrencyCode,
[EndNetBookValue_Amount] ,
@CurrencyCode,
[Income_Amount],
@CurrencyCode,
[IncomeAccrued_Amount],
@CurrencyCode,
[IncomeBalance_Amount],
@CurrencyCode,
[ResidualIncome_Amount],
@CurrencyCode,
[ResidualIncomeBalance_Amount] ,
@CurrencyCode,
[OperatingBeginNetBookValue_Amount],
@CurrencyCode,
[OperatingEndNetBookValue_Amount],
@CurrencyCode,
[RentalIncome_Amount] ,
@CurrencyCode,
[DeferredRentalIncome_Amount] ,
@CurrencyCode,
[Depreciation_Amount] ,
@CurrencyCode,
[Payment_Amount] ,
@CurrencyCode,
1,
@CreatedByUserId ,
@CreatedTime ,
[AssetId] ,
[LeaseIncomeScheduleId]
FROM
@AssetIncome
SET NOCOUNT OFF;
END

GO
