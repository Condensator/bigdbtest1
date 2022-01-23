SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdatePrimaryEmployeeAssignment]
(
@EmpAssignedToContractIdCSV NVARCHAR(MAX)
,@EmpAssignedToLOCIdCSV NVARCHAR(MAX)
,@EmpAssignedToProposalIdCSV NVARCHAR(MAX)
,@EmpAssignedToCreditAppIdCSV NVARCHAR(MAX)
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
--CONTRACTS
IF(@EmpAssignedToContractIdCSV IS NOT NULL AND @EmpAssignedToContractIdCSV != '')
BEGIN
UPDATE EmployeesAssignedToContracts SET IsPrimary = 1 , UpdatedById = @UpdatedById , UpdatedTime = @UpdatedTime
WHERE Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmpAssignedToContractIdCSV,','))
END
--LOC
IF(@EmpAssignedToLOCIdCSV IS NOT NULL AND @EmpAssignedToLOCIdCSV != '')
BEGIN
UPDATE EmployeesAssignedToLOCs SET IsPrimary = 1 , UpdatedById = @UpdatedById , UpdatedTime = @UpdatedTime
WHERE Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmpAssignedToLOCIdCSV,','))
END
--PROPOSAL
IF(@EmpAssignedToProposalIdCSV IS NOT NULL AND @EmpAssignedToProposalIdCSV != '')
BEGIN
UPDATE EmployeesAssignedToProposals SET IsPrimary = 1 , UpdatedById = @UpdatedById , UpdatedTime = @UpdatedTime
WHERE Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmpAssignedToProposalIdCSV,','))
END
--CREDIT APP
IF(@EmpAssignedToCreditAppIdCSV IS NOT NULL AND @EmpAssignedToCreditAppIdCSV != '')
BEGIN
UPDATE EmployeesAssignedToCreditApplications SET IsPrimary = 1 , UpdatedById = @UpdatedById , UpdatedTime = @UpdatedTime
WHERE Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@EmpAssignedToCreditAppIdCSV,','))
END
END

GO
