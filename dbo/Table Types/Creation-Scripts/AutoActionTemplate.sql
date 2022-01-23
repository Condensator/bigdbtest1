CREATE TYPE [dbo].[AutoActionTemplate] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntitySelectionSQL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[UpdateStoredProc] [nvarchar](128) COLLATE Latin1_General_CI_AS NULL,
	[MasterStoredProc] [nvarchar](128) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreateWorkItem] [bit] NOT NULL,
	[CreateNotification] [bit] NOT NULL,
	[CreateComment] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[EntityTypeId] [bigint] NULL,
	[TransactionConfigId] [bigint] NULL,
	[NotificationConfigId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
