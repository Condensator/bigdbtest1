SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[LogInvalidReceivables]
(
@LegalEntityName NVARCHAR(MAX),
@GLErrorMessage NVARCHAR(2000),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)
AS
BEGIN
INSERT INTO JobStepInstanceLogs
(
Message, MessageType, CreatedById, CreatedTime, JobStepInstanceId)
VALUES
(REPLACE(@GLErrorMessage,'@LegalEntityName', @LegalEntityName)
,'Error'
,@CreatedById
,SYSDATETIMEOFFSET()
,@JobStepInstanceId
);
END

GO
