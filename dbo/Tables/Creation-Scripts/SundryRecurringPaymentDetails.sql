SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SundryRecurringPaymentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[StartDate] [date] NULL,
	[TerminationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[BillToId] [bigint] NULL,
	[SundryRecurringId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayableAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SundryRecurringPaymentDetails]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_SundryRecurringPaymentDetails] FOREIGN KEY([SundryRecurringId])
REFERENCES [dbo].[SundryRecurrings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SundryRecurringPaymentDetails] CHECK CONSTRAINT [ESundryRecurring_SundryRecurringPaymentDetails]
GO
ALTER TABLE [dbo].[SundryRecurringPaymentDetails]  WITH CHECK ADD  CONSTRAINT [ESundryRecurringPaymentDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurringPaymentDetails] CHECK CONSTRAINT [ESundryRecurringPaymentDetail_Asset]
GO
ALTER TABLE [dbo].[SundryRecurringPaymentDetails]  WITH CHECK ADD  CONSTRAINT [ESundryRecurringPaymentDetail_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurringPaymentDetails] CHECK CONSTRAINT [ESundryRecurringPaymentDetail_BillTo]
GO
