CREATE TYPE [dbo].[ReportPreferenceConfig] AS TABLE(
	[ReportName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReportColumn] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReportColumnLabel] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Order] [bigint] NOT NULL,
	[GroupOrder] [bigint] NOT NULL,
	[AllowSort] [bit] NOT NULL,
	[AllowGroup] [bit] NOT NULL,
	[AllowSubTotal] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
