SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractCustomerLocations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxBasisType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerLocationId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractCustomerLocations]  WITH CHECK ADD  CONSTRAINT [EContractCustomerLocation_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ContractCustomerLocations] CHECK CONSTRAINT [EContractCustomerLocation_Contract]
GO
ALTER TABLE [dbo].[ContractCustomerLocations]  WITH CHECK ADD  CONSTRAINT [EContractCustomerLocation_CustomerLocation] FOREIGN KEY([CustomerLocationId])
REFERENCES [dbo].[CustomerLocations] ([Id])
GO
ALTER TABLE [dbo].[ContractCustomerLocations] CHECK CONSTRAINT [EContractCustomerLocation_CustomerLocation]
GO
