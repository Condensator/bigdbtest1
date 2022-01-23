SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeactivateEmployeeAssignmentFromEnMasseUpdate]
(
@EmployeeAssignmentIdCSV NVARCHAR(MAX)
,@UpdatedById BIGINT
,@CurrentTime DATETIMEOFFSET
,@IsReplace BIT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @DeactivationDate DATETIME = CAST(@CurrentTime AS DATE)
IF(@EmployeeAssignmentIdCSV IS NOT NULL AND @EmployeeAssignmentIdCSV != '')
BEGIN
UPDATE
dbo.EmployeesAssignedToContracts
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @CurrentTime
FROM	EmployeesAssignedToContracts EAC
WHERE	EAC.IsActive = 1
AND	EAC.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
UPDATE
dbo.EmployeesAssignedToLOCs
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @CurrentTime
FROM	EmployeesAssignedToLOCs EALOC
WHERE	EALOC.IsActive = 1
AND	EALOC.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
UPDATE
dbo.EmployeesAssignedToProposals
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @CurrentTime
FROM	EmployeesAssignedToProposals EAP
WHERE	EAP.IsActive = 1
AND	EAP.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
UPDATE
dbo.EmployeesAssignedToCreditApplications
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @CurrentTime
FROM	EmployeesAssignedToCreditApplications EACA
WHERE	EACA.IsActive = 1
AND	EACA.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
IF(@IsReplace = 1)
BEGIN
UPDATE
dbo.EmployeesAssignedToParties
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @CurrentTime
WHERE	Id in (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
END
END
END

GO
