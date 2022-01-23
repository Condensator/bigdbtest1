SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingSundries](
	[Id] [bigint] NOT NULL,
	[PaymentScheduleId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingSundry_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[DiscountingSundries] CHECK CONSTRAINT [EDiscountingSundry_Contract]
GO
ALTER TABLE [dbo].[DiscountingSundries]  WITH CHECK ADD  CONSTRAINT [EDiscountingSundry_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[DiscountingSundries] CHECK CONSTRAINT [EDiscountingSundry_Discounting]
GO
ALTER TABLE [dbo].[DiscountingSundries]  WITH CHECK ADD  CONSTRAINT [ESundry_DiscountingSundry] FOREIGN KEY([Id])
REFERENCES [dbo].[Sundries] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingSundries] CHECK CONSTRAINT [ESundry_DiscountingSundry]
GO
