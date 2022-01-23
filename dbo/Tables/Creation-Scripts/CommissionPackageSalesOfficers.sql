SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommissionPackageSalesOfficers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsPrimary] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FreeCashSplit] [decimal](10, 2) NOT NULL,
	[VolumeSplit] [decimal](10, 2) NOT NULL,
	[FeeSplit] [decimal](10, 2) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[PlanBasisPayoutId] [bigint] NOT NULL,
	[CommissionPackageId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CommissionPackageSalesOfficers]  WITH CHECK ADD  CONSTRAINT [ECommissionPackage_CommissionPackageSalesOfficers] FOREIGN KEY([CommissionPackageId])
REFERENCES [dbo].[CommissionPackages] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CommissionPackageSalesOfficers] CHECK CONSTRAINT [ECommissionPackage_CommissionPackageSalesOfficers]
GO
ALTER TABLE [dbo].[CommissionPackageSalesOfficers]  WITH CHECK ADD  CONSTRAINT [ECommissionPackageSalesOfficer_PlanBasisPayout] FOREIGN KEY([PlanBasisPayoutId])
REFERENCES [dbo].[PlanBasesPayouts] ([Id])
GO
ALTER TABLE [dbo].[CommissionPackageSalesOfficers] CHECK CONSTRAINT [ECommissionPackageSalesOfficer_PlanBasisPayout]
GO
ALTER TABLE [dbo].[CommissionPackageSalesOfficers]  WITH CHECK ADD  CONSTRAINT [ECommissionPackageSalesOfficer_SalesOfficer] FOREIGN KEY([SalesOfficerId])
REFERENCES [dbo].[SalesOfficers] ([Id])
GO
ALTER TABLE [dbo].[CommissionPackageSalesOfficers] CHECK CONSTRAINT [ECommissionPackageSalesOfficer_SalesOfficer]
GO
