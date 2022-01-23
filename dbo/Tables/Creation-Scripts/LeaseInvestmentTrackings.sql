SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseInvestmentTrackings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Investment] [decimal](16, 2) NOT NULL,
	[InvestmentDate] [date] NOT NULL,
	[IsLessorOwned] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseInvestmentTrackings]  WITH CHECK ADD  CONSTRAINT [ELeaseInvestmentTracking_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LeaseInvestmentTrackings] CHECK CONSTRAINT [ELeaseInvestmentTracking_Contract]
GO
ALTER TABLE [dbo].[LeaseInvestmentTrackings]  WITH CHECK ADD  CONSTRAINT [ELeaseInvestmentTracking_LeaseFinance] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[LeaseInvestmentTrackings] CHECK CONSTRAINT [ELeaseInvestmentTracking_LeaseFinance]
GO
