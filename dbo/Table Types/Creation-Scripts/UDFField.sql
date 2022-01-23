CREATE TYPE [dbo].[UDFField] AS TABLE(
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ColumnName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[UILabelName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BusinessColumns] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ChangeType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
