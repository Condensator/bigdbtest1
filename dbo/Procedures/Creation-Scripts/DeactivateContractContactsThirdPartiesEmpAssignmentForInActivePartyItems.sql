SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeactivateContractContactsThirdPartiesEmpAssignmentForInActivePartyItems]
(
@PartyContactIdCSV NVARCHAR(MAX)
,@ThirdPartyRelationshipIdCSV NVARCHAR(MAX)
,@EmployeeAssignmentIdCSV NVARCHAR(MAX)
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
,@AccessedFromCustomerLevel BIT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @DeactivationDate DATETIME = CAST(GETDATE() AS DATE)
IF(@PartyContactIdCSV IS NOT NULL AND @PartyContactIdCSV != '')
BEGIN
IF(@AccessedFromCustomerLevel = 0)
BEGIN
UPDATE
dbo.PartyContacts
SET
IsActive = 0
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM PartyContacts CC
WHERE CC.IsActive = 1
AND CC.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@PartyContactIdCSV,','))
END
UPDATE
dbo.ContractContacts
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM ContractContacts CC
WHERE CC.IsActive = 1
AND CC.PartyContactId IN (SELECT Id FROM ConvertCSVToBigIntTable(@PartyContactIdCSV,','))
UPDATE
dbo.CreditProfileContacts
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM CreditProfileContacts CPC
WHERE CPC.IsActive = 1
AND CPC.PartyContactId IN (SELECT Id FROM ConvertCSVToBigIntTable(@PartyContactIdCSV,','))
UPDATE
dbo.ProposalContacts
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM ProposalContacts PC
WHERE PC.IsActive = 1
AND PC.PartyContactId IN (SELECT Id FROM ConvertCSVToBigIntTable(@PartyContactIdCSV,','))
UPDATE
dbo.PreQuoteContacts
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM PreQuoteContacts PQC
WHERE PQC.IsActive = 1
AND PQC.PartyContactId IN (SELECT Id FROM ConvertCSVToBigIntTable(@PartyContactIdCSV,','))
END
IF(@ThirdPartyRelationshipIdCSV IS NOT NULL AND @ThirdPartyRelationshipIdCSV != '')
BEGIN
IF(@AccessedFromCustomerLevel = 0)
BEGIN
UPDATE
dbo.CustomerThirdPartyRelationships
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	CustomerThirdPartyRelationships CTR
WHERE	CTR.IsActive = 1
AND	CTR.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@ThirdPartyRelationshipIdCSV,','))
END
UPDATE
dbo.ContractThirdPartyRelationships
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	ContractThirdPartyRelationships CTR
WHERE	CTR.IsActive = 1
AND	CTR.ThirdPartyRelationshipId IN (SELECT Id FROM ConvertCSVToBigIntTable(@ThirdPartyRelationshipIdCSV,','))
UPDATE
dbo.CreditProfileThirdPartyRelationships
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	CreditProfileThirdPartyRelationships CPTR
WHERE	CPTR.IsActive = 1
AND	CPTR.ThirdPartyRelationshipId IN (SELECT Id FROM ConvertCSVToBigIntTable(@ThirdPartyRelationshipIdCSV,','))
UPDATE
dbo.ProposalThirdPartyRelationships
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	ProposalThirdPartyRelationships PTPR
WHERE	PTPR.IsActive = 1
AND	PTPR.ThirdPartyRelationshipId IN (SELECT Id FROM ConvertCSVToBigIntTable(@ThirdPartyRelationshipIdCSV,','))
END
IF(@EmployeeAssignmentIdCSV IS NOT NULL AND @EmployeeAssignmentIdCSV != '')
BEGIN
UPDATE
dbo.EmployeesAssignedToContracts
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	EmployeesAssignedToContracts EAC
WHERE	EAC.IsActive = 1
AND	EAC.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
UPDATE
dbo.EmployeesAssignedToLOCs
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	EmployeesAssignedToLOCs EALOC
WHERE	EALOC.IsActive = 1
AND	EALOC.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
UPDATE
dbo.EmployeesAssignedToProposals
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	EmployeesAssignedToProposals EAP
WHERE	EAP.IsActive = 1
AND	EAP.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
UPDATE
dbo.EmployeesAssignedToCreditApplications
SET
IsActive = 0
,DeactivationDate = @DeactivationDate
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM	EmployeesAssignedToCreditApplications EACA
WHERE	EACA.IsActive = 1
AND	EACA.EmployeeAssignedToPartyId IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
END
END

GO
