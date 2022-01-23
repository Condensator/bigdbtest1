CREATE TYPE [dbo].[AssetFMVMatrixDetail] AS TABLE(
	[FromMonth] [int] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ToMonth] [int] NULL,
	[FMVFactor] [decimal](8, 4) NULL,
	[AssetFMVMatrixId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
