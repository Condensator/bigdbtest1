CREATE TYPE [dbo].[ProgramRateCard] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[RateCardFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[RateCardFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[RateCardFile_Content] [varbinary](82) NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RateCardId] [bigint] NULL,
	[ProgramDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
