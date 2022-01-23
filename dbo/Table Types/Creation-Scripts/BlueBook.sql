CREATE TYPE [dbo].[BlueBook] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Model] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ManufacturerId] [bigint] NOT NULL,
	[AssetCategoryId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
