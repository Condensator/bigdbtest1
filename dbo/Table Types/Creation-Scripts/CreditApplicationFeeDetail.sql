CREATE TYPE [dbo].[CreditApplicationFeeDetail] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowNumber] [int] NULL,
	[IncludeInAPR] [bit] NULL,
	[IsVAT] [bit] NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AmountInclVAT_Amount] [decimal](16, 2) NULL,
	[AmountInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FeeDetailId] [bigint] NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
