SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateReportStatusForLegalStatus]
(
@LegalStatusId BIGINT,
@CustomerId BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE LegalStatusHistories SET IsActive = 0,UpdatedById = @CreatedById,UpdatedTime=@CreatedTime WHERE CustomerId = @CustomerId AND IsActive = 1
UPDATE Customers SET LegalStatusId = @LegalStatusId,UpdatedById = @CreatedById,UpdatedTime=@CreatedTime WHERE Id = @CustomerId
INSERT INTO dbo.LegalStatusHistories
(
AssignmentDate,
IsActive,
SourceModule,
CreatedById,
CreatedTime,
LegalStatusId,
CustomerId
)
VALUES
(CAST(@CreatedTime AS DATE),
1,
'ActivityCenter',
@CreatedById,
@CreatedTime,
@LegalStatusId,
@CustomerId
)
DECLARE @LegalStatus NVARCHAR(MAX)
SELECT @LegalStatus = LegalStatus FROM LegalStatusConfigs WHERE Id = @LegalStatusId
SELECT DISTINCT T.ContractId
INTO #ContractIds
FROM
(
SELECT ContractId FROM Leasefinances
WHERE CustomerId = @CustomerId
AND IsCurrent = 1
UNION
SELECT ContractId FROM LoanFinances
WHERE CustomerId = @CustomerId
AND IsCurrent = 1
) T
DECLARE @ReportStatus NVARCHAR(MAX) = NULL
SELECT @ReportStatus = (CASE WHEN @LegalStatus = 'Chapter 7 Bankruptcy Discharged'
OR @LegalStatus =  'Chapter 11 Bankruptcy Discharged'
OR @LegalStatus =  'Chapter 13 Bankruptcy Discharged'
THEN 'Discharged'
WHEN @LegalStatus = 'Chapter 13 Bankruptcy'
THEN 'BK13'
WHEN @LegalStatus = 'Chapter 7 Bankruptcy' OR @LegalStatus = 'Chapter 11 Bankruptcy'
THEN 'BK7/11'
ELSE ''
END)
IF @ReportStatus <> '' AND @ReportStatus IS NOT NULL
BEGIN

SELECT c.ID INTO #ContractIdToUpdates FROM Contracts C
JOIN #ContractIds mc on c.Id = mc.ContractId
WHERE C.ReportStatus <> @ReportStatus 

UPDATE Contracts SET ReportStatus = @ReportStatus,UpdatedById = @CreatedById,UpdatedTime=@CreatedTime WHERE Id IN (SELECT ContractId FROM #ContractIds)

INSERT INTO ContractReportStatusHistories (ReportStatus,  CreatedById, CreatedTime, ContractId)
SELECT @ReportStatus,@CreatedById, @CreatedTime, #ContractIdToUpdates.Id
FROM #ContractIdToUpdates 

END
END

GO
