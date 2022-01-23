SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReportPreferenceConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReportName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReportColumn] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReportColumnLabel] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Order] [bigint] NOT NULL,
	[GroupOrder] [bigint] NOT NULL,
	[AllowSort] [bit] NOT NULL,
	[AllowGroup] [bit] NOT NULL,
	[AllowSubTotal] [bit] NOT NULL,
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
