SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptDiscountingContracts_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DiscountingId] [bigint] NOT NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[SharedPercentage] [decimal](16, 2) NULL,
	[BookedResidual] [decimal](16, 2) NULL,
	[ResidualBalance] [decimal](16, 2) NULL,
	[IncludeResidual] [bit] NOT NULL,
	[DiscountingContractId] [bigint] NULL,
	[PaymentAllocation] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[MaturityDate] [date] NULL,
	[FunderId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[Currency] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[InterestPayableCodeId] [bigint] NULL,
	[PrincipalPayableCodeId] [bigint] NULL,
	[ResidualRepaymentId] [bigint] NULL,
	[ResidualAmountUtilized] [decimal](16, 2) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
