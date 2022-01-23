SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomizationPacks](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[MetamodelContent] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DomainAssembly] [varbinary](max) NULL,
	[DatabaseUpdateScript] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[PublisherTool] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Comments] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
