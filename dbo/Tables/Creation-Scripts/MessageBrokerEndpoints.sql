SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MessageBrokerEndpoints](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Direction] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[QueueType] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[ConnectionConfig] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ComponentName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
