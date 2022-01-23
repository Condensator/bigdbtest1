SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingPaydownSundries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DueDate] [date] NOT NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[BillToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[RemitToId] [bigint] NOT NULL,
	[SundryId] [bigint] NULL,
	[SundryPayableCodeId] [bigint] NULL,
	[SundryReceivableCodeId] [bigint] NULL,
	[DiscountingPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydown_DiscountingPaydownSundries] FOREIGN KEY([DiscountingPaydownId])
REFERENCES [dbo].[DiscountingPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydown_DiscountingPaydownSundries]
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownSundry_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydownSundry_BillTo]
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownSundry_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydownSundry_Location]
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownSundry_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydownSundry_Party]
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownSundry_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydownSundry_RemitTo]
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownSundry_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydownSundry_Sundry]
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownSundry_SundryPayableCode] FOREIGN KEY([SundryPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydownSundry_SundryPayableCode]
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownSundry_SundryReceivableCode] FOREIGN KEY([SundryReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownSundries] CHECK CONSTRAINT [EDiscountingPaydownSundry_SundryReceivableCode]
GO
