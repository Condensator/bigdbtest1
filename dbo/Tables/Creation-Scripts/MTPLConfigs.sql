SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MTPLConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RegionId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EngineCapacityFrom] [decimal](16, 2) NOT NULL,
	[EngineCapacityTo] [decimal](16, 2) NOT NULL,
	[PermissibleMassFrom] [decimal](16, 2) NULL,
	[PermissibleMassTo] [decimal](16, 2) NULL,
	[SeatsFrom] [int] NULL,
	[SeatsTo] [int] NULL,
	[Frequency] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[InsurancePremium_Amount] [decimal](16, 2) NOT NULL,
	[InsurancePremium_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MTPLConfigs]  WITH CHECK ADD  CONSTRAINT [EMTPLConfig_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[MTPLConfigs] CHECK CONSTRAINT [EMTPLConfig_AssetType]
GO
ALTER TABLE [dbo].[MTPLConfigs]  WITH CHECK ADD  CONSTRAINT [EMTPLConfig_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[MTPLConfigs] CHECK CONSTRAINT [EMTPLConfig_LegalEntity]
GO
