SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgencyLegalPlacementContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FundsReceived_Amount] [decimal](16, 2) NULL,
	[FundsReceived_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[AcceleratedBalanceDetailId] [bigint] NULL,
	[AgencyLegalPlacementId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AgencyLegalPlacementContracts]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacement_AgencyLegalPlacementContracts] FOREIGN KEY([AgencyLegalPlacementId])
REFERENCES [dbo].[AgencyLegalPlacements] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AgencyLegalPlacementContracts] CHECK CONSTRAINT [EAgencyLegalPlacement_AgencyLegalPlacementContracts]
GO
ALTER TABLE [dbo].[AgencyLegalPlacementContracts]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacementContract_AcceleratedBalanceDetail] FOREIGN KEY([AcceleratedBalanceDetailId])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
GO
ALTER TABLE [dbo].[AgencyLegalPlacementContracts] CHECK CONSTRAINT [EAgencyLegalPlacementContract_AcceleratedBalanceDetail]
GO
ALTER TABLE [dbo].[AgencyLegalPlacementContracts]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacementContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[AgencyLegalPlacementContracts] CHECK CONSTRAINT [EAgencyLegalPlacementContract_Contract]
GO
