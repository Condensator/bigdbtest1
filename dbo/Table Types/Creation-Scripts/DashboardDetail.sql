CREATE TYPE [dbo].[DashboardDetail] AS TABLE(
	[DisplayText1] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DisplayText2] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DisplayText3] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
