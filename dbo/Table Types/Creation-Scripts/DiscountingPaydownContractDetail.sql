CREATE TYPE [dbo].[DiscountingPaydownContractDetail] AS TABLE(
	[Release] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalPaymentSold_Amount] [decimal](16, 2) NULL,
	[TotalPaymentSold_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BookedResidual_Amount] [decimal](16, 2) NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[AccountResidualBalanceToGainLoss] [bit] NOT NULL,
	[ResidualGainLoss_Amount] [decimal](16, 2) NOT NULL,
	[ResidualGainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ResidualPayable_Amount] [decimal](16, 2) NOT NULL,
	[ResidualPayable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DiscountingContractId] [bigint] NULL,
	[DiscountingPaydownId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
