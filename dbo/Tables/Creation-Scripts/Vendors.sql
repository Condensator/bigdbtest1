SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Vendors](
	[Id] [bigint] NOT NULL,
	[Type] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status1099] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[NextReviewDate] [date] NULL,
	[InactivationReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[RejectionReasonCode] [nvarchar](25) COLLATE Latin1_General_CI_AS NULL,
	[W8IssueDate] [date] NULL,
	[W8ExpirationDate] [date] NULL,
	[FATCA] [decimal](5, 0) NULL,
	[Percentage1441] [decimal](5, 0) NULL,
	[IsVendorProgram] [bit] NOT NULL,
	[IsVendorRecourse] [bit] NOT NULL,
	[VendorProgramType] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[MaxQuoteExpirationDays] [int] NULL,
	[LessorContactEmail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[RVIFactor] [decimal](8, 4) NULL,
	[ApprovalStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsForVendorLegalEntityAddition] [bit] NOT NULL,
	[IsForRemittance] [bit] NOT NULL,
	[IsForVendorEdit] [bit] NOT NULL,
	[LEApprovalStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Website] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxRate] [decimal](6, 3) NULL,
	[Specialities] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[MaximumResidualSharingPercentage] [decimal](5, 2) NULL,
	[MaximumResidualSharingAmount_Amount] [decimal](16, 2) NULL,
	[MaximumResidualSharingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsFlatFee] [bit] NOT NULL,
	[IsContingencyPercentage] [bit] NOT NULL,
	[IsHourly] [bit] NOT NULL,
	[FlatFeeAmount_Amount] [decimal](16, 2) NOT NULL,
	[FlatFeeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[HourlyAmount_Amount] [decimal](16, 2) NOT NULL,
	[HourlyAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContingencyPercentage] [decimal](5, 2) NOT NULL,
	[PTMSExternalId] [bigint] NULL,
	[ParalegalName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SecretaryName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[WebPage] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NULL,
	[VendorCategoryId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[FundingApprovalLeadDays] [int] NULL,
	[IsPercentageBasedDocFee] [bit] NOT NULL,
	[DocFeePercentage] [decimal](5, 2) NULL,
	[DocFeeAmount_Amount] [decimal](16, 2) NULL,
	[DocFeeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsManualCreditDecision] [bit] NOT NULL,
	[IsPITAAgreement] [bit] NOT NULL,
	[PITASignedDate] [date] NULL,
	[PSTorQSTNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RestrictPromotions] [bit] NOT NULL,
	[FirstRightOfRefusal] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[IsRetained] [bit] NOT NULL,
	[IsAMReviewRequired] [bit] NOT NULL,
	[IsNotQuotable] [bit] NOT NULL,
	[ProgramId] [bigint] NULL,
	[IsWithholdingTaxApplicable] [bit] NOT NULL,
	[IsRelatedToLessor] [bit] NOT NULL,
	[IsRoadTrafficOffice] [bit] NOT NULL,
	[IsMunicipalityRoadTax] [bit] NOT NULL,
	[BusinessTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Vendors]  WITH CHECK ADD  CONSTRAINT [EParty_Vendor] FOREIGN KEY([Id])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Vendors] CHECK CONSTRAINT [EParty_Vendor]
GO
ALTER TABLE [dbo].[Vendors]  WITH CHECK ADD  CONSTRAINT [EVendor_BusinessType] FOREIGN KEY([BusinessTypeId])
REFERENCES [dbo].[BusinessTypes] ([Id])
GO
ALTER TABLE [dbo].[Vendors] CHECK CONSTRAINT [EVendor_BusinessType]
GO
ALTER TABLE [dbo].[Vendors]  WITH CHECK ADD  CONSTRAINT [EVendor_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[Vendors] CHECK CONSTRAINT [EVendor_LineofBusiness]
GO
ALTER TABLE [dbo].[Vendors]  WITH CHECK ADD  CONSTRAINT [EVendor_Program] FOREIGN KEY([ProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[Vendors] CHECK CONSTRAINT [EVendor_Program]
GO
ALTER TABLE [dbo].[Vendors]  WITH CHECK ADD  CONSTRAINT [EVendor_VendorCategory] FOREIGN KEY([VendorCategoryId])
REFERENCES [dbo].[VendorCategoryConfigs] ([Id])
GO
ALTER TABLE [dbo].[Vendors] CHECK CONSTRAINT [EVendor_VendorCategory]
GO
