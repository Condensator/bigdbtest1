SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplicationAdditionalCharges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AdditionalChargeId] [bigint] NOT NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IncludeInAPR] [bit] NULL,
	[IsVAT] [bit] NULL,
	[AmountInclVAT_Amount] [decimal](16, 2) NULL,
	[AmountInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SundryOrBlendedItem] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[FeeId] [bigint] NULL,
	[CreditApplicationEquipmentDetailId] [bigint] NULL,
	[AmountExclVAT_Amount] [decimal](16, 2) NULL,
	[AmountExclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FeeDetailId] [bigint] NULL,
	[IsPopulatedFromCreditApplicationEquipment] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_CreditApplicationAdditionalCharges] FOREIGN KEY([CreditApplicationId])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplication_CreditApplicationAdditionalCharges]
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAdditionalCharge_AdditionalCharge] FOREIGN KEY([AdditionalChargeId])
REFERENCES [dbo].[AdditionalCharges] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplicationAdditionalCharge_AdditionalCharge]
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAdditionalCharge_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplicationAdditionalCharge_BlendedItemCode]
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAdditionalCharge_CreditApplicationEquipmentDetail] FOREIGN KEY([CreditApplicationEquipmentDetailId])
REFERENCES [dbo].[CreditApplicationEquipmentDetails] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplicationAdditionalCharge_CreditApplicationEquipmentDetail]
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAdditionalCharge_Fee] FOREIGN KEY([FeeId])
REFERENCES [dbo].[FeeTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplicationAdditionalCharge_Fee]
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAdditionalCharge_FeeDetail] FOREIGN KEY([FeeDetailId])
REFERENCES [dbo].[FeeDetails] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplicationAdditionalCharge_FeeDetail]
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAdditionalCharge_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplicationAdditionalCharge_PayableCode]
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAdditionalCharge_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAdditionalCharges] CHECK CONSTRAINT [ECreditApplicationAdditionalCharge_ReceivableCode]
GO
