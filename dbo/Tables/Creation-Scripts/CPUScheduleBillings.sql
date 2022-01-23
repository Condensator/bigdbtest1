SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUScheduleBillings](
	[Id] [bigint] NOT NULL,
	[BasePassThroughPercent] [decimal](5, 2) NULL,
	[OveragePassThroughPercent] [decimal](5, 2) NULL,
	[InvoiceLeadDays] [int] NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[BillToId] [bigint] NULL,
	[PassThroughRemitToId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUScheduleBillings]  WITH CHECK ADD  CONSTRAINT [ECPUSchedule_CPUScheduleBilling] FOREIGN KEY([Id])
REFERENCES [dbo].[CPUSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUScheduleBillings] CHECK CONSTRAINT [ECPUSchedule_CPUScheduleBilling]
GO
ALTER TABLE [dbo].[CPUScheduleBillings]  WITH CHECK ADD  CONSTRAINT [ECPUScheduleBilling_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[CPUScheduleBillings] CHECK CONSTRAINT [ECPUScheduleBilling_BillTo]
GO
ALTER TABLE [dbo].[CPUScheduleBillings]  WITH CHECK ADD  CONSTRAINT [ECPUScheduleBilling_PassThroughRemitTo] FOREIGN KEY([PassThroughRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[CPUScheduleBillings] CHECK CONSTRAINT [ECPUScheduleBilling_PassThroughRemitTo]
GO
ALTER TABLE [dbo].[CPUScheduleBillings]  WITH CHECK ADD  CONSTRAINT [ECPUScheduleBilling_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CPUScheduleBillings] CHECK CONSTRAINT [ECPUScheduleBilling_Vendor]
GO
