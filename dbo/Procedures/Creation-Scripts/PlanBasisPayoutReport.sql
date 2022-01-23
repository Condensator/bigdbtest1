SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[PlanBasisPayoutReport]
(
@PlanBaseId Bigint,
@Culture Nvarchar(20)
)
AS
SELECT
PlanBases.Id As PlanBasesId
,PlanBases.PlanBasisAbbreviation
,PlanBases.PlanBasisDescription
,PlanBases.Status
,EntityResources.Value as CalculationMethod
,PlanBasesPayouts.PayOutDescription
,PlanBasesPayouts.Id As PlanBasesPayoutId
FROM PlanBases
left join PlanBasesPayouts
ON PlanBasesPayouts.PlanBaseId = PlanBases.Id
join EntityResources
on EntityResources.Entitytype ='PlanBaseCalculationMethodStatusValues' and EntityResources.Name=PlanBasesPayouts.CalculationMethod  and EntityResources.Culture =@Culture
where PlanBasesPayouts.PlanBaseId = @PlanBaseId

GO
