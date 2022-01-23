SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingAmendments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AccountingDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AmendmentAtInception] [bit] NOT NULL,
	[AmendmentDate] [date] NOT NULL,
	[AmendmentType] [nvarchar](31) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[QuoteGoodThroughDate] [date] NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[QuoteStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceId] [bigint] NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[DiscountingRepaymentScheduleId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[QuoteNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdditionalLoanAmount_Amount] [decimal](16, 2) NULL,
	[AdditionalLoanAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureLoanAmount_Amount] [decimal](16, 2) NULL,
	[PreRestructureLoanAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureYield] [decimal](14, 9) NULL,
	[RestructureAmortOption] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[OriginalDiscountingFinanceId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingAmendments]  WITH CHECK ADD  CONSTRAINT [EDiscountingAmendment_DiscountingFinance] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
GO
ALTER TABLE [dbo].[DiscountingAmendments] CHECK CONSTRAINT [EDiscountingAmendment_DiscountingFinance]
GO
ALTER TABLE [dbo].[DiscountingAmendments]  WITH CHECK ADD  CONSTRAINT [EDiscountingAmendment_DiscountingRepaymentSchedule] FOREIGN KEY([DiscountingRepaymentScheduleId])
REFERENCES [dbo].[DiscountingRepaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[DiscountingAmendments] CHECK CONSTRAINT [EDiscountingAmendment_DiscountingRepaymentSchedule]
GO
ALTER TABLE [dbo].[DiscountingAmendments]  WITH CHECK ADD  CONSTRAINT [EDiscountingAmendment_OriginalDiscountingFinance] FOREIGN KEY([OriginalDiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
GO
ALTER TABLE [dbo].[DiscountingAmendments] CHECK CONSTRAINT [EDiscountingAmendment_OriginalDiscountingFinance]
GO
