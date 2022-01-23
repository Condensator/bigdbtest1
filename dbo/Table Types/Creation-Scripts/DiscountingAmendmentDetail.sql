CREATE TYPE [dbo].[DiscountingAmendmentDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveDate] [date] NOT NULL,
	[DiscountingProceedsAmount_Amount] [decimal](16, 2) NULL,
	[DiscountingProceedsAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DiscountRate] [decimal](14, 9) NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
