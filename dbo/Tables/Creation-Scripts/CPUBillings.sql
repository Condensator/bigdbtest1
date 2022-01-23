SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUBillings](
	[Id] [bigint] NOT NULL,
	[BasePassThroughPercent] [decimal](5, 2) NULL,
	[OveragePassThroughPercent] [decimal](5, 2) NULL,
	[InvoiceLeadDays] [int] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[BillToId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[PassThroughRemitToId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[PerfectPayModeAssigned] [bit] NOT NULL,
	[InvoiceTransitDays] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUBillings]  WITH CHECK ADD  CONSTRAINT [ECPUBilling_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[CPUBillings] CHECK CONSTRAINT [ECPUBilling_BillTo]
GO
ALTER TABLE [dbo].[CPUBillings]  WITH CHECK ADD  CONSTRAINT [ECPUBilling_PassThroughRemitTo] FOREIGN KEY([PassThroughRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[CPUBillings] CHECK CONSTRAINT [ECPUBilling_PassThroughRemitTo]
GO
ALTER TABLE [dbo].[CPUBillings]  WITH CHECK ADD  CONSTRAINT [ECPUBilling_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[CPUBillings] CHECK CONSTRAINT [ECPUBilling_RemitTo]
GO
ALTER TABLE [dbo].[CPUBillings]  WITH CHECK ADD  CONSTRAINT [ECPUBilling_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CPUBillings] CHECK CONSTRAINT [ECPUBilling_Vendor]
GO
ALTER TABLE [dbo].[CPUBillings]  WITH CHECK ADD  CONSTRAINT [ECPUFinance_CPUBilling] FOREIGN KEY([Id])
REFERENCES [dbo].[CPUFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUBillings] CHECK CONSTRAINT [ECPUFinance_CPUBilling]
GO
