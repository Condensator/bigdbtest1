CREATE TYPE [dbo].[EncryptedMasterKey] AS TABLE(
	[Key] [varbinary](max) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SqlUser] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
