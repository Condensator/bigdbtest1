SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingServicingDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Collected] [bit] NOT NULL,
	[PerfectPay] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RemitToId] [bigint] NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingServicingDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingServicingDetails] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingServicingDetails] CHECK CONSTRAINT [EDiscountingFinance_DiscountingServicingDetails]
GO
ALTER TABLE [dbo].[DiscountingServicingDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingServicingDetail_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingServicingDetails] CHECK CONSTRAINT [EDiscountingServicingDetail_RemitTo]
GO
