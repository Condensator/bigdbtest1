SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PlanBasisReport]
(
@PlanBasisNumber NVARCHAR(200)
)
AS
SELECT
PlanBases.Id
,PlanBases.PlanBasisAbbreviation
,PlanBases.PlanBasisDescription
,PlanBases.Status
,PlanFamilies.PlanFamilyNumber
,PlanFamilies.PlanFamilyDescription
,PlanBasisAdministrativeCharges.MaximumTransaction_Amount
,PlanBasisAdministrativeCharges.MinimumTransaction_Amount
,PlanBasisAdministrativeCharges.AdministrativeCost_Amount
,PlanBasisAdministrativeCharges.COFAdjustment
FROM PlanBases
INNER JOIN PlanFamilies
ON PlanBases.PlanFamilyId = PlanFamilies.Id
left JOIN PlanBasisAdministrativeCharges
ON PlanBases.Id = PlanBasisAdministrativeCharges.PlanBaseId
where PlanBases.Id=@PlanBasisNumber

GO
