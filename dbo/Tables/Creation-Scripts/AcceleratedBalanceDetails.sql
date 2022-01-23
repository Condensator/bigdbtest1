SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcceleratedBalanceDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AsofDate] [date] NOT NULL,
	[DateofDefault] [date] NULL,
	[MaturityDate] [date] NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CurrentLegalBalance] [bit] NOT NULL,
	[BalanceType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Balance_Amount] [decimal](16, 2) NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Number] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[JudgementId] [bigint] NULL,
	[CopyFromAcceleratedBalanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UserId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_BusinessUnit]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_Contract]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_CopyFromAcceleratedBalance] FOREIGN KEY([CopyFromAcceleratedBalanceId])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_CopyFromAcceleratedBalance]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_Customer]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_JobStepInstance]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_Judgement] FOREIGN KEY([JudgementId])
REFERENCES [dbo].[Judgements] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_Judgement]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_LegalEntity]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_LineofBusiness]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetails] CHECK CONSTRAINT [EAcceleratedBalanceDetail_User]
GO
