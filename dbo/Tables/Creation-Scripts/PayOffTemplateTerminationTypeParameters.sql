SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffTemplateTerminationTypeParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ApplicableForFixedTerm] [bit] NOT NULL,
	[DiscountRate] [decimal](8, 4) NULL,
	[Factor] [decimal](8, 4) NULL,
	[NumberofTerms] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TerminationTypeParameterConfigId] [bigint] NOT NULL,
	[PayOffTemplateTerminationTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[IsExcludeFeeApplicable] [bit] NOT NULL,
	[FeeExclusionExpression] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationType_PayOffTemplateTerminationTypeParameters] FOREIGN KEY([PayOffTemplateTerminationTypeId])
REFERENCES [dbo].[PayOffTemplateTerminationTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters] CHECK CONSTRAINT [EPayOffTemplateTerminationType_PayOffTemplateTerminationTypeParameters]
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationTypeParameter_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters] CHECK CONSTRAINT [EPayOffTemplateTerminationTypeParameter_PayableCode]
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationTypeParameter_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters] CHECK CONSTRAINT [EPayOffTemplateTerminationTypeParameter_ReceivableCode]
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationTypeParameter_TerminationTypeParameterConfig] FOREIGN KEY([TerminationTypeParameterConfigId])
REFERENCES [dbo].[TerminationTypeParameterConfigs] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypeParameters] CHECK CONSTRAINT [EPayOffTemplateTerminationTypeParameter_TerminationTypeParameterConfig]
GO
