CREATE TYPE [dbo].[TiedContractPaymentDetail] AS TABLE(
	[SharedAmount_Amount] [decimal](16, 2) NOT NULL,
	[SharedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentScheduleId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[DiscountingRepaymentScheduleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
