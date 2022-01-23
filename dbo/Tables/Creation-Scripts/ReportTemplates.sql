SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReportTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[OutputFormat] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[Privacy] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[ColumnsToHide] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ColumnOrder] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SortOrder] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[GroupBy] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[GroupByLabel] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[TotalFieldsToHide] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SortBy] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Culture] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[NonAccessableFieldList] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Type] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
