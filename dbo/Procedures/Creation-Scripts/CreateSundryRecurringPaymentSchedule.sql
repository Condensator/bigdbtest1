SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	
CREATE PROCEDURE [dbo].[CreateSundryRecurringPaymentSchedule]
(
	@LastDueDate DATE,
	@DueDay INT,
	@Frequency NVARCHAR(20),
	@NumberOfDays INT,
	@NumberOfPayments INT,
	@SundryType NVARCHAR(30),
	@IsRegular BIT,
	@PayableAmount DECIMAL(16,2),
	@ReceivableAmount DECIMAL(16,2),
	@InitialPayableAmount DECIMAL(16,2),
	@InitialAmount DECIMAL(16,2),
	@RegularAmount DECIMAL(16,2),
	@SundryRecurringId BIGINT,
	@ToolIdentifier INT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @EndDate DATE
DECLARE @Count INT = 1;
DECLARE @PAmount DECIMAL(16,2) = 0.00
DECLARE @RAmount DECIMAL(16,2) = 0.00
DECLARE @BillPastEndDate BIT = 0
EXEC GetPaymentDueDateForSundryRecurring  @LastDueDate,@DueDay,@Frequency,@NumberOfDays,@EndDate OUTPUT
IF @SundryType='PassThrough'
	BEGIN
	IF @IsRegular = 1
		BEGIN
		SET @PAmount = @PayableAmount
		SET @RAmount = @ReceivableAmount
		END
	ELSE
		BEGIN
		SET @PAmount = @InitialPayableAmount
		SET @RAmount = @InitialAmount
		END 
	END
ELSE If @SundryType='ReceivableOnly'
	BEGIN
	IF @IsRegular = 1
		BEGIN
		SET @RAmount = @RegularAmount
		END
	ELSE 
		BEGIN
		SET @RAmount = @InitialAmount
		END
	END
ELSE If  @SundryType='PayableOnly'
	BEGIN
	IF @IsRegular = 1
		BEGIN
		SET @RAmount = @RegularAmount
		END
	ELSE 
		BEGIN
		SET @RAmount = @InitialPayableAmount
		END
	END
WHILE @Count <= @NumberOfPayments
	BEGIN
	INSERT INTO #GeneratedSundryRecurringPaymentSchedule
	(
	 Amount,
	 PayableAmount,
	 DueDate,
	 Number,
	 SundryRecurringId,
	 BillPastEndDate,
	 ProjectedVATAmount
	)
	VALUES
	(
	@RAmount,
	@PAmount,
	@LastDueDate,
	@Count,
	@SundryRecurringId,
	@BillPastEndDate,
	0.00
	)
	SET @Count = @Count + 1 ;
	SET @LastDueDate =DATEADD(DAY,1,@EndDate) ;
	EXEC GetPaymentDueDateForSundryRecurring @LastDueDate,@DueDay,@Frequency,@NumberOfDays,@EndDate OUTPUT
	END
	SET NOCOUNT OFF
END

GO
