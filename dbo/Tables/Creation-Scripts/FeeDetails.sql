SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FeeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[FeePercent] [decimal](5, 2) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FloorAmount_Amount] [decimal](16, 2) NOT NULL,
	[FloorAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CeilingAmount_Amount] [decimal](16, 2) NOT NULL,
	[CeilingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AccountingTreatment] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SundryOrBlendedItem] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[Occurrence] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[FeeType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[FeeBasis] [nvarchar](26) COLLATE Latin1_General_CI_AS NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[FeeTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[GracePeriodInMonths] [int] NULL,
	[FeeAssessmentLevel] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[FeeCategoryId] [bigint] NOT NULL,
	[UsageCondition] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsImport] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FeeDetails]  WITH CHECK ADD  CONSTRAINT [EFeeDetail_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[FeeDetails] CHECK CONSTRAINT [EFeeDetail_BlendedItemCode]
GO
ALTER TABLE [dbo].[FeeDetails]  WITH CHECK ADD  CONSTRAINT [EFeeDetail_FeeCategory] FOREIGN KEY([FeeCategoryId])
REFERENCES [dbo].[FeeTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[FeeDetails] CHECK CONSTRAINT [EFeeDetail_FeeCategory]
GO
ALTER TABLE [dbo].[FeeDetails]  WITH CHECK ADD  CONSTRAINT [EFeeDetail_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[FeeDetails] CHECK CONSTRAINT [EFeeDetail_PayableCode]
GO
ALTER TABLE [dbo].[FeeDetails]  WITH CHECK ADD  CONSTRAINT [EFeeDetail_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[FeeDetails] CHECK CONSTRAINT [EFeeDetail_ReceivableCode]
GO
ALTER TABLE [dbo].[FeeDetails]  WITH CHECK ADD  CONSTRAINT [EFeeTemplate_FeeDetails] FOREIGN KEY([FeeTemplateId])
REFERENCES [dbo].[FeeTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FeeDetails] CHECK CONSTRAINT [EFeeTemplate_FeeDetails]
GO
