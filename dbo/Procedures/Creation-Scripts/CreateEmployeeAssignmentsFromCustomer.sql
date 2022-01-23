SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateEmployeeAssignmentsFromCustomer]
(
@EmployeeAssignmentIdCSV NVARCHAR(MAX)
,@ContractIdCSV NVARCHAR(MAX)
,@LOCIdCSV NVARCHAR(MAX)
,@ProposalIdCSV NVARCHAR(MAX)
,@CreditAppIdCSV NVARCHAR(MAX)
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
,@IsReplace BIT
)
AS
BEGIN
SET NOCOUNT ON
IF(@EmployeeAssignmentIdCSV IS NOT NULL AND @EmployeeAssignmentIdCSV != '')
BEGIN
--CONTRACTS
IF(@ContractIdCSV IS NOT NULL AND @ContractIdCSV != '')
BEGIN
DECLARE @ContracIdToModify BIGINT;
SELECT Id INTO #ContractIDS FROM ConvertCSVToBigIntTable(@ContractIdCSV,',');
DECLARE ContractCur CURSOR
FOR SELECT * FROM #ContractIDS;
OPEN ContractCur
FETCH NEXT FROM ContractCur
INTO @ContracIdToModify
WHILE @@FETCH_STATUS = 0
BEGIN
SELECT
EmployeesAssignedToParties.RoleFunctionId, EmployeesAssignedToContracts.Id
INTO
#ExistingContractPrimaryRoleFunctions
FROM
EmployeesAssignedToContracts JOIN EmployeesAssignedToParties
on EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
WHERE
ContractId = @ContracIdToModify and EmployeesAssignedToContracts.IsPrimary = 1 and EmployeesAssignedToContracts.IsActive = 1
and EmployeesAssignedToParties.PartyRole = 'Customer'
INSERT INTO EmployeesAssignedToContracts
(IsActive
,ActivationDate
,DeactivationDate
,IsPrimary
,IsDisplayDashboard
,CreatedById
,CreatedTime
,EmployeeAssignedToPartyId
,ContractId
)
SELECT
1
,ActivationDate
,DeactivationDate
,IsPrimary
,0
,CreatedById
,CreatedTime
,EmployeesAssignedToParties.Id
,@ContracIdToModify
FROM EmployeesAssignedToParties
LEFT JOIN #ExistingContractPrimaryRoleFunctions ON EmployeesAssignedToParties.RoleFunctionId = #ExistingContractPrimaryRoleFunctions.RoleFunctionId
WHERE EmployeesAssignedToParties.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
and EmployeesAssignedToParties.PartyRole = 'Customer'
-- Resetting Primary to false for employees other then newly inserted ones.
UPDATE ExistingEmployee SET IsPrimary = 0
FROM #ExistingContractPrimaryRoleFunctions PrimaryEmployeeInfo
JOIN EmployeesAssignedToContracts ExistingEmployee ON PrimaryEmployeeInfo.Id = ExistingEmployee.Id
JOIN EmployeesAssignedToParties ExistingParty ON ExistingEmployee.EmployeeAssignedToPartyId = ExistingParty.Id AND ExistingParty.RoleFunctionId = PrimaryEmployeeInfo.RoleFunctionId
JOIN EmployeesAssignedToContracts MatchingRecord
ON ExistingEmployee.ContractId = MatchingRecord.ContractId  AND MatchingRecord.IsPrimary = 1 AND MatchingRecord.IsActive = 1 AND ExistingEmployee.Id <> MatchingRecord.Id
JOIN EmployeesAssignedToParties MatchingRecordParty ON MatchingRecord.EmployeeAssignedToPartyId = MatchingRecordParty.Id AND ExistingParty.RoleFunctionId = MatchingRecordParty.RoleFunctionId
DROP TABLE #ExistingContractPrimaryRoleFunctions
FETCH NEXT FROM ContractCur INTO @ContracIdToModify
END
CLOSE ContractCur;
DEALLOCATE ContractCur;
DROP TABLE #ContractIDS
END
--CREDIT PROFILES
IF(@LOCIdCSV IS NOT NULL AND @LOCIdCSV != '')
BEGIN
DECLARE @LOCIdToModify BIGINT;
SELECT Id INTO #LOCIDS FROM ConvertCSVToBigIntTable(@LOCIdCSV,',');
DECLARE LOCCur CURSOR
FOR SELECT * FROM #LOCIDS;
OPEN LOCCur
FETCH NEXT FROM LOCCur
INTO @LOCIdToModify
WHILE @@FETCH_STATUS = 0
BEGIN
SELECT
EmployeesAssignedToParties.RoleFunctionId, EmployeesAssignedToLOCs.Id
INTO
#ExistingLOCPrimaryRoleFunctions
FROM
EmployeesAssignedToLOCs JOIN EmployeesAssignedToParties
ON EmployeesAssignedToLOCs.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
WHERE
CreditProfileId = @LOCIdToModify AND EmployeesAssignedToLOCs.IsPrimary = 1 AND EmployeesAssignedToLOCs.IsActive = 1
AND EmployeesAssignedToParties.PartyRole = 'Customer'
INSERT INTO EmployeesAssignedToLOCs
(IsActive
,ActivationDate
,DeactivationDate
,IsPrimary
,IsDisplayDashboard
,CreatedById
,CreatedTime
,EmployeeAssignedToPartyId
,CreditProfileId)
SELECT
1
,ActivationDate
,DeactivationDate
,IsPrimary
,0
,CreatedById
,CreatedTime
,EmployeesAssignedToParties.Id
,@LOCIdToModify
FROM EmployeesAssignedToParties
LEFT JOIN #ExistingLOCPrimaryRoleFunctions ON EmployeesAssignedToParties.RoleFunctionId = #ExistingLOCPrimaryRoleFunctions.RoleFunctionId
WHERE EmployeesAssignedToParties.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
and EmployeesAssignedToParties.PartyRole = 'Customer'
UPDATE ExistingEmployee SET IsPrimary = 0
FROM
#ExistingLOCPrimaryRoleFunctions PrimaryEmployeeInfo
JOIN EmployeesAssignedToLOCs ExistingEmployee ON PrimaryEmployeeInfo.Id = ExistingEmployee.Id
JOIN EmployeesAssignedToParties ExistingParty ON ExistingEmployee.EmployeeAssignedToPartyId = ExistingParty.Id AND PrimaryEmployeeInfo.RoleFunctionId = ExistingParty.RoleFunctionId
JOIN EmployeesAssignedToLOCs MatchingRecord
ON ExistingEmployee.CreditProfileId = MatchingRecord.CreditProfileId AND MatchingRecord.IsPrimary = 1 AND MatchingRecord.IsActive = 1 AND ExistingEmployee.Id <> MatchingRecord.Id
JOIN EmployeesAssignedToParties MatchingRecordParty ON MatchingRecord.EmployeeAssignedToPartyId = MatchingRecordParty.Id AND ExistingParty.RoleFunctionId = MatchingRecordParty.RoleFunctionId
DROP TABLE #ExistingLOCPrimaryRoleFunctions
FETCH NEXT FROM LOCCur INTO @LOCIdToModify
END
CLOSE LOCCur;
DEALLOCATE LOCCur;
DROP TABLE #LOCIDS
END
--PROPOSALS
IF(@ProposalIdCSV IS NOT NULL AND @ProposalIdCSV != '')
BEGIN
DECLARE @ProposalToModify BIGINT;
SELECT Id INTO #ProposalIDS FROM ConvertCSVToBigIntTable(@ProposalIdCSV,',');
DECLARE ProposalCur CURSOR
FOR SELECT * FROM #ProposalIDS;
OPEN ProposalCur
FETCH NEXT FROM ProposalCur
INTO @ProposalToModify
WHILE @@FETCH_STATUS = 0
BEGIN
SELECT
EmployeesAssignedToParties.RoleFunctionId, EmployeesAssignedToProposals.Id
INTO
#ExistingProposalPrimaryRoleFunctions
FROM
EmployeesAssignedToProposals JOIN EmployeesAssignedToParties
ON EmployeesAssignedToProposals.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
WHERE
ProposalId = @ProposalToModify AND EmployeesAssignedToProposals.IsPrimary = 1 AND EmployeesAssignedToProposals.IsActive = 1
AND EmployeesAssignedToParties.PartyRole = 'Customer'
INSERT INTO EmployeesAssignedToProposals
(IsActive
,ActivationDate
,DeactivationDate
,IsPrimary
,IsDisplayDashboard
,CreatedById
,CreatedTime
,EmployeeAssignedToPartyId
,ProposalId)
SELECT
1
,ActivationDate
,DeactivationDate
,IsPrimary
,0
,CreatedById
,CreatedTime
,EmployeesAssignedToParties.Id
,@ProposalToModify
FROM EmployeesAssignedToParties
LEFT JOIN #ExistingProposalPrimaryRoleFunctions ON EmployeesAssignedToParties.RoleFunctionId = #ExistingProposalPrimaryRoleFunctions.RoleFunctionId
WHERE EmployeesAssignedToParties.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
and EmployeesAssignedToParties.PartyRole = 'Customer'
UPDATE ExistingEmployee SET IsPrimary = 0
FROM
#ExistingProposalPrimaryRoleFunctions PrimaryEmployeeInfo
JOIN EmployeesAssignedToProposals ExistingEmployee ON PrimaryEmployeeInfo.Id = ExistingEmployee.Id
JOIN EmployeesAssignedToParties ExistingParty ON ExistingEmployee.EmployeeAssignedToPartyId = ExistingParty.Id AND PrimaryEmployeeInfo.RoleFunctionId = ExistingParty.RoleFunctionId
JOIN EmployeesAssignedToProposals MatchingRecord
ON ExistingEmployee.ProposalId = MatchingRecord.ProposalId AND MatchingRecord.IsPrimary = 1 AND MatchingRecord.IsActive = 1 AND ExistingEmployee.Id <> MatchingRecord.Id
JOIN EmployeesAssignedToParties MatchingRecordParty ON MatchingRecord.EmployeeAssignedToPartyId = MatchingRecordParty.Id AND ExistingParty.RoleFunctionId = MatchingRecordParty.RoleFunctionId
DROP TABLE #ExistingProposalPrimaryRoleFunctions
FETCH NEXT FROM ProposalCur INTO @ProposalToModify
END
CLOSE ProposalCur;
DEALLOCATE ProposalCur;
DROP TABLE #ProposalIDS
END
--CREDIT APPS
IF(@CreditAppIdCSV IS NOT NULL AND @CreditAppIdCSV != '')
BEGIN
DECLARE @CreditAppToModify BIGINT;
SELECT Id INTO #CreditAppIDS FROM ConvertCSVToBigIntTable(@CreditAppIdCSV,',');
DECLARE CreditAppCur CURSOR
FOR SELECT * FROM #CreditAppIDS;
OPEN CreditAppCur
FETCH NEXT FROM CreditAppCur
INTO @CreditAppToModify
WHILE @@FETCH_STATUS = 0
BEGIN
SELECT
EmployeesAssignedToParties.RoleFunctionId, EmployeesAssignedToCreditApplications.Id
INTO
#ExistingCreditAppPrimaryRoleFunctions
FROM
EmployeesAssignedToCreditApplications JOIN EmployeesAssignedToParties
ON EmployeesAssignedToCreditApplications.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
WHERE
CreditApplicationId = @CreditAppToModify AND EmployeesAssignedToCreditApplications.IsPrimary = 1 AND EmployeesAssignedToCreditApplications.IsActive = 1
AND EmployeesAssignedToParties.PartyRole = 'Customer'
INSERT INTO EmployeesAssignedToCreditApplications
(IsActive
,ActivationDate
,DeactivationDate
,IsPrimary
,IsDisplayDashboard
,CreatedById
,CreatedTime
,EmployeeAssignedToPartyId
,CreditApplicationId)
SELECT
1
,ActivationDate
,DeactivationDate
,IsPrimary
,0
,CreatedById
,CreatedTime
,EmployeesAssignedToParties.Id
,@CreditAppToModify
FROM EmployeesAssignedToParties
LEFT JOIN #ExistingCreditAppPrimaryRoleFunctions ON EmployeesAssignedToParties.RoleFunctionId = #ExistingCreditAppPrimaryRoleFunctions.RoleFunctionId
WHERE EmployeesAssignedToParties.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmployeeAssignmentIdCSV,','))
and EmployeesAssignedToParties.PartyRole = 'Customer'
UPDATE ExistingEmployee SET IsPrimary = 0
FROM
#ExistingCreditAppPrimaryRoleFunctions PrimaryEmployeeInfo
JOIN EmployeesAssignedToCreditApplications ExistingEmployee ON PrimaryEmployeeInfo.Id = ExistingEmployee.Id
JOIN EmployeesAssignedToParties ExistingParty ON ExistingEmployee.EmployeeAssignedToPartyId = ExistingParty.Id AND PrimaryEmployeeInfo.RoleFunctionId = ExistingParty.RoleFunctionId
JOIN EmployeesAssignedToCreditApplications MatchingRecord
ON ExistingEmployee.CreditApplicationId = MatchingRecord.CreditApplicationId AND MatchingRecord.IsPrimary = 1 AND MatchingRecord.IsActive = 1 AND ExistingEmployee.Id <> MatchingRecord.Id
JOIN EmployeesAssignedToParties MatchingRecordParty ON MatchingRecord.EmployeeAssignedToPartyId = MatchingRecordParty.Id AND ExistingParty.RoleFunctionId = MatchingRecordParty.RoleFunctionId
DROP TABLE #ExistingCreditAppPrimaryRoleFunctions
FETCH NEXT FROM CreditAppCur INTO @CreditAppToModify
END
CLOSE CreditAppCur;
DEALLOCATE CreditAppCur;
DROP TABLE #CreditAppIDS
END
END
END

GO
