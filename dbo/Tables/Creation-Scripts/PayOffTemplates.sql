SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TemplateName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TemplateType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[FRRApplicable] [bit] NOT NULL,
	[FRROption] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[RetainedVendorApplicable] [bit] NOT NULL,
	[VendorRetained] [bit] NOT NULL,
	[IsEPOApplicable] [bit] NOT NULL,
	[IsApplicableWhenEPOAvailable] [bit] NOT NULL,
	[ApplicableforFloatRateContract] [bit] NOT NULL,
	[TradeupFeeApplicable] [bit] NOT NULL,
	[TradeupFeeCalculationMethod] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[TradeupFeeAmount] [decimal](16, 2) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayoffTradeUpFeeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayOffTemplates]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplate_PayoffTradeUpFee] FOREIGN KEY([PayoffTradeUpFeeId])
REFERENCES [dbo].[PayoffTradeUpFees] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplates] CHECK CONSTRAINT [EPayOffTemplate_PayoffTradeUpFee]
GO
ALTER TABLE [dbo].[PayOffTemplates]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplate_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplates] CHECK CONSTRAINT [EPayOffTemplate_Portfolio]
GO
ALTER TABLE [dbo].[PayOffTemplates]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplate_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplates] CHECK CONSTRAINT [EPayOffTemplate_ReceivableCode]
GO
