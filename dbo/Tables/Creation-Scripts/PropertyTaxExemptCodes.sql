SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxExemptCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[EffectiveToDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NOT NULL,
	[PropertyTaxReportCodeId] [bigint] NOT NULL,
	[PropertyTaxParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[UniqueIdentifier] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxExemptCode_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes] CHECK CONSTRAINT [EPropertyTaxExemptCode_Portfolio]
GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxExemptCode_PropertyTaxReportCode] FOREIGN KEY([PropertyTaxReportCodeId])
REFERENCES [dbo].[PropertyTaxReportCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes] CHECK CONSTRAINT [EPropertyTaxExemptCode_PropertyTaxReportCode]
GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxExemptCode_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes] CHECK CONSTRAINT [EPropertyTaxExemptCode_State]
GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxParameter_PropertyTaxExemptCodes] FOREIGN KEY([PropertyTaxParameterId])
REFERENCES [dbo].[PropertyTaxParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PropertyTaxExemptCodes] CHECK CONSTRAINT [EPropertyTaxParameter_PropertyTaxExemptCodes]
GO
