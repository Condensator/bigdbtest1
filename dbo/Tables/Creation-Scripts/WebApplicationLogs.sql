SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebApplicationLogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CorrelationId] [nvarchar](36) COLLATE Latin1_General_CI_AS NULL,
	[HostName] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicationName] [nvarchar](256) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Level] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[RawUrl] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Message] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Exception] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
