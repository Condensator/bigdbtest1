SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SyndicatedDealExposures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityId] [bigint] NOT NULL,
	[SyndicatedLOCBalanceExposureRevolving_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedLOCBalanceExposureRevolving_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedLOCBalanceExposureNonRevolving_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedLOCBalanceExposureNonRevolving_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedContractExposure_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedContractExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalSyndicatedExposures_Amount] [decimal](24, 2) NOT NULL,
	[TotalSyndicatedExposures_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ExposureDate] [date] NULL,
	[OriginationVendorId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RNIId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SyndicatedDealExposures]  WITH CHECK ADD  CONSTRAINT [ESyndicatedDealExposure_OriginationVendor] FOREIGN KEY([OriginationVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[SyndicatedDealExposures] CHECK CONSTRAINT [ESyndicatedDealExposure_OriginationVendor]
GO
ALTER TABLE [dbo].[SyndicatedDealExposures]  WITH CHECK ADD  CONSTRAINT [ESyndicatedDealExposure_RNI] FOREIGN KEY([RNIId])
REFERENCES [dbo].[RemainingNetInvestments] ([Id])
GO
ALTER TABLE [dbo].[SyndicatedDealExposures] CHECK CONSTRAINT [ESyndicatedDealExposure_RNI]
GO
