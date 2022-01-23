CREATE TYPE [dbo].[LockboxFileFormatConfigDetail] AS TABLE(
	[FieldName] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StartPosition] [int] NOT NULL,
	[Length] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[LockboxFileFormatConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
