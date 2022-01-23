CREATE TYPE [dbo].[Mig_LWTables] AS TABLE(
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaxId] [bigint] NOT NULL,
	[HasIdentity] [bit] NOT NULL,
	[IsMerged] [bit] NOT NULL,
	[StartTime] [datetimeoffset](7) NULL,
	[EndTime] [datetimeoffset](7) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
