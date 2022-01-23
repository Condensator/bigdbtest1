CREATE TYPE [dbo].[CompensationAdjustment] AS TABLE(
	[PaymentType] [nvarchar](29) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SwapOrSyndicatedFeeIncome_Amount] [decimal](16, 2) NULL,
	[SwapOrSyndicatedFeeIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RelatedBusinessName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentDate] [date] NOT NULL,
	[LogDate] [date] NOT NULL,
	[AdditionalComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[YTDVolumeAdjustments_Amount] [decimal](16, 2) NULL,
	[YTDVolumeAdjustments_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyType] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO