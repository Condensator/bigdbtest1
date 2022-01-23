CREATE TYPE [dbo].[PartyTaxRegistrationDetail] AS TABLE(
	[TaxRegistrationName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxRegistrationId] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
