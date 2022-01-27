SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[AllocateMoney]
(
@Collection MoneyAllocationType READONLY,
@Amount DECIMAL(16,2)
)
RETURNS @AllocatedList TABLE
(
EntityId BIGINT,
Amount DECIMAL(16,2)
)
AS
BEGIN
DECLARE @DistributiveList MoneyDistributiveListType;
INSERT INTO @DistributiveList
SELECT ROW_NUMBER() OVER (ORDER BY DistributionBase DESC, EntityId ASC), EntityId, DistributionBase
FROM @Collection;
DECLARE @TotalDistributionBase DECIMAL(16,2) = (SELECT SUM(Amount) FROM @DistributiveList);
IF @TotalDistributionBase != 0.0
UPDATE @DistributiveList SET Amount = ROUND(@Amount * (Amount/@TotalDistributionBase),2)
ELSE
BEGIN
DECLARE @Count BIGINT = (SELECT COUNT(EntityId) FROM @DistributiveList);
UPDATE @DistributiveList SET Amount = ROUND(@Amount/@Count,2);
END
DECLARE @DifferenceAfterDistribution DECIMAL(16,2) = @Amount - (SELECT SUM(Amount) FROM @DistributiveList);
IF @DifferenceAfterDistribution > 0.0
UPDATE @DistributiveList SET Amount = (Amount + 0.01) WHERE RowNumber <= CAST(@DifferenceAfterDistribution/0.01 AS BIGINT);
ELSE IF @DifferenceAfterDistribution < 0.0
UPDATE @DistributiveList SET Amount = Amount - 0.01 WHERE RowNumber <= CAST(@DifferenceAfterDistribution/-0.01 AS BIGINT);
INSERT INTO @AllocatedList
SELECT EntityId, Amount FROM @DistributiveList;
RETURN;
END

GO
