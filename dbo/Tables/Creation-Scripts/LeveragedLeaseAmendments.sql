SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeveragedLeaseAmendments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RestructureDate] [date] NOT NULL,
	[AmortDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmortDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmortDocument_Content] [varbinary](82) NOT NULL,
	[PostDate] [date] NOT NULL,
	[LeveragedLeaseAmendmentStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[MaturityDate] [date] NULL,
	[Term] [decimal](10, 6) NOT NULL,
	[EquipmentCost_Amount] [decimal](24, 2) NULL,
	[EquipmentCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ResidualValue_Amount] [decimal](24, 2) NULL,
	[ResidualValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LongTermDebt_Amount] [decimal](24, 2) NULL,
	[LongTermDebt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EquityInvestment_Amount] [decimal](24, 2) NULL,
	[EquityInvestment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IDC_Amount] [decimal](24, 2) NULL,
	[IDC_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RentalsReceivable_Amount] [decimal](24, 2) NULL,
	[RentalsReceivable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Debt_Amount] [decimal](24, 2) NULL,
	[Debt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsFromStandalone] [bit] NOT NULL,
	[IsRestructureAtInception] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrentLeveragedLeaseId] [bigint] NULL,
	[LeveragedLeaseRestructureReasonConfigId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeveragedLeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeveragedLeaseAmendment_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeaseAmendments] CHECK CONSTRAINT [ELeveragedLeaseAmendment_Contract]
GO
ALTER TABLE [dbo].[LeveragedLeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeveragedLeaseAmendment_CurrentLeveragedLease] FOREIGN KEY([CurrentLeveragedLeaseId])
REFERENCES [dbo].[LeveragedLeases] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeaseAmendments] CHECK CONSTRAINT [ELeveragedLeaseAmendment_CurrentLeveragedLease]
GO
ALTER TABLE [dbo].[LeveragedLeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeveragedLeaseAmendment_LeveragedLeaseRestructureReasonConfig] FOREIGN KEY([LeveragedLeaseRestructureReasonConfigId])
REFERENCES [dbo].[LeveragedLeaseRestructureReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeaseAmendments] CHECK CONSTRAINT [ELeveragedLeaseAmendment_LeveragedLeaseRestructureReasonConfig]
GO
