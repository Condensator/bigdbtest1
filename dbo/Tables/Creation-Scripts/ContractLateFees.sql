SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractLateFees](
	[Id] [bigint] NOT NULL,
	[InvoiceGraceDays] [int] NULL,
	[LateFeeFloorAmount_Amount] [decimal](16, 2) NOT NULL,
	[LateFeeFloorAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LateFeeCeilingAmount_Amount] [decimal](16, 2) NOT NULL,
	[LateFeeCeilingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WaiveIfLateFeeBelow_Amount] [decimal](16, 2) NULL,
	[WaiveIfLateFeeBelow_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[WaiveIfInvoiceAmountBelow_Amount] [decimal](16, 2) NULL,
	[WaiveIfInvoiceAmountBelow_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceGraceDaysAtInception] [int] NULL,
	[Spread] [decimal](5, 2) NULL,
	[InterestFloorPercentage] [decimal](5, 2) NULL,
	[InterestCeilingPercentage] [decimal](5, 2) NULL,
	[HolidayMethod] [nvarchar](22) COLLATE Latin1_General_CI_AS NULL,
	[IsMoveAcrossMonth] [bit] NOT NULL,
	[IsIndexPercentage] [bit] NOT NULL,
	[PercentageBasis] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Percentage] [decimal](8, 4) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LateFeeTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractLateFees]  WITH CHECK ADD  CONSTRAINT [EContract_ContractLateFee] FOREIGN KEY([Id])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractLateFees] CHECK CONSTRAINT [EContract_ContractLateFee]
GO
ALTER TABLE [dbo].[ContractLateFees]  WITH CHECK ADD  CONSTRAINT [EContractLateFee_LateFeeTemplate] FOREIGN KEY([LateFeeTemplateId])
REFERENCES [dbo].[LateFeeTemplates] ([Id])
GO
ALTER TABLE [dbo].[ContractLateFees] CHECK CONSTRAINT [EContractLateFee_LateFeeTemplate]
GO
