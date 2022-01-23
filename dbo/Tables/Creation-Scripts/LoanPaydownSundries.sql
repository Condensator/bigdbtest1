SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownSundries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncludeInPaydownInvoice] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DueDate] [date] NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LocationId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[RemitToId] [bigint] NOT NULL,
	[BillToId] [bigint] NULL,
	[SundryPayableCodeId] [bigint] NULL,
	[SundryReceivableCodeId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsPenalty] [bit] NOT NULL,
	[IsForSuggestedPaydownAmount] [bit] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanPaydownSundries] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydown_LoanPaydownSundries]
GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSundry_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydownSundry_BillTo]
GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSundry_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydownSundry_Location]
GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSundry_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydownSundry_RemitTo]
GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSundry_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydownSundry_Sundry]
GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSundry_SundryPayableCode] FOREIGN KEY([SundryPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydownSundry_SundryPayableCode]
GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSundry_SundryReceivableCode] FOREIGN KEY([SundryReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydownSundry_SundryReceivableCode]
GO
ALTER TABLE [dbo].[LoanPaydownSundries]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSundry_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSundries] CHECK CONSTRAINT [ELoanPaydownSundry_Vendor]
GO
