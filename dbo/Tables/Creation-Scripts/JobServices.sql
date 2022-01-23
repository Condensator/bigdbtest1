SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobServices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[HostName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsRunning] [bit] NOT NULL,
	[RecentActiveTime] [datetimeoffset](7) NULL,
	[PhysicalPath] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ServiceName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[HostingEnvironment] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
