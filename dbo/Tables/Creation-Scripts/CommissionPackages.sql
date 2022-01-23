SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommissionPackages](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PackageId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[PlanBasisPayoutId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommissionPackages]  WITH CHECK ADD  CONSTRAINT [ECommissionPackage_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[CommissionPackages] CHECK CONSTRAINT [ECommissionPackage_Contract]
GO
ALTER TABLE [dbo].[CommissionPackages]  WITH CHECK ADD  CONSTRAINT [ECommissionPackage_PlanBasisPayout] FOREIGN KEY([PlanBasisPayoutId])
REFERENCES [dbo].[PlanBasesPayouts] ([Id])
GO
ALTER TABLE [dbo].[CommissionPackages] CHECK CONSTRAINT [ECommissionPackage_PlanBasisPayout]
GO
ALTER TABLE [dbo].[CommissionPackages]  WITH CHECK ADD  CONSTRAINT [ECommissionPackage_SalesOfficer] FOREIGN KEY([SalesOfficerId])
REFERENCES [dbo].[SalesOfficers] ([Id])
GO
ALTER TABLE [dbo].[CommissionPackages] CHECK CONSTRAINT [ECommissionPackage_SalesOfficer]
GO
