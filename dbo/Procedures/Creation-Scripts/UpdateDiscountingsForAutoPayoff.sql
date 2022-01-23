SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateDiscountingsForAutoPayoff]
(
	@Payoffs PayoffDiscountingData READONLY,
	@DiscountingApprovalStatus NVARCHAR(46),
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)  
AS  
	BEGIN  
		SET NOCOUNT ON;  
		
		SELECT DISTINCT Contracts.Id AS DiscountingContractId,
				Finances.Id AS DiscountingFinanceId,
				Input.PayoffId,
				Input.PayoffEffectiveDate
			INTO #PayoffDiscountingContractData
			FROM @Payoffs Input
				JOIN DiscountingContracts Contracts ON Input.ContractId = Contracts.ContractId
				JOIN DiscountingFinances Finances ON Contracts.DiscountingFinanceId = Finances.Id
				JOIN DiscountingRepaymentSchedules ReSchedules ON Finances.Id = ReSchedules.DiscountingFinanceId
				JOIN TiedContractPaymentDetails TiedContracts ON ReSchedules.Id = TiedContracts.DiscountingRepaymentScheduleId AND Input.ContractId = TiedContracts.ContractId
				JOIN LeasePaymentSchedules Schedules ON TiedContracts.PaymentScheduleId = Schedules.Id
			WHERE Finances.Tied = 1
				AND Finances.IsCurrent = 1
				AND Finances.ApprovalStatus = @DiscountingApprovalStatus
				AND Schedules.EndDate >= Input.PayoffEffectiveDate
				AND Contracts.IsActive = 1
				AND ReSchedules.IsActive = 1
				AND Schedules.IsActive = 1
				AND TiedContracts.IsActive = 1;


		UPDATE DiscountingContracts
			SET PaidOffDate = Input.PayoffEffectiveDate,
				PaidOffId = Input.PayoffId,
				UpdatedById = @UserId,
				UpdatedTime = @UpdatedTime
			FROM DiscountingContracts
				JOIN #PayoffDiscountingContractData Input ON DiscountingContracts.Id = Input.DiscountingContractId;


		UPDATE DiscountingFinances
			SET IsOnHold = 1,
				UpdatedById = @UserId,
				UpdatedTime = @UpdatedTime
			FROM DiscountingFinances
				JOIN #PayoffDiscountingContractData Input ON DiscountingFinances.Id = Input.DiscountingFinanceId
			WHERE IsOnHold = 0;


		UPDATE TiedContract
			SET
				TiedContract.PaymentScheduleId = New_Schedule.Id,
				TiedContract.UpdatedById = @UserId,
				TiedContract.UpdatedTime = @UpdatedTime
			FROM TiedContractPaymentDetails TiedContract
				JOIN @Payoffs Input ON TiedContract.ContractId = Input.ContractId
				JOIN LeasePaymentSchedules Old_Schedule ON TiedContract.PaymentScheduleId = Old_Schedule.Id
				JOIN LeasePaymentSchedules New_Schedule ON Old_Schedule.StartDate = New_Schedule.StartDate AND Old_Schedule.EndDate = New_Schedule.EndDate AND Old_Schedule.PaymentType = New_Schedule.PaymentType AND  New_Schedule.LeaseFinanceDetailId = Input.NewLeaseFinanceId
				JOIN DiscountingContracts Contracts ON TiedContract.ContractId = Contracts.ContractId AND Input.ContractId = Contracts.ContractId
				JOIN DiscountingFinances Finances ON Contracts.DiscountingFinanceId = Finances.Id
			WHERE Finances.Tied = 1 
				AND Finances.ApprovalStatus = @DiscountingApprovalStatus
				AND TiedContract.IsActive = 1
				AND New_Schedule.IsActive = 1;


	SET NOCOUNT OFF;
	END

GO
