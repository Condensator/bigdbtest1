SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcceleratedBalanceQuotes](
	[Id] [bigint] NOT NULL,
	[QuoteDate] [date] NULL,
	[QuoteGoodThrough] [date] NULL,
	[Comment1] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PerDiem_Amount] [decimal](16, 2) NULL,
	[PerDiem_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LateCharges_Amount] [decimal](16, 2) NULL,
	[LateCharges_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NSFOrProcessFeesOrOther_Amount] [decimal](16, 2) NULL,
	[NSFOrProcessFeesOrOther_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InsuranceFees_Amount] [decimal](16, 2) NULL,
	[InsuranceFees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ChaseOrInspectionFees_Amount] [decimal](16, 2) NULL,
	[ChaseOrInspectionFees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentRelatedExpenses_Amount] [decimal](16, 2) NULL,
	[EquipmentRelatedExpenses_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LegalFeesOrCost_Amount] [decimal](16, 2) NULL,
	[LegalFeesOrCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DocumentationFees_Amount] [decimal](16, 2) NULL,
	[DocumentationFees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Waivers_Amount] [decimal](16, 2) NULL,
	[Waivers_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Credits_Amount] [decimal](16, 2) NULL,
	[Credits_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DirectAllInquiriesTo] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[TotalDue_Amount] [decimal](16, 2) NULL,
	[TotalDue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Comment2] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Comment3] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[BuyerAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PayableTo] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ToId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AcceleratedBalanceQuotes]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceQuote] FOREIGN KEY([Id])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AcceleratedBalanceQuotes] CHECK CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceQuote]
GO
ALTER TABLE [dbo].[AcceleratedBalanceQuotes]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceQuote_To] FOREIGN KEY([ToId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceQuotes] CHECK CONSTRAINT [EAcceleratedBalanceQuote_To]
GO
