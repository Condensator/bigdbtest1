CREATE TYPE [dbo].[CustomizationPack] AS TABLE(
	[MetamodelContent] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DomainAssembly] [varbinary](max) NULL,
	[DatabaseUpdateScript] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[PublisherTool] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Comments] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveDate] [date] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
