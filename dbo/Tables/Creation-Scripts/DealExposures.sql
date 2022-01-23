SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DealExposures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[ExposureDate] [date] NOT NULL,
	[ExposureType] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[RelationshipPercentage] [decimal](5, 2) NOT NULL,
	[CommencedDealRNI_Amount] [decimal](24, 2) NOT NULL,
	[CommencedDealRNI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CommencedDealExposure_Amount] [decimal](24, 2) NOT NULL,
	[CommencedDealExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPLeaseRNI_Amount] [decimal](24, 2) NOT NULL,
	[OTPLeaseRNI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPLeaseExposure_Amount] [decimal](24, 2) NOT NULL,
	[OTPLeaseExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UncommencedDealRNI_Amount] [decimal](24, 2) NOT NULL,
	[UncommencedDealRNI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UncommencedDealExposure_Amount] [decimal](24, 2) NOT NULL,
	[UncommencedDealExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LOCBalanceRevolving_Amount] [decimal](24, 2) NOT NULL,
	[LOCBalanceRevolving_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LOCBalanceNonRevolving_Amount] [decimal](24, 2) NOT NULL,
	[LOCBalanceNonRevolving_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LOCBalanceExposure_Amount] [decimal](24, 2) NOT NULL,
	[LOCBalanceExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalExposure_Amount] [decimal](24, 2) NOT NULL,
	[TotalExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RNIId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[ExposureCustomerId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[OriginatingVendorId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DealExposures]  WITH CHECK ADD  CONSTRAINT [EDealExposure_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[DealExposures] CHECK CONSTRAINT [EDealExposure_Customer]
GO
ALTER TABLE [dbo].[DealExposures]  WITH CHECK ADD  CONSTRAINT [EDealExposure_ExposureCustomer] FOREIGN KEY([ExposureCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[DealExposures] CHECK CONSTRAINT [EDealExposure_ExposureCustomer]
GO
ALTER TABLE [dbo].[DealExposures]  WITH CHECK ADD  CONSTRAINT [EDealExposure_OriginatingVendor] FOREIGN KEY([OriginatingVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[DealExposures] CHECK CONSTRAINT [EDealExposure_OriginatingVendor]
GO
ALTER TABLE [dbo].[DealExposures]  WITH CHECK ADD  CONSTRAINT [EDealExposure_RNI] FOREIGN KEY([RNIId])
REFERENCES [dbo].[RemainingNetInvestments] ([Id])
GO
ALTER TABLE [dbo].[DealExposures] CHECK CONSTRAINT [EDealExposure_RNI]
GO
