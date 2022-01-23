SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[PayoutFreeCashReport]
(
@PlanBaseId bigint
,@PayoutId bigint
)
as
begin
select
PlanBasesPayouts.PlanBaseId
,PlanBasesPayouts.Id
,PlanBasesPayouts.PayOutDescription
,PlanBasesPayouts.CalculationMethod
,PlanPayoutOptionVolumeTiers.MaximumVolume_Amount
,PlanPayoutOptionVolumeTiers.MinimumVolume_Amount
,PlanPayoutOptionVolumeTiers.Commission
from PlanBasesPayouts
left join PlanPayoutOptionVolumeTiers
on PlanPayoutOptionVolumeTiers.PlanBasesPayoutId = PlanBasesPayouts.Id
where PlanBasesPayouts.PlanBaseId=@PlanBaseId
and PlanBasesPayouts.Id = @PayoutId
End

GO
