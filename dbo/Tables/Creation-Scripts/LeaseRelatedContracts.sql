SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseRelatedContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsInclude] [bit] NOT NULL,
	[ReasonCode] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[ScheduleDate] [date] NULL,
	[MasterDate] [date] NULL,
	[ContractId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsParent] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseRelatedContracts]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseRelatedContracts] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseRelatedContracts] CHECK CONSTRAINT [ELeaseFinance_LeaseRelatedContracts]
GO
ALTER TABLE [dbo].[LeaseRelatedContracts]  WITH CHECK ADD  CONSTRAINT [ELeaseRelatedContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LeaseRelatedContracts] CHECK CONSTRAINT [ELeaseRelatedContract_Contract]
GO
