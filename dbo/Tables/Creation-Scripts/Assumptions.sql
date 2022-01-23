SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Assumptions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssumptionReason] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NULL,
	[Status] [nvarchar](25) COLLATE Latin1_General_CI_AS NULL,
	[AssumptionDate] [date] NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCloneAssetLocation] [bit] NOT NULL,
	[IsAccountingApproved] [bit] NOT NULL,
	[IsFundingApproved] [bit] NOT NULL,
	[IsAMReviewRequired] [bit] NOT NULL,
	[IsAMReviewCompleted] [bit] NOT NULL,
	[SortOrder] [int] NOT NULL,
	[IsSalesTaxExemption] [bit] NOT NULL,
	[IsSalesTaxReviewRequired] [bit] NOT NULL,
	[IsSalesTaxReviewCompleted] [bit] NOT NULL,
	[IsSalesLeaseBackReviewCompleted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[NewCustomerId] [bigint] NULL,
	[NewLocationId] [bigint] NULL,
	[NewBillToId] [bigint] NULL,
	[LineOfCreditId] [bigint] NULL,
	[OriginalCustomerId] [bigint] NOT NULL,
	[LeasePaymentId] [bigint] NULL,
	[LoanPaymentId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsBillInAlternateCurrency] [bit] NOT NULL,
	[OldSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NewSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsVATAssessed] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_Contract]
GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_LeasePayment] FOREIGN KEY([LeasePaymentId])
REFERENCES [dbo].[LeasePaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_LeasePayment]
GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_LineOfCredit] FOREIGN KEY([LineOfCreditId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_LineOfCredit]
GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_LoanPayment] FOREIGN KEY([LoanPaymentId])
REFERENCES [dbo].[LoanPaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_LoanPayment]
GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_NewBillTo] FOREIGN KEY([NewBillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_NewBillTo]
GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_NewCustomer] FOREIGN KEY([NewCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_NewCustomer]
GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_NewLocation] FOREIGN KEY([NewLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_NewLocation]
GO
ALTER TABLE [dbo].[Assumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_OriginalCustomer] FOREIGN KEY([OriginalCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Assumptions] CHECK CONSTRAINT [EAssumption_OriginalCustomer]
GO
