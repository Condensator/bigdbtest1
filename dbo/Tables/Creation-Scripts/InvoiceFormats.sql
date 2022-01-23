SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceFormats](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ReportName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[InvoiceLanguageId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[IsStatementFormat] [bit] NOT NULL,
	[IsVATInvoiceFormat] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EInvoiceFormat_InvoiceLanguage] FOREIGN KEY([InvoiceLanguageId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[InvoiceFormats] CHECK CONSTRAINT [EInvoiceFormat_InvoiceLanguage]
GO
ALTER TABLE [dbo].[InvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EInvoiceFormat_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[InvoiceFormats] CHECK CONSTRAINT [EInvoiceFormat_Portfolio]
GO
ALTER TABLE [dbo].[InvoiceFormats]  WITH CHECK ADD  CONSTRAINT [EInvoiceType_InvoiceFormats] FOREIGN KEY([InvoiceTypeId])
REFERENCES [dbo].[InvoiceTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InvoiceFormats] CHECK CONSTRAINT [EInvoiceType_InvoiceFormats]
GO
