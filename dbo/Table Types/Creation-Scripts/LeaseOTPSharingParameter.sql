CREATE TYPE [dbo].[LeaseOTPSharingParameter] AS TABLE(
	[PaymentNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OTPSharingPercentage] [decimal](18, 8) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[LeaseFinanceDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
