SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LateFeeAssessments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FullyAssessed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LateFeeAssessedUntilDate] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LateFeeAssessments]  WITH CHECK ADD  CONSTRAINT [ELateFeeAssessment_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LateFeeAssessments] CHECK CONSTRAINT [ELateFeeAssessment_Contract]
GO
ALTER TABLE [dbo].[LateFeeAssessments]  WITH CHECK ADD  CONSTRAINT [ELateFeeAssessment_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LateFeeAssessments] CHECK CONSTRAINT [ELateFeeAssessment_Customer]
GO
ALTER TABLE [dbo].[LateFeeAssessments]  WITH CHECK ADD  CONSTRAINT [ELateFeeAssessment_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[LateFeeAssessments] CHECK CONSTRAINT [ELateFeeAssessment_ReceivableInvoice]
GO
