SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDiscountingBlendedItemsForAmortizationReport]
(
@DiscountingId BIGINT,
@IsAccounting BIT
)
AS
-- DECLARE
--@DiscountingId BIGINT = 2286,
--@IsAccounting BIT = 1
BEGIN
SET NOCOUNT ON
CREATE TABLE #BlendedItem
(
BlendedItemCode NVARCHAR(40),
BlendedItemName NVARCHAR(40),
BlendedType NVARCHAR(40),
BookRecognition NVARCHAR(40),
IsIncludedInBlended BIT,
ISFAS91 BIT,
GeneratePayableOrReceivable BIT,
Occurrence NVARCHAR(40),
DueDate DATE,
RecurringAmount DECIMAL(18,2) DEFAULT 0
);
;WITH cte_BlendedItem AS
(SELECT  BlendedItemCodes.name AS code,BlendedItems.Name,BlendedItems.Type,BlendedItems.BookRecognitionMode,
BlendedItems.IncludeInBlendedYield,BlendedItems.IsFAS91,
BlendedItems.GeneratePayableOrReceivable,BlendedItems.Occurrence,BlendedItemDetails.DueDate,BlendedItemDetails.Amount_Amount
FROM BlendedItems
JOIN BlendedItemDetails ON BlendedItems.Id = BlendedItemDetails.BlendedItemId
JOIN DiscountingBlendedItems ON BlendedItems.Id = DiscountingBlendedItems.BlendedItemId
LEFT JOIN BlendedItemCodes ON BlendedItemCodes.EntityType ='Discounting'
JOIN DiscountingFinances ON DiscountingBlendedItems.DiscountingFinanceId = DiscountingFinances.Id
WHERE DiscountingFinances.DiscountingId = @DiscountingId
AND DiscountingFinances.IsCurrent = 1 AND BlendedItems.IsActive=1)
INSERT INTO #BlendedItem
SELECT * FROM cte_BlendedItem
SELECT * FROM #BlendedItem
IF OBJECT_ID('tempdb..#BlendedItem') IS NOT NULL
DROP TABLE #BlendedItem
END

GO
