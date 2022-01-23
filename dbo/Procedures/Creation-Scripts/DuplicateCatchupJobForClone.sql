SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DuplicateCatchupJobForClone]
(
  @TotalNodes INT
)
AS
    BEGIN

        DECLARE @ToolIdentifier INT= 1;
		DECLARE @CloneProcessingOrder decimal(16, 2) = (select ProcessingOrder from stgModule where name = 'CloneDB')
		DECLARE @MergeProcessingOrder decimal(16, 2) = (select ProcessingOrder from stgModule where name = 'MergeDB')
        WHILE @ToolIdentifier <= @TotalNodes		
		
            BEGIN
                IF @ToolIdentifier = 1
                    BEGIN
                        UPDATE StgCatchUpJob SET ToolIdentifier = 1
						FROM stgCatchUpJob c 
						JOIN (
							select * from stgmodule m
							cross apply string_split(m.WhereClause,' ') where value like '%Stage=%') t
							on c.Stage=right(t.value, LEN(t.value)-CHARINDEX('=',t.value))
                        WHERE t.ProcessingOrder > @CloneProcessingOrder AND t.ProcessingOrder < @MergeProcessingOrder AND (c.ToolIdentifier IS NULL
                              OR c.ToolIdentifier = 1);
				    END;
				ELSE
				    BEGIN
					CREATE TABLE #InsertedJobIds([InsertedId] BIGINT NOT NULL, [JobId] BIGINT NOT NULL); 
					CREATE TABLE #InsertedCatchupJobStepIds([InsertedId] BIGINT NOT NULL, [CatchupJobStepId] BIGINT NOT NULL); 
					SELECT c.*
					INTO #JobDetails
					FROM StgCatchUpJob c 
						JOIN (
							select * from stgmodule m
							cross apply string_split(m.WhereClause,' ') where value like '%Stage=%') t
							on c.Stage=right(t.value, LEN(t.value)-CHARINDEX('=',t.value))
                        WHERE t.ProcessingOrder > @CloneProcessingOrder AND t.ProcessingOrder < @MergeProcessingOrder AND 
					 c.ToolIdentifier = 1;

					MERGE StgCatchUpJob
					USING
					(SELECT jd.*
					 FROM #JobDetails AS jd
					 LEFT JOIN StgCatchUpJob ON StgCatchUpJob.JobName = jd.JobName
												AND ISNULL(StgCatchUpJob.Description, '') = ISNULL(jd.Description, '')
					 							AND StgCatchUpJob.Stage = jd.Stage
												AND ISNULL(StgCatchUpJob.UserName, '') = ISNULL(jd.UserName, '')
					   							AND ISNULL(StgCatchUpJob.ToolIdentifier, 0) = @ToolIdentifier
					 WHERE StgCatchUpJob.Id IS NULL) AS Jobs					
					ON 1= 0   
					WHEN NOT MATCHED
					THEN
						INSERT(JobName, 
							   CreatedById, 
							   CreatedTime, 
							   UpdatedById, 
							   UpdatedTime, 
							   Description, 
							   UserName, 
							   IsMigrated, 
							   Stage, 
							   ToolIdentifier)
						VALUES
							   (JobName, 
							   CreatedById, 
							   SYSDATETIMEOFFSET(), 
							   UpdatedById, 
							   UpdatedTime, 
							   Description, 
							   UserName, 
							   IsMigrated, 
							   Stage, 
							   @ToolIdentifier)
					OUTPUT Inserted.Id AS InsertedId, Jobs.Id AS JobId INTO #InsertedJobIds;

					MERGE StgCatchUpJobStep
					USING
					(SELECT *
					 FROM StgCatchUpJobStep AS cujs
						  INNER JOIN #InsertedJobIds AS iji ON iji.JobId = cujs.CatchUpJobId
					) AS catchupjobstep
					ON 1 = 0
					WHEN NOT MATCHED
					THEN
						INSERT(JobStepName, 
							   CreatedById, 
							   CreatedTime, 
							   GLTemplate, 
							   ExecutionOrder, 
							   AbortOnFailure, 
							   CreateMultipleSteps, 
							   AllLegalEntities, 
							   ProcessThroughDate, 
							   PostDate, 
							   CatchUpJobId, 
							   ProcessThroughDateOption, 
							   NumberOfDaysFromRunDate)
						VALUES (JobStepName, 
							   catchupjobstep.CreatedById, 
							   SYSDATETIMEOFFSET(), 
							   GLTemplate, 
							   ExecutionOrder, 
							   AbortOnFailure, 
							   CreateMultipleSteps, 
							   AllLegalEntities, 
							   ProcessThroughDate, 
							   PostDate, 
							   catchupjobstep.InsertedId, 
							   ProcessThroughDateOption, 
							   NumberOfDaysFromRunDate)
					OUTPUT inserted.Id AS InsertedId, catchupjobstep.Id AS CatchupJobStepId INTO #InsertedCatchupJobStepIds;

					INSERT INTO StgCatchUpJobStepLegalEntity
					(LegalEntityNumber, 
					CreatedById, 
					CreatedTime, 
					UpdatedById, 
					UpdatedTime, 
					CatchUpJobStepId)

					SELECT LegalEntityNumber,
							CreatedById,
							SYSDATETIMEOFFSET(),
							UpdatedById,
							UpdatedTime,
							Jobs.InsertedId 
					FROM #InsertedCatchupJobStepIds Jobs
						 INNER JOIN StgCatchUpJobStepLegalEntity legalentity ON legalentity.CatchUpJobStepId = Jobs.CatchupJobStepId;
					DROP TABLE #InsertedJobIds;
					DROP TABLE #JobDetails;
					DROP TABLE #InsertedCatchupJobStepIds;
		    END;
		SET @ToolIdentifier = @ToolIdentifier + 1;
        END;
    END;

GO
