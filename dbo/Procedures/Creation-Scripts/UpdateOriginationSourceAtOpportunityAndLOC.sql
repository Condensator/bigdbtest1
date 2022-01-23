SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateOriginationSourceAtOpportunityAndLOC]
(
@ContractId BIGINT,
@OriginationSourceId BIGINT,
@CreditProfileId BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @DefaultRemitToId BIGINT = NULL;
DECLARE @OpportunityId BIGINT =  NULL;
SELECT TOP 1 @DefaultRemitToId = RemitToId FROM PartyRemitToes
WHERE PartyId = @OriginationSourceId AND IsDefault=1
CREATE TABLE #CreditProfileTemp
(
Id BIGINT NULL
);
CREATE TABLE #OpportunityTemp
(
Id BIGINT NULL
);
CREATE TABLE #ContractTemp
(
Id BIGINT NULL,
IsLease BIT NOT NULL
);
INSERT INTO #OpportunityTemp
SELECT OpportunityId FROM CreditProfiles WHERE Id = @CreditProfileId
SELECT TOP 1 @OpportunityId = Id from #OpportunityTemp
IF @OpportunityId IS NULL
BEGIN
INSERT INTO #CreditProfileTemp
SELECT @CreditProfileId
END
ELSE
BEGIN
INSERT INTO #CreditProfileTemp
SELECT Id FROM CreditProfiles
WHERE OpportunityId IN (SELECT Id FROM #OpportunityTemp)
AND CreditProfiles.Status NOT IN ('Cancelled','Declined','Inactivate','NotAccepted','OpportunityWithdrawn')
END
INSERT INTO #ContractTemp
SELECT Contracts.Id,CASE WHEN Contracts.ContractType = 'Lease' THEN 1 ELSE 0 END FROM Contracts
JOIN CreditApprovedStructures ON Contracts.CreditApprovedStructureId = CreditApprovedStructures.Id
WHERE CreditApprovedStructures.CreditProfileId IN (SELECT Id FROM #CreditProfileTemp)
AND Contracts.Id <> @ContractId
IF EXISTS(SELECT * FROM #OpportunityTemp)
BEGIN
UPDATE Opportunities
SET OriginationSourceId = @OriginationSourceId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
WHERE Opportunities.Id IN (SELECT Id FROM #OpportunityTemp)
END
IF EXISTS(SELECT * FROM #CreditProfileTemp)
BEGIN
UPDATE CreditProfiles
SET OriginationSourceId = @OriginationSourceId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
WHERE CreditProfiles.Id IN (SELECT Id FROM #CreditProfileTemp)
END
IF EXISTS(SELECT * FROM #ContractTemp WHERE IsLease=1)
BEGIN
UPDATE ContractOriginations
SET OriginationSourceId = @OriginationSourceId,
OriginatorPayableRemitToId = @DefaultRemitToId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM ContractOriginations JOIN LeaseFinances ON ContractOriginations.Id = LeaseFinances.ContractOriginationId
WHERE LeaseFinances.ContractId IN (SELECT Id FROM #ContractTemp WHERE IsLease=1)
AND LeaseFinances.BookingStatus NOT IN ('Commenced','Terminated','Inactive','FullyPaidOff')
END
IF EXISTS(SELECT * FROM #ContractTemp WHERE IsLease=0)
BEGIN
UPDATE ContractOriginations
SET OriginationSourceId = @OriginationSourceId,
OriginatorPayableRemitToId = @DefaultRemitToId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM ContractOriginations JOIN LoanFinances ON ContractOriginations.Id = LoanFinances.ContractOriginationId
WHERE LoanFinances.ContractId IN (SELECT Id FROM #ContractTemp WHERE IsLease=0)
AND LoanFinances.Status NOT IN ('Commenced','FullyPaid','Terminated','FullyPaidOff','Cancelled')
AND LoanFinances.ApprovalStatus NOT IN ('Approved','Completed')
END
Drop Table #CreditProfileTemp
Drop Table #OpportunityTemp
Drop Table #ContractTemp
END

GO
