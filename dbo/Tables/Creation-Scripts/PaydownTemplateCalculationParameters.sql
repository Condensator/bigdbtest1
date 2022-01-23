SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaydownTemplateCalculationParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[DiscountRate] [decimal](8, 4) NULL,
	[Factor] [decimal](8, 4) NULL,
	[NumberofTerms] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TerminationTypeParameterConfigId] [bigint] NULL,
	[PaydownCalculationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaydownTemplateCalculationParameters]  WITH CHECK ADD  CONSTRAINT [EPaydownCalculation_PaydownTemplateCalculationParameters] FOREIGN KEY([PaydownCalculationId])
REFERENCES [dbo].[PaydownCalculations] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaydownTemplateCalculationParameters] CHECK CONSTRAINT [EPaydownCalculation_PaydownTemplateCalculationParameters]
GO
ALTER TABLE [dbo].[PaydownTemplateCalculationParameters]  WITH CHECK ADD  CONSTRAINT [EPaydownTemplateCalculationParameter_TerminationTypeParameterConfig] FOREIGN KEY([TerminationTypeParameterConfigId])
REFERENCES [dbo].[TerminationTypeParameterConfigs] ([Id])
GO
ALTER TABLE [dbo].[PaydownTemplateCalculationParameters] CHECK CONSTRAINT [EPaydownTemplateCalculationParameter_TerminationTypeParameterConfig]
GO
