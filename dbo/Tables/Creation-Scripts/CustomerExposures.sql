SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerExposures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExposureDate] [date] NOT NULL,
	[PrimaryCustomerCommencedLoanExposure_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomerCommencedLoanExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomerCommencedLeaseExposure_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomerCommencedLeaseExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomerOTPLeaseExposure_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomerOTPLeaseExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomerUncommencedDealExposure_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomerUncommencedDealExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomerLOCBalanceExposure_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomerLOCBalanceExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomerUnallocatedSecurityDepositOSAR_Amount] [decimal](24, 2) NULL,
	[PrimaryCustomerUnallocatedSecurityDepositOSAR_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PrimaryCustomerUnallocatedSecurityDeposit_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomerUnallocatedSecurityDeposit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryCustomerUnallocatedCash_Amount] [decimal](24, 2) NOT NULL,
	[PrimaryCustomerUnallocatedCash_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DirectRelationshipCommencedLoanExposure_Amount] [decimal](24, 2) NOT NULL,
	[DirectRelationshipCommencedLoanExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DirectRelationshipCommencedLeaseExposure_Amount] [decimal](24, 2) NOT NULL,
	[DirectRelationshipCommencedLeaseExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DirectRelationshipOTPLeaseExposure_Amount] [decimal](24, 2) NULL,
	[DirectRelationshipOTPLeaseExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DirectRelationshipUncommencedDealExposure_Amount] [decimal](24, 2) NULL,
	[DirectRelationshipUncommencedDealExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DirectRelationshipLOCBalanceExposure_Amount] [decimal](24, 2) NOT NULL,
	[DirectRelationshipLOCBalanceExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipCommencedLoanExposure_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipCommencedLoanExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipCommencedLeaseExposure_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipCommencedLeaseExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipOTPLeaseExposure_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipOTPLeaseExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipUncommencedDealExposure_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipUncommencedDealExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipLOCBalanceExposure_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipLOCBalanceExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipUnallocatedSecurityDepositOSAR_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipUnallocatedSecurityDepositOSAR_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipUnallocatedSecurityDeposit_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipUnallocatedSecurityDeposit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IndirectRelationshipUnallocatedCash_Amount] [decimal](24, 2) NOT NULL,
	[IndirectRelationshipUnallocatedCash_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalPrimaryCustomerExposure_Amount] [decimal](24, 2) NOT NULL,
	[TotalPrimaryCustomerExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalDirectRelationshipExposure_Amount] [decimal](24, 2) NOT NULL,
	[TotalDirectRelationshipExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalIndirectRelationshipExposure_Amount] [decimal](24, 2) NOT NULL,
	[TotalIndirectRelationshipExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalCreditExposure_Amount] [decimal](24, 2) NOT NULL,
	[TotalCreditExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ExposureCustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerExposures]  WITH CHECK ADD  CONSTRAINT [ECustomerExposure_ExposureCustomer] FOREIGN KEY([ExposureCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CustomerExposures] CHECK CONSTRAINT [ECustomerExposure_ExposureCustomer]
GO
