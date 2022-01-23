SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[ExtractPayablesForApprovalProcess]
(
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@FilterOption  BIT = 0,
@EntityId BIGINT = NULL,
@EntityType NVARCHAR(MAX),
@ProcessThroughDate DATETIME,
@JobStepInstanceId BIGINT
)AS
BEGIN
SET NOCOUNT ON
--DECLARE
--	@CreatedById BIGINT = 40413,
--	@CreatedTime DATETIMEOFFSET = sysdatetimeoffset(),
--  @FilterOption  BIT = 0,
--	@EntityID BIGINT = null,
--  @EntityType NVARCHAR(MAX) = '_',
--	@ProcessThroughDate DATETIMEOFFSET = sysdatetimeoffset(),
--	@JobStepInstanceId BIGINT = 1234
CREATE TABLE #Payables  (
PayableId BIGINT
)
CREATE TABLE #Contracts(
ContractId BIGINT
)
IF (@EntityType = 'CU' AND @FilterOption = 0)
BEGIN
INSERT INTO #Contracts(ContractId)
SELECT lf.ContractId FROM LeaseFinances lf WHERE lf.CustomerId = @EntityId
UNION ALL
SELECT lf.ContractId FROM LoanFinances lf WHERE lf.CustomerId = @EntityId
UNION ALL
SELECT lf.ContractId FROM LeveragedLeases lf WHERE lf.CustomerId = @EntityId
INSERT INTO #Payables(PayableId)
SELECT payable.Id
FROM Payables payable
JOIN #Contracts c on payable.EntityId = c.ContractId
WHERE payable.EntityType = 'CT'
AND payable.DueDate <= @ProcessThroughDate
AND (payable.Status = 'ReadyForDR' OR payable.Status = 'ReadyForTP')
END
INSERT INTO #Payables( PayableId)
SELECT payable.Id
FROM Payables payable
WHERE ((@EntityType = 'CU' AND @FilterOption = 1 AND payable.EntityType != 'DT')
OR (payable.EntityType = @EntityType AND (payable.EntityId = @EntityId OR @FilterOption = 1) AND @EntityType != 'DT'))
AND payable.DueDate <= @ProcessThroughDate
AND (payable.Status = 'ReadyForDR' OR payable.Status = 'ReadyForTP')
INSERT INTO #Payables( PayableId)
SELECT payable.Id
FROM Payables payable
WHERE ((@EntityType = 'DT' AND @FilterOption = 1 AND payable.EntityType = 'DT')
OR (payable.EntityType = @EntityType AND (payable.EntityId = @EntityId OR @FilterOption = 1) AND @EntityType = 'DT'))
AND payable.DueDate <= @ProcessThroughDate
AND (payable.Status = 'ReadyForDR' OR payable.Status = 'ReadyForTP')
INSERT INTO PayableExtracts(PayableId, JobStepInstanceId, CreatedById, CreatedTime, IsSubmitted)
SELECT p.PayableId, @JobStepInstanceId, @CreatedById, @CreatedTime, 0
FROM #Payables p
DROP TABLE #Payables
SET NOCOUNT OFF
END

GO
