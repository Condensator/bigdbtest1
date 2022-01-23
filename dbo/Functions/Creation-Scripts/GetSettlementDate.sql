SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetSettlementDate]
(
@ContractId BIGINT
,@ReceivableDueDate Date
)
RETURNS DATETIME
AS
BEGIN
--Declare @ContractId BIGINT;
Declare @ContractWithBusinessCalenderDetails Table(BusinessDate Date, IsWeekDay Bit, IsHoliday Bit);
Declare @BankAccountId BIGINT;
Declare @NonWorkingDay BIGINT;
Declare @NextWorkingDay Date;
--Declare @ReceivableDueDate Date;
--Set @ReceivableDueDate = GETDATE();
--Set @ContractId = 426184
Select
@BankAccountId = BankAccountId
From
(
select
BankAccountId
, ContractOrder = ROW_NUMBER() Over(Partition By Contracts.Id Order By RemitToWireDetails.BankAccountId)
From Contracts
Inner Join RemitToWireDetails On RemitToWireDetails.RemitToId = Contracts.RemitToId
And Contracts.Id = @ContractId AND RemitToWireDetails.IsActive = 1 And RemitToWireDetails.BankAccountId Is Not Null
) As Temp_ContractsWithRemitToWireDetails Where ContractOrder = 1;
Insert Into @ContractWithBusinessCalenderDetails
Select
BusinessCalendarDetails.BusinessDate
,BusinessCalendarDetails.IsWeekday
,BusinessCalendarDetails.IsHoliday
From
BankAccounts
Inner Join BankBranches On BankBranches.Id = BankAccounts.BankBranchId And BankAccounts.Id = @BankAccountId
Inner Join BusinessCalendars On BusinessCalendars.Id = BankBranches.BusinessCalendarId
Inner Join BusinessCalendarDetails On BusinessCalendars.Id = BusinessCalendarDetails.BusinessCalendarId
Select @NonWorkingDay = IsNull(COUNT(*),0) from @ContractWithBusinessCalenderDetails where BusinessDate = @ReceivableDueDate And (IsWeekday=0 Or IsHoliday=1);
If(@NonWorkingDay !=0)
Select Top 1 @NextWorkingDay = BusinessDate from @ContractWithBusinessCalenderDetails where BusinessDate > @ReceivableDueDate And (IsWeekday=1 And IsHoliday=0) Order By BusinessDate;
If(@NonWorkingDay !=0 And @NextWorkingDay Is Not Null)
Begin
Set @NextWorkingDay = @NextWorkingDay;
End
Else
Begin
Set @NextWorkingDay = @ReceivableDueDate;
End
Return @NextWorkingDay
END

GO
