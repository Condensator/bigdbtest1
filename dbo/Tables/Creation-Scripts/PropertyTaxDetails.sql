SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReportedCost_Amount] [decimal](16, 2) NOT NULL,
	[ReportedCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssessedValue_Amount] [decimal](16, 2) NOT NULL,
	[AssessedValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdministrativeFee_Amount] [decimal](16, 2) NOT NULL,
	[AdministrativeFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[PropertyTaxId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertyTaxDetails]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_PropertyTaxDetails] FOREIGN KEY([PropertyTaxId])
REFERENCES [dbo].[PropertyTaxes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PropertyTaxDetails] CHECK CONSTRAINT [EPropertyTax_PropertyTaxDetails]
GO
ALTER TABLE [dbo].[PropertyTaxDetails]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxDetails] CHECK CONSTRAINT [EPropertyTaxDetail_Asset]
GO
ALTER TABLE [dbo].[PropertyTaxDetails]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxDetail_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxDetails] CHECK CONSTRAINT [EPropertyTaxDetail_BillTo]
GO
