SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ACHAmount_Amount] [decimal](16, 2) NOT NULL,
	[ACHAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsSeparateReceipt] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableId] [bigint] NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[OneTimeACHId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OneTimeACHSchedules]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_OneTimeACHSchedules] FOREIGN KEY([OneTimeACHId])
REFERENCES [dbo].[OneTimeACHes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OneTimeACHSchedules] CHECK CONSTRAINT [EOneTimeACH_OneTimeACHSchedules]
GO
ALTER TABLE [dbo].[OneTimeACHSchedules]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHSchedule_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHSchedules] CHECK CONSTRAINT [EOneTimeACHSchedule_Receivable]
GO
ALTER TABLE [dbo].[OneTimeACHSchedules]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHSchedule_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHSchedules] CHECK CONSTRAINT [EOneTimeACHSchedule_ReceivableInvoice]
GO
