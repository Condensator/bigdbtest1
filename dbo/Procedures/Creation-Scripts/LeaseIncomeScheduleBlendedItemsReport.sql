SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseIncomeScheduleBlendedItemsReport]
(
@SequenceNumber NVARCHAR(50),
@IsAccounting BIT
)
AS
SELECT
BlendedItemCodes.Name [Code],
BlendedItems.Name [Name],
BlendedItems.Type,
BlendedItems.Amount_Amount [Amount],
BlendedItems.Amount_Currency,
BlendedItems.StartDate,
BlendedItems.EndDate,
BlendedItems.RecognitionMethod,
BlendedItems.BookRecognitionMode,
BlendedItems.AccumulateExpense,
BlendedItems.IncludeInBlendedYield,
BlendedItems.IsFAS91,
BlendedItems.TaxRecognitionMode,
BlendedItems.GeneratePayableOrReceivable,
BlendedItems.Occurrence,
BlendedItems.DueDate,
BlendedItems.Frequency,
BlendedItems.NumberOfPayments [RecurringNumber],
Case When BlendedItems.NumberOfPayments = 0 Then 0 else BlendedItems.Amount_Amount / BlendedItems.NumberOfPayments End [RecurringAmount],
BlendedItems.IsAssetBased
FROM
Contracts
INNER JOIN
LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent=1
INNER JOIN
LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
INNER JOIN
BlendedItems ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId AND BlendedItems.IsActive = 1
LEFT JOIN
BlendedItemCodes ON BlendedItems.BlendedItemCodeId = BlendedItemCodes.Id
WHERE Contracts.SequenceNumber = @SequenceNumber

GO
