CREATE TYPE [dbo].[ConsumerCreditBureauLookup] AS TABLE(
	[PostalCodeFrom] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PostalCodeTo] [int] NOT NULL,
	[CreditBureau] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[AlternateBureau] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
