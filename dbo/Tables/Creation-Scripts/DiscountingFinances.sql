SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingFinances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SharedPercentage] [decimal](5, 2) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalPaymentSold_Amount] [decimal](24, 2) NULL,
	[TotalPaymentSold_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CalculateRate] [bit] NOT NULL,
	[DiscountRate] [decimal](14, 9) NULL,
	[DiscountingProceedsAmount_Amount] [decimal](16, 2) NULL,
	[DiscountingProceedsAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SuggestedDiscountingProceedsAmount_Amount] [decimal](16, 2) NULL,
	[SuggestedDiscountingProceedsAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsCurrent] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[Tied] [bit] NOT NULL,
	[EffectiveDate] [date] NULL,
	[Recourse] [bit] NOT NULL,
	[BookingStatus] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[BookedResidual_Amount] [decimal](16, 2) NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ApprovalStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[ModificationType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPricingParametersChanged] [bit] NOT NULL,
	[IsPricingPerformed] [bit] NOT NULL,
	[DiscountingId] [bigint] NOT NULL,
	[DiscountingGLTemplateId] [bigint] NULL,
	[ExpenseRecognitionGLTemplateId] [bigint] NULL,
	[DiscountingProceedsReceivableCodeId] [bigint] NULL,
	[DiscountingProceedsBillToId] [bigint] NULL,
	[DiscountingProceedsRemitToId] [bigint] NULL,
	[DiscountingInterestPayableCodeId] [bigint] NULL,
	[DiscountingPrincipalPayableCodeId] [bigint] NULL,
	[DiscountingPayablesRemitToId] [bigint] NULL,
	[CostCenterId] [bigint] NOT NULL,
	[LineOfBusinessId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[InstrumentTypeId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[FunderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PricingDayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PricingCompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[CommencementDate] [date] NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[CompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[DueDay] [int] NOT NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PaymentNumberOfDays] [int] NOT NULL,
	[Term] [decimal](10, 6) NULL,
	[Advance] [bit] NOT NULL,
	[IsRegularPaymentStream] [bit] NOT NULL,
	[RegularPaymentAmount_Amount] [decimal](16, 2) NULL,
	[RegularPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[MaturityDate] [date] NULL,
	[FrequencyStartDate] [date] NULL,
	[NumberOfPayments] [int] NULL,
	[Yield] [decimal](14, 9) NULL,
	[IsRepaymentScheduleGenerated] [bit] NOT NULL,
	[IsRepaymentScheduleParametersChanged] [bit] NOT NULL,
	[IsRepaymentPricingPerformed] [bit] NOT NULL,
	[IsRepaymentPricingParametersChanged] [bit] NOT NULL,
	[IsOnHold] [bit] NOT NULL,
	[AdditionalPaymentSold_Amount] [decimal](16, 2) NULL,
	[AdditionalPaymentSold_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AdditionalBookedResidual_Amount] [decimal](16, 2) NULL,
	[AdditionalBookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PaymentAllocation] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[APTemplateId] [bigint] NULL,
	[InterestWithholdingTaxRate] [decimal](5, 2) NULL,
	[PrincipalWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_APTemplate] FOREIGN KEY([APTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_APTemplate]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_Branch]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_CostCenter]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_Discounting]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingGLTemplate] FOREIGN KEY([DiscountingGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_DiscountingGLTemplate]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingInterestPayableCode] FOREIGN KEY([DiscountingInterestPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_DiscountingInterestPayableCode]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingPayablesRemitTo] FOREIGN KEY([DiscountingPayablesRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_DiscountingPayablesRemitTo]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingPrincipalPayableCode] FOREIGN KEY([DiscountingPrincipalPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_DiscountingPrincipalPayableCode]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingProceedsBillTo] FOREIGN KEY([DiscountingProceedsBillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_DiscountingProceedsBillTo]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingProceedsReceivableCode] FOREIGN KEY([DiscountingProceedsReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_DiscountingProceedsReceivableCode]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingProceedsRemitTo] FOREIGN KEY([DiscountingProceedsRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_DiscountingProceedsRemitTo]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_ExpenseRecognitionGLTemplate] FOREIGN KEY([ExpenseRecognitionGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_ExpenseRecognitionGLTemplate]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_Funder] FOREIGN KEY([FunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_Funder]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_InstrumentType]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_LegalEntity]
GO
ALTER TABLE [dbo].[DiscountingFinances]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_LineOfBusiness] FOREIGN KEY([LineOfBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[DiscountingFinances] CHECK CONSTRAINT [EDiscountingFinance_LineOfBusiness]
GO
