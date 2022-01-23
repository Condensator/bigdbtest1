SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AMLRiskCategorizations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Adjustment] [decimal](5, 2) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Point] [decimal](16, 2) NULL,
	[Category] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[AMLRiskCategoryConfigId] [bigint] NULL,
	[AMLRiskAssessmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AMLRiskCategorizations]  WITH CHECK ADD  CONSTRAINT [EAMLRiskAssessment_AMLRiskCategorizations] FOREIGN KEY([AMLRiskAssessmentId])
REFERENCES [dbo].[AMLRiskAssessments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AMLRiskCategorizations] CHECK CONSTRAINT [EAMLRiskAssessment_AMLRiskCategorizations]
GO
ALTER TABLE [dbo].[AMLRiskCategorizations]  WITH CHECK ADD  CONSTRAINT [EAMLRiskCategorization_AMLRiskCategoryConfig] FOREIGN KEY([AMLRiskCategoryConfigId])
REFERENCES [dbo].[AMLRiskCategoryConfigs] ([Id])
GO
ALTER TABLE [dbo].[AMLRiskCategorizations] CHECK CONSTRAINT [EAMLRiskCategorization_AMLRiskCategoryConfig]
GO
