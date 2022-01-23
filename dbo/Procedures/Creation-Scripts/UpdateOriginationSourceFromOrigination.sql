SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateOriginationSourceFromOrigination]
(
@OpportunityId BIGINT,
@OriginationSourceTypeId BIGINT,
@OriginationSourceId BIGINT,
@CreditProfileId BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @DefaultRemitToId BIGINT = NULL;
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
IF @CreditProfileId != 0
BEGIN
INSERT INTO #OpportunityTemp
SELECT OpportunityId FROM CreditProfiles WHERE Id = @CreditProfileId
END
ELSE
BEGIN
INSERT INTO #OpportunityTemp
SELECT @OpportunityId
END
IF @OpportunityId = 0
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
IF EXISTS(SELECT * FROM #OpportunityTemp)
BEGIN
UPDATE Opportunities
SET OriginationSourceId = @OriginationSourceId,
OriginationSourceTypeId = @OriginationSourceTypeId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
WHERE Opportunities.Id IN (SELECT Id FROM #OpportunityTemp) AND Opportunities.Id != @OpportunityId
END
IF EXISTS(SELECT * FROM #ContractTemp WHERE IsLease = 1)
BEGIN
UPDATE ContractOriginations
SET OriginationSourceId = @OriginationSourceId,
OriginationSourceTypeId = @OriginationSourceTypeId,
OriginatorPayableRemitToId = @DefaultRemitToId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM ContractOriginations JOIN LeaseFinances ON ContractOriginations.Id = LeaseFinances.ContractOriginationId
WHERE LeaseFinances.ContractId IN (SELECT Id FROM #ContractTemp)
AND LeaseFinances.BookingStatus NOT IN ('Commenced','Terminated','Inactive','FullyPaidOff')
END
IF EXISTS(SELECT * FROM #ContractTemp)
BEGIN
UPDATE ContractOriginations
SET OriginationSourceId = @OriginationSourceId,
OriginationSourceTypeId = @OriginationSourceTypeId,
OriginatorPayableRemitToId = @DefaultRemitToId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM ContractOriginations JOIN LoanFinances ON ContractOriginations.Id = LoanFinances.ContractOriginationId
WHERE LoanFinances.ContractId IN (SELECT Id FROM #ContractTemp)
AND LoanFinances.Status NOT IN ('Commenced','Terminated','Inactive','FullyPaidOff','FullyPaid')
END
DROP TABLE #CreditProfileTemp
DROP TABLE #OpportunityTemp
DROP TABLE #ContractTemp
END

GO
