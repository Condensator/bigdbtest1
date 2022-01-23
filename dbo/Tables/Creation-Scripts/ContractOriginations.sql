SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractOriginations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OriginationFee_Amount] [decimal](16, 2) NOT NULL,
	[OriginationFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginationScrapeFactor] [decimal](8, 4) NOT NULL,
	[IsOriginationGeneratePayable] [bit] NOT NULL,
	[ManagementSegment] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OriginationSourceTypeId] [bigint] NULL,
	[OriginationSourceId] [bigint] NULL,
	[OriginationSourceUserId] [bigint] NULL,
	[AcquiredPortfolioId] [bigint] NULL,
	[OriginationFeeBlendedItemCodeId] [bigint] NULL,
	[OriginatorPayableRemitToId] [bigint] NULL,
	[ScrapePayableCodeId] [bigint] NULL,
	[OriginatingLineofBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ProgramVendorOriginationSourceId] [bigint] NULL,
	[DocFeeAmount_Amount] [decimal](16, 2) NULL,
	[DocFeeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DocFeeReceivableCodeId] [bigint] NULL,
	[ProgramId] [bigint] NULL,
	[ScrapeWithholdingTaxRate] [decimal](5, 2) NULL,
	[CommissionType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[CommissionValueExcludingVAT_Amount] [decimal](16, 2) NOT NULL,
	[CommissionValueExcludingVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginationChannelId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_AcquiredPortfolio] FOREIGN KEY([AcquiredPortfolioId])
REFERENCES [dbo].[AcquiredPortfolios] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_AcquiredPortfolio]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_DocFeeReceivableCode] FOREIGN KEY([DocFeeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_DocFeeReceivableCode]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_OriginatingLineofBusiness] FOREIGN KEY([OriginatingLineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_OriginatingLineofBusiness]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_OriginationChannel] FOREIGN KEY([OriginationChannelId])
REFERENCES [dbo].[OriginationSourceTypes] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_OriginationChannel]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_OriginationFeeBlendedItemCode] FOREIGN KEY([OriginationFeeBlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_OriginationFeeBlendedItemCode]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_OriginationSource] FOREIGN KEY([OriginationSourceId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_OriginationSource]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_OriginationSourceType] FOREIGN KEY([OriginationSourceTypeId])
REFERENCES [dbo].[OriginationSourceTypes] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_OriginationSourceType]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_OriginationSourceUser] FOREIGN KEY([OriginationSourceUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_OriginationSourceUser]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_OriginatorPayableRemitTo] FOREIGN KEY([OriginatorPayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_OriginatorPayableRemitTo]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_Program] FOREIGN KEY([ProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_Program]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_ProgramVendorOriginationSource] FOREIGN KEY([ProgramVendorOriginationSourceId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_ProgramVendorOriginationSource]
GO
ALTER TABLE [dbo].[ContractOriginations]  WITH CHECK ADD  CONSTRAINT [EContractOrigination_ScrapePayableCode] FOREIGN KEY([ScrapePayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[ContractOriginations] CHECK CONSTRAINT [EContractOrigination_ScrapePayableCode]
GO
