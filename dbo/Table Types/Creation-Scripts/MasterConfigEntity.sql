CREATE TYPE [dbo].[MasterConfigEntity] AS TABLE(
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ExcelSheetName] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ParentEntityId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
