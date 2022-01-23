CREATE TYPE [dbo].[State] AS TABLE(
	[ShortName] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LongName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsMaxTaxApplicable] [bit] NOT NULL,
	[IsTaxable] [bit] NOT NULL,
	[DefaultTaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
