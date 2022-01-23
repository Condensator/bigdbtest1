CREATE TYPE [dbo].[DocumentExtractionScript] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MappingScript] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[SampleXML] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
