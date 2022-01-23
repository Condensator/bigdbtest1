SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetExtractedReceivablesForPostReceivables]
(
@JobStepInstanceId BIGINT
)
AS
SET NOCOUNT ON;
BEGIN

SELECT IsSubmitted 
FROM PostReceivableToGLJob_Extracts 
WHERE JobStepInstanceId = @JobStepInstanceId

END

GO
