SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ValuationAllowances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[OriginalBookValue_Amount] [decimal](16, 2) NULL,
	[OriginalBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Allowance_Amount] [decimal](16, 2) NULL,
	[Allowance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ValuationReserveBalance_Amount] [decimal](16, 2) NULL,
	[ValuationReserveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NetInvestmentWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetInvestmentWithReserve_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithReserve_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WrittenDownNBV_Amount] [decimal](16, 2) NOT NULL,
	[WrittenDownNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[HFIStatusHistoriesId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[ContractHoldingStatusHistoryId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ValuationAllowances]  WITH CHECK ADD  CONSTRAINT [EValuationAllowance_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[ValuationAllowances] CHECK CONSTRAINT [EValuationAllowance_BusinessUnit]
GO
ALTER TABLE [dbo].[ValuationAllowances]  WITH CHECK ADD  CONSTRAINT [EValuationAllowance_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ValuationAllowances] CHECK CONSTRAINT [EValuationAllowance_Contract]
GO
ALTER TABLE [dbo].[ValuationAllowances]  WITH CHECK ADD  CONSTRAINT [EValuationAllowance_ContractHoldingStatusHistory] FOREIGN KEY([ContractHoldingStatusHistoryId])
REFERENCES [dbo].[ContractHoldingStatusHistories] ([Id])
GO
ALTER TABLE [dbo].[ValuationAllowances] CHECK CONSTRAINT [EValuationAllowance_ContractHoldingStatusHistory]
GO
ALTER TABLE [dbo].[ValuationAllowances]  WITH CHECK ADD  CONSTRAINT [EValuationAllowance_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ValuationAllowances] CHECK CONSTRAINT [EValuationAllowance_GLTemplate]
GO
ALTER TABLE [dbo].[ValuationAllowances]  WITH CHECK ADD  CONSTRAINT [EValuationAllowance_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[ValuationAllowances] CHECK CONSTRAINT [EValuationAllowance_JobStepInstance]
GO
