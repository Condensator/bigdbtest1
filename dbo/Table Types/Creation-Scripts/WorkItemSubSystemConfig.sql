CREATE TYPE [dbo].[WorkItemSubSystemConfig] AS TABLE(
	[Form] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Viewable] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[SubSystemId] [bigint] NOT NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
