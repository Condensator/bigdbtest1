SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateComments]
(@UserId                  BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN
CREATE TABLE #ErrorLogs
(Id                  BIGINT NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result              NVARCHAR(10),
Message             NVARCHAR(MAX)
);
CREATE TABLE #FailedProcessingLogs
([Id]        BIGINT NOT NULL,
[CommentId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM dbo.stgComment
WHERE IsMigrated = 0
);
UPDATE stgComment
SET
R_AuthorId = Users.Id
FROM stgComment Comment
INNER JOIN Users ON Comment.AuthorLoginName = USERS.LoginName
WHERE Comment.R_AuthorId IS NULL
AND Comment.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid Author Login Name {' + ISNULL(AuthorLoginName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
WHERE C.IsMigrated = 0
AND R_AuthorId IS NULL
AND AuthorLoginName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Please Enter Comment Type Name {' + ISNULL(CommentTypeName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
WHERE C.IsMigrated = 0
AND CommentTypeName IS NULL;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Please Enter Title {' + ISNULL(Title, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
WHERE C.IsMigrated = 0
AND Title IS NULL;
UPDATE stgComment
SET
R_CommentTypeId = type.Id
FROM stgComment Comment
INNER JOIN CommentTypes type ON Comment.CommentTypeName = type.Name
WHERE type.IsActive =1 AND Comment.R_CommentTypeId IS NULL
AND Comment.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid Comment Type Name {' + ISNULL(CommentTypeName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
WHERE C.IsMigrated = 0
AND R_CommentTypeId IS NULL
AND CommentTypeName IS NOT NULL;
UPDATE stgCommentUser
SET
R_UserLoginId = U.Id
FROM stgCommentUser CU
INNER JOIN stgComment C ON C.Id = CU.CommentId
INNER JOIN Users U ON U.LoginName = CU.UserLoginName
WHERE CU.R_UserLoginId IS NULL
AND IsMigrated = 0
AND CU.UserLoginName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid User Login Name {' + ISNULL(UserLoginName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
INNER JOIN stgCommentUser CU ON C.Id = CU.CommentId
WHERE C.IsMigrated = 0
AND R_UserLoginId IS NULL
AND UserLoginName IS NOT NULL;
UPDATE stgComment
SET
R_FollowUpById = Users.Id
FROM stgComment Comment
INNER JOIN Users ON Comment.FollowUpByLoginName = Users.LoginName
WHERE Comment.R_FollowUpById IS NULL
AND Comment.IsMigrated = 0
AND Comment.FollowUpByLoginName IS NOT NULL
AND Comment.ConversationMode = 'Open';
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid Follow Up By Login Name {' + ISNULL(FollowUpByLoginName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
WHERE C.IsMigrated = 0
AND R_FollowUpById IS NULL
AND FollowUpByLoginName IS NOT NULL
AND ConversationMode = 'Open';
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Follow Up By Login Name should not be present when ConversationMode is None {' + ISNULL(FollowUpByLoginName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
WHERE C.IsMigrated = 0
AND R_FollowUpById IS NULL
AND FollowUpByLoginName IS NOT NULL
AND ConversationMode = 'None';
UPDATE stgCommentResponse
SET
R_UserId = Users.Id
FROM stgCommentResponse CommentResponse
INNER JOIN Users ON CommentResponse.UserLoginName = Users.LoginName
INNER JOIN stgComment Comment ON Comment.Id = CommentResponse.CommentId
WHERE CommentResponse.R_UserId IS NULL
AND IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid User Login Name {' + ISNULL(CommentResponse.UserLoginName, 'NULL') + '} with Comment Response Id {' + CONVERT(NVARCHAR(MAX), CommentResponse.Id) + '}')
FROM stgCommentResponse CommentResponse
INNER JOIN stgComment C ON C.Id = CommentResponse.CommentId
WHERE C.IsMigrated = 0
AND CommentResponse.R_UserId IS NULL;
UPDATE stgComment
SET
R_CommentEntityTagId = detail.CommentEntityConfigId
FROM stgComment C
INNER JOIN
(
SELECT UserFriendlyName AS        Name
, CommentEntityConfigs.Id AS CommentEntityConfigId
, EntityResources.Value AS   Value
FROM CommentEntityConfigs
INNER JOIN EntityConfigs ON CommentEntityConfigs.Id = EntityConfigs.Id
LEFT JOIN EntityResources ON EntityConfigs.Id = EntityResources.EntityId
AND EntityResources.EntityType = 'EntityConfig'
AND EntityResources.Name = 'UserFriendlyName'
) AS detail ON((detail.Name = C.EntityTypeName
AND detail.Value IS NULL)
OR detail.Value = C.EntityTypeName)
WHERE C.IsMigrated = 0
AND C.EntityTypeName IS NOT NULL
AND C.R_CommentEntityTagId IS NULL;
UPDATE stgCommentTag
SET
R_CommentEntityTagId = CommentTagValuesConfigs.Id
, R_IsEntityTag = 0
FROM stgCommentTag
INNER JOIN stgComment Comment ON Comment.Id = stgCommentTag.CommentId
INNER JOIN CommentTagConfigs ON stgCommentTag.CommentTagConfigName = CommentTagConfigs.Name
AND CommentTagConfigs.IsActive = 1
INNER JOIN CommentTagValuesConfigs ON CommentTagConfigs.Id = CommentTagValuesConfigs.CommentTagConfigId
AND CommentTagValuesConfigs.Value = stgCommentTag.Value
WHERE Comment.IsMigrated = 0
AND stgCommentTag.CommentTagConfigName IS NOT NULL
AND stgCommentTag.R_CommentEntityTagId IS NULL;
UPDATE stgCommentTag
SET
R_CommentEntityTagId = detail.CommentEntityConfigId
, R_IsEntityTag = 1
FROM stgCommentTag CT
INNER JOIN stgComment C ON CT.CommentId = C.Id
INNER JOIN
(
SELECT UserFriendlyName AS        Name
, CommentEntityConfigs.Id AS CommentEntityConfigId
, EntityResources.Value AS   Value
FROM CommentEntityConfigs
INNER JOIN EntityConfigs ON CommentEntityConfigs.Id = EntityConfigs.Id
LEFT JOIN EntityResources ON EntityConfigs.Id = EntityResources.EntityId
AND EntityResources.EntityType = 'EntityConfig'
AND EntityResources.Name = 'UserFriendlyName'
) AS detail ON((detail.Name = CT.CommentTagConfigName
AND detail.Value IS NULL)
OR detail.Value = CT.CommentTagConfigName)
WHERE C.IsMigrated = 0
AND CT.CommentTagConfigName IS NOT NULL
AND CT.R_CommentEntityTagId IS NULL;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Tag Value does not match {' + ISNULL(tag.CommentTagConfigName, 'NULL') + '} for Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
INNER JOIN stgCommentTag tag ON C.Id = tag.CommentId
INNER JOIN CommentTagValuesConfigs config ON tag.R_CommentEntityTagId = config.Id
WHERE C.IsMigrated = 0
AND tag.R_IsEntityTag = 0
AND config.Value != tag.Value;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid Tag Name {' + ISNULL(C.EntityTypeName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
WHERE C.IsMigrated = 0
AND C.R_CommentEntityTagId IS NULL
AND C.EntityTypeName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid Tag Name {' + ISNULL(CommentTag.CommentTagConfigName, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
INNER JOIN stgCommentTag CommentTag ON C.Id = CommentTag.CommentId
WHERE C.IsMigrated = 0
AND CommentTag.R_CommentEntityTagId IS NULL
AND CommentTagConfigName IS NOT NULL;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('At least one Comment Sub-Type must be added for Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
INNER JOIN CommentTypes CT ON C.R_CommentTypeId = CT.Id
LEFT JOIN stgCommentTypeSubType SubType ON SubType.CommentId = C.Id
WHERE C.IsMigrated = 0
AND CT.IsSubTypeRequired = 1
AND SubType.Id IS NULL;
UPDATE stgCommentTypeSubType
SET
R_SubTypeId = CommentSubTypes.Id
FROM stgCommentTypeSubType SubType
INNER JOIN stgComment C ON C.Id = SubType.CommentId
INNER JOIN CommentTypes type ON C.R_CommentTypeId = type.Id
INNER JOIN CommentTypeSubTypes CommentSubTypes ON CommentSubTypes.Name = SubType.Name
AND type.Id = CommentTypeId
WHERE SubType.R_SubTypeId IS NULL
AND IsMigrated = 0
AND CommentSubTypes.IsActive = 1;
INSERT INTO #ErrorLogs
SELECT C.Id
, 'Error'
, ('Invalid Sub Type Name {' + ISNULL(SubType.Name, 'NULL') + '} with Comment Id {' + CONVERT(NVARCHAR(MAX), C.Id) + '}')
FROM stgComment C
INNER JOIN CommentTypes type ON C.R_CommentTypeId = type.Id
INNER JOIN stgCommentTypeSubType SubType ON C.Id = SubType.CommentId
WHERE C.IsMigrated = 0
AND SubType.R_SubTypeId IS NULL;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM dbo.stgComment
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedComments
ON(ProcessingLog.StagingRootEntityId = ProcessedComments.Id
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ProcessedComments.Id
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT 'Successful'
, 'Information'
, @UserId
, @CreatedTime
, Id
FROM #CreatedProcessingLogs;
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT
StagingRootEntityId
FROM #ErrorLogs
) AS ErrorComments
ON(ProcessingLog.StagingRootEntityId = ErrorComments.StagingRootEntityId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
, UpdatedById = @UserId
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ErrorComments.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorComments.StagingRootEntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #ErrorLogs.Message
, 'Error'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.CommentId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO
