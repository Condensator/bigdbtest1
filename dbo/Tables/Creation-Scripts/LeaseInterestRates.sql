SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseInterestRates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsPricingInterestRate] [bit] NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InterestRateDetailId] [bigint] NOT NULL,
	[ParentLeaseInterestRateId] [bigint] NULL,
	[LeaseFinanceDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseInterestRates]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_LeaseInterestRates] FOREIGN KEY([LeaseFinanceDetailId])
REFERENCES [dbo].[LeaseFinanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseInterestRates] CHECK CONSTRAINT [ELeaseFinanceDetail_LeaseInterestRates]
GO
ALTER TABLE [dbo].[LeaseInterestRates]  WITH CHECK ADD  CONSTRAINT [ELeaseInterestRate_InterestRateDetail] FOREIGN KEY([InterestRateDetailId])
REFERENCES [dbo].[InterestRateDetails] ([Id])
GO
ALTER TABLE [dbo].[LeaseInterestRates] CHECK CONSTRAINT [ELeaseInterestRate_InterestRateDetail]
GO
ALTER TABLE [dbo].[LeaseInterestRates]  WITH CHECK ADD  CONSTRAINT [ELeaseInterestRate_ParentLeaseInterestRate] FOREIGN KEY([ParentLeaseInterestRateId])
REFERENCES [dbo].[LeaseInterestRates] ([Id])
GO
ALTER TABLE [dbo].[LeaseInterestRates] CHECK CONSTRAINT [ELeaseInterestRate_ParentLeaseInterestRate]
GO
