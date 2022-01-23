CREATE TYPE [dbo].[AssetSerialNumberHistory] AS TABLE(
	[OldSerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NewSerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetHistoryId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
