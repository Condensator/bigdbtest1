SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AMLRiskAssessmentCriterias](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Point] [decimal](16, 2) NULL,
	[AMLMasterConfigId] [bigint] NULL,
	[ChoiceId] [bigint] NULL,
	[CountryId] [bigint] NULL,
	[AMLRiskAssessmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias]  WITH CHECK ADD  CONSTRAINT [EAMLRiskAssessment_AMLRiskAssessmentCriterias] FOREIGN KEY([AMLRiskAssessmentId])
REFERENCES [dbo].[AMLRiskAssessments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias] CHECK CONSTRAINT [EAMLRiskAssessment_AMLRiskAssessmentCriterias]
GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias]  WITH CHECK ADD  CONSTRAINT [EAMLRiskAssessmentCriteria_AMLMasterConfig] FOREIGN KEY([AMLMasterConfigId])
REFERENCES [dbo].[AMLMasterConfigs] ([Id])
GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias] CHECK CONSTRAINT [EAMLRiskAssessmentCriteria_AMLMasterConfig]
GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias]  WITH CHECK ADD  CONSTRAINT [EAMLRiskAssessmentCriteria_Choice] FOREIGN KEY([ChoiceId])
REFERENCES [dbo].[AMLChoiceConfigs] ([Id])
GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias] CHECK CONSTRAINT [EAMLRiskAssessmentCriteria_Choice]
GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias]  WITH CHECK ADD  CONSTRAINT [EAMLRiskAssessmentCriteria_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[AMLRiskAssessmentCriterias] CHECK CONSTRAINT [EAMLRiskAssessmentCriteria_Country]
GO
