CREATE TYPE [dbo].[ProgramAssetTypeEOTOption] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsDefault] [bit] NOT NULL,
	[EOTOption] [nvarchar](32) COLLATE Latin1_General_CI_AS NOT NULL,
	[ProgramAssetTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
