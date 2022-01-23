SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UDFFields](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ColumnName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[UILabelName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BusinessColumns] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ChangeType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
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
