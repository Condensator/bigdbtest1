CREATE TYPE [dbo].[PartyInfoType] AS TABLE(
	[PartyId] [bigint] NULL,
	[FourDigitUniqueIdentificationNumber] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL
)
GO
