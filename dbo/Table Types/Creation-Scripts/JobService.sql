CREATE TYPE [dbo].[JobService] AS TABLE(
	[HostName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ServiceName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsRunning] [bit] NOT NULL,
	[RecentActiveTime] [datetimeoffset](7) NULL,
	[PhysicalPath] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[HostingEnvironment] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
