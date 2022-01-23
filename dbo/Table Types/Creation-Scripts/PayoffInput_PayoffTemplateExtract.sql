CREATE TYPE [dbo].[PayoffInput_PayoffTemplateExtract] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[PayoffTemplateId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[TerminationTypeId] [bigint] NOT NULL,
	[PaymentScheduleNumber] [int] NOT NULL,
	[PayoffEffectiveDate] [date] NOT NULL,
	[IsAdvanceLease] [bit] NOT NULL,
	[TradeupFeeCalculationMethod] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[TradeupFeeId] [bigint] NULL,
	[LeaseNumberOfPayments] [bigint] NOT NULL,
	[PayoffAtOTP] [bit] NOT NULL
)
GO
