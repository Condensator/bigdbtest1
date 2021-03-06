CREATE TYPE [dbo].[Judgement] AS TABLE(
	[JudgementNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[JudgementDate] [date] NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Fees_Amount] [decimal](16, 2) NULL,
	[Fees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalAmount_Amount] [decimal](16, 2) NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsDomesticated] [bit] NOT NULL,
	[InterestRate] [decimal](5, 2) NULL,
	[InterestGrantedFromDate] [date] NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsAmended] [bit] NOT NULL,
	[AmendedDate] [date] NULL,
	[AmendedAmount_Amount] [decimal](16, 2) NULL,
	[AmendedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsAmendedAmountSettled] [bit] NOT NULL,
	[ExpirationDate] [date] NULL,
	[RenewalDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[CourtId] [bigint] NULL,
	[CourtFilingId] [bigint] NULL,
	[CourtFilingActionId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
