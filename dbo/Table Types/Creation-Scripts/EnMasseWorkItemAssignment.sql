CREATE TYPE [dbo].[EnMasseWorkItemAssignment] AS TABLE(
	[AdminMode] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Type] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Operation] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[OldUserId] [bigint] NULL,
	[NewUserId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
