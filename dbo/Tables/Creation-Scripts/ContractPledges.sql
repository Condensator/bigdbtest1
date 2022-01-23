SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractPledges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsExpired] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Bank] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BIC] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountBGN] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountEUR] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PledgeReceivables] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PledgeVehicles] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PledgeInFavorOf] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CascoCoverage] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[InterestBaseId] [bigint] NULL,
	[LoanNumberId] [bigint] NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractPledges]  WITH CHECK ADD  CONSTRAINT [EContract_ContractPledges] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractPledges] CHECK CONSTRAINT [EContract_ContractPledges]
GO
ALTER TABLE [dbo].[ContractPledges]  WITH CHECK ADD  CONSTRAINT [EContractPledge_InterestBase] FOREIGN KEY([InterestBaseId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[ContractPledges] CHECK CONSTRAINT [EContractPledge_InterestBase]
GO
ALTER TABLE [dbo].[ContractPledges]  WITH CHECK ADD  CONSTRAINT [EContractPledge_LoanNumber] FOREIGN KEY([LoanNumberId])
REFERENCES [dbo].[ContractPledgeConfigs] ([Id])
GO
ALTER TABLE [dbo].[ContractPledges] CHECK CONSTRAINT [EContractPledge_LoanNumber]
GO
