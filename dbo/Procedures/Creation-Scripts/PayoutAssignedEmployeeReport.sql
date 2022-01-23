SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[PayoutAssignedEmployeeReport]
@PlanBaseId bigint
,@PayoutId bigint
as
begin
select  PlanBasesPayouts.PayOutDescription
,PlanBasesPayouts.CalculationMethod
,PlanBasesPayouts.PlanBaseId
,PlanBasesPayouts.Id
,convert(date,PlanPayoutOptionAssignedEmployees.EffectiveStartDate) as EffectiveStartDate
,convert(date,PlanPayoutOptionAssignedEmployees.EffectiveEndDate) as EffectiveEndDate
,users.FullName as Name
from PlanBasesPayouts
left join PlanPayoutOptionAssignedEmployees
on PlanPayoutOptionAssignedEmployees.PlanBasesPayoutId = PlanBasesPayouts.Id
left join SalesOfficers as salesofficer
on PlanPayoutOptionAssignedEmployees.SalesOfficerId =salesofficer.Id
left join Users as users
on users.Id = salesofficer.UserNameId
where PlanBasesPayouts.PlanBaseId=@PlanBaseId
and  PlanBasesPayouts.Id = @PayoutId
End

GO
