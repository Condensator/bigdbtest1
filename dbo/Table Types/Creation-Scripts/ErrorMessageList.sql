CREATE TYPE [dbo].[ErrorMessageList] AS TABLE(
	[StagingRootEntityId] [bigint] NOT NULL,
	[ModuleIterationStatusId] [bigint] NOT NULL,
	[Message] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL DEFAULT ('Error')
)
GO
