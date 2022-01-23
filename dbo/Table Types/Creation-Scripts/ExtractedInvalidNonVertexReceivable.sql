CREATE TYPE [dbo].[ExtractedInvalidNonVertexReceivable] AS TABLE(
	[Message] [nvarchar](2000) COLLATE Latin1_General_CI_AS NOT NULL,
	[MessageType] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL
)
GO
