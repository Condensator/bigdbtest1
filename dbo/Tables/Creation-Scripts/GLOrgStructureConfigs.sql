SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLOrgStructureConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BusinessCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[BusinessCodeDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[MORDate] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[OrgStructureComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AnalysisCodeBasedOnCenter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AnalysisCodeBasedOnBizCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CounterpartyAnalysisCodeBasedOnBizCodeAndLE] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLOrgStructureConfigs]  WITH CHECK ADD  CONSTRAINT [EGLOrgStructureConfig_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[GLOrgStructureConfigs] CHECK CONSTRAINT [EGLOrgStructureConfig_CostCenter]
GO
ALTER TABLE [dbo].[GLOrgStructureConfigs]  WITH CHECK ADD  CONSTRAINT [EGLOrgStructureConfig_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[GLOrgStructureConfigs] CHECK CONSTRAINT [EGLOrgStructureConfig_Currency]
GO
ALTER TABLE [dbo].[GLOrgStructureConfigs]  WITH CHECK ADD  CONSTRAINT [EGLOrgStructureConfig_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[GLOrgStructureConfigs] CHECK CONSTRAINT [EGLOrgStructureConfig_LegalEntity]
GO
ALTER TABLE [dbo].[GLOrgStructureConfigs]  WITH CHECK ADD  CONSTRAINT [EGLOrgStructureConfig_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[GLOrgStructureConfigs] CHECK CONSTRAINT [EGLOrgStructureConfig_LineofBusiness]
GO
