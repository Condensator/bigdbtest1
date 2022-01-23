CREATE TYPE [dbo].[LegalReliefProofOfClaim] AS TABLE(
	[Date] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FilingDate] [date] NULL,
	[ClaimNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAmount_Amount] [decimal](16, 2) NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[Active] [bit] NOT NULL,
	[StateId] [bigint] NULL,
	[OriginalPOCId] [bigint] NULL,
	[LegalReliefId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
