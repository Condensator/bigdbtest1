SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AllocateAmountById]
(@DistributionById   DistributionById READONLY, 
 @AmountToDistribute DECIMAL(18, 2)
)
AS
    BEGIN
        CREATE TABLE #AllocatedTemp
        (Id                BIGINT, 
         Amount            DECIMAL(18, 2), 
         DistributedAmount DECIMAL(18, 2),
		 IsProcessed	   BIT
        );

        INSERT INTO #AllocatedTemp
        (Id
       , Amount
       , DistributedAmount
	   , IsProcessed
        )
        SELECT Id
             , Amount
             , 0.00
			 , 0
        FROM @DistributionById
        ORDER BY ABS(Amount) DESC, Id ASC;

        DECLARE @TotalAmount DECIMAL(20, 10) =
        (
            SELECT SUM(Amount)
            FROM #AllocatedTemp
        );
		
		IF(@TotalAmount = 0)
		BEGIN
			SET @TotalAmount = (SELECT SUM(Amount)
            FROM #AllocatedTemp WHERE Amount > 0)

			UPDATE #AllocatedTemp SET Amount = Amount * 2
			WHERE Amount > 0
		END
		
		DECLARE @Id BIGINT;

		UPDATE #AllocatedTemp SET DistributedAmount = ROUND((@AmountToDistribute * Amount) / @TotalAmount, 2);

		DECLARE @Reminder DECIMAL(16, 2)= @AmountToDistribute -
		(
			SELECT SUM(DistributedAmount)
			FROM #AllocatedTemp
		);

		DECLARE @CentsLeftToDivide BIGINT = @Reminder * 100;
		DECLARE @OneCent DECIMAL(20,10) = 0.01

		IF(@CentsLeftToDivide < 0)
		BEGIN
		SET @OneCent = -@OneCent
		SET @CentsLeftToDivide = -@CentsLeftToDivide
		END

		IF(@Reminder <> 0)
		BEGIN
			WHILE (SELECT Count(*) From #AllocatedTemp Where IsProcessed = 0) > 0 AND @CentsLeftToDivide > 0
			BEGIN
				SELECT TOP 1 @Id = Id From #AllocatedTemp Where IsProcessed = 0

				UPDATE #AllocatedTemp Set IsProcessed = 1,DistributedAmount = DistributedAmount + @OneCent  Where Id = @Id 
				SET @CentsLeftToDivide = @CentsLeftToDivide - 1;
			END
		END

		SELECT Id, DistributedAmount AS Amount FROM #AllocatedTemp

        IF OBJECT_ID('tempdb..#AllocatedTemp') IS NOT NULL
            DROP TABLE #AllocatedTemp;
    END;

GO
