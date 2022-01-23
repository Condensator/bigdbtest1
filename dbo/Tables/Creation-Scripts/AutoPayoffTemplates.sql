SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoPayoffTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ThresholdDaysOption] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[ThresholdDays] [int] NULL,
	[ActivatePayoffQuote] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayoffTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayoffTemplateTerminationTypeConfigId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AutoPayoffTemplates]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplate_PayoffTemplate] FOREIGN KEY([PayoffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplates] CHECK CONSTRAINT [EAutoPayoffTemplate_PayoffTemplate]
GO
ALTER TABLE [dbo].[AutoPayoffTemplates]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplate_PayoffTemplateTerminationTypeConfig] FOREIGN KEY([PayoffTemplateTerminationTypeConfigId])
REFERENCES [dbo].[PayoffTemplateTerminationTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplates] CHECK CONSTRAINT [EAutoPayoffTemplate_PayoffTemplateTerminationTypeConfig]
GO
