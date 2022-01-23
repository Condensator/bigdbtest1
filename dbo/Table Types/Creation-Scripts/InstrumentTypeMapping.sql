CREATE TYPE [dbo].[InstrumentTypeMapping] AS TABLE(
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AccountingTreatment] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsBankQualified] [int] NOT NULL,
	[IsFloatingRate] [int] NOT NULL,
	[IsRevolving] [int] NOT NULL,
	[TransactionType] [nvarchar](32) COLLATE Latin1_General_CI_AS NULL,
	[ProductType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SOPStatus] [int] NOT NULL,
	[IsRecovery] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FederalTaxExempt] [int] NOT NULL,
	[IsNonAccrual] [int] NOT NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
