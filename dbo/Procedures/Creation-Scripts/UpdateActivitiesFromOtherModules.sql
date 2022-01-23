SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateActivitiesFromOtherModules]
(
@EntityType NVARCHAR(50),
@EntityID BIGINT,
@ApprovalStatusName NVARCHAR(50) = '',
@InactivateStatusName NVARCHAR(50) = '',
@NoticeOfIntentSentDate DATE = NULL
)
AS
BEGIN
DECLARE @Test bit;
/*
DECLARE @ActivityID BIGINT = 0
DECLARE @ActivityTypes TABLE
(ActivityType NVARCHAR(MAX))
IF @EntityType = 'Payoff'
BEGIN
INSERT INTO @ActivityTypes
VALUES ('Abandonment') , ('AssetRecovery')
END
IF @EntityType = 'AppraisalRequest'
BEGIN
INSERT INTO @ActivityTypes
VALUES ('AssetAppraisal') , ('AssetInspection')
END
IF @EntityType = 'Assumption'
BEGIN
INSERT INTO @ActivityTypes
VALUES ('Assumption')
END
IF @EntityType = 'LeaseAmendment' OR @EntityType  = 'LoanAmendment'
BEGIN
INSERT INTO @ActivityTypes
VALUES ('PaymentArrangement')
END
IF @EntityType = 'Party'
BEGIN
INSERT INTO @ActivityTypes
VALUES ('NoticeofIntent')
END
IF @EntityType = 'ChargeOff'
BEGIN
INSERT INTO @ActivityTypes
VALUES ('ChargeOff')
END
IF (SELECT COUNT(*) FROM @ActivityTypes) > 0
BEGIN
SET @ActivityID  =
(SELECT TOP 1 ISNULL(AC.ActivityId,A.ID)
FROM Activities A
LEFT JOIN ActivityContractDetails AC ON A.Id = AC.ActivityId
WHERE A.ActivityType IN (SELECT ActivityType FROM @ActivityTypes)
AND A.Status = 'Open'
AND A.IsActive = 1
AND AC.IsActive = 1
AND ((AC.EntityId IS NULL  AND A.EntityId = @EntityID ) OR (AC.EntityId IS NOT NULL AND AC.EntityId = @EntityID )))
END
IF @ActivityID <> 0 AND @ActivityID IS NOT NULL
BEGIN
IF @EntityType = 'Payoff'
BEGIN
SELECT AC.EntityId INTO #PayoffIDs
FROM Activities A
INNER JOIN ActivityContractDetails AC ON A.Id = AC.ActivityId
WHERE A.Id = @ActivityID
DECLARE @PayoffCount INT = (SELECT COUNT (*) FROM Payoffs WHERE ID IN (SELECT EntityId FROM #PayoffIDs) AND (Status <> @ApprovalStatusName AND Status <> @InactivateStatusName))
IF @PayoffCount = 0
BEGIN
UPDATE Activities SET Status = 'Completed' WHERE ID = @ActivityID
END
END
IF @EntityType = 'Assumption'
BEGIN
SELECT AC.EntityId INTO #AssumptionIDs
FROM Activities A
INNER JOIN ActivityContractDetails AC ON A.Id = AC.ActivityId
WHERE A.Id = @ActivityID
DECLARE @AssumptionCount INT = (SELECT COUNT (*) FROM Assumptions WHERE ID IN (SELECT EntityId FROM #AssumptionIDs) AND (Status <> @ApprovalStatusName AND Status <> @InactivateStatusName))
IF @AssumptionCount = 0
BEGIN
UPDATE Activities SET Status = 'Completed' WHERE ID = @ActivityID
END
END
IF @EntityType = 'LeaseAmendment'
BEGIN
SELECT AC.EntityId INTO #LeaseAmendmentIds
FROM Activities A
INNER JOIN ActivityContractDetails AC ON A.Id = AC.ActivityId
WHERE A.Id = @ActivityID
DECLARE @LeaseAmendmentCount INT = (SELECT COUNT (*) FROM LeaseAmendments WHERE ID IN (SELECT EntityId FROM #LeaseAmendmentIds) AND (LeaseAmendmentStatus <> @ApprovalStatusName AND LeaseAmendmentStatus <> @InactivateStatusName))
IF @LeaseAmendmentCount = 0
BEGIN
UPDATE Activities SET Status = 'Completed' WHERE ID = @ActivityID
END
END
IF @EntityType = 'LoanAmendment'
BEGIN
SELECT AC.EntityId INTO #LoanAmendmentIds
FROM Activities A
INNER JOIN ActivityContractDetails AC ON A.Id = AC.ActivityId
WHERE A.Id = @ActivityID
DECLARE @LoanAmendmentCount INT = (SELECT COUNT (*) FROM LoanAmendments WHERE ID IN (SELECT EntityId FROM #LoanAmendmentIds) AND (QuoteStatus <> @ApprovalStatusName AND QuoteStatus <> @InactivateStatusName))
IF @LoanAmendmentCount = 0
BEGIN
UPDATE Activities SET Status = 'Completed' WHERE ID = @ActivityID
END
END
IF @EntityType = 'ChargeOff'
BEGIN
SELECT AC.EntityId INTO #ChargeOffIds
FROM Activities A
INNER JOIN ActivityContractDetails AC ON A.Id = AC.ActivityId
WHERE A.Id = @ActivityID
DECLARE @ChargeOffCount INT = (SELECT COUNT (*) FROM ChargeOffs WHERE ID IN (SELECT EntityId FROM #ChargeOffIds) AND (Status <> @ApprovalStatusName AND Status <> @InactivateStatusName))
IF @ChargeOffCount = 0
BEGIN
UPDATE Activities SET Status = 'Completed' WHERE ID = @ActivityID
END
END
IF @EntityType = 'Party'
BEGIN
UPDATE Activities SET Status = 'Completed' , Comment = CONVERT(NVARCHAR, @NoticeOfIntentSentDate, 110)  WHERE ID = @ActivityID
END
IF @EntityType = 'AppraisalRequest'
BEGIN
UPDATE Activities SET Status = 'Completed' WHERE ID = @ActivityID
END
END
*/
END

GO
