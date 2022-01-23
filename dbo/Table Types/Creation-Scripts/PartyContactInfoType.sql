CREATE TYPE [dbo].[PartyContactInfoType] AS TABLE(
	[PartyContactId] [bigint] NULL,
	[FourDigitSocialSecurityNumber] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL
)
GO
