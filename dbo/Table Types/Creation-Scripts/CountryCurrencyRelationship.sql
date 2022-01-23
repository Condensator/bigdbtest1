CREATE TYPE [dbo].[CountryCurrencyRelationship] AS TABLE(
	[IsDefault] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MandatoryAccountNumberField] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[RoutingNumberLength] [int] NOT NULL,
	[TransitCodeLength] [int] NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
