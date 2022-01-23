SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFinanceAdditionalCharges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AdditionalChargeId] [bigint] NOT NULL,
	[SundryId] [bigint] NULL,
	[RecurringSundryId] [bigint] NULL,
	[LeaseAssetId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsAssetBased] [bit] NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[GracePeriodinMonths] [int] NULL,
	[DueDate] [date] NULL,
	[IsRentalBased] [bit] NULL,
	[IsIncludeinAPR] [bit] NULL,
	[IsVatable] [bit] NULL,
	[ReceivableAmountInclVAT_Amount] [decimal](16, 2) NULL,
	[ReceivableAmountInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PayableAmount_Amount] [decimal](16, 2) NULL,
	[PayableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[VendorId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[AdditionalChargeLeaseAssetId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseFinanceAdditionalCharges] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinance_LeaseFinanceAdditionalCharges]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_AdditionalCharge] FOREIGN KEY([AdditionalChargeId])
REFERENCES [dbo].[AdditionalCharges] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_AdditionalCharge]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_AdditionalChargeLeaseAsset] FOREIGN KEY([AdditionalChargeLeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_AdditionalChargeLeaseAsset]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_LeaseAsset] FOREIGN KEY([LeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_LeaseAsset]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_PayableCode]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_RecurringSundry] FOREIGN KEY([RecurringSundryId])
REFERENCES [dbo].[SundryRecurrings] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_RecurringSundry]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_RemitTo]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_Sundry]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalCharges] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_Vendor]
GO
